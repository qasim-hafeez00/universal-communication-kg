"""
UCKB Phase 6 — Validation Script
Runs all 8 acceptance criteria against a running Neo4j instance and writes
outputs/phase6_uckb/reports/phase6_validation_report.txt.

Usage:
  python validate_phase6.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]
"""

import sys
import io
import argparse
from datetime import datetime
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from neo4j import GraphDatabase, exceptions as neo4j_exc

ROOT   = Path(__file__).resolve().parent.parent.parent.parent
REPORT = ROOT / "outputs" / "phase6_uckb" / "reports" / "phase6_validation_report.txt"
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
    """AC-1: All 4 EgoState nodes present with all 6 required properties."""
    rows, err = run_query(session, """
        MATCH (e:EgoState)
        WITH e,
             CASE WHEN e.berneCategory        IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN e.karpmanRole          IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN e.winnerTriangleTarget IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN e.linguisticMarkers    IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN e.agentAction          IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN e.isDysfunctional      IS NOT NULL THEN 1 ELSE 0 END
             AS score
        RETURN count(e) AS total,
               count(CASE WHEN score = 6 THEN 1 END) AS complete,
               round(100.0 * count(CASE WHEN score = 6 THEN 1 END) / count(e), 1) AS pct
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["total"] == 4 and r["pct"] == 100.0)
    detail = f"total={r['total']}, complete={r['complete']} ({r['pct']}% — need 4 nodes at 100%)"
    return passed, detail


def check_ac2(session):
    """AC-2: >=6 FacsMapping nodes with auCombination and routingAction."""
    rows, err = run_query(session, """
        MATCH (f:FacsMapping)
        WHERE f.auCombination IS NOT NULL AND f.routingAction IS NOT NULL
        RETURN count(f) AS n
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["n"]
    passed = (n >= 6)
    detail = f"facs_complete={n} (need >=6)"
    return passed, detail


def check_ac3(session):
    """AC-3: >=6 ProsodicFeature nodes with threshold value set."""
    rows, err = run_query(session, """
        MATCH (p:ProsodicFeature)
        WHERE p.threshold IS NOT NULL
        RETURN count(p) AS n
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["n"]
    passed = (n >= 6)
    detail = f"prosodic_with_threshold={n} (need >=6)"
    return passed, detail


def check_ac4(session):
    """AC-4: All 4 EgoState nodes have >=1 TRIGGERS link to a Technique."""
    rows, err = run_query(session, """
        MATCH (e:EgoState)
        OPTIONAL MATCH (e)-[:TRIGGERS]->(t:Technique)
        WITH e, count(t) AS trigger_count
        RETURN count(e) AS total,
               count(CASE WHEN trigger_count > 0 THEN 1 END) AS with_triggers,
               round(100.0 * count(CASE WHEN trigger_count > 0 THEN 1 END) / count(e), 1) AS pct
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["pct"] == 100.0)
    detail = f"ego_states_with_triggers={r['with_triggers']}/{r['total']} ({r['pct']}% — need 100%)"
    return passed, detail


def check_ac5(session):
    """AC-5: MAPS_TO_EGO_STATE relationships >= 10."""
    rows, err = run_query(session, """
        MATCH ()-[r:MAPS_TO_EGO_STATE]->()
        RETURN count(r) AS n
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["n"]
    passed = (n >= 10)
    detail = f"maps_to_ego_state={n} (need >=10)"
    return passed, detail


def check_ac6(session):
    """AC-6: INDICATES_EMOTION relationships (FacsMapping + ProsodicFeature + BehavioralAdaptor) >= 10."""
    rows, err = run_query(session, """
        MATCH (source)-[r:INDICATES_EMOTION]->(:EmotionalState)
        WHERE source:FacsMapping OR source:ProsodicFeature OR source:BehavioralAdaptor
        RETURN count(r) AS total,
               count(CASE WHEN source:FacsMapping       THEN 1 END) AS from_facs,
               count(CASE WHEN source:ProsodicFeature   THEN 1 END) AS from_prosodic,
               count(CASE WHEN source:BehavioralAdaptor THEN 1 END) AS from_adaptor
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = (r["total"] >= 10)
    detail = (f"total={r['total']} (FACS={r['from_facs']}, "
              f"Prosodic={r['from_prosodic']}, Adaptor={r['from_adaptor']}) — need >=10")
    return passed, detail


def check_ac7(session):
    """AC-7: Zero Phase 1 doctrine violations in ego-state routing paths."""
    rows, err = run_query(session, """
        MATCH (ego:EgoState)-[:TRIGGERS]->(t:Technique)
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
    """AC-8: M5 full nonverbal turn returns >=1 result for 3 scenarios."""
    results = {}

    # Scenario A: verbal-only (ego_adapted_child + Distress)
    rows, err = run_query(session, """
        MATCH (ego:EgoState {id: "ego_adapted_child"})
        MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
        MATCH (ego)-[:TRIGGERS]->(t:Technique)
        WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
          AND NOT t.requiresEmotionalClearance = true
        RETURN count(t) AS n LIMIT 1
    """)
    results["verbal-only"] = rows[0]["n"] if rows else 0

    # Scenario B: prosodic-incongruent (speech rate drop → Dissociated)
    rows, err = run_query(session, """
        MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
        MATCH (p)-[ie:INDICATES_EMOTION]->(prosodic_state:EmotionalState)
        WHERE ie.direction = "drop"
        MATCH (ego:EgoState {id: "ego_adapted_child"})
        MATCH (ego)-[:TRIGGERS]->(t:Technique)
        WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(prosodic_state)
          AND NOT t.requiresEmotionalClearance = true
        RETURN count(t) AS n LIMIT 1
    """)
    results["prosodic-incongruent"] = rows[0]["n"] if rows else 0

    # Scenario C: FACS anger (ego_critical_parent + facs_anger)
    rows, err = run_query(session, """
        MATCH (facs:FacsMapping {id: "facs_anger"})
        MATCH (facs)-[:INDICATES_EMOTION]->(facs_state:EmotionalState)
        MATCH (ego:EgoState {id: "ego_critical_parent"})
        MATCH (ego)-[:TRIGGERS]->(t:Technique)
        WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(facs_state)
          AND NOT t.requiresEmotionalClearance = true
        RETURN count(t) AS n LIMIT 1
    """)
    results["facs-anger"] = rows[0]["n"] if rows else 0

    passed = all(n >= 1 for n in results.values())
    detail = ", ".join(f"{scenario}={n}" for scenario, n in results.items()) + " (need >=1 each)"
    return passed, detail


CHECKS = [
    ("AC-1", "All 4 EgoState nodes present with all 6 required properties",         check_ac1),
    ("AC-2", ">=6 FacsMapping nodes with auCombination and routingAction",           check_ac2),
    ("AC-3", ">=6 ProsodicFeature nodes with threshold value set",                   check_ac3),
    ("AC-4", "All 4 EgoState nodes have >=1 TRIGGERS link to a Technique",           check_ac4),
    ("AC-5", "MAPS_TO_EGO_STATE relationships (SignalMarker -> EgoState) >= 10",     check_ac5),
    ("AC-6", "INDICATES_EMOTION relationships (FACS+Prosodic+Adaptor) >= 10",        check_ac6),
    ("AC-7", "Zero Phase 1 doctrine violations in ego-state routing paths",           check_ac7),
    ("AC-8", "M5 full nonverbal turn returns >=1 result for 3 scenarios",            check_ac8),
]


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 6 Validator")
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
    lines.append("UCKB Phase 6 — Validation Report")
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
            # Phase 6 node counts
            rows, _ = run_query(session, """
                MATCH (n)
                WHERE n:EgoState OR n:FacsMapping OR n:ProsodicFeature
                   OR n:BehavioralAdaptor OR n:ModalityWeight
                RETURN labels(n)[0] AS label, count(n) AS cnt
                ORDER BY label
            """)
            lines.append("\nPhase 6 node counts:")
            for r in rows:
                lines.append(f"  {r['label']:<25} {r['cnt']}")

            # Phase 6 relationship counts
            rows, _ = run_query(session, """
                MATCH ()-[r]->()
                WHERE type(r) IN ['MAPS_TO_EGO_STATE','INDICATES_EMOTION',
                                  'RESOLVES_EGO_STATE','BELONGS_TO_MODEL','MODALITY_OVERRIDES']
                RETURN type(r) AS rel_type, count(r) AS cnt
                ORDER BY cnt DESC
            """)
            lines.append("\nPhase 6 relationship counts:")
            for r in rows:
                lines.append(f"  {r['rel_type']:<30} {r['cnt']}")

            # EgoState → technique TRIGGERS counts
            rows, _ = run_query(session, """
                MATCH (e:EgoState)
                OPTIONAL MATCH (e)-[:TRIGGERS]->(t:Technique)
                RETURN e.name AS ego_state, count(t) AS triggers
                ORDER BY e.name
            """)
            lines.append("\nEgoState TRIGGERS coverage:")
            for r in rows:
                lines.append(f"  {r['ego_state']:<25} {r['triggers']} techniques")

            # MAPS_TO_EGO_STATE per ego state
            rows, _ = run_query(session, """
                MATCH (sm:SignalMarker)-[:MAPS_TO_EGO_STATE]->(e:EgoState)
                RETURN e.name AS ego_state, count(sm) AS signal_markers
                ORDER BY e.name
            """)
            lines.append("\nSignalMarker → EgoState (MAPS_TO_EGO_STATE):")
            for r in rows:
                lines.append(f"  {r['ego_state']:<25} {r['signal_markers']} markers")

            # INDICATES_EMOTION coverage
            rows, _ = run_query(session, """
                MATCH (src)-[:INDICATES_EMOTION]->(es:EmotionalState)
                WHERE src:FacsMapping OR src:ProsodicFeature OR src:BehavioralAdaptor
                RETURN labels(src)[0] AS source_type, src.id AS source_id, es.name AS emotion
                ORDER BY source_type, source_id
            """)
            lines.append("\nINDICATES_EMOTION coverage:")
            for r in rows:
                lines.append(f"  {r['source_type']:<22} {r['source_id']:<30} -> {r['emotion']}")

            # MODALITY_OVERRIDES chain
            rows, _ = run_query(session, """
                MATCH (mk:ModalityWeight)-[r:MODALITY_OVERRIDES]->(ms:ModalityWeight)
                RETURN mk.modalityType AS from_modality, mk.weight AS from_weight,
                       ms.modalityType AS to_modality, ms.weight AS to_weight
                ORDER BY mk.priority
            """)
            lines.append("\nMODALITY_OVERRIDES chain (Mehrabian 7-38-55):")
            for r in rows:
                lines.append(f"  {r['from_modality']} ({r['from_weight']}) -> {r['to_modality']} ({r['to_weight']})")

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
