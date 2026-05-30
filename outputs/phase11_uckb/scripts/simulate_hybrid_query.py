"""
UCKB Phase 11 — Hybrid Query Simulator
Demonstrates the 3-leg hybrid retrieval engine across 6 demo queries
(one per domain) in mock mode — no Neo4j or sentence-transformers required.

Shows per-leg rankings, RRF fusion, and the final ranked output with
leg attribution and safety validation status.

Usage:
    python simulate_hybrid_query.py
"""

import sys
import io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hybrid_retriever import HybridRetriever, DOMAIN_CONFIGS

DIVIDER  = "=" * 70
DIVIDER2 = "-" * 70


# ─────────────────────────────────────────────────────────────────────────────
# DEMO QUERIES
# ─────────────────────────────────────────────────────────────────────────────

DEMO_QUERIES = [
    {
        "domain":      "dispatch",
        "query":       "caller panicking, weapon mentioned, refuses to comply",
        "description": "Crisis dispatch — panic state, weapon present, non-compliance",
        "expected_winner": "t_bcsm_minimal_enc",
    },
    {
        "domain":      "clinical",
        "query":       "patient resistant to bad news, oncologist delivering diagnosis",
        "description": "Clinical — SPIKES Step E, empathy response needed",
        "expected_winner": "t_spikes_empathy_response",
    },
    {
        "domain":      "negotiation",
        "query":       "prospect stalling on price objection, late-stage deal",
        "description": "Negotiation — SPIN Implication, price objection handling",
        "expected_winner": "t_spin_implication_q",
    },
    {
        "domain":      "legal",
        "query":       "subject using pronoun changes and verb tense shifts, interview step 3",
        "description": "Legal — PEACE Account step, SA markers 1+2 detected",
        "expected_winner": "t_peace_probing",
    },
    {
        "domain":      "corporate",
        "query":       "team member displaying defensiveness during code review feedback",
        "description": "Corporate — SBI feedback delivery, defensiveness signal present",
        "expected_winner": "t_sbi_feedback",
    },
    {
        "domain":      "education",
        "query":       "student making systematic errors on fractions, low confidence",
        "description": "Education — BKT mastery < 0.4, Tier 1 scaffold needed",
        "expected_winner": "t_scaffold_tier1",
    },
]


def print_leg_table(leg_name: str, results: list):
    print(f"\n  {leg_name.upper()} LEG:")
    print(f"  {'Rank':<6} {'Score':>8}  Technique")
    print(f"  {'----':<6} {'-----':>8}  ---------")
    for r in results:
        print(f"  {r.rank:<6} {r.raw_score:>8.4f}  {r.technique_name}")


def print_rrf_table(fused: list, cfg: dict):
    k = cfg["k"]
    print(f"\n  FUSED RESULTS (weighted RRF, k={k}, "
          f"bm25={cfg['bm25']} vec={cfg['vector']} cyp={cfg['cypher']}):")
    print(f"  {'Rank':<6} {'RRF Score':>10}  {'bm25_r':>6} {'vec_r':>6} {'cyp_r':>6}  Technique")
    print(f"  {'----':<6} {'---------':>10}  {'------':>6} {'-----':>6} {'------':>6}  ---------")
    for r in fused:
        safety = " [SAFE]" if r.safety_validated else " [!BLOCKED]"
        print(f"  {r.fused_rank:<6} {r.rrf_score:>10.6f}  "
              f"{r.leg_bm25_rank:>6} {r.leg_vector_rank:>6} {r.leg_cypher_rank:>6}  "
              f"{r.technique_name}{safety}")


def run_demo(q: dict):
    domain      = q["domain"]
    query_text  = q["query"]
    cfg         = DOMAIN_CONFIGS[domain]
    retriever   = HybridRetriever(domain=domain)

    print(f"\n{DIVIDER}")
    print(f"  Domain:  {domain.upper()}")
    print(f"  Query:   {query_text}")
    print(f"  Context: {q['description']}")
    print(DIVIDER2)

    # Run each leg independently for display
    bm25_leg   = retriever._bm25_leg(query_text, top_k=5)
    vector_leg = retriever._vector_leg(top_k=5)
    cypher_leg = retriever._cypher_leg(top_k=5)

    print_leg_table("bm25",   bm25_leg)
    print_leg_table("vector", vector_leg)
    print_leg_table("cypher", cypher_leg)

    # Full retrieval (safety filter + RRF fusion)
    fused = retriever.retrieve(query_text, top_k=5)
    print_rrf_table(fused, cfg)

    winner = fused[0] if fused else None
    expected = q["expected_winner"]
    match = winner and winner.technique_id == expected
    status = "MATCH" if match else f"MISMATCH (expected {expected})"
    print(f"\n  Top result: {winner.technique_id if winner else 'NONE'}  [{status}]")


def main():
    print(f"\n{DIVIDER}")
    print("  UCKB Phase 11 — Hybrid Retrieval Simulation (mock mode)")
    print("  3 legs: BM25 + vector + Cypher, fused via weighted RRF (k=60)")
    print(f"{DIVIDER}")

    all_match = True
    for q in DEMO_QUERIES:
        run_demo(q)
        retriever = HybridRetriever(domain=q["domain"])
        fused = retriever.retrieve(q["query"], top_k=5)
        if not fused or fused[0].technique_id != q["expected_winner"]:
            all_match = False

    print(f"\n{DIVIDER}")
    overall = "ALL MATCH" if all_match else "SOME MISMATCHES (check mock data ordering)"
    print(f"  Simulation complete — {overall}")
    print(f"  {len(DEMO_QUERIES)} demo queries across {len(DEMO_QUERIES)} domains")
    print(DIVIDER)
    print("\nNote: mock mode uses pseudo-random rankings.")
    print("Use --real and --neo4j flags with generate_embeddings.py + import_phase11_neo4j.py")
    print("for genuine BM25/vector/Cypher results against a live graph.")


if __name__ == "__main__":
    main()
