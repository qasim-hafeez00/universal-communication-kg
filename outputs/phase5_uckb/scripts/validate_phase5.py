"""
UCKB Phase 5 — Validation Script
Runs all 8 acceptance criteria against a running Neo4j instance and writes
outputs/phase5_uckb/reports/phase5_validation_report.txt.

Usage:
  python validate_phase5.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]
"""

import sys
import io
import argparse
from datetime import datetime
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from neo4j import GraphDatabase, exceptions as neo4j_exc

ROOT    = Path(__file__).resolve().parent.parent.parent.parent
REPORT  = ROOT / "outputs" / "phase5_uckb" / "reports" / "phase5_validation_report.txt"
REPORT.parent.mkdir(parents=True, exist_ok=True)

DEFAULT_URI      = "bolt://localhost:7687"
DEFAULT_USER     = "neo4j"
DEFAULT_PASSWORD = "uckb_admin_2024"


def run_query(session, cypher: str, params: dict = None):
    try:
        result = session.run(cypher, params or {})
        return list(result), None
    except neo4j_exc.Neo4jError as e:
        return [], str(e)


def check_ac1(session):
    """AC-1: All 6 ISO dimensions present."""
    rows, err = run_query(session,
        "MATCH (d:DialogueDimension) RETURN count(d) AS n, collect(d.name) AS names")
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["n"]
    names = sorted(rows[0]["names"])
    passed = (n == 6)
    detail = f"total={n} ({', '.join(names)})"
    return passed, detail


def check_ac2(session):
    """AC-2: >=30 DialogueAct nodes."""
    rows, err = run_query(session,
        "MATCH (a:DialogueAct) RETURN count(a) AS n")
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["n"]
    passed = (n >= 30)
    detail = f"total={n} (need >=30)"
    return passed, detail


def check_ac3(session):
    """AC-3: >=90% DialogueActs have >=1 TRIGGERS link."""
    rows, err = run_query(session, """
        MATCH (a:DialogueAct) WITH count(a) AS total
        MATCH (linked:DialogueAct)-[:TRIGGERS]->(:Technique)
        WITH total, count(DISTINCT linked) AS linked_count
        RETURN total, linked_count,
               round(100.0 * linked_count / total, 1) AS pct
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["pct"] >= 90.0)
    detail = f"linked={r['linked_count']}/{r['total']} ({r['pct']}% — need >=90%)"
    return passed, detail


def check_ac4(session):
    """AC-4: 5 DomainSlot nodes per domain."""
    rows, err = run_query(session,
        "MATCH (s:DomainSlot) RETURN s.domain AS domain, count(s) AS n ORDER BY domain")
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    detail_parts = []
    passed = True
    for r in rows:
        ok = (r["n"] == 5)
        if not ok:
            passed = False
        detail_parts.append(f"{r['domain']}={r['n']}")
    detail = ", ".join(detail_parts) + " (need 5 each)"
    return passed, detail


def check_ac5(session):
    """AC-5: >=10 FUNCTIONAL_DEPENDENCY relationships."""
    rows, err = run_query(session,
        "MATCH ()-[r:FUNCTIONAL_DEPENDENCY]->() RETURN count(r) AS n")
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["n"]
    passed = (n >= 10)
    detail = f"total={n} (need >=10)"
    return passed, detail


def check_ac6(session):
    """AC-6: Zero Phase 1 doctrine violations."""
    rows, err = run_query(session, """
        MATCH (a:DialogueAct {requiresInfluencePrereq: true})-[:TRIGGERS]->(t:Technique)
        WHERE t.requiresEmotionalClearance = true
          AND NOT exists {
            MATCH (prereq:Technique {isEmotionalPrerequisite: true})-[:PRECEDES]->(t)
          }
        RETURN count(*) AS violations
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["violations"]
    passed = (n == 0)
    detail = f"violations={n} (need 0)"
    return passed, detail


def check_ac7(session):
    """AC-7: All DialogueAct nodes carry all 8 ISO mandatory properties."""
    rows, err = run_query(session, """
        MATCH (a:DialogueAct)
        WITH a,
             CASE WHEN a.communicativeFunction   IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN a.dimension               IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN a.sentiment               IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN a.certainty               IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN a.conditionality          IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN a.typicalSender           IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN a.requiresGrounding       IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN a.requiresInfluencePrereq IS NOT NULL THEN 1 ELSE 0 END
             AS score
        RETURN count(a) AS total,
               count(CASE WHEN score = 8 THEN 1 END) AS complete,
               round(100.0 * count(CASE WHEN score = 8 THEN 1 END) / count(a), 1) AS pct
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["pct"] == 100.0)
    detail = f"complete={r['complete']}/{r['total']} ({r['pct']}% — need 100%)"
    return passed, detail


def check_ac8(session):
    """AC-8: BDI B6 full-turn query returns >=1 result per domain."""
    results = {}
    for domain, state in [
        ("Crisis Dispatch", "panic"),
        ("Clinical",        "grief"),
        ("Sales",           "defensive"),
    ]:
        rows, err = run_query(session, """
            MATCH (bdi:BDIState {domain: $domain})-[:HAS_SLOT]->(s:DomainSlot)
            WITH bdi, collect({slot: s.slotName, filled: s.filled}) AS slots
            MATCH (e:EmotionalState)
            WHERE toLower(e.name) CONTAINS toLower($state)
            MATCH (a:DialogueAct)
            WHERE NOT (a)-[:CONTRAINDICATED_WHEN]->(e)
              AND NOT a.requiresInfluencePrereq = true
            MATCH (a)-[:TRIGGERS]->(t:Technique)
            WHERE t.domain CONTAINS $domainKey
              AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
              AND NOT t.requiresEmotionalClearance = true
            RETURN a.communicativeFunction AS act, t.name AS technique LIMIT 1
        """, {"domain": domain, "state": state,
              "domainKey": domain.split()[0]})
        results[domain] = len(rows)

    passed = all(n >= 1 for n in results.values())
    detail = ", ".join(f"{d}={n}" for d, n in results.items()) + " (need >=1 each)"
    return passed, detail


CHECKS = [
    ("AC-1", "All 6 ISO dimensions present as DialogueDimension nodes", check_ac1),
    ("AC-2", ">=30 DialogueAct communicativeFunction types present",     check_ac2),
    ("AC-3", ">=90% DialogueActs linked via TRIGGERS to Technique",      check_ac3),
    ("AC-4", "DomainSlot nodes per domain == 5 (Dispatch, Clinical, Sales)", check_ac4),
    ("AC-5", "FUNCTIONAL_DEPENDENCY relationships >= 10",                check_ac5),
    ("AC-6", "Zero Phase 1 violations: influence acts lack prereqs",     check_ac6),
    ("AC-7", "All DialogueAct nodes carry all 8 ISO mandatory properties", check_ac7),
    ("AC-8", "BDI B6 full-turn query returns >=1 result per domain",    check_ac8),
]


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 5 Validator")
    parser.add_argument("--uri",      default=DEFAULT_URI)
    parser.add_argument("--user",     default=DEFAULT_USER)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    try:
        driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        driver.verify_connectivity()
    except Exception as e:
        print(f"FATAL: Cannot connect to Neo4j at {args.uri}: {e}")
        sys.exit(1)

    lines = []
    lines.append("UCKB Phase 5 — Validation Report")
    lines.append(f"Generated: {datetime.now():%Y-%m-%d %H:%M:%S}")
    lines.append("=" * 70)
    lines.append("")
    lines.append("ACCEPTANCE CRITERIA")
    lines.append("-" * 70)

    results = []
    with driver.session() as session:
        for ac_id, description, check_fn in CHECKS:
            passed, detail = check_fn(session)
            results.append(passed)
            status = "PASS" if passed else "FAIL"
            lines.append(f"  {ac_id}  [{status}]  {description}")
            lines.append(f"            {detail}")
            lines.append("")

    driver.close()

    all_pass = all(results)
    lines.append("=" * 70)
    lines.append(f"  OVERALL: {'ALL PASS' if all_pass else 'FAILURES DETECTED'}")
    lines.append("=" * 70)

    # Diagnostics
    lines.append("")
    lines.append("DIAGNOSTICS")
    lines.append("-" * 70)

    try:
        driver2 = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        with driver2.session() as session:
            # Node counts
            rows, _ = run_query(session, """
                MATCH (n)
                WHERE n:DialogueAct OR n:DialogueDimension OR n:DomainSlot OR n:BDIState
                RETURN labels(n)[0] AS label, count(n) AS cnt
                ORDER BY label
            """)
            lines.append("\nPhase 5 node counts:")
            for r in rows:
                lines.append(f"  {r['label']:<25} {r['cnt']}")

            # Relationship counts
            rows, _ = run_query(session, """
                MATCH ()-[r]->()
                WHERE type(r) IN ['BELONGS_TO_DIMENSION','FUNCTIONAL_DEPENDENCY',
                                  'REQUIRES_ACT','HAS_SLOT']
                RETURN type(r) AS rel_type, count(r) AS cnt
                ORDER BY cnt DESC
            """)
            lines.append("\nPhase 5 relationship counts:")
            for r in rows:
                lines.append(f"  {r['rel_type']:<30} {r['cnt']}")

            # Acts by dimension
            rows, _ = run_query(session, """
                MATCH (a:DialogueAct)-[:BELONGS_TO_DIMENSION]->(d:DialogueDimension)
                RETURN d.name AS dimension, count(a) AS acts ORDER BY dimension
            """)
            lines.append("\nDialogueActs by dimension:")
            for r in rows:
                lines.append(f"  {r['dimension']:<25} {r['acts']}")

            # TRIGGERS coverage
            rows, _ = run_query(session, """
                MATCH (a:DialogueAct)
                OPTIONAL MATCH (a)-[:TRIGGERS]->(t:Technique)
                RETURN a.communicativeFunction AS act,
                       count(t) AS triggers ORDER BY triggers DESC
            """)
            lines.append("\nTRIGGERS coverage (DialogueAct → Technique):")
            for r in rows:
                lines.append(f"  {r['act']:<30} {r['triggers']} techniques")

        driver2.close()
    except Exception as e:
        lines.append(f"\n[Diagnostics skipped: {e}]")

    lines.append("\n" + "=" * 70)

    report_text = "\n".join(lines)
    REPORT.write_text(report_text, encoding="utf-8")
    print(report_text)
    print(f"\nReport written to: {REPORT}")

    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
