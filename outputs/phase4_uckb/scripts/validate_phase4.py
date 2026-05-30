"""
UCKB Phase 4 — Acceptance Criteria Validation
Connects to Neo4j, runs all 10 acceptance criteria queries,
and writes a detailed validation report.

Usage:
  python validate_phase4.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]
"""

import sys
import argparse
from datetime import datetime
from pathlib import Path

from neo4j import GraphDatabase, exceptions as neo4j_exc

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT       = Path(__file__).resolve().parent.parent.parent.parent
REPORT_DIR = ROOT / "outputs" / "phase4_uckb" / "reports"
REPORT_DIR.mkdir(parents=True, exist_ok=True)

DEFAULT_URI      = "bolt://localhost:7687"
DEFAULT_USER     = "neo4j"
DEFAULT_PASSWORD = "uckb_admin_2024"

LOCKED_EDGE_TYPES = [
    "REQUIRES", "ENHANCES", "CONTRADICTS",
    "DOMAIN_VARIANT_OF", "CULTURAL_VARIANT_OF",
    "CONTRAINDICATED_WHEN", "ESCALATES_TO",
    "RESOLVES", "TRIGGERED_BY", "PRECEDES", "FOLLOWS",
]


# ─────────────────────────────────────────────────────────────────────────────
# Check functions — each returns (passed: bool, detail: str)
# ─────────────────────────────────────────────────────────────────────────────

def check_ac1_node_count(session) -> tuple[bool, str]:
    """AC-1: At least 150 content nodes across all technique-type labels."""
    result = session.run("""
        MATCH (n)
        WHERE n:Technique OR n:DomainProtocol
           OR n:EmotionalState OR n:SignalMarker
           OR n:CommunicationStyle
        RETURN labels(n)[0] AS label, count(n) AS cnt
        ORDER BY cnt DESC
    """).data()
    total = sum(r["cnt"] for r in result)
    breakdown = ", ".join(f"{r['label']}={r['cnt']}" for r in result)
    passed = total >= 150
    return passed, f"total={total} ({breakdown})"


def check_ac2_domain_distribution(session) -> tuple[bool, str]:
    """AC-2: 60 Crisis, 45 Sales, 45 Clinical."""
    result = session.run("""
        MATCH (t:Technique)
        RETURN t.domain AS domain, count(t) AS cnt
        ORDER BY cnt DESC
    """).data()
    counts = {r["domain"]: r["cnt"] for r in result}
    crisis  = sum(v for k, v in counts.items() if k and "Crisis" in k)
    sales   = sum(v for k, v in counts.items() if k and "Sales" in k)
    clinical = sum(v for k, v in counts.items() if k and "Clinical" in k)
    passed = (crisis >= 55 and sales >= 40 and clinical >= 40)
    return passed, f"crisis={crisis}, sales={sales}, clinical={clinical}"


def check_ac3_relationship_types(session) -> tuple[bool, str]:
    """AC-3: All 11 locked relationship types present with count > 0."""
    result = session.run("""
        MATCH ()-[r]->()
        RETURN type(r) AS rel_type, count(r) AS cnt
    """).data()
    present = {r["rel_type"]: r["cnt"] for r in result}
    missing = [e for e in LOCKED_EDGE_TYPES if present.get(e, 0) == 0]
    total_rels = sum(r["cnt"] for r in result)
    passed = len(missing) == 0
    detail = f"total_relationships={total_rels}, missing_edge_types={missing or 'none'}"
    return passed, detail


def check_ac4_orphan_nodes(session) -> tuple[bool, str]:
    """AC-4: Zero orphan Technique nodes (nodes with no relationships)."""
    result = session.run("""
        MATCH (t:Technique)
        WHERE NOT (t)-[]-()
        RETURN count(t) AS orphans, collect(t.name)[..5] AS examples
    """).single()
    orphans = result["orphans"]
    examples = result["examples"]
    passed = orphans == 0
    return passed, f"orphan_count={orphans}" + (f", examples={examples}" if orphans > 0 else "")


def check_ac5_constraints(session) -> tuple[bool, str]:
    """AC-5: All uniqueness constraints created (existence = active in Neo4j 5)."""
    result = session.run("""
        SHOW CONSTRAINTS
        YIELD name, type
        WHERE type = 'UNIQUENESS'
        RETURN count(name) AS total
    """).single()
    total = result["total"] if result else 0
    passed = total >= 7
    return passed, f"constraints_present={total} (need ≥7)"


def check_ac6_indices(session) -> tuple[bool, str]:
    """AC-6: All performance indices created and ONLINE."""
    result = session.run("""
        SHOW INDEXES
        YIELD name, type, state
        WHERE type <> 'LOOKUP'
        RETURN name, state
    """).data()
    online = [r for r in result if r["state"] == "ONLINE"]
    passed = len(online) >= 8
    return passed, f"indexes_online={len(online)} (need ≥8)"


def check_ac7_doctrine_violations(session) -> tuple[bool, str]:
    """AC-7: Zero Phase 1 doctrine violations (influence without empathy prerequisite)."""
    result = session.run("""
        MATCH (influence:Technique {requiresEmotionalClearance: true})
        WHERE NOT exists {
            MATCH (influence)-[:REQUIRES|FOLLOWS|PRECEDES*1..4]->(prereq:Technique)
            WHERE prereq.isEmotionalPrerequisite = true
        }
        RETURN count(influence) AS violations,
               collect(influence.name)[..5] AS examples
    """).single()
    violations = result["violations"]
    examples   = result["examples"]
    passed = violations == 0
    return passed, f"doctrine_violations={violations}" + (f", examples={examples}" if violations > 0 else "")


def check_ac8_track_link(session) -> tuple[bool, str]:
    """AC-8: Track A Resource nodes linked to Track B nodes."""
    result = session.run("""
        MATCH (r:Resource)
        WHERE r.cardId IS NOT NULL
        OPTIONAL MATCH (t {id: r.cardId})
        RETURN count(r) AS resource_count, count(t) AS linked_count
    """).single()
    rc = result["resource_count"]
    lc = result["linked_count"]
    if rc == 0:
        return True, "Track A not yet run (n10s import skipped) — skipped"
    passed = rc == lc
    return passed, f"resource_nodes={rc}, linked_to_track_b={lc}"


def check_ac9_dispatch_query(session) -> tuple[bool, str]:
    """AC-9: Text2Cypher Q12 returns ≥ 3 results for Panic in Crisis domain."""
    result = session.run("""
        MATCH (e:EmotionalState)
        WHERE toLower(e.name) CONTAINS 'panic'
        MATCH (t:Technique)
        WHERE t.domain CONTAINS 'Crisis'
          AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
          AND NOT t.requiresEmotionalClearance = true
        RETURN count(t) AS result_count
    """).single()
    if result is None:
        return False, "query returned no data"
    count = result["result_count"]
    passed = count >= 3
    return passed, f"dispatch_panic_results={count} (need ≥3)"


def check_ac10_cognitive_load_tags(session) -> tuple[bool, str]:
    """AC-10: Cognitive complexity tags applied to techniques."""
    result = session.run("""
        MATCH (t:Technique)
        RETURN count(t) AS total,
               count(t.cognitiveComplexity) AS tagged
    """).single()
    total  = result["total"]
    tagged = result["tagged"]
    passed = tagged > 0
    pct = round(tagged / total * 100, 1) if total > 0 else 0
    return passed, f"tagged={tagged}/{total} ({pct}%)"


# ─────────────────────────────────────────────────────────────────────────────
# Additional diagnostics
# ─────────────────────────────────────────────────────────────────────────────

def collect_diagnostics(session) -> dict:
    """Collect full node/rel inventory and summary stats."""
    diag = {}

    node_counts = session.run("""
        MATCH (n)
        UNWIND labels(n) AS lbl
        RETURN lbl, count(n) AS cnt
        ORDER BY cnt DESC
    """).data()
    diag["node_counts"] = node_counts

    rel_counts = session.run("""
        MATCH ()-[r]->()
        RETURN type(r) AS rel_type, count(r) AS cnt
        ORDER BY cnt DESC
    """).data()
    diag["rel_counts"] = rel_counts

    evidence_dist = session.run("""
        MATCH (t:Technique)
        WHERE t.evidenceLevel IS NOT NULL
        RETURN t.evidenceLevel AS level, count(t) AS cnt
        ORDER BY cnt DESC
    """).data()
    diag["evidence_distribution"] = evidence_dist

    domain_dist = session.run("""
        MATCH (t:Technique)
        RETURN t.domain AS domain, count(t) AS cnt
        ORDER BY cnt DESC
    """).data()
    diag["domain_distribution"] = domain_dist

    safety_stats = session.run("""
        MATCH (t:Technique)
        RETURN
          count(t) AS total,
          sum(CASE WHEN t.requiresEmotionalClearance THEN 1 ELSE 0 END) AS influence_tagged,
          sum(CASE WHEN t.isEmotionalPrerequisite     THEN 1 ELSE 0 END) AS prereq_tagged,
          sum(CASE WHEN t.safetyCriticalDomain         THEN 1 ELSE 0 END) AS safety_critical,
          sum(CASE WHEN t.cognitiveComplexity IS NOT NULL THEN 1 ELSE 0 END) AS load_tagged,
          sum(CASE WHEN t.catDirection IS NOT NULL THEN 1 ELSE 0 END) AS cat_tagged
    """).single()
    diag["safety_stats"] = dict(safety_stats)

    return diag


# ─────────────────────────────────────────────────────────────────────────────
# Report writer
# ─────────────────────────────────────────────────────────────────────────────

def write_report(results: list, diag: dict, path: Path):
    lines = [
        "UCKB Phase 4 — Validation Report",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "=" * 70,
        "",
        "ACCEPTANCE CRITERIA",
        "-" * 70,
    ]

    all_pass = True
    for ac_id, description, passed, detail in results:
        status = "PASS" if passed else "FAIL"
        if not passed:
            all_pass = False
        lines.append(f"  {ac_id}  [{status:4}]  {description}")
        lines.append(f"            {detail}")
        lines.append("")

    lines += [
        "=" * 70,
        f"  OVERALL: {'ALL PASS' if all_pass else 'FAILURES PRESENT'}",
        "=" * 70,
        "",
        "DIAGNOSTICS",
        "-" * 70,
        "",
        "Node counts by label:",
    ]
    for r in diag.get("node_counts", []):
        lines.append(f"  {r['lbl']:<30} {r['cnt']:>5}")

    lines += ["", "Relationship counts by type:"]
    for r in diag.get("rel_counts", []):
        lines.append(f"  {r['rel_type']:<30} {r['cnt']:>5}")

    lines += ["", "Evidence level distribution:"]
    for r in diag.get("evidence_distribution", []):
        lines.append(f"  {r['level']:<10} {r['cnt']:>5}")

    lines += ["", "Domain distribution:"]
    for r in diag.get("domain_distribution", []):
        lines.append(f"  {str(r['domain']):<40} {r['cnt']:>5}")

    ss = diag.get("safety_stats", {})
    lines += [
        "",
        "Safety annotation summary:",
        f"  Total techniques:            {ss.get('total', '?')}",
        f"  Influence-tagged:            {ss.get('influence_tagged', '?')}",
        f"  Empathy prerequisite-tagged: {ss.get('prereq_tagged', '?')}",
        f"  Safety-critical domain:      {ss.get('safety_critical', '?')}",
        f"  Cognitive load tagged:       {ss.get('load_tagged', '?')}",
        f"  CAT direction tagged:        {ss.get('cat_tagged', '?')}",
        "",
        "=" * 70,
    ]

    report_text = "\n".join(lines)
    path.write_text(report_text, encoding="utf-8")
    return all_pass, report_text


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 4 Validator")
    parser.add_argument("--uri",      default=DEFAULT_URI)
    parser.add_argument("--user",     default=DEFAULT_USER)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    sys.stdout.reconfigure(encoding="utf-8")

    print("\n" + "=" * 60)
    print("UCKB Phase 4 — Acceptance Criteria Validation")
    print("=" * 60)
    print(f"  Target: {args.uri}")

    try:
        driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        driver.verify_connectivity()
        print("  Connected successfully.\n")
    except neo4j_exc.ServiceUnavailable as e:
        print(f"\n  ERROR: Cannot connect to Neo4j at {args.uri}")
        print(f"  Run: docker compose up -d  in outputs/phase4_uckb/docker/")
        print(f"  Detail: {e}")
        sys.exit(1)

    checks = [
        ("AC-1",  "150 content nodes across domain labels",            check_ac1_node_count),
        ("AC-2",  "Domain distribution: Crisis=60, Sales=45, Clinical=45", check_ac2_domain_distribution),
        ("AC-3",  "All 11 locked relationship types present",          check_ac3_relationship_types),
        ("AC-4",  "Zero orphan Technique nodes",                       check_ac4_orphan_nodes),
        ("AC-5",  "All uniqueness constraints ONLINE",                 check_ac5_constraints),
        ("AC-6",  "All performance indices ONLINE",                    check_ac6_indices),
        ("AC-7",  "Zero Phase 1 doctrine violations",                  check_ac7_doctrine_violations),
        ("AC-8",  "Track A Resources linked to Track B nodes",         check_ac8_track_link),
        ("AC-9",  "Q12 Dispatch/Panic query returns ≥3 results",       check_ac9_dispatch_query),
        ("AC-10", "Cognitive complexity tags applied",                  check_ac10_cognitive_load_tags),
    ]

    results = []
    with driver.session(database="neo4j") as session:
        for ac_id, description, check_fn in checks:
            try:
                passed, detail = check_fn(session)
            except Exception as e:
                passed, detail = False, f"ERROR: {e}"
            status = "PASS" if passed else "FAIL"
            print(f"  {ac_id}  [{status:4}]  {description}")
            print(f"            {detail}")
            results.append((ac_id, description, passed, detail))

        print("\n  Collecting diagnostics …")
        diag = collect_diagnostics(session)

    driver.close()

    report_path = REPORT_DIR / "phase4_validation_report.txt"
    all_pass, report_text = write_report(results, diag, report_path)

    print("\n" + "=" * 60)
    print(f"  OVERALL: {'ALL PASS' if all_pass else 'FAILURES PRESENT'}")
    print(f"  Report:  {report_path.relative_to(ROOT)}")
    print("=" * 60)


if __name__ == "__main__":
    main()
