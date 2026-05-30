"""
UCKB Phase 10 — Neo4j Import Script
Executes Cypher scripts 21-27 against a running Neo4j instance via the Bolt driver.

Usage:
    python import_phase10_neo4j.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]

Prerequisites:
    pip install neo4j
    Neo4j running with Phase 4-9 data already loaded.
"""

import sys
import argparse
from pathlib import Path

try:
    from neo4j import GraphDatabase, exceptions as neo4j_exc
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "neo4j", "-q"])
    from neo4j import GraphDatabase, exceptions as neo4j_exc

sys.stdout.reconfigure(encoding="utf-8")

ROOT   = Path(__file__).resolve().parents[1]
CYPHER = ROOT / "cypher"

DEFAULT_URI      = "bolt://localhost:7687"
DEFAULT_USER     = "neo4j"
DEFAULT_PASSWORD = "uckb_admin_2024"

SCRIPTS = [
    ("21_dsmart_schema.cypher",          "D-SMART schema — 6 constraints + 12 indices"),
    ("22_conversation_facts.cypher",     "Conversation facts — 18 ConversationFact nodes + EXTRACTED_FROM edges"),
    ("23_goal_tracking.cypher",          "Goal tracking — 3 GoalState nodes + HAS_GOAL edges"),
    ("24_protocol_trackers.cypher",      "Protocol trackers — 3 ProtocolTracker nodes + HAS_TRACKER + TRACKS edges"),
    ("25_conflict_detection.cypher",     "Conflict detection — 4 ConsistencyConflict + CONTRADICTS + SUPERSEDES + FLAGGED_DEVIATION"),
    ("26_reasoning_candidates.cypher",   "Reasoning candidates — 15 ReasoningCandidate + 3 ConsistencyReport nodes"),
    ("27_consistency_templates.cypher",  "Consistency templates — 6 Text2CypherTemplate (category=consistency)"),
]


def split_statements(text: str) -> list:
    stmts, current = [], []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("//") or stripped == "":
            if current:
                current.append(line)
            continue
        current.append(line)
        if stripped.endswith(";"):
            stmt = "\n".join(current).strip().rstrip(";").strip()
            if stmt and not stmt.startswith("//"):
                stmts.append(stmt)
            current = []
    if current:
        stmt = "\n".join(current).strip()
        if stmt and not stmt.startswith("//"):
            stmts.append(stmt)
    return [s for s in stmts if s]


def run_script(session, script_path: Path, label: str):
    text  = script_path.read_text(encoding="utf-8")
    stmts = split_statements(text)
    ok = errors = 0
    for stmt in stmts:
        if stmt.strip().upper().startswith("SHOW"):
            ok += 1
            continue
        try:
            result = session.run(stmt)
            result.consume()
            ok += 1
        except neo4j_exc.Neo4jError as e:
            msg = str(e).lower()
            if "already exists" in msg or "equivalent" in msg or "constraintvalidation" in msg:
                ok += 1
            else:
                errors += 1
                print(f"    ! {e.message[:140]}")
    status = "PASS" if errors == 0 else f"WARN ({errors} errors)"
    print(f"  [{status}]  {label}  —  {ok}/{len(stmts)} statements OK")


def print_phase10_summary(session):
    print("\n  ── Phase 10 node counts ─────────────────────────────")
    result = session.run("""
        MATCH (n)
        WHERE n:ConversationFact OR n:GoalState OR n:ProtocolTracker
           OR n:ConsistencyConflict OR n:ReasoningCandidate OR n:ConsistencyReport
        WITH labels(n)[0] AS lbl, count(n) AS cnt
        RETURN lbl, cnt ORDER BY lbl
    """)
    total_p10 = 0
    for r in result:
        print(f"    {r['lbl']:<28} {r['cnt']:>4}")
        total_p10 += r["cnt"]
    print(f"    {'─'*33}")
    print(f"    {'TOTAL Phase 10 nodes':<28} {total_p10:>4}")

    print("\n  ── Phase 10 relationship counts ────────────────────")
    result = session.run("""
        MATCH ()-[r]->()
        WHERE type(r) IN ['EXTRACTED_FROM','CONTRADICTS','SUPERSEDES',
                          'HAS_GOAL','HAS_TRACKER','TRACKS',
                          'CANDIDATE_FOR','HAS_REPORT','FLAGGED_DEVIATION']
        RETURN type(r) AS rel, count(r) AS cnt ORDER BY cnt DESC
    """)
    for r in result:
        print(f"    {r['rel']:<28} {r['cnt']:>4}")

    print("\n  ── Consistency templates ────────────────────────────")
    result = session.run("""
        MATCH (t:Text2CypherTemplate {category: 'consistency'})
        RETURN t.name AS name ORDER BY t.name
    """)
    for r in result:
        print(f"    {r['name']}")

    print("\n  ── ConsistencyReport DER scores ─────────────────────")
    result = session.run("""
        MATCH (cr:ConsistencyReport)
        RETURN cr.sessionId AS session,
               cr.turnNumber AS turn,
               cr.derScore AS der,
               cr.factCount AS facts,
               cr.conflictCount AS conflicts
        ORDER BY cr.sessionId, cr.turnNumber
    """)
    for r in result:
        print(f"    {r['session']}  t{r['turn']}  DER={r['der']:.2f}  "
              f"facts={r['facts']}  conflicts={r['conflicts']}")

    result = session.run("MATCH (n) RETURN count(n) AS total")
    total_nodes = result.single()["total"]
    print(f"\n  Total nodes in graph now: {total_nodes}")


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 10 Neo4j Importer")
    parser.add_argument("--uri",      default=DEFAULT_URI)
    parser.add_argument("--user",     default=DEFAULT_USER)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    print(f"\n{'='*62}")
    print(f"  UCKB Phase 10 — Neo4j Import")
    print(f"  URI:  {args.uri}")
    print(f"{'='*62}")

    try:
        driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        driver.verify_connectivity()
    except Exception as e:
        print(f"FATAL: Cannot connect to Neo4j: {e}")
        sys.exit(1)

    with driver.session() as db:
        baseline = db.run("MATCH (n) RETURN count(n) AS n").single()["n"]
        print(f"\nBaseline nodes: {baseline}")

        for filename, label in SCRIPTS:
            path = CYPHER / filename
            if not path.exists():
                print(f"\n  [SKIP] {label} — file not found: {path}")
                continue
            print(f"\nRunning: {filename}")
            run_script(db, path, label)

        after = db.run("MATCH (n) RETURN count(n) AS n").single()["n"]
        print(f"\n{'='*62}")
        print(f"  Nodes before: {baseline}")
        print(f"  Nodes after:  {after}")
        print(f"  Added:        +{after - baseline}")
        print(f"{'='*62}")

        print_phase10_summary(db)

    driver.close()
    print(f"\n{'='*62}")
    print("  Phase 10 import complete.")
    print("  Run validate_phase10.py to confirm all 10 ACs.")
    print(f"{'='*62}")


if __name__ == "__main__":
    main()
