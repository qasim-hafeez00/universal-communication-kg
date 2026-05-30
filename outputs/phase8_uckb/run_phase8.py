"""
UCKB Phase 8 — Neo4j Ingestion Runner
Pipes Cypher scripts 08-14 into cypher-shell inside the uckb_neo4j container
via docker exec, then queries and prints the full graph summary.

Usage:
    python run_phase8.py
"""
import sys
import time
import pathlib
import subprocess
import base64
import json

try:
    import requests
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "-q"])
    import requests

sys.stdout.reconfigure(encoding="utf-8")

# ── Config ────────────────────────────────────────────────────
NEO4J_HTTP = "http://localhost:7474/db/neo4j/tx/commit"
NEO4J_USER = "neo4j"
NEO4J_PASS = "uckb_admin_2024"
CONTAINER  = "uckb_neo4j"
CYPHER_DIR = pathlib.Path(__file__).parent / "cypher"

SCRIPTS = [
    "08_legal_domain.cypher",
    "09_corporate_domain.cypher",
    "10_education_domain.cypher",
    "11_protocol_dags.cypher",
    "12_cross_domain_guards.cypher",
    "13_schema_filter_registry.cypher",
]

AUTH = base64.b64encode(f"{NEO4J_USER}:{NEO4J_PASS}".encode()).decode()
HTTP_HEADERS = {"Content-Type": "application/json", "Authorization": f"Basic {AUTH}"}


def http_cypher(query: str) -> list:
    body = {"statements": [{"statement": query}]}
    r = requests.post(NEO4J_HTTP, json=body, headers=HTTP_HEADERS, timeout=60)
    r.raise_for_status()
    data = r.json()
    if data.get("errors"):
        raise RuntimeError(data["errors"])
    return data["results"]


def count_nodes() -> int:
    return http_cypher("MATCH (n) RETURN COUNT(n) AS total")[0]["data"][0]["row"][0]


def run_via_cypher_shell(script_path: pathlib.Path) -> tuple[bool, str]:
    """
    Pipes a .cypher file into cypher-shell inside the container.
    Returns (success, output_text).
    """
    content = script_path.read_bytes()   # bytes to avoid encoding transforms
    cmd = [
        "docker", "exec", "-i", CONTAINER,
        "cypher-shell",
        "-u", NEO4J_USER,
        "-p", NEO4J_PASS,
        "--database", "neo4j",
        "--non-interactive",
        "--format", "plain",
    ]
    result = subprocess.run(
        cmd,
        input=content,
        capture_output=True,
        timeout=120,
    )
    stdout = result.stdout.decode("utf-8", errors="replace")
    stderr = result.stderr.decode("utf-8", errors="replace")
    combined = (stdout + stderr).strip()
    success = result.returncode == 0
    return success, combined


def print_graph_summary():
    print("\n  ── Node distribution ──────────────────────────────────")
    rows = http_cypher("""
        MATCH (n)
        WITH labels(n)[0] AS label, COUNT(n) AS cnt
        WHERE label IS NOT NULL
        RETURN label, cnt ORDER BY cnt DESC
    """)[0]["data"]
    total = 0
    for row in rows:
        label, cnt = row["row"]
        print(f"    {label:<32} {cnt:>5}")
        total += cnt
    print(f"    {'─'*39}")
    print(f"    {'TOTAL':<32} {total:>5}")

    print("\n  ── Relationship types ─────────────────────────────────")
    rows = http_cypher("""
        MATCH ()-[r]->()
        WITH type(r) AS rtype, COUNT(r) AS cnt
        RETURN rtype, cnt ORDER BY cnt DESC
    """)[0]["data"]
    rel_total = 0
    for row in rows:
        rtype, cnt = row["row"]
        print(f"    {rtype:<32} {cnt:>5}")
        rel_total += cnt
    print(f"    {'─'*39}")
    print(f"    {'TOTAL':<32} {rel_total:>5}")

    print("\n  ── Domain distribution ────────────────────────────────")
    rows = http_cypher("""
        MATCH (t:Technique)
        WHERE t.domain IS NOT NULL
        RETURN t.domain AS domain, COUNT(t) AS techniques
        ORDER BY techniques DESC
    """)[0]["data"]
    for row in rows:
        domain, cnt = row["row"]
        bar = "█" * min(int(cnt / 3), 25)
        print(f"    {(domain or 'None'):<35} {cnt:>4}  {bar}")

    print("\n  ── Protocol DAGs ──────────────────────────────────────")
    rows = http_cypher("""
        MATCH (d:ProtocolDAG)
        OPTIONAL MATCH (s:ProtocolStep {protocol: d.protocol})
        OPTIONAL MATCH (g:ProtocolGate {protocol: d.protocol})
        RETURN d.name AS dag, d.domain AS domain,
               COUNT(DISTINCT s) AS steps, COUNT(DISTINCT g) AS gates
        ORDER BY domain
    """)[0]["data"]
    if rows:
        for row in rows:
            dag, domain, steps, gates = row["row"]
            print(f"    {dag:<30} {steps} steps  {gates} gates  [{domain}]")
    else:
        print("    (no ProtocolDAG nodes yet)")

    print("\n  ── Phase 8 new domain counts ──────────────────────────")
    rows = http_cypher("""
        MATCH (n)
        WHERE n.domain IN ['Legal & Investigative','Corporate & Engineering','Education']
        RETURN n.domain AS domain, labels(n)[0] AS type, COUNT(n) AS cnt
        ORDER BY domain, type
    """)[0]["data"]
    current_domain = None
    for row in rows:
        domain, lbl, cnt = row["row"]
        if domain != current_domain:
            current_domain = domain
            print(f"\n    [{domain}]")
        print(f"      {lbl:<28} {cnt:>4}")


# ── Main ──────────────────────────────────────────────────────

def main():
    print("=" * 62)
    print("  UCKB Phase 8 — Neo4j Ingestion Runner")
    print("=" * 62)

    # Verify connection
    try:
        baseline = count_nodes()
        print(f"\nConnected.  Current nodes in graph: {baseline}")
    except Exception as e:
        print(f"\nCannot connect to Neo4j: {e}")
        sys.exit(1)

    # Check if Phase 8 data already exists
    check = http_cypher(
        "MATCH (t:Technique {cardId:'legal_001_free_narrative_invitation'}) RETURN COUNT(t) AS c"
    )
    already = check[0]["data"][0]["row"][0] if check[0]["data"] else 0
    if already > 0:
        print(f"Phase 8 data already partially loaded ({already} legal techniques found).")
        print("Running again — all statements use MERGE so this is idempotent.")

    # Run each script
    ok_count = 0
    err_count = 0
    for script_name in SCRIPTS:
        path = CYPHER_DIR / script_name
        if not path.exists():
            print(f"\n  [{script_name}] NOT FOUND — skipping")
            continue

        print(f"\n  [{script_name}]", end=" ", flush=True)
        t0 = time.time()
        success, output = run_via_cypher_shell(path)
        elapsed = time.time() - t0

        if success:
            ok_count += 1
            print(f"\033[32mOK\033[0m  ({elapsed:.1f}s)")
            # Show last meaningful output lines (skip blank/delimiter lines)
            for line in output.splitlines()[-6:]:
                line = line.strip()
                if line and not line.startswith("+") and not line.startswith("0 rows"):
                    print(f"    {line}")
        else:
            err_count += 1
            print(f"\033[31mFAIL\033[0m  ({elapsed:.1f}s)")
            # Print first 10 error lines
            for line in output.splitlines()[:10]:
                if line.strip():
                    print(f"    ! {line.strip()}")
        time.sleep(0.3)

    # Final state
    final = count_nodes()
    added = final - baseline

    print(f"\n{'=' * 62}")
    print(f"  Ingestion summary")
    print(f"  Baseline  : {baseline} nodes")
    print(f"  Final     : {final} nodes")
    print(f"  Added     : +{added} nodes")
    print(f"  Scripts   : {ok_count} OK, {err_count} failed")
    print(f"{'=' * 62}")

    # Full graph summary
    print_graph_summary()

    print(f"\n{'=' * 62}")
    print("  HOW TO VISUALIZE — Neo4j Browser")
    print(f"{'=' * 62}")
    print("""
  Open: http://localhost:7474
  Login: neo4j / uckb_admin_2024

  ── Starter queries (paste into the query bar) ────────────

  1. Overview — all 6 domains at once (100 nodes)
     MATCH (t:Technique)-[r]-(n)
     WHERE t.domain IS NOT NULL
     RETURN t, r, n LIMIT 100

  2. Legal domain — PEACE framework + techniques
     MATCH (d:ProtocolDAG {protocol:'PEACE'})-[:PART_OF*0..1]-(s:ProtocolStep)
     OPTIONAL MATCH (g:ProtocolGate)-[:GATES]->(s)
     OPTIONAL MATCH (s)-[:TRIGGERS]->(t:Technique)
     RETURN d, s, g, t

  3. Crisis — BCSM 5-step DAG wired to techniques
     MATCH (d:ProtocolDAG {protocol:'BCSM'})-[:PART_OF*0..1]-(s:ProtocolStep)
     OPTIONAL MATCH (g:ProtocolGate)-[:GATES]->(s)
     OPTIONAL MATCH (s)-[:TRIGGERS]->(t:Technique)
     RETURN d, s, g, t

  4. Education — BKT states triggering CoachIDL acts
     MATCH (ks:KnowledgeState)-[:TRIGGERS]->(t:Technique)
     RETURN ks, t

  5. Corporate — Radical Candor quadrants + feedback chain
     MATCH (cs:CommunicationStyle)-[r]-(t:Technique)
     WHERE t.domain = 'Corporate & Engineering'
     RETURN cs, r, t LIMIT 60

  6. Cross-domain contamination layer
     MATCH (t:Technique)-[r:CONTRAINDICATED_WHEN]->(e)
     WHERE r.crossDomain = true
     RETURN t.name, t.domain, e.name LIMIT 40

  7. Reid Technique — confirm it is permanently blocked
     MATCH (t:Technique {cardId:'legal_contraindicated_reid'})-[r]-(n)
     RETURN t, r, n

  8. SPIKES clinical protocol with consent gate
     MATCH (d:ProtocolDAG {protocol:'SPIKES'})-[:PART_OF*0..1]-(s:ProtocolStep)
     OPTIONAL MATCH (g:ProtocolGate)-[:GATES]->(s)
     RETURN d, s, g ORDER BY s.stepNumber

  9. Full domain neighbourhood (replace 'Legal & Investigative')
     MATCH (t:Technique {domain:'Legal & Investigative'})-[r]-(n)
     RETURN t, r, n LIMIT 80

  10. All technique→signal→technique paths
      MATCH path = (t1:Technique)-[:TRIGGERS|ESCALATES_TO*1..2]-(t2:Technique)
      RETURN path LIMIT 40

  ── Tips ───────────────────────────────────────────────────
  • Click any node → see all its properties in the right panel
  • Drag nodes to rearrange the graph layout
  • Double-click a node to expand its neighbours
  • Top-right gear → increase "Initial Node Display" to 300
  • Use the visual style panel (paintbrush icon) to colour
    nodes by label (Technique=blue, SignalMarker=orange, etc.)
""")

    return 0 if err_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
