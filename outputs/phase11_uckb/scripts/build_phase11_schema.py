"""
UCKB Phase 11 — Schema Builder
Generates all Phase 11 node definitions as Python dataclasses and saves them
to outputs/phase11_uckb/data/phase11_data.json for use by validate_phase11.py.

Does NOT require Neo4j or sentence-transformers.

Usage:
    python build_phase11_schema.py
"""

import json
import sys
import io
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import List, Optional

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT     = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# DATA CLASSES
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class FullTextIndex:
    indexId:             str
    indexName:           str
    labels:              List[str]
    fields:              List[str]
    analyzer:            str
    queryOperator:       str
    eventuallyConsistent: bool
    version:             str
    createdPhase:        str
    description:         str


@dataclass
class VectorIndex:
    indexId:      str
    indexName:    str
    label:        str
    property:     str
    dims:         int
    similarity:   str
    model:        str
    quantization: str
    version:      str
    createdPhase: str
    description:  str


@dataclass
class FusionConfig:
    domain:          str
    k:               int
    bm25Weight:      float
    vectorWeight:    float
    cypherWeight:    float
    bm25TopK:        int
    vectorTopK:      int
    cypherTopK:      int
    finalTopK:       int
    safetyFirstOrder: bool
    rationale:       str
    updatedPhase:    str


@dataclass
class HybridQuery:
    queryId:         str
    domain:          str
    description:     str
    bm25Fields:      List[str]
    vectorProperty:  str
    cypherTemplate:  str
    defaultTopK:     int
    version:         str
    createdPhase:    str
    fusionDomain:    str   # points to FusionConfig.domain
    filterDomain:    str   # points to SchemaFilterRegistry.domain


@dataclass
class RetrievalLeg:
    legId:         str
    queryId:       str
    legType:       str   # bm25 | vector | cypher
    rank:          int
    rawScore:      float
    techniqueId:   str
    techniqueName: str
    queryText:     str
    domain:        str
    createdPhase:  str


@dataclass
class HybridResult:
    resultId:          str
    queryId:           str
    domain:            str
    techniqueId:       str
    techniqueName:     str
    fusedRank:         int
    rrfScore:          float
    legBM25Rank:       int
    legVectorRank:     int
    legCypherRank:     int
    safetyValidated:   bool
    activationBlocked: bool
    queryText:         str
    createdPhase:      str


@dataclass
class HybridTemplate:
    id:          str
    name:        str
    domain:      str
    category:    str
    description: str
    phase:       str
    cypherQuery: str


# ─────────────────────────────────────────────────────────────────────────────
# NODE DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────

FULL_TEXT_INDEX = FullTextIndex(
    indexId='uckb_fulltext_v1',
    indexName='uckb_fulltext',
    labels=['Technique', 'SignalMarker', 'ProtocolStep'],
    fields=['name', 'steps', 'whenToUse', 'failureSignals', 'culturalNotes'],
    analyzer='standard-no-stopwords',
    queryOperator='OR',
    eventuallyConsistent=False,
    version='1.0',
    createdPhase='11',
    description='BM25 Lucene full-text index over UCKB technique and signal text fields',
)

VECTOR_INDEX = VectorIndex(
    indexId='uckb_vector_v1',
    indexName='uckb_vector',
    label='Technique',
    property='embedding',
    dims=384,
    similarity='cosine',
    model='sentence-transformers/all-MiniLM-L6-v2',
    quantization='none',
    version='1.0',
    createdPhase='11',
    description='384-dim cosine vector index over Technique.embedding (all-MiniLM-L6-v2)',
)

FUSION_CONFIGS = [
    FusionConfig('dispatch',    60, 0.15, 0.25, 0.60, 10, 10, 10, 5, True,
                 'Safety graph structure dominates; BM25 keyword signals; vector catches synonyms', '11'),
    FusionConfig('clinical',    60, 0.20, 0.30, 0.50, 10, 10, 10, 5, True,
                 'SPIKES protocol gates critical; vector empathy nuance; BM25 medical terminology', '11'),
    FusionConfig('negotiation', 60, 0.30, 0.40, 0.30, 10, 10, 10, 5, False,
                 'Semantic intent dominant; BM25 objection/stalling keywords; graph validates SPIN/Harvard', '11'),
    FusionConfig('legal',       60, 0.40, 0.25, 0.35, 10, 10, 10, 5, True,
                 'Lexical precision for SA markers and PEACE steps; graph blocks Reid Technique', '11'),
    FusionConfig('corporate',   60, 0.25, 0.35, 0.40, 10, 10, 10, 5, False,
                 'Balanced; vector interpersonal nuance; graph private-channel constraint', '11'),
    FusionConfig('education',   60, 0.20, 0.40, 0.40, 10, 10, 10, 5, False,
                 'Semantic pedagogical intent high; BKT state Cypher; vector analogous scaffolds', '11'),
]

HYBRID_QUERIES = [
    HybridQuery('hq_dispatch_v1',    'dispatch',    'Hybrid retrieval for crisis dispatch',
                ['name','steps','whenToUse','failureSignals'], 'embedding',
                'MATCH (e:EmotionalState) WHERE ... NOT t.activationBlocked = true ... LIMIT $topK',
                5, '1.0', '11', 'dispatch', 'dispatch'),
    HybridQuery('hq_clinical_v1',    'clinical',    'Hybrid retrieval for clinical: SPIKES gate-aware',
                ['name','steps','whenToUse','culturalNotes'], 'embedding',
                'MATCH (p:ProtocolStep {protocol:"SPIKES"}) WHERE ... NOT t.activationBlocked = true ... LIMIT $topK',
                5, '1.0', '11', 'clinical', 'clinical'),
    HybridQuery('hq_negotiation_v1', 'negotiation', 'Hybrid retrieval for sales/negotiation: SPIN/Harvard',
                ['name','steps','whenToUse','failureSignals'], 'embedding',
                'MATCH (t:Technique) WHERE t.domain = "Sales & Negotiation" ... NOT t.activationBlocked = true ... LIMIT $topK',
                5, '1.0', '11', 'negotiation', 'negotiation'),
    HybridQuery('hq_legal_v1',       'legal',       'Hybrid retrieval for legal: PEACE-aware, Reid hard-blocked',
                ['name','steps','whenToUse','failureSignals'], 'embedding',
                'MATCH (s:ProtocolStep {protocol:"PEACE"}) WHERE ... NOT t.activationBlocked = true ... LIMIT $topK',
                5, '1.0', '11', 'legal', 'legal'),
    HybridQuery('hq_corporate_v1',   'corporate',   'Hybrid retrieval for corporate: SBI/NVC, private-channel guard',
                ['name','steps','whenToUse','culturalNotes'], 'embedding',
                'MATCH (t:Technique) WHERE t.domain = "Corporate & Engineering" ... NOT t.activationBlocked = true ... LIMIT $topK',
                5, '1.0', '11', 'corporate', 'corporate'),
    HybridQuery('hq_education_v1',   'education',   'Hybrid retrieval for education: BKT-aware',
                ['name','steps','whenToUse','failureSignals'], 'embedding',
                'MATCH (ks:KnowledgeState) ... NOT t.activationBlocked = true ORDER BY t.tier ASC LIMIT $topK',
                5, '1.0', '11', 'education', 'education'),
]

# 18 RetrievalLeg nodes — 3 legs per domain × 6 domains
RETRIEVAL_LEGS = [
    # Dispatch: BM25 rank=1, vector rank=2, cypher rank=1
    RetrievalLeg('leg_dispatch_bm25_01',   'hq_dispatch_v1',    'bm25',   1, 4.812,
                 't_bcsm_minimal_enc',  'Minimal Encouragers (BCSM Step 2)',
                 'caller panicking weapon mentioned', 'dispatch', '11'),
    RetrievalLeg('leg_dispatch_vector_01', 'hq_dispatch_v1',    'vector', 2, 0.847,
                 't_bcsm_minimal_enc',  'Minimal Encouragers (BCSM Step 2)',
                 'caller panicking weapon mentioned', 'dispatch', '11'),
    RetrievalLeg('leg_dispatch_cypher_01', 'hq_dispatch_v1',    'cypher', 1, 0.94,
                 't_bcsm_minimal_enc',  'Minimal Encouragers (BCSM Step 2)',
                 'detectedState=Panic domain=dispatch', 'dispatch', '11'),

    # Clinical: BM25 rank=2, vector rank=1, cypher rank=1
    RetrievalLeg('leg_clinical_bm25_01',   'hq_clinical_v1',    'bm25',   2, 3.291,
                 't_spikes_empathy_response', 'SPIKES Empathy Response (Step E)',
                 'patient resistant bad news oncologist', 'clinical', '11'),
    RetrievalLeg('leg_clinical_vector_01', 'hq_clinical_v1',    'vector', 1, 0.891,
                 't_spikes_empathy_response', 'SPIKES Empathy Response (Step E)',
                 'patient resistant bad news oncologist', 'clinical', '11'),
    RetrievalLeg('leg_clinical_cypher_01', 'hq_clinical_v1',    'cypher', 1, 0.91,
                 't_spikes_empathy_response', 'SPIKES Empathy Response (Step E)',
                 'current_step=4 protocol=SPIKES', 'clinical', '11'),

    # Negotiation: BM25 rank=1, vector rank=1, cypher rank=2
    RetrievalLeg('leg_negotiation_bm25_01',   'hq_negotiation_v1', 'bm25',   1, 5.437,
                 't_spin_implication_q', 'SPIN Implication Question',
                 'prospect stalling price objection', 'negotiation', '11'),
    RetrievalLeg('leg_negotiation_vector_01', 'hq_negotiation_v1', 'vector', 1, 0.874,
                 't_spin_implication_q', 'SPIN Implication Question',
                 'prospect stalling price objection', 'negotiation', '11'),
    RetrievalLeg('leg_negotiation_cypher_01', 'hq_negotiation_v1', 'cypher', 2, 0.88,
                 't_spin_implication_q', 'SPIN Implication Question',
                 'domain=negotiation evidenceLevel DESC', 'negotiation', '11'),

    # Legal: BM25 rank=1, vector rank=2, cypher rank=1
    RetrievalLeg('leg_legal_bm25_01',   'hq_legal_v1',       'bm25',   1, 6.104,
                 't_peace_probing', 'PEACE Probing Questions (Step A — Account)',
                 'subject pronoun changes verb tense shifts', 'legal', '11'),
    RetrievalLeg('leg_legal_vector_01', 'hq_legal_v1',       'vector', 2, 0.813,
                 't_peace_probing', 'PEACE Probing Questions (Step A — Account)',
                 'subject pronoun changes verb tense shifts', 'legal', '11'),
    RetrievalLeg('leg_legal_cypher_01', 'hq_legal_v1',       'cypher', 1, 0.92,
                 't_peace_probing', 'PEACE Probing Questions (Step A — Account)',
                 'current_peace_step=3 activationBlocked=false', 'legal', '11'),

    # Corporate: BM25 rank=2, vector rank=1, cypher rank=1
    RetrievalLeg('leg_corporate_bm25_01',   'hq_corporate_v1',   'bm25',   2, 3.628,
                 't_sbi_feedback', 'SBI Feedback (Situation-Behavior-Impact)',
                 'team member defensiveness code review', 'corporate', '11'),
    RetrievalLeg('leg_corporate_vector_01', 'hq_corporate_v1',   'vector', 1, 0.862,
                 't_sbi_feedback', 'SBI Feedback (Situation-Behavior-Impact)',
                 'team member defensiveness code review', 'corporate', '11'),
    RetrievalLeg('leg_corporate_cypher_01', 'hq_corporate_v1',   'cypher', 1, 0.89,
                 't_sbi_feedback', 'SBI Feedback (Situation-Behavior-Impact)',
                 'domain=corporate NOT public_setting activationBlocked=false', 'corporate', '11'),

    # Education: BM25 rank=3, vector rank=1, cypher rank=1
    RetrievalLeg('leg_education_bm25_01',   'hq_education_v1',   'bm25',   3, 2.814,
                 't_scaffold_tier1', 'Scaffolded Hint Tier 1 (Minimal Support)',
                 'student systematic errors fractions low confidence', 'education', '11'),
    RetrievalLeg('leg_education_vector_01', 'hq_education_v1',   'vector', 1, 0.878,
                 't_scaffold_tier1', 'Scaffolded Hint Tier 1 (Minimal Support)',
                 'student systematic errors fractions low confidence', 'education', '11'),
    RetrievalLeg('leg_education_cypher_01', 'hq_education_v1',   'cypher', 1, 0.86,
                 't_scaffold_tier1', 'Scaffolded Hint Tier 1 (Minimal Support)',
                 'p_know_bracket=low bkt_condition=mastery_lt_0.4', 'education', '11'),
]

# 6 HybridResult nodes — rrfScore = Σ w_i / (k + rank_i)
# Dispatch:    0.15/61 + 0.25/62 + 0.60/61 = 0.016327
# Clinical:    0.20/62 + 0.30/61 + 0.50/61 = 0.016341
# Negotiation: 0.30/61 + 0.40/61 + 0.30/62 = 0.016314
# Legal:       0.40/61 + 0.25/62 + 0.35/61 = 0.016327
# Corporate:   0.25/62 + 0.35/61 + 0.40/61 = 0.016327
# Education:   0.20/63 + 0.40/61 + 0.40/61 = 0.016289
HYBRID_RESULTS = [
    HybridResult('hresult_dispatch_01',    'hq_dispatch_v1',    'dispatch',
                 't_bcsm_minimal_enc',          'Minimal Encouragers (BCSM Step 2)',
                 1, 0.016327, 1, 2, 1, True, False,
                 'caller panicking weapon mentioned', '11'),
    HybridResult('hresult_clinical_01',    'hq_clinical_v1',    'clinical',
                 't_spikes_empathy_response',   'SPIKES Empathy Response (Step E)',
                 1, 0.016341, 2, 1, 1, True, False,
                 'patient resistant to bad news, oncologist', '11'),
    HybridResult('hresult_negotiation_01', 'hq_negotiation_v1', 'negotiation',
                 't_spin_implication_q',        'SPIN Implication Question',
                 1, 0.016314, 1, 1, 2, True, False,
                 'prospect stalling on price objection', '11'),
    HybridResult('hresult_legal_01',       'hq_legal_v1',       'legal',
                 't_peace_probing',             'PEACE Probing Questions (Step A — Account)',
                 1, 0.016327, 1, 2, 1, True, False,
                 'subject using pronoun changes and verb tense shifts', '11'),
    HybridResult('hresult_corporate_01',   'hq_corporate_v1',   'corporate',
                 't_sbi_feedback',             'SBI Feedback (Situation-Behavior-Impact)',
                 1, 0.016327, 2, 1, 1, True, False,
                 'team member displaying defensiveness in code review', '11'),
    HybridResult('hresult_education_01',   'hq_education_v1',   'education',
                 't_scaffold_tier1',           'Scaffolded Hint Tier 1 (Minimal Support)',
                 1, 0.016289, 3, 1, 1, True, False,
                 'student making systematic errors on fractions, low confidence', '11'),
]

HYBRID_TEMPLATES = [
    HybridTemplate('hybrid_dispatch_v1',    'HYBRID_DISPATCH',    'dispatch',    'hybrid',
                   'Dispatch BM25 + vector + Cypher fused via weighted RRF (k=60)', '11',
                   '... ORDER BY rrfScore DESC LIMIT $topK'),
    HybridTemplate('hybrid_clinical_v1',    'HYBRID_CLINICAL',    'clinical',    'hybrid',
                   'Clinical BM25 + vector + SPIKES gate-checked Cypher fused via weighted RRF (k=60)', '11',
                   '... ORDER BY rrfScore DESC LIMIT $topK'),
    HybridTemplate('hybrid_negotiation_v1', 'HYBRID_NEGOTIATION', 'negotiation', 'hybrid',
                   'Negotiation BM25 + vector (dominant) + Cypher fused via weighted RRF (k=60)', '11',
                   '... ORDER BY rrfScore DESC LIMIT $topK'),
    HybridTemplate('hybrid_legal_v1',       'HYBRID_LEGAL',       'legal',       'hybrid',
                   'Legal BM25 (dominant) + vector + PEACE-step Cypher fused via weighted RRF (k=60)', '11',
                   '... ORDER BY rrfScore DESC LIMIT $topK'),
    HybridTemplate('hybrid_corporate_v1',   'HYBRID_CORPORATE',   'corporate',   'hybrid',
                   'Corporate BM25 + vector + SBI/NVC Cypher fused via weighted RRF (k=60)', '11',
                   '... ORDER BY rrfScore DESC LIMIT $topK'),
    HybridTemplate('hybrid_education_v1',   'HYBRID_EDUCATION',   'education',   'hybrid',
                   'Education BM25 + vector (dominant) + BKT-state Cypher fused via weighted RRF (k=60)', '11',
                   '... ORDER BY rrfScore DESC LIMIT $topK'),
]


# ─────────────────────────────────────────────────────────────────────────────
# SERIALISE + SAVE
# ─────────────────────────────────────────────────────────────────────────────

def main():
    data = {
        "full_text_index":  asdict(FULL_TEXT_INDEX),
        "vector_index":     asdict(VECTOR_INDEX),
        "fusion_configs":   [asdict(fc) for fc in FUSION_CONFIGS],
        "hybrid_queries":   [asdict(hq) for hq in HYBRID_QUERIES],
        "retrieval_legs":   [asdict(rl) for rl in RETRIEVAL_LEGS],
        "hybrid_results":   [asdict(hr) for hr in HYBRID_RESULTS],
        "hybrid_templates": [asdict(ht) for ht in HYBRID_TEMPLATES],
        "metadata": {
            "phase": "11",
            "description": "UCKB Phase 11 — Real-Time Hybrid Retrieval Engine (BM25 + Vector + Cypher, RRF)",
            "new_node_types": ["FullTextIndex","VectorIndex","FusionConfig",
                               "HybridQuery","RetrievalLeg","HybridResult"],
            "new_relationship_types": ["USES_FUSION","QUERIES_INDEX","FILTERS_BY",
                                       "HAS_LEG","PRODUCED_BY","FUSED_INTO","SAFE_FOR",
                                       "CO_INDEX_WITH"],
            "counts": {
                "FullTextIndex": 1,
                "VectorIndex":   1,
                "FusionConfig":  6,
                "HybridQuery":   6,
                "RetrievalLeg":  18,
                "HybridResult":  6,
                "Text2CypherTemplate_hybrid": 6,
                "total_new_nodes": 44,
            },
        },
    }

    out = DATA_DIR / "phase11_data.json"
    out.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Written: {out.relative_to(ROOT.parent.parent)}")

    print("\nPhase 11 schema summary:")
    for key, val in data["metadata"]["counts"].items():
        print(f"  {key:<36} {val}")

    # Verify weight sums
    print("\nFusionConfig weight sums:")
    for fc in FUSION_CONFIGS:
        s = round(fc.bm25Weight + fc.vectorWeight + fc.cypherWeight, 6)
        status = "OK" if abs(s - 1.0) < 0.001 else "FAIL"
        print(f"  {fc.domain:<15} {s:.6f}  [{status}]")

    # Verify RRF scores
    print("\nHybridResult RRF score verification:")
    fc_map = {fc.domain: fc for fc in FUSION_CONFIGS}
    for hr in HYBRID_RESULTS:
        fc = fc_map[hr.domain]
        computed = (fc.bm25Weight / (fc.k + hr.legBM25Rank)
                  + fc.vectorWeight / (fc.k + hr.legVectorRank)
                  + fc.cypherWeight / (fc.k + hr.legCypherRank))
        delta = abs(hr.rrfScore - computed)
        status = "OK" if delta < 0.001 else "FAIL"
        print(f"  {hr.domain:<15} stored={hr.rrfScore:.6f}  computed={computed:.6f}  Δ={delta:.2e}  [{status}]")

    print("\nBuild complete.")


if __name__ == "__main__":
    main()
