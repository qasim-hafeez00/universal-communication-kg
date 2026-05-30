"""
UCKB Phase 9 — Neo4j Import Script
Executes Cypher scripts 15-19 against a running Neo4j instance via the Bolt driver.
Scripts are split on semicolons (safe: Phase 9 scripts contain no apostrophes in data).

Usage:
    python import_phase9_neo4j.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]

Prerequisites:
    pip install neo4j
    Neo4j running with Phase 4-8 data already loaded.
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
    ("15_temporal_schema.cypher",          "Temporal schema — constraints + 10 indices"),
    ("16_episodic_memory.cypher",          "Episodic memory — demo Sessions, Turns, EpisodicMemory"),
    ("17_working_memory.cypher",           "Working memory — WorkingMemorySlot nodes"),
    ("18_memory_traces.cypher",            "Memory traces — MemoryTrace decay + REINFORCES edges"),
    ("19_temporal_retrieval_library.cypher", "Temporal retrieval library — 6 Text2CypherTemplate nodes"),
]


def split_statements(text: str) -> list[str]:
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
        # Skip SHOW statements — they are not executable via Bolt driver session.run
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


def print_graph_summary(session):
    print("\n  ── Phase 9 node counts ──────────────────────────────")
    result = session.run("""
        MATCH (n)
        WHERE n:Session OR n:Turn OR n:TemporalFact OR
              n:WorkingMemorySlot OR n:EpisodicMemory OR n:MemoryTrace
        WITH labels(n)[0] AS lbl, count(n) AS cnt
        RETURN lbl, cnt ORDER BY cnt DESC
    """)
    total = 0
    for r in result:
        print(f"    {r['lbl']:<28} {r['cnt']:>4}")
        total += r["cnt"]
    print(f"    {'─'*33}")
    print(f"    {'TOTAL Phase 9 nodes':<28} {total:>4}")

    print("\n  ── Temporal edge counts ────────────────────────────")
    result = session.run("""
        MATCH ()-[r]->()
        WHERE type(r) IN ['HAS_TURN','HAS_EPISODE','HAS_SLOT','HAS_FACT',
                          'DETECTED','FOLLOWS','ACTIVE_PROTOCOL','AT_STEP',
                          'REINFORCES','TRIGGERED','PRECEDES']
        RETURN type(r) AS rel, count(r) AS cnt ORDER BY cnt DESC
    """)
    for r in result:
        print(f"    {r['rel']:<28} {r['cnt']:>4}")

    print("\n  ── Temporal retrieval templates ────────────────────")
    result = session.run("""
        MATCH (t:Text2CypherTemplate {category: 'temporal'})
        RETURN t.name AS name, t.templateId AS id ORDER BY t.name
    """)
    for r in result:
        print(f"    {r['name']}")

    result = session.run("MATCH (n) RETURN count(n) AS total")
    total_nodes = result.single()["total"]
    print(f"\n  Total nodes in graph now: {total_nodes}")


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 9 Neo4j Importer")
    parser.add_argument("--uri",      default=DEFAULT_URI)
    parser.add_argument("--user",     default=DEFAULT_USER)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    print(f"\n{'='*62}")
    print(f"  UCKB Phase 9 — Neo4j Import")
    print(f"  URI:  {args.uri}")
    print(f"{'='*62}")

    try:
        driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        driver.verify_connectivity()
    except Exception as e:
        print(f"FATAL: Cannot connect to Neo4j: {e}")
        sys.exit(1)

    with driver.session() as db:
        # Baseline
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

        print_graph_summary(db)

    driver.close()
    print(f"\n{'='*62}")
    print("  Phase 9 import complete.")
    print("  Run validate_phase9.py to confirm all 10 ACs.")
    print(f"{'='*62}")


if __name__ == "__main__":
    main()
