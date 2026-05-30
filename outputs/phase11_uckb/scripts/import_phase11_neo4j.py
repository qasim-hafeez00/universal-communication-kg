"""
UCKB Phase 11 — Neo4j Import Script
Executes Cypher scripts 29-34 against a running Neo4j instance via the Bolt
driver, then creates the full-text and vector indices.

Prerequisites:
    pip install neo4j
    Neo4j 5.11+ running with Phase 4-10 data already loaded.
    Run generate_embeddings.py first if you want vector embeddings populated.

Usage:
    python import_phase11_neo4j.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]
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
    ("29_hybrid_schema.cypher",    "Hybrid schema — 6 constraints + 8 indices"),
    ("30_index_registry.cypher",   "Index registry — 1 FullTextIndex + 1 VectorIndex metadata nodes"),
    ("31_fusion_config.cypher",    "Fusion config — 6 FusionConfig nodes (RRF k=60)"),
    ("32_hybrid_queries.cypher",   "Hybrid queries — 6 HybridQuery nodes + USES_FUSION + QUERIES_INDEX + FILTERS_BY"),
    ("33_retrieval_legs.cypher",   "Retrieval legs — 18 RetrievalLeg + 6 HybridResult nodes"),
    ("34_hybrid_templates.cypher", "Hybrid templates — 6 Text2CypherTemplate (category=hybrid)"),
]

# Neo4j full-text index creation (run after scripts 29-34)
FULLTEXT_INDEX_DDL = """
CREATE FULLTEXT INDEX uckb_fulltext IF NOT EXISTS
FOR (n:Technique|SignalMarker|ProtocolStep)
ON EACH [n.name, n.steps, n.whenToUse, n.failureSignals, n.culturalNotes]
"""

# Neo4j vector index creation (5.15+ declarative syntax)
VECTOR_INDEX_DDL = """
CREATE VECTOR INDEX uckb_vector IF NOT EXISTS
FOR (n:Technique) ON (n.embedding)
OPTIONS { indexConfig: {
  `vector.dimensions`: 384,
  `vector.similarity_function`: 'cosine'
}}
"""

# Fallback: procedure-based (5.11-5.14)
VECTOR_INDEX_PROC = """
CALL db.index.vector.createNodeIndex(
  'uckb_vector', 'Technique', 'embedding', 384, 'cosine'
)
"""


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
            if stmt and not stmt.strip().startswith("//"):
                stmts.append(stmt)
            current = []
    if current:
        stmt = "\n".join(current).strip()
        if stmt and not stmt.strip().startswith("//"):
            stmts.append(stmt)
    return [s for s in stmts if s]


def run_script(session, script_path: Path, label: str):
    text  = script_path.read_text(encoding="utf-8")
    stmts = split_statements(text)
    ok = errors = 0
    for stmt in stmts:
        upper = stmt.strip().upper()
        if upper.startswith("SHOW") or upper.startswith("RETURN"):
            ok += 1
            continue
        try:
            result = session.run(stmt)
            result.consume()
            ok += 1
        except neo4j_exc.Neo4jError as e:
            msg = str(e).lower()
            if ("already exists" in msg or "equivalent" in msg
                    or "constraintvalidation" in msg):
                ok += 1
            else:
                errors += 1
                print(f"    ! {str(e)[:140]}")
    status = "PASS" if errors == 0 else f"WARN ({errors} errors)"
    print(f"  [{status}]  {label}  —  {ok}/{len(stmts)} statements OK")


def create_indices(session):
    print("\n  Creating Neo4j full-text and vector indices...")
    for label, ddl in [
        ("Full-text index (BM25)", FULLTEXT_INDEX_DDL),
        ("Vector index (cosine, 384-dim)", VECTOR_INDEX_DDL),
    ]:
        try:
            session.run(ddl).consume()
            print(f"  [PASS]  {label}")
        except neo4j_exc.Neo4jError as e:
            if "already exists" in str(e).lower():
                print(f"  [SKIP]  {label} — already exists")
            elif "unknown function" in str(e).lower() or "procedure not found" in str(e).lower():
                # Try procedure-based fallback for vector index
                if "vector" in label.lower():
                    try:
                        session.run(VECTOR_INDEX_PROC).consume()
                        print(f"  [PASS]  {label} (via procedure fallback)")
                    except neo4j_exc.Neo4jError as e2:
                        if "already exists" in str(e2).lower():
                            print(f"  [SKIP]  {label} — already exists")
                        else:
                            print(f"  [WARN]  {label}: {str(e2)[:100]}")
            else:
                print(f"  [WARN]  {label}: {str(e)[:100]}")


def print_phase11_summary(session):
    print("\n  ── Phase 11 node counts ─────────────────────────────")
    result = session.run("""
        MATCH (n)
        WHERE n:FullTextIndex OR n:VectorIndex OR n:FusionConfig
           OR n:HybridQuery   OR n:RetrievalLeg OR n:HybridResult
        WITH labels(n)[0] AS lbl, count(n) AS cnt
        RETURN lbl, cnt ORDER BY lbl
    """)
    total_p11 = 0
    for r in result:
        print(f"    {r['lbl']:<28} {r['cnt']:>4}")
        total_p11 += r["cnt"]
    print(f"    {'─'*33}")
    print(f"    {'TOTAL Phase 11 nodes':<28} {total_p11:>4}")

    print("\n  ── FusionConfig weight sums ─────────────────────────")
    result = session.run("""
        MATCH (fc:FusionConfig)
        RETURN fc.domain AS domain,
               fc.k AS k,
               round(fc.bm25Weight + fc.vectorWeight + fc.cypherWeight, 4) AS weight_sum
        ORDER BY domain
    """)
    for r in result:
        ok = "OK" if abs(r["weight_sum"] - 1.0) < 0.001 else "FAIL"
        print(f"    {r['domain']:<15} k={r['k']}  weight_sum={r['weight_sum']}  [{ok}]")

    print("\n  ── Hybrid templates ─────────────────────────────────")
    result = session.run("""
        MATCH (t:Text2CypherTemplate {category: 'hybrid'})
        RETURN t.name AS name ORDER BY t.name
    """)
    for r in result:
        print(f"    {r['name']}")

    print("\n  ── HybridResult RRF scores ──────────────────────────")
    result = session.run("""
        MATCH (hr:HybridResult)
        RETURN hr.domain AS domain,
               hr.techniqueId AS technique,
               hr.rrfScore AS rrf,
               hr.safetyValidated AS safe
        ORDER BY hr.domain
    """)
    for r in result:
        print(f"    {r['domain']:<15} {r['technique']:<35} rrf={r['rrf']:.6f}  safe={r['safe']}")

    result = session.run("MATCH (n) RETURN count(n) AS total")
    total_nodes = result.single()["total"]
    print(f"\n  Total nodes in graph now: {total_nodes}")


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 11 Neo4j Importer")
    parser.add_argument("--uri",      default=DEFAULT_URI)
    parser.add_argument("--user",     default=DEFAULT_USER)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    print(f"\n{'='*62}")
    print(f"  UCKB Phase 11 — Neo4j Import")
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

        create_indices(db)

        after = db.run("MATCH (n) RETURN count(n) AS n").single()["n"]
        print(f"\n{'='*62}")
        print(f"  Nodes before: {baseline}")
        print(f"  Nodes after:  {after}")
        print(f"  Added:        +{after - baseline}")
        print(f"{'='*62}")

        print_phase11_summary(db)

    driver.close()
    print(f"\n{'='*62}")
    print("  Phase 11 import complete.")
    print("  Run generate_embeddings.py --neo4j to populate Technique.embedding.")
    print("  Run validate_phase11.py to confirm all 10 ACs.")
    print(f"{'='*62}")


if __name__ == "__main__":
    main()
