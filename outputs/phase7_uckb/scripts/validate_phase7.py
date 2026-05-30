"""
UCKB Phase 7 — Validation Script
Runs all 8 acceptance criteria against a running Neo4j instance and writes
outputs/phase7_uckb/reports/phase7_validation_report.txt.

Usage:
  python validate_phase7.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]
"""

import sys
import io
import argparse
from datetime import datetime
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from neo4j import GraphDatabase, exceptions as neo4j_exc

ROOT   = Path(__file__).resolve().parent.parent.parent.parent
REPORT = ROOT / "outputs" / "phase7_uckb" / "reports" / "phase7_validation_report.txt"
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


# ─────────────────────────────────────────────────────────────────────────────
# Acceptance Criteria checks
# ─────────────────────────────────────────────────────────────────────────────

def check_ac1(session):
    """AC-1: All 10 CulturalProfile nodes present with >=4 Hofstede dimension scores."""
    rows, err = run_query(session, """
        MATCH (cp:CulturalProfile)
        WITH cp,
             CASE WHEN cp.hofstedePDI IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN cp.hofstedeIDV IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN cp.hofstedeMAS IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN cp.hofstedeUAI IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN cp.hofstedeLTO IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN cp.hofstedeIVR IS NOT NULL THEN 1 ELSE 0 END
             AS hofstede_score_count
        RETURN count(cp) AS total,
               count(CASE WHEN hofstede_score_count >= 4 THEN 1 END) AS complete,
               round(100.0 * count(CASE WHEN hofstede_score_count >= 4 THEN 1 END) / count(cp), 1) AS pct
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["total"] == 10 and r["pct"] == 100.0)
    detail = f"total={r['total']}, complete={r['complete']} ({r['pct']}% — need 10 at 100%)"
    return passed, detail


def check_ac2(session):
    """AC-2: Each CulturalProfile has >=3 HAS_DIMENSION links to CulturalContext nodes."""
    rows, err = run_query(session, """
        MATCH (cp:CulturalProfile)
        OPTIONAL MATCH (cp)-[:HAS_DIMENSION]->(c:CulturalContext)
        WITH cp, count(c) AS dimension_count
        RETURN count(cp) AS total,
               count(CASE WHEN dimension_count >= 3 THEN 1 END) AS with_3plus_dims,
               round(100.0 * count(CASE WHEN dimension_count >= 3 THEN 1 END) / count(cp), 1) AS pct,
               min(dimension_count) AS min_dims
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["pct"] == 100.0)
    detail = f"profiles_with_3plus_dims={r['with_3plus_dims']}/{r['total']} ({r['pct']}% — need 100%), min={r['min_dims']}"
    return passed, detail


def check_ac3(session):
    """AC-3: Each CulturalProfile has >=1 APPLIES_RULE link to a CulturalAdaptationRule."""
    rows, err = run_query(session, """
        MATCH (cp:CulturalProfile)
        OPTIONAL MATCH (cp)-[:APPLIES_RULE]->(r:CulturalAdaptationRule)
        WITH cp, count(r) AS rule_count
        RETURN count(cp) AS total,
               count(CASE WHEN rule_count >= 1 THEN 1 END) AS with_rules,
               round(100.0 * count(CASE WHEN rule_count >= 1 THEN 1 END) / count(cp), 1) AS pct
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["pct"] == 100.0)
    detail = f"profiles_with_rules={r['with_rules']}/{r['total']} ({r['pct']}% — need 100%)"
    return passed, detail


def check_ac4(session):
    """AC-4: All 7 BehavioralStyleProfile nodes have >=1 STYLE_SUGGESTS link to Technique."""
    rows, err = run_query(session, """
        MATCH (bsp:BehavioralStyleProfile)
        OPTIONAL MATCH (bsp)-[:STYLE_SUGGESTS]->(t:Technique)
        WITH bsp, count(t) AS technique_count
        RETURN count(bsp) AS total,
               count(CASE WHEN technique_count >= 1 THEN 1 END) AS with_techniques,
               round(100.0 * count(CASE WHEN technique_count >= 1 THEN 1 END) / count(bsp), 1) AS pct
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["total"] == 7 and r["pct"] == 100.0)
    detail = f"bsp_with_techniques={r['with_techniques']}/{r['total']} ({r['pct']}% — need 7 at 100%)"
    return passed, detail


def check_ac5(session):
    """AC-5: adaptor_emblem RECALIBRATE_IN >=3; facs_microexpression RECALIBRATE_IN >=2."""
    rows_emblem, err1 = run_query(session, """
        MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})-[:RECALIBRATE_IN]->(c:CulturalContext)
        RETURN count(DISTINCT c) AS n
    """)
    rows_facs, err2 = run_query(session, """
        MATCH (facs:FacsMapping {id: "facs_microexpression"})-[:RECALIBRATE_IN]->(c:CulturalContext)
        RETURN count(DISTINCT c) AS n
    """)
    if err1 or err2 or not rows_emblem or not rows_facs:
        return False, f"QUERY ERROR: {err1 or err2}"
    emblem_n = rows_emblem[0]["n"]
    facs_n   = rows_facs[0]["n"]
    passed   = (emblem_n >= 3 and facs_n >= 2)
    detail   = f"adaptor_emblem={emblem_n} (need >=3), facs_microexpression={facs_n} (need >=2)"
    return passed, detail


def check_ac6(session):
    """AC-6: ADAPTS_FOR relationships (Technique -> CulturalContext) total >= 10."""
    rows, err = run_query(session, """
        MATCH (t:Technique)-[r:ADAPTS_FOR]->(c:CulturalContext)
        RETURN count(r) AS total,
               count(DISTINCT t) AS distinct_techniques,
               count(DISTINCT c) AS distinct_contexts
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["total"] >= 10)
    detail = f"total={r['total']} (distinct_techniques={r['distinct_techniques']}, distinct_contexts={r['distinct_contexts']}) — need >=10"
    return passed, detail


def check_ac7(session):
    """AC-7: Zero Phase 1 doctrine violations in behavioral style routing paths."""
    rows, err = run_query(session, """
        MATCH (bsp:BehavioralStyleProfile)-[:STYLE_SUGGESTS]->(t:Technique)
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


def check_ac8(session):
    """AC-8: C5 full cultural turn returns >=1 result for 3 scenarios."""
    results = {}

    # Scenario A: Japan profile + Distress
    rows, err = run_query(session, """
        MATCH (cp:CulturalProfile {id: "culture_japan"})
        MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
        MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
        MATCH (t:Technique)-[:ADAPTS_FOR]->(dim)
        WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
          AND NOT t.requiresEmotionalClearance = true
        RETURN count(t) AS n LIMIT 1
    """)
    results["japan_distress"] = rows[0]["n"] if rows else 0

    # Scenario B: Germany profile + Hostile
    rows, err = run_query(session, """
        MATCH (cp:CulturalProfile {id: "culture_germany"})
        MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
        MATCH (e:EmotionalState) WHERE toLower(e.name) = "hostile"
        MATCH (t:Technique)-[:ADAPTS_FOR]->(dim)
        WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
          AND NOT t.requiresEmotionalClearance = true
        RETURN count(t) AS n LIMIT 1
    """)
    results["germany_hostile"] = rows[0]["n"] if rows else 0

    # Scenario C: Arab World profile + adaptor_emblem disambiguation
    rows, err = run_query(session, """
        MATCH (cp:CulturalProfile {id: "culture_arab_world"})
        MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
        MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})-[:RECALIBRATE_IN]->(dim)
        MATCH (rule:CulturalAdaptationRule {id: "rule_emblem_disambiguation"})
        MATCH (cp)-[:APPLIES_RULE]->(rule)
        RETURN count(*) AS n LIMIT 1
    """)
    results["arab_world_emblem"] = rows[0]["n"] if rows else 0

    passed = all(n >= 1 for n in results.values())
    detail = ", ".join(f"{scenario}={n}" for scenario, n in results.items()) + " (need >=1 each)"
    return passed, detail


CHECKS = [
    ("AC-1", "All 10 CulturalProfile nodes present with >=4 Hofstede dimension scores",       check_ac1),
    ("AC-2", "Each CulturalProfile has >=3 HAS_DIMENSION links to CulturalContext nodes",      check_ac2),
    ("AC-3", "Each CulturalProfile has >=1 APPLIES_RULE link to a CulturalAdaptationRule",    check_ac3),
    ("AC-4", "All 7 BehavioralStyleProfile nodes have >=1 STYLE_SUGGESTS link to Technique",  check_ac4),
    ("AC-5", "adaptor_emblem RECALIBRATE_IN >=3; facs_microexpression RECALIBRATE_IN >=2",    check_ac5),
    ("AC-6", "ADAPTS_FOR relationships (Technique -> CulturalContext) total >= 10",            check_ac6),
    ("AC-7", "Zero Phase 1 doctrine violations in behavioral style routing paths",              check_ac7),
    ("AC-8", "C5 full cultural turn returns >=1 result for 3 scenarios",                       check_ac8),
]


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 7 Validator")
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
    lines.append("UCKB Phase 7 — Validation Report")
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

    # Diagnostics section
    lines.append("")
    lines.append("DIAGNOSTICS")
    lines.append("-" * 70)

    try:
        driver2 = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        with driver2.session() as session:

            # Phase 7 node counts
            rows, _ = run_query(session, """
                MATCH (n)
                WHERE n:CulturalProfile OR n:CulturalAdaptationRule OR n:BehavioralStyleProfile
                RETURN labels(n)[0] AS label, count(n) AS cnt
                ORDER BY label
            """)
            lines.append("\nPhase 7 node counts:")
            for r in rows:
                lines.append(f"  {r['label']:<30} {r['cnt']}")

            # Phase 7 relationship counts
            rows, _ = run_query(session, """
                MATCH ()-[r]->()
                WHERE type(r) IN ['HAS_DIMENSION','APPLIES_RULE','STYLE_SUGGESTS',
                                  'ADAPTS_FOR','RECALIBRATE_IN','PREFERS_STYLE']
                RETURN type(r) AS rel_type, count(r) AS cnt
                ORDER BY cnt DESC
            """)
            lines.append("\nPhase 7 relationship counts:")
            for r in rows:
                lines.append(f"  {r['rel_type']:<30} {r['cnt']}")

            # HAS_DIMENSION per CulturalProfile
            rows, _ = run_query(session, """
                MATCH (cp:CulturalProfile)
                OPTIONAL MATCH (cp)-[:HAS_DIMENSION]->(c:CulturalContext)
                RETURN cp.name AS profile, count(c) AS dimensions
                ORDER BY cp.name
            """)
            lines.append("\nCulturalProfile HAS_DIMENSION coverage:")
            for r in rows:
                lines.append(f"  {r['profile']:<30} {r['dimensions']} dimensions")

            # APPLIES_RULE per CulturalProfile
            rows, _ = run_query(session, """
                MATCH (cp:CulturalProfile)
                OPTIONAL MATCH (cp)-[:APPLIES_RULE]->(r:CulturalAdaptationRule)
                RETURN cp.name AS profile, count(r) AS rules, collect(r.name)[0..3] AS sample_rules
                ORDER BY cp.name
            """)
            lines.append("\nCulturalProfile APPLIES_RULE coverage:")
            for r in rows:
                lines.append(f"  {r['profile']:<30} {r['rules']} rules -> {r['sample_rules']}")

            # STYLE_SUGGESTS per BehavioralStyleProfile
            rows, _ = run_query(session, """
                MATCH (bsp:BehavioralStyleProfile)
                OPTIONAL MATCH (bsp)-[:STYLE_SUGGESTS]->(t:Technique)
                RETURN bsp.name AS profile, count(t) AS techniques
                ORDER BY bsp.name
            """)
            lines.append("\nBehavioralStyleProfile STYLE_SUGGESTS coverage:")
            for r in rows:
                lines.append(f"  {r['profile']:<30} {r['techniques']} techniques")

            # RECALIBRATE_IN coverage
            rows, _ = run_query(session, """
                MATCH (src)-[r:RECALIBRATE_IN]->(c:CulturalContext)
                WHERE src:BehavioralAdaptor OR src:FacsMapping
                RETURN labels(src)[0] AS source_type, src.id AS source_id, c.name AS cultural_context, r.signal AS signal
                ORDER BY source_type, source_id
            """)
            lines.append("\nRECALIBRATE_IN coverage:")
            for r in rows:
                sig = r["signal"] or "gesture"
                lines.append(f"  {r['source_type']:<22} {r['source_id']:<25} -> {r['cultural_context']} ({sig})")

            # PREFERS_STYLE coverage
            rows, _ = run_query(session, """
                MATCH (c:CulturalContext)-[:PREFERS_STYLE]->(cs:CommunicationStyle)
                RETURN c.name AS dimension, collect(cs.name) AS preferred_styles
                ORDER BY c.name
            """)
            lines.append("\nPREFERS_STYLE (CulturalContext -> CommunicationStyle):")
            for r in rows:
                lines.append(f"  {r['dimension']:<30} -> {r['preferred_styles']}")

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
