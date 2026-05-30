"""
UCKB Phase 5 — Neo4j Import Script
Executes the 4 data Cypher scripts (01-04) against a running Neo4j instance.

Usage:
  python import_phase5_neo4j.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]

Prerequisites:
  pip install neo4j
  Neo4j running with Phase 4 data already loaded.
"""

import sys
import argparse
from pathlib import Path

from neo4j import GraphDatabase, exceptions as neo4j_exc

ROOT    = Path(__file__).resolve().parent.parent.parent.parent
CYPHER  = ROOT / "outputs" / "phase5_uckb" / "cypher"

DEFAULT_URI      = "bolt://localhost:7687"
DEFAULT_USER     = "neo4j"
DEFAULT_PASSWORD = "uckb_admin_2024"

SCRIPTS = [
    ("01_da_constraints.cypher",        "Constraints + Indices"),
    ("02_import_iso_taxonomy.cypher",   "ISO 24617-2 Taxonomy (Dimensions + Acts)"),
    ("03_link_da_to_techniques.cypher", "Link DialogueActs to Techniques (Clinical + Dispatch)"),
    ("03b_da_triggers_patch.cypher",    "TRIGGERS Coverage Patch (remaining acts + Sales domain)"),
    ("04_dst_schema.cypher",            "DST Slots + BDI Templates"),
]


def split_statements(cypher_text: str) -> list[str]:
    """Split a Cypher file into individual statements on semicolons, skip comments."""
    stmts = []
    current = []
    for line in cypher_text.splitlines():
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
    # flush remainder without semicolon
    if current:
        stmt = "\n".join(current).strip()
        if stmt and not stmt.startswith("//"):
            stmts.append(stmt)
    return [s for s in stmts if s]


def run_script(session, script_path: Path, label: str):
    text = script_path.read_text(encoding="utf-8")
    statements = split_statements(text)
    ok = 0
    errors = []
    for stmt in statements:
        try:
            result = session.run(stmt)
            result.consume()
            ok += 1
        except neo4j_exc.Neo4jError as e:
            if "already exists" in str(e).lower() or "equivalent" in str(e).lower():
                ok += 1  # idempotent — constraint/index already exists
            else:
                errors.append(f"  ERROR: {e.message[:120]}")
    status = "PASS" if not errors else f"WARN ({len(errors)} errors)"
    print(f"  [{status}]  {label}  —  {ok}/{len(statements)} statements OK")
    for err in errors:
        print(err)


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 5 Neo4j Importer")
    parser.add_argument("--uri",      default=DEFAULT_URI)
    parser.add_argument("--user",     default=DEFAULT_USER)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    print(f"\nUCKB Phase 5 — Neo4j Import")
    print(f"  URI:  {args.uri}")
    print(f"  User: {args.user}")
    print("=" * 60)

    try:
        driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        driver.verify_connectivity()
    except Exception as e:
        print(f"FATAL: Cannot connect to Neo4j at {args.uri}: {e}")
        sys.exit(1)

    with driver.session() as session:
        for filename, label in SCRIPTS:
            path = CYPHER / filename
            if not path.exists():
                print(f"  [SKIP]  {label}  —  file not found: {path}")
                continue
            print(f"\nRunning: {filename}")
            run_script(session, path, label)

    driver.close()
    print("\n" + "=" * 60)
    print("Phase 5 import complete.")
    print("Run validate_phase5.py to check all acceptance criteria.")


if __name__ == "__main__":
    main()
