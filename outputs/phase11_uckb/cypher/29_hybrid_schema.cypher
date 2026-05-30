// ============================================================
// UCKB Phase 11 — Script 29: Hybrid Retrieval Schema
// Constraints and indices for 6 new node types:
//   FullTextIndex, VectorIndex, FusionConfig, HybridQuery,
//   RetrievalLeg, HybridResult
// Run before: 30_index_registry.cypher
// ============================================================

// ── Uniqueness constraints ────────────────────────────────────

CREATE CONSTRAINT fulltext_index_id_unique IF NOT EXISTS
FOR (n:FullTextIndex) REQUIRE n.indexId IS UNIQUE;

CREATE CONSTRAINT vector_index_id_unique IF NOT EXISTS
FOR (n:VectorIndex) REQUIRE n.indexId IS UNIQUE;

CREATE CONSTRAINT fusion_config_domain_unique IF NOT EXISTS
FOR (n:FusionConfig) REQUIRE n.domain IS UNIQUE;

CREATE CONSTRAINT hybrid_query_id_unique IF NOT EXISTS
FOR (n:HybridQuery) REQUIRE n.queryId IS UNIQUE;

CREATE CONSTRAINT retrieval_leg_id_unique IF NOT EXISTS
FOR (n:RetrievalLeg) REQUIRE n.legId IS UNIQUE;

CREATE CONSTRAINT hybrid_result_id_unique IF NOT EXISTS
FOR (n:HybridResult) REQUIRE n.resultId IS UNIQUE;

// ── Performance indices ───────────────────────────────────────

CREATE INDEX retrieval_leg_type_idx IF NOT EXISTS
FOR (n:RetrievalLeg) ON (n.legType);

CREATE INDEX retrieval_leg_rank_idx IF NOT EXISTS
FOR (n:RetrievalLeg) ON (n.rank);

CREATE INDEX retrieval_leg_query_idx IF NOT EXISTS
FOR (n:RetrievalLeg) ON (n.queryId);

CREATE INDEX hybrid_result_rank_idx IF NOT EXISTS
FOR (n:HybridResult) ON (n.fusedRank);

CREATE INDEX hybrid_result_score_idx IF NOT EXISTS
FOR (n:HybridResult) ON (n.rrfScore);

CREATE INDEX hybrid_result_safety_idx IF NOT EXISTS
FOR (n:HybridResult) ON (n.safetyValidated);

CREATE INDEX hybrid_query_domain_idx IF NOT EXISTS
FOR (n:HybridQuery) ON (n.domain);

CREATE INDEX fusion_config_k_idx IF NOT EXISTS
FOR (n:FusionConfig) ON (n.k);

RETURN 'Phase 11 schema — 6 constraints + 8 indices created' AS status;
