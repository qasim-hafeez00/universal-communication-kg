// ============================================================
// UCKB Phase 11 — Script 31: Fusion Configuration
// 6 FusionConfig nodes, one per domain.
// RRF formula: weightedRRF(d) = Σ_i  w_i / (k + rank_i)
// All weight triples sum to 1.0; k = 60 (standard RRF constant).
// Run after: 30_index_registry.cypher
// ============================================================

// ── 1. Dispatch — safety graph must dominate ──────────────────

MERGE (fc:FusionConfig {domain: 'dispatch'})
SET fc += {
  k:              60,
  bm25Weight:     0.15,
  vectorWeight:   0.25,
  cypherWeight:   0.60,
  bm25TopK:       10,
  vectorTopK:     10,
  cypherTopK:     10,
  finalTopK:      5,
  safetyFirstOrder: true,
  rationale:      'Safety graph structure dominates; BM25 supplies keyword signals; vector catches synonyms for panic/threat vocabulary',
  updatedPhase:   '11'
};

// ── 2. Clinical — protocol gates critical ────────────────────

MERGE (fc:FusionConfig {domain: 'clinical'})
SET fc += {
  k:              60,
  bm25Weight:     0.20,
  vectorWeight:   0.30,
  cypherWeight:   0.50,
  bm25TopK:       10,
  vectorTopK:     10,
  cypherTopK:     10,
  finalTopK:      5,
  safetyFirstOrder: true,
  rationale:      'SPIKES protocol gates critical; vector enriches empathy/communication nuance; BM25 handles medical terminology',
  updatedPhase:   '11'
};

// ── 3. Negotiation — semantic intent most important ───────────

MERGE (fc:FusionConfig {domain: 'negotiation'})
SET fc += {
  k:              60,
  bm25Weight:     0.30,
  vectorWeight:   0.40,
  cypherWeight:   0.30,
  bm25TopK:       10,
  vectorTopK:     10,
  cypherTopK:     10,
  finalTopK:      5,
  safetyFirstOrder: false,
  rationale:      'Semantic intent matching dominant; BM25 handles objection/stalling keywords; graph validates SPIN/Harvard position',
  updatedPhase:   '11'
};

// ── 4. Legal — lexical precision for SA markers ───────────────

MERGE (fc:FusionConfig {domain: 'legal'})
SET fc += {
  k:              60,
  bm25Weight:     0.40,
  vectorWeight:   0.25,
  cypherWeight:   0.35,
  bm25TopK:       10,
  vectorTopK:     10,
  cypherTopK:     10,
  finalTopK:      5,
  safetyFirstOrder: true,
  rationale:      'Lexical precision critical for SA markers and PEACE steps; graph enforces activationBlocked=true on Reid Technique',
  updatedPhase:   '11'
};

// ── 5. Corporate — balanced, interpersonal nuance ────────────

MERGE (fc:FusionConfig {domain: 'corporate'})
SET fc += {
  k:              60,
  bm25Weight:     0.25,
  vectorWeight:   0.35,
  cypherWeight:   0.40,
  bm25TopK:       10,
  vectorTopK:     10,
  cypherTopK:     10,
  finalTopK:      5,
  safetyFirstOrder: false,
  rationale:      'Balanced; vector captures interpersonal and emotional nuance; graph enforces private-channel constraint',
  updatedPhase:   '11'
};

// ── 6. Education — semantic pedagogical intent ───────────────

MERGE (fc:FusionConfig {domain: 'education'})
SET fc += {
  k:              60,
  bm25Weight:     0.20,
  vectorWeight:   0.40,
  cypherWeight:   0.40,
  bm25TopK:       10,
  vectorTopK:     10,
  cypherTopK:     10,
  finalTopK:      5,
  safetyFirstOrder: false,
  rationale:      'Semantic pedagogical intent high; BKT state queries via Cypher; vector finds analogous learning scaffolds',
  updatedPhase:   '11'
};

// ── Weight-sum verification ───────────────────────────────────

MATCH (fc:FusionConfig)
RETURN fc.domain AS domain,
       round(fc.bm25Weight + fc.vectorWeight + fc.cypherWeight, 6) AS weight_sum
ORDER BY domain;

RETURN 'Fusion config complete — 6 FusionConfig nodes, RRF k=60, all weight sums = 1.0' AS status;
