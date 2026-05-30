"""
UCKB Phase 11 — HybridRetriever
Core retrieval class: 3-leg execution (BM25 + vector + Cypher) with
weighted Reciprocal Rank Fusion (RRF) and cross-domain safety filtering.

Can run in mock mode (no Neo4j, no ML) or connected mode.

Usage (mock):
    from hybrid_retriever import HybridRetriever
    r = HybridRetriever(domain='dispatch')
    results = r.retrieve("caller panicking, weapon mentioned")

Usage (Neo4j connected):
    from neo4j import GraphDatabase
    driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j","uckb_admin_2024"))
    r = HybridRetriever(driver=driver, domain='dispatch')
    results = r.retrieve("caller panicking, weapon mentioned",
                         query_embedding=[...],   # 384-dim float list
                         cypher_params={"detectedState": "Panic"})
"""

from __future__ import annotations

import math
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Any

ROOT     = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"


# ─────────────────────────────────────────────────────────────────────────────
# DOMAIN CONFIGURATION (mirrors FusionConfig nodes in Neo4j)
# ─────────────────────────────────────────────────────────────────────────────

DOMAIN_CONFIGS = {
    "dispatch":    {"bm25": 0.15, "vector": 0.25, "cypher": 0.60, "k": 60, "safety_first": True,
                    "blocked": ["Sales & Negotiation", "Corporate & Engineering", "Education"]},
    "clinical":    {"bm25": 0.20, "vector": 0.30, "cypher": 0.50, "k": 60, "safety_first": True,
                    "blocked": ["Sales & Negotiation", "Corporate & Engineering"]},
    "negotiation": {"bm25": 0.30, "vector": 0.40, "cypher": 0.30, "k": 60, "safety_first": False,
                    "blocked": ["Crisis Dispatch / Emergency"]},
    "legal":       {"bm25": 0.40, "vector": 0.25, "cypher": 0.35, "k": 60, "safety_first": True,
                    "blocked": ["Sales & Negotiation", "Corporate & Engineering"]},
    "corporate":   {"bm25": 0.25, "vector": 0.35, "cypher": 0.40, "k": 60, "safety_first": False,
                    "blocked": ["Crisis Dispatch / Emergency", "Legal & Investigative"]},
    "education":   {"bm25": 0.20, "vector": 0.40, "cypher": 0.40, "k": 60, "safety_first": False,
                    "blocked": ["Crisis Dispatch / Emergency", "Legal & Investigative"]},
}

# Reid Technique is ALWAYS blocked regardless of domain
HARD_BLOCKED_IDS = {"legal_contraindicated_reid"}


# ─────────────────────────────────────────────────────────────────────────────
# DATA CLASSES
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class LegResult:
    technique_id:   str
    technique_name: str
    domain:         str
    raw_score:      float
    rank:           int = 0
    leg_type:       str = ""  # bm25 | vector | cypher


@dataclass
class FusedResult:
    technique_id:   str
    technique_name: str
    domain:         str
    rrf_score:      float
    fused_rank:     int
    leg_bm25_rank:  int
    leg_vector_rank: int
    leg_cypher_rank: int
    safety_validated: bool = True

    def __str__(self):
        return (f"[{self.fused_rank}] {self.technique_name} "
                f"(rrf={self.rrf_score:.6f}, "
                f"bm25_r={self.leg_bm25_rank}, "
                f"vec_r={self.leg_vector_rank}, "
                f"cyp_r={self.leg_cypher_rank})")


# ─────────────────────────────────────────────────────────────────────────────
# MOCK RETRIEVAL DATA (used when no Neo4j driver is provided)
# ─────────────────────────────────────────────────────────────────────────────

MOCK_TECHNIQUES = {
    "dispatch": [
        ("t_bcsm_minimal_enc",       "Minimal Encouragers (BCSM Step 2)",           "Crisis Dispatch / Emergency"),
        ("t_bcsm_active_listening",  "Active Listening (BCSM)",                     "Crisis Dispatch / Emergency"),
        ("t_bcsm_emotional_labeling","Emotional Labeling",                           "Crisis Dispatch / Emergency"),
        ("t_bcsm_mirroring",         "Mirroring (BCSM)",                            "Crisis Dispatch / Emergency"),
        ("t_bcsm_paraphrasing",      "Paraphrasing (BCSM)",                         "Crisis Dispatch / Emergency"),
    ],
    "clinical": [
        ("t_spikes_empathy_response","SPIKES Empathy Response (Step E)",             "Clinical / Medical"),
        ("t_spikes_invitation",      "SPIKES Invitation (Step I)",                  "Clinical / Medical"),
        ("t_teach_back",             "Teach-Back Technique",                        "Clinical / Medical"),
        ("t_motivational_interview", "Motivational Interviewing",                   "Clinical / Medical"),
        ("t_chunking_checking",      "Chunk-and-Check Information Delivery",        "Clinical / Medical"),
    ],
    "negotiation": [
        ("t_spin_implication_q",     "SPIN Implication Question",                   "Sales & Negotiation"),
        ("t_spin_need_payoff_q",     "SPIN Need-Payoff Question",                   "Sales & Negotiation"),
        ("t_harvard_interests",      "Interest-Based Bargaining (Harvard)",         "Sales & Negotiation"),
        ("t_tactical_empathy",       "Tactical Empathy",                            "Sales & Negotiation"),
        ("t_calibrated_questions",   "Calibrated Questions",                        "Sales & Negotiation"),
    ],
    "legal": [
        ("t_peace_probing",          "PEACE Probing Questions (Step A)",            "Legal & Investigative"),
        ("t_peace_account",          "PEACE Account — Free Recall",                 "Legal & Investigative"),
        ("t_cognitive_interview",    "Cognitive Interview Protocol",                "Legal & Investigative"),
        ("t_sa_probe",               "Statement Analysis Probe",                    "Legal & Investigative"),
        ("t_free_recall_prompt",     "Free Recall Prompt",                          "Legal & Investigative"),
    ],
    "corporate": [
        ("t_sbi_feedback",           "SBI Feedback (Situation-Behavior-Impact)",    "Corporate & Engineering"),
        ("t_nvc_observation",        "NVC Observation",                             "Corporate & Engineering"),
        ("t_radical_candor",         "Radical Candor",                              "Corporate & Engineering"),
        ("t_psychological_safety",   "Psychological Safety Priming",                "Corporate & Engineering"),
        ("t_accountability_convo",   "Accountability Conversation",                 "Corporate & Engineering"),
    ],
    "education": [
        ("t_scaffold_tier1",         "Scaffolded Hint Tier 1 (Minimal Support)",   "Education"),
        ("t_scaffold_tier2",         "Scaffolded Hint Tier 2 (Moderate Support)",  "Education"),
        ("t_socratic_q",             "Socratic Questioning",                        "Education"),
        ("t_error_analysis",         "Error Analysis Prompt",                       "Education"),
        ("t_praise_effort",          "Praise for Effort",                           "Education"),
    ],
}


# ─────────────────────────────────────────────────────────────────────────────
# HYBRID RETRIEVER
# ─────────────────────────────────────────────────────────────────────────────

class HybridRetriever:
    """
    3-leg retrieval engine with weighted RRF fusion.

    Legs:
      BM25   — full-text lexical search (Lucene)
      Vector — cosine similarity over Technique.embedding
      Cypher — graph traversal (existing Text2Cypher templates)

    Safety:
      Cypher leg builds a blockedSet from activationBlocked=true nodes.
      BM25 and vector results are post-filtered before fusion.
      Cross-domain contamination is enforced via SchemaFilterRegistry.blockedDomains.
    """

    def __init__(self, domain: str, driver=None):
        if domain not in DOMAIN_CONFIGS:
            raise ValueError(f"Unknown domain: {domain!r}. "
                             f"Valid: {list(DOMAIN_CONFIGS)}")
        self.domain  = domain
        self.driver  = driver
        self.cfg     = DOMAIN_CONFIGS[domain]
        self._mock   = driver is None

    # ── BM25 leg ──────────────────────────────────────────────────────────────

    def _bm25_leg(self, query_text: str, top_k: int = 10) -> List[LegResult]:
        if self._mock:
            techs = MOCK_TECHNIQUES.get(self.domain, [])
            # Simulate BM25 relevance with keyword overlap count as a proxy
            q_words = set(query_text.lower().split())
            scored  = []
            for tid, tname, tdomain in techs:
                overlap = len(q_words & set((tid + " " + tname).lower().split("_")))
                scored.append(LegResult(tid, tname, tdomain, float(overlap + 1), leg_type='bm25'))
            scored.sort(key=lambda x: x.raw_score, reverse=True)
            for i, r in enumerate(scored[:top_k]):
                r.rank = i + 1
            return scored[:top_k]

        results = []
        with self.driver.session() as db:
            rows = db.run(
                'CALL db.index.fulltext.queryNodes("uckb_fulltext", $q) '
                'YIELD node AS n, score '
                'WHERE n:Technique AND n.domain CONTAINS $domain '
                '  AND NOT n.activationBlocked = true '
                'RETURN n.id AS id, n.name AS name, n.domain AS domain, score '
                'ORDER BY score DESC LIMIT $topK',
                q=query_text, domain=self.domain, topK=top_k,
            )
            for i, r in enumerate(rows, 1):
                results.append(LegResult(r["id"], r["name"], r["domain"],
                                         r["score"], rank=i, leg_type='bm25'))
        return results

    # ── Vector leg ────────────────────────────────────────────────────────────

    def _vector_leg(self, query_embedding: Optional[List[float]] = None,
                    top_k: int = 10) -> List[LegResult]:
        if self._mock:
            techs  = MOCK_TECHNIQUES.get(self.domain, [])
            # Mock cosine similarities: descending from 0.95
            scored = []
            for i, (tid, tname, tdomain) in enumerate(techs[:top_k]):
                sim = round(0.95 - i * 0.04, 3)
                scored.append(LegResult(tid, tname, tdomain, sim, rank=i + 1, leg_type='vector'))
            return scored

        if query_embedding is None:
            return []
        results = []
        with self.driver.session() as db:
            rows = db.run(
                'CALL db.index.vector.queryNodes("uckb_vector", $topK, $vec) '
                'YIELD node AS n, score '
                'WHERE NOT n.activationBlocked = true '
                'RETURN n.id AS id, n.name AS name, n.domain AS domain, score '
                'ORDER BY score DESC LIMIT $topK',
                vec=query_embedding, topK=top_k,
            )
            for i, r in enumerate(rows, 1):
                results.append(LegResult(r["id"], r["name"], r["domain"],
                                         r["score"], rank=i, leg_type='vector'))
        return results

    # ── Cypher leg ────────────────────────────────────────────────────────────

    def _cypher_leg(self, params: Optional[dict] = None, top_k: int = 10) -> List[LegResult]:
        if self._mock:
            techs  = MOCK_TECHNIQUES.get(self.domain, [])
            scored = []
            # Simulate graph-structured order (slightly different from vector)
            for i, (tid, tname, tdomain) in enumerate(reversed(techs[:top_k])):
                score = round(0.94 - i * 0.03, 3)
                scored.append(LegResult(tid, tname, tdomain, score,
                                        rank=i + 1, leg_type='cypher'))
            return scored

        if params is None:
            params = {}
        results = []
        with self.driver.session() as db:
            # Load the HybridQuery's cypherTemplate from the graph
            row = db.run(
                'MATCH (hq:HybridQuery {queryId: $qid}) RETURN hq.cypherTemplate AS tmpl',
                qid=f'hq_{self.domain}_v1',
            ).single()
            if not row:
                return []
            cypher = row["tmpl"].replace("$topK", str(top_k))
            rows   = db.run(cypher, **params)
            for i, r in enumerate(rows, 1):
                t = r["t"] if "t" in r.keys() else None
                if t:
                    results.append(LegResult(
                        t["id"], t["name"], t.get("domain", ""),
                        float(r.get("score", 0.5)), rank=i, leg_type='cypher',
                    ))
        return results

    # ── Safety filter ─────────────────────────────────────────────────────────

    def _safety_filter(self, results: List[LegResult]) -> List[LegResult]:
        blocked_domains = self.cfg["blocked"]
        return [
            r for r in results
            if r.technique_id not in HARD_BLOCKED_IDS
            and not any(b.lower() in r.domain.lower() for b in blocked_domains)
        ]

    # ── RRF fusion ────────────────────────────────────────────────────────────

    def rrf_fusion(self, *ranked_lists: List[LegResult],
                   weights: Optional[List[float]] = None) -> List[FusedResult]:
        """
        Weighted Reciprocal Rank Fusion.
        weightedRRF(d) = Σ_i  w_i / (k + rank_i)
        k = 60 (standard), weights must sum to 1.0.
        """
        k = self.cfg["k"]
        if weights is None:
            weights = [self.cfg["bm25"], self.cfg["vector"], self.cfg["cypher"]]

        # Collect all unique technique IDs across legs
        all_ids: dict[str, dict] = {}
        for leg_idx, leg_results in enumerate(ranked_lists):
            for res in leg_results:
                if res.technique_id not in all_ids:
                    all_ids[res.technique_id] = {
                        "name":   res.technique_name,
                        "domain": res.domain,
                        "ranks":  [None] * len(ranked_lists),
                    }
                all_ids[res.technique_id]["ranks"][leg_idx] = res.rank

        # Compute weighted RRF score; missing rank → last place (top_k + 1)
        max_rank = max(
            (r.rank for leg in ranked_lists for r in leg),
            default=10
        ) + 1

        scored = []
        for tid, info in all_ids.items():
            score = 0.0
            for w, rank in zip(weights, info["ranks"]):
                r = rank if rank is not None else max_rank
                score += w / (k + r)
            ranks = info["ranks"]
            scored.append({
                "technique_id":    tid,
                "technique_name":  info["name"],
                "domain":          info["domain"],
                "rrf_score":       round(score, 9),
                "leg_bm25_rank":   ranks[0] if ranks[0] is not None else max_rank,
                "leg_vector_rank": ranks[1] if ranks[1] is not None else max_rank,
                "leg_cypher_rank": ranks[2] if ranks[2] is not None else max_rank,
            })

        scored.sort(key=lambda x: x["rrf_score"], reverse=True)
        return [
            FusedResult(
                technique_id=s["technique_id"],
                technique_name=s["technique_name"],
                domain=s["domain"],
                rrf_score=s["rrf_score"],
                fused_rank=i + 1,
                leg_bm25_rank=s["leg_bm25_rank"],
                leg_vector_rank=s["leg_vector_rank"],
                leg_cypher_rank=s["leg_cypher_rank"],
            )
            for i, s in enumerate(scored)
        ]

    # ── Public interface ──────────────────────────────────────────────────────

    def retrieve(
        self,
        query_text:      str,
        query_embedding: Optional[List[float]] = None,
        cypher_params:   Optional[dict] = None,
        top_k:           int = 5,
    ) -> List[FusedResult]:
        """
        Run all 3 legs, apply safety filter, fuse via weighted RRF, return top-K.
        """
        bm25_results   = self._bm25_leg(query_text, top_k=10)
        vector_results = self._vector_leg(query_embedding, top_k=10)
        cypher_results = self._cypher_leg(cypher_params, top_k=10)

        # Safety filter on all legs before fusion
        if self.cfg["safety_first"]:
            bm25_results   = self._safety_filter(bm25_results)
            vector_results = self._safety_filter(vector_results)
            cypher_results = self._safety_filter(cypher_results)

        fused = self.rrf_fusion(bm25_results, vector_results, cypher_results)

        # Final safety pass on fused output
        fused = [r for r in fused if r.technique_id not in HARD_BLOCKED_IDS]

        return fused[:top_k]
