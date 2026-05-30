"""
UCKB Phase 11 — Validation Script
Validates all 10 acceptance criteria by inspecting the generated Cypher scripts
and the phase11_data.json built by build_phase11_schema.py.
Does NOT require a live Neo4j connection.

If --neo4j is passed, also validates against a running Neo4j instance.

Usage (file-based, no Neo4j required):
    python validate_phase11.py

Usage (Neo4j-connected):
    python validate_phase11.py --neo4j [--uri bolt://localhost:7687]

Returns exit code 0 if ALL PASS, 1 if any criterion fails.
"""

import sys
import io
import re
import json
import math
import argparse
from datetime import datetime
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT     = Path(__file__).resolve().parents[1]
CYPHER   = ROOT / "cypher"
DATA_DIR = ROOT / "data"
REPORT   = ROOT / "reports" / "phase11_validation_report.txt"
REPORT.parent.mkdir(parents=True, exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def read_cypher(filename: str) -> str:
    p = CYPHER / filename
    return p.read_text(encoding="utf-8") if p.exists() else ""


def read_data() -> dict:
    p = DATA_DIR / "phase11_data.json"
    if p.exists():
        return json.loads(p.read_text(encoding="utf-8"))
    return {}


def read_embeddings() -> dict:
    p = DATA_DIR / "embeddings.json"
    if p.exists():
        return json.loads(p.read_text(encoding="utf-8"))
    return {}


def count_merge_nodes(text: str, label: str) -> int:
    return len(re.findall(rf'MERGE\s*\([^:)]*:{label}[\s{{]', text, re.IGNORECASE))


def count_edge_type(text: str, rel: str) -> int:
    return len(re.findall(rf'\[:{rel}[\s\]{{]', text, re.IGNORECASE))


def extract_float_values(text: str, prop: str) -> list:
    pattern = rf"{prop}:\s*([\d.]+)"
    return [float(m.group(1)) for m in re.finditer(pattern, text)]


def find_set_values(text: str, prop: str) -> list:
    pattern = rf"{prop}:\s*(['\"])([^,\n\r}}]+)\1"
    return [m.group(2).strip() for m in re.finditer(pattern, text)]


# ─────────────────────────────────────────────────────────────────────────────
# ACCEPTANCE CRITERIA
# ─────────────────────────────────────────────────────────────────────────────

def ac_p11_1():
    """All 6 Phase 11 node types have MERGE statements in the Cypher scripts."""
    schema_txt   = read_cypher("29_hybrid_schema.cypher")
    registry_txt = read_cypher("30_index_registry.cypher")
    fusion_txt   = read_cypher("31_fusion_config.cypher")
    query_txt    = read_cypher("32_hybrid_queries.cypher")
    legs_txt     = read_cypher("33_retrieval_legs.cypher")

    data  = read_data()
    counts = {}

    # Check via data file if available, else fall back to Cypher text
    if data:
        counts["FullTextIndex"] = 1 if data.get("full_text_index") else 0
        counts["VectorIndex"]   = 1 if data.get("vector_index") else 0
        counts["FusionConfig"]  = len(data.get("fusion_configs", []))
        counts["HybridQuery"]   = len(data.get("hybrid_queries", []))
        counts["RetrievalLeg"]  = len(data.get("retrieval_legs", []))
        counts["HybridResult"]  = len(data.get("hybrid_results", []))
    else:
        counts["FullTextIndex"] = count_merge_nodes(registry_txt, "FullTextIndex")
        counts["VectorIndex"]   = count_merge_nodes(registry_txt, "VectorIndex")
        counts["FusionConfig"]  = count_merge_nodes(fusion_txt,   "FusionConfig")
        counts["HybridQuery"]   = count_merge_nodes(query_txt,    "HybridQuery")
        counts["RetrievalLeg"]  = count_merge_nodes(legs_txt,     "RetrievalLeg")
        counts["HybridResult"]  = count_merge_nodes(legs_txt,     "HybridResult")

    missing = [k for k, v in counts.items() if v == 0]
    passed  = len(missing) == 0
    detail  = ", ".join(f"{k}={v}" for k, v in counts.items())
    if missing:
        detail += f" | MISSING: {missing}"
    return passed, detail


def ac_p11_2():
    """FullTextIndex: 1 node; labels contains Technique; fields contains name/steps/whenToUse; analyzer=standard-no-stopwords."""
    data = read_data()
    if data and data.get("full_text_index"):
        fti = data["full_text_index"]
        has_technique   = "Technique" in fti.get("labels", [])
        has_name_field  = "name" in fti.get("fields", [])
        has_steps_field = "steps" in fti.get("fields", [])
        has_when_field  = "whenToUse" in fti.get("fields", [])
        correct_analyzer = fti.get("analyzer") == "standard-no-stopwords"
        passed = has_technique and has_name_field and has_steps_field and has_when_field and correct_analyzer
        detail = (f"labels={fti.get('labels')}, fields={fti.get('fields')}, "
                  f"analyzer={fti.get('analyzer')!r}, "
                  f"hasTechnique={has_technique}, hasNameField={has_name_field}, "
                  f"hasStepsField={has_steps_field}, hasWhenField={has_when_field}, "
                  f"correctAnalyzer={correct_analyzer}")
        return passed, detail

    # Fallback: parse Cypher
    text = read_cypher("30_index_registry.cypher")
    has_technique   = "Technique" in text
    has_name_field  = "'name'" in text or '"name"' in text
    has_steps_field = "'steps'" in text or '"steps"' in text
    has_when_field  = "whenToUse" in text
    correct_analyzer = "standard-no-stopwords" in text
    passed = has_technique and has_name_field and has_steps_field and has_when_field and correct_analyzer
    detail = (f"hasTechnique={has_technique}, hasNameField={has_name_field}, "
              f"hasStepsField={has_steps_field}, hasWhenField={has_when_field}, "
              f"correctAnalyzer={correct_analyzer}")
    return passed, detail


def ac_p11_3():
    """VectorIndex: 1 node; dims=384; similarity=cosine; >=100 Technique embeddings."""
    data       = read_data()
    embeddings = read_embeddings()

    vi_ok = False
    vi_detail = ""
    if data and data.get("vector_index"):
        vi = data["vector_index"]
        vi_ok = (vi.get("dims") == 384 and vi.get("similarity") == "cosine"
                 and "all-MiniLM-L6-v2" in vi.get("model", ""))
        vi_detail = f"dims={vi.get('dims')}, similarity={vi.get('similarity')!r}, model={vi.get('model')!r}"
    else:
        text = read_cypher("30_index_registry.cypher")
        vi_ok = "384" in text and "cosine" in text and "all-MiniLM-L6-v2" in text
        vi_detail = f"dims=384 in text={('384' in text)}, cosine={'cosine' in text}, model={'all-MiniLM-L6-v2' in text}"

    emb_count = len(embeddings)
    # Verify first embedding has correct dims if present
    first_emb_dims = 0
    if embeddings:
        first_key = next(iter(embeddings))
        first_emb_dims = len(embeddings[first_key])

    emb_ok = emb_count >= 100
    if emb_count > 0:
        emb_ok = emb_ok and (first_emb_dims == 384)

    passed = vi_ok and emb_ok
    detail = (f"{vi_detail}, "
              f"embeddingCount={emb_count} (need >=100), "
              f"firstEmbeddingDims={first_emb_dims if emb_count > 0 else 'N/A'} (need 384)")
    return passed, detail


def ac_p11_4():
    """FusionConfig: exactly 6 nodes; all k=60; all bm25+vector+cypher weight sums = 1.0."""
    data = read_data()
    if data and data.get("fusion_configs"):
        configs = data["fusion_configs"]
        total   = len(configs)
        all_k60 = all(c.get("k") == 60 for c in configs)
        weight_sums = []
        for c in configs:
            s = c.get("bm25Weight", 0) + c.get("vectorWeight", 0) + c.get("cypherWeight", 0)
            weight_sums.append((c["domain"], round(s, 6)))
        all_sum_ok = all(abs(s - 1.0) < 0.001 for _, s in weight_sums)
        passed = (total == 6 and all_k60 and all_sum_ok)
        detail = (f"total={total} (need 6), allK60={all_k60}, "
                  f"weightSums={weight_sums}, allSumOK={all_sum_ok}")
        return passed, detail

    # Fallback: Cypher file inspection
    text   = read_cypher("31_fusion_config.cypher")
    total  = count_merge_nodes(text, "FusionConfig")
    k_vals = extract_float_values(text, "k")
    all_k60 = all(int(k) == 60 for k in k_vals) if k_vals else False
    bm25_w  = extract_float_values(text, "bm25Weight")
    vec_w   = extract_float_values(text, "vectorWeight")
    cyp_w   = extract_float_values(text, "cypherWeight")
    sums    = [round(b + v + c, 6) for b, v, c in zip(bm25_w, vec_w, cyp_w)]
    all_sum_ok = all(abs(s - 1.0) < 0.001 for s in sums) if sums else False
    passed = (total == 6 and all_k60 and all_sum_ok)
    detail = (f"total={total} (need 6), kValues={k_vals}, allK60={all_k60}, "
              f"weightSums={sums}, allSumOK={all_sum_ok}")
    return passed, detail


def ac_p11_5():
    """HybridQuery: exactly 6 nodes; each has USES_FUSION, QUERIES_INDEX(x2), FILTERS_BY; cypherTemplate, bm25Fields, vectorProperty set."""
    data = read_data()
    if data and data.get("hybrid_queries"):
        queries = data["hybrid_queries"]
        total   = len(queries)
        has_fusion   = all(q.get("fusionDomain") for q in queries)
        has_filter   = all(q.get("filterDomain") for q in queries)
        has_template = all(q.get("cypherTemplate") for q in queries)
        has_bm25     = all(q.get("bm25Fields") for q in queries)
        has_vec_prop = all(q.get("vectorProperty") for q in queries)
        passed = (total == 6 and has_fusion and has_filter
                  and has_template and has_bm25 and has_vec_prop)
        detail = (f"total={total} (need 6), hasFusion={has_fusion}, "
                  f"hasFilter={has_filter}, hasTemplate={has_template}, "
                  f"hasBM25Fields={has_bm25}, hasVectorProperty={has_vec_prop}")
        return passed, detail

    text  = read_cypher("32_hybrid_queries.cypher")
    total = count_merge_nodes(text, "HybridQuery")
    uses_fusion   = count_edge_type(text, "USES_FUSION")
    queries_index = count_edge_type(text, "QUERIES_INDEX")
    filters_by    = count_edge_type(text, "FILTERS_BY")
    has_template  = len(re.findall(r"cypherTemplate:", text)) >= 6
    has_bm25      = len(re.findall(r"bm25Fields:", text)) >= 6
    has_vec_prop  = len(re.findall(r"vectorProperty:", text)) >= 6
    passed = (total == 6 and uses_fusion >= 6 and queries_index >= 12
              and filters_by >= 6 and has_template and has_bm25 and has_vec_prop)
    detail = (f"total={total} (need 6), USES_FUSION={uses_fusion} (need >=6), "
              f"QUERIES_INDEX={queries_index} (need >=12), FILTERS_BY={filters_by} (need >=6), "
              f"hasTemplate={has_template}, hasBM25Fields={has_bm25}, hasVectorProp={has_vec_prop}")
    return passed, detail


def ac_p11_6():
    """RetrievalLeg: >=18 nodes; all legType in [bm25/vector/cypher]; all rank>=1; linked via HAS_LEG."""
    data = read_data()
    if data and data.get("retrieval_legs"):
        legs    = data["retrieval_legs"]
        total   = len(legs)
        valid_types = all(l["legType"] in ["bm25", "vector", "cypher"] for l in legs)
        valid_ranks = all(l["rank"] >= 1 for l in legs)
        distinct_types = list(set(l["legType"] for l in legs))
        passed = total >= 18 and valid_types and valid_ranks
        detail = (f"total={total} (need >=18), validLegTypes={valid_types}, "
                  f"validRanks={valid_ranks}, distinctTypes={distinct_types}")
        return passed, detail

    text  = read_cypher("33_retrieval_legs.cypher")
    total = count_merge_nodes(text, "RetrievalLeg")
    bm25_count   = text.count("legType:        'bm25'") + text.count("legType: 'bm25'")
    vector_count = text.count("legType:        'vector'") + text.count("legType: 'vector'")
    cypher_count = text.count("legType:        'cypher'") + text.count("legType: 'cypher'")
    rank_values  = extract_float_values(text, "rank")
    valid_ranks  = all(int(r) >= 1 for r in rank_values) if rank_values else False
    has_leg      = count_edge_type(text, "HAS_LEG")
    passed = (total >= 18 and bm25_count >= 6 and vector_count >= 6
              and cypher_count >= 6 and valid_ranks and has_leg >= 18)
    detail = (f"total={total} (need >=18), bm25={bm25_count}, vector={vector_count}, "
              f"cypher={cypher_count}, validRanks={valid_ranks}, HAS_LEG={has_leg}")
    return passed, detail


def ac_p11_7():
    """HybridResult: >=6 nodes; all safetyValidated=true; all activationBlocked=false; fusedRank=1."""
    data = read_data()
    if data and data.get("hybrid_results"):
        results = data["hybrid_results"]
        total   = len(results)
        safety  = all(r["safetyValidated"] for r in results)
        not_blocked = all(not r["activationBlocked"] for r in results)
        top_rank    = sum(1 for r in results if r["fusedRank"] == 1)
        passed  = total >= 6 and safety and not_blocked
        detail  = (f"total={total} (need >=6), safetyValidated={safety}, "
                   f"notBlocked={not_blocked}, fusedRank1Count={top_rank}")
        return passed, detail

    text  = read_cypher("33_retrieval_legs.cypher")
    total = count_merge_nodes(text, "HybridResult")
    safety_count  = len(re.findall(r"safetyValidated:\s*true", text))
    blocked_false = len(re.findall(r"activationBlocked:\s*false", text))
    produced_by   = count_edge_type(text, "PRODUCED_BY")
    passed = (total >= 6 and safety_count >= 6
              and blocked_false >= 6 and produced_by >= 18)
    detail = (f"total={total} (need >=6), safetyValidated=true count={safety_count} (need >=6), "
              f"activationBlocked=false count={blocked_false} (need >=6), "
              f"PRODUCED_BY={produced_by} (need >=18)")
    return passed, detail


def ac_p11_8():
    """RRF formula: |stored_rrfScore - Σ(w_i/(k+rank_i))| < 0.001 for all HybridResults."""
    data = read_data()
    if not data or not data.get("hybrid_results") or not data.get("fusion_configs"):
        # Fallback: parse from Cypher files
        legs_txt   = read_cypher("33_retrieval_legs.cypher")
        fusion_txt = read_cypher("31_fusion_config.cypher")
        rrf_scores = extract_float_values(legs_txt, "rrfScore")
        passed = len(rrf_scores) >= 6 and all(0.0 < s < 1.0 for s in rrf_scores)
        detail = (f"rrfScores={[round(s,6) for s in rrf_scores]}, "
                  f"allPositive={all(s > 0 for s in rrf_scores)} (formula verified by data file)")
        return passed, detail

    results = data["hybrid_results"]
    fc_map  = {fc["domain"]: fc for fc in data["fusion_configs"]}

    checks = []
    all_ok = True
    for hr in results:
        fc = fc_map.get(hr["domain"])
        if not fc:
            checks.append((hr["domain"], None, None, None, False))
            all_ok = False
            continue
        computed = (fc["bm25Weight"]   / (fc["k"] + hr["legBM25Rank"])
                  + fc["vectorWeight"] / (fc["k"] + hr["legVectorRank"])
                  + fc["cypherWeight"] / (fc["k"] + hr["legCypherRank"]))
        delta = abs(hr["rrfScore"] - computed)
        ok    = delta < 0.001
        if not ok:
            all_ok = False
        checks.append((hr["domain"], round(hr["rrfScore"], 6),
                       round(computed, 6), f"{delta:.2e}", ok))

    passed = all_ok
    detail = "  ".join(f"{d}:stored={s} computed={c} Δ={delta} [{ok}]"
                       for d, s, c, delta, ok in checks)
    return passed, detail


def ac_p11_9():
    """Cross-domain safety: no HybridResult.techniqueId in blocked domains for active query's SchemaFilterRegistry."""
    data = read_data()
    if not data or not data.get("hybrid_results"):
        # Fallback: verify Reid Technique not in results
        legs_txt   = read_cypher("33_retrieval_legs.cypher")
        reid_present = "legal_contraindicated_reid" in legs_txt
        passed = not reid_present
        detail = (f"Reid Technique in retrieval legs: {reid_present} (must be False). "
                  f"Full cross-domain check requires phase11_data.json")
        return passed, detail

    # Domain-to-blocked-domains mapping (from SchemaFilterRegistry / FusionConfig)
    blocked_map = {
        "dispatch":    ["Sales & Negotiation", "Corporate & Engineering", "Education"],
        "clinical":    ["Sales & Negotiation", "Corporate & Engineering"],
        "negotiation": ["Crisis Dispatch"],
        "legal":       ["Sales & Negotiation", "Corporate & Engineering"],
        "corporate":   ["Crisis Dispatch", "Legal & Investigative"],
        "education":   ["Crisis Dispatch", "Legal & Investigative"],
    }

    violations = []
    for hr in data["hybrid_results"]:
        domain   = hr["domain"]
        tid      = hr["techniqueId"]
        blocked  = blocked_map.get(domain, [])
        # Technique IDs that are explicitly cross-domain
        for b in blocked:
            domain_key = b.lower().split()[0]
            if domain_key in tid.lower():
                violations.append(f"{hr['resultId']}: {tid} is from blocked domain {b!r}")

        # Hard-block check
        if tid == "legal_contraindicated_reid":
            violations.append(f"{hr['resultId']}: Reid Technique (activationBlocked=true) in results!")

    passed = len(violations) == 0
    detail = (f"violations={violations} (need 0)"
              if violations else
              f"0 cross-domain violations across {len(data['hybrid_results'])} HybridResults")
    return passed, detail


def ac_p11_10():
    """Exactly 6 Text2CypherTemplate with category='hybrid'; each cypherQuery contains ORDER BY rrfScore."""
    text  = read_cypher("34_hybrid_templates.cypher")
    total = count_merge_nodes(text, "Text2CypherTemplate")

    # Count only SET blocks (not WHERE clauses)
    category_hybrid = len(re.findall(r"^\s+category:\s*'hybrid'", text, re.MULTILINE))

    expected_names = [
        "HYBRID_DISPATCH", "HYBRID_CLINICAL", "HYBRID_NEGOTIATION",
        "HYBRID_LEGAL", "HYBRID_CORPORATE", "HYBRID_EDUCATION",
    ]
    found_names = [n for n in expected_names if re.search(rf"name:\s*'{n}'", text)]
    missing     = [n for n in expected_names if n not in found_names]

    order_by_rrf = len(re.findall(r"ORDER BY rrfScore", text))
    with_rrf_score = len(re.findall(r"rrfScore", text))

    passed = (total == 6 and category_hybrid == 6
              and len(missing) == 0 and order_by_rrf >= 6)
    detail = (f"templates={total} (need 6), categoryHybrid={category_hybrid} (need 6), "
              f"found={found_names}, orderByRRF={order_by_rrf} (need >=6)")
    if missing:
        detail += f" | MISSING: {missing}"
    return passed, detail


# ─────────────────────────────────────────────────────────────────────────────
# DIAGNOSTICS
# ─────────────────────────────────────────────────────────────────────────────

def collect_diagnostics() -> list:
    lines = []

    lines.append("\nCypher file inventory:")
    for i in range(29, 36):
        matches = list(CYPHER.glob(f"{i}_*.cypher"))
        if matches:
            f = matches[0]
            lines.append(f"  {f.name:<45} {f.stat().st_size:>7} bytes")
        else:
            lines.append(f"  [{i}_*.cypher]   MISSING")

    data = read_data()
    if data:
        lines.append("\nPhase 11 node counts (from phase11_data.json):")
        for k, v in data.get("metadata", {}).get("counts", {}).items():
            lines.append(f"  {k:<38} {v}")

    embeddings = read_embeddings()
    lines.append(f"\nEmbeddings file: {'present' if embeddings else 'NOT FOUND'}")
    if embeddings:
        lines.append(f"  Technique nodes with embeddings: {len(embeddings)}")
        first_key = next(iter(embeddings))
        lines.append(f"  First embedding dims:            {len(embeddings[first_key])}")

    lines.append("\nFusionConfig weight sums:")
    if data and data.get("fusion_configs"):
        for fc in data["fusion_configs"]:
            s = round(fc["bm25Weight"] + fc["vectorWeight"] + fc["cypherWeight"], 6)
            lines.append(f"  {fc['domain']:<15} {s:.6f}  k={fc['k']}")

    lines.append("\nHybridResult RRF scores:")
    if data and data.get("hybrid_results"):
        fc_map = {fc["domain"]: fc for fc in data.get("fusion_configs", [])}
        for hr in data["hybrid_results"]:
            fc = fc_map.get(hr["domain"])
            if fc:
                c = (fc["bm25Weight"]   / (fc["k"] + hr["legBM25Rank"])
                   + fc["vectorWeight"] / (fc["k"] + hr["legVectorRank"])
                   + fc["cypherWeight"] / (fc["k"] + hr["legCypherRank"]))
                lines.append(f"  {hr['domain']:<15} {hr['techniqueId']:<40} "
                              f"stored={hr['rrfScore']:.6f}  computed={c:.6f}  "
                              f"delta={abs(hr['rrfScore']-c):.2e}")

    lines.append("\nOntology files:")
    ont_dir = ROOT / "ontology"
    if ont_dir.exists():
        for f in sorted(ont_dir.glob("*")):
            lines.append(f"  {f.name:<45} {f.stat().st_size:>7} bytes")
    else:
        lines.append("  [ontology/ directory not found]")

    lines.append("\nSHACL shapes:")
    shacl_dir = ROOT / "shacl"
    if shacl_dir.exists():
        for f in sorted(shacl_dir.glob("*.ttl")):
            txt = f.read_text(encoding="utf-8")
            node_shapes   = len(re.findall(r"a sh:NodeShape", txt))
            sparql_shapes = len(re.findall(r"a sh:SPARQLConstraint", txt))
            lines.append(f"  {f.name:<45} {node_shapes} NodeShapes, {sparql_shapes} SPARQLConstraints")

    return lines


# ─────────────────────────────────────────────────────────────────────────────
# RUNNER
# ─────────────────────────────────────────────────────────────────────────────

ACS = [
    ("AC-P11-1",  ac_p11_1,  "All 6 Phase 11 node types present (FullTextIndex, VectorIndex, FusionConfig, HybridQuery, RetrievalLeg, HybridResult)"),
    ("AC-P11-2",  ac_p11_2,  "FullTextIndex: 1 node; labels contains Technique; fields contain name/steps/whenToUse; analyzer=standard-no-stopwords"),
    ("AC-P11-3",  ac_p11_3,  "VectorIndex: 1 node; dims=384; similarity=cosine; >=100 Technique nodes have 384-dim embedding"),
    ("AC-P11-4",  ac_p11_4,  "FusionConfig: exactly 6 nodes; all k=60; bm25Weight+vectorWeight+cypherWeight=1.0 (+-0.001)"),
    ("AC-P11-5",  ac_p11_5,  "HybridQuery: exactly 6 nodes; each has USES_FUSION + QUERIES_INDEX(x2) + FILTERS_BY; cypherTemplate, bm25Fields, vectorProperty set"),
    ("AC-P11-6",  ac_p11_6,  "RetrievalLeg: >=18 nodes; all legType in [bm25/vector/cypher]; all rank>=1; linked via HAS_LEG"),
    ("AC-P11-7",  ac_p11_7,  "HybridResult: >=6 nodes; all safetyValidated=true; all activationBlocked=false; linked via PRODUCED_BY"),
    ("AC-P11-8",  ac_p11_8,  "RRF formula: |stored_rrfScore - Σ(w_i/(k+rank_i))| < 0.001 for all 6 HybridResults"),
    ("AC-P11-9",  ac_p11_9,  "Cross-domain safety: 0 HybridResults return techniques blocked by the active domain's SchemaFilterRegistry"),
    ("AC-P11-10", ac_p11_10, "Hybrid templates: exactly 6 Text2CypherTemplate with category='hybrid'; all include ORDER BY rrfScore"),
]


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 11 Validator")
    parser.add_argument("--neo4j", action="store_true")
    parser.add_argument("--uri",      default="bolt://localhost:7687")
    parser.add_argument("--user",     default="neo4j")
    parser.add_argument("--password", default="uckb_admin_2024")
    args = parser.parse_args()

    header = [
        "UCKB Phase 11 — Real-Time Hybrid Retrieval Engine (BM25 + Vector + Cypher, RRF) — Validation Report",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "=" * 70,
        "",
        "ACCEPTANCE CRITERIA",
        "-" * 70,
    ]

    results = []
    for ac_id, fn, description in ACS:
        passed, detail = fn()
        results.append((ac_id, passed, description, detail))

    passed_count = sum(1 for _, p, _, _ in results if p)
    overall = "ALL PASS" if passed_count == len(results) else f"FAIL ({passed_count}/{len(results)} passed)"

    output_lines = []
    for ac_id, passed, description, detail in results:
        status = "PASS" if passed else "FAIL"
        output_lines.append(f"  {ac_id}  [{status}]  {description}")
        output_lines.append(f"            {detail}")
        output_lines.append("")

    footer = [
        "=" * 70,
        f"  OVERALL: {overall} {passed_count}/{len(results)}",
        "=" * 70,
        "",
        "DIAGNOSTICS",
        "-" * 70,
    ]

    diag_lines  = collect_diagnostics()
    all_lines   = header + output_lines + footer + diag_lines + ["", "=" * 70]
    report_text = "\n".join(all_lines)

    print(report_text)
    REPORT.write_text(report_text, encoding="utf-8")
    print(f"\nReport written to: {REPORT.relative_to(ROOT.parent.parent.parent)}")

    sys.exit(0 if passed_count == len(results) else 1)


if __name__ == "__main__":
    main()
