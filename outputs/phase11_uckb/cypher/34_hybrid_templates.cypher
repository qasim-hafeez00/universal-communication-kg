// ============================================================
// UCKB Phase 11 — Script 34: Hybrid Retrieval Templates
// 6 Text2CypherTemplate nodes with category='hybrid'.
// Each template performs all 3 retrieval legs (BM25, vector,
// Cypher) and returns results ORDER BY rrfScore DESC.
//
// These templates are the live query interface for the
// HybridRetriever. Parameters:
//   $query          — natural language query string
//   $queryEmbedding — pre-computed 384-dim float array
//   $domain         — domain key string
//   $topK           — number of results to return
//
// Run after: 33_retrieval_legs.cypher
// ============================================================

// ── 1. Dispatch hybrid template ───────────────────────────────

MERGE (t:Text2CypherTemplate {id: 'hybrid_dispatch_v1'})
SET t += {
  name:        'HYBRID_DISPATCH',
  domain:      'dispatch',
  category:    'hybrid',
  description: 'Dispatch: BM25 keyword + vector semantic + Cypher graph legs fused via weighted RRF (k=60)',
  phase:       '11',
  cypherQuery: '// BM25 leg\nCALL db.index.fulltext.queryNodes("uckb_fulltext", $query) YIELD node AS n1, score AS bm25Score\nWHERE n1:Technique AND n1.domain CONTAINS "Crisis" AND NOT n1.activationBlocked = true\nWITH n1, bm25Score, row_number() OVER (ORDER BY bm25Score DESC) AS bm25Rank\n// Vector leg\nCALL db.index.vector.queryNodes("uckb_vector", $topK, $queryEmbedding) YIELD node AS n2, score AS vecScore\nWHERE n2.domain CONTAINS "Crisis" AND NOT n2.activationBlocked = true\nWITH n1, bm25Rank, n2, vecScore, row_number() OVER (ORDER BY vecScore DESC) AS vecRank\n// Cypher graph leg\nMATCH (e:EmotionalState) WHERE e.name IN $detectedStates\nMATCH (n3:Technique) WHERE n3.domain CONTAINS "Crisis"\n  AND NOT (n3)-[:CONTRAINDICATED_WHEN]->(e) AND NOT n3.activationBlocked = true\nWITH n1, bm25Rank, n2, vecRank, n3, n3.evidenceLevel AS cypherScore,\n     row_number() OVER (ORDER BY cypherScore DESC) AS cypherRank\n// RRF fusion (weights: bm25=0.15, vector=0.25, cypher=0.60, k=60)\nWITH coalesce(n1,n2,n3) AS t,\n     0.15/(60+bm25Rank) + 0.25/(60+vecRank) + 0.60/(60+cypherRank) AS rrfScore\nRETURN t.id AS techniqueId, t.name AS techniqueName, rrfScore\nORDER BY rrfScore DESC LIMIT $topK'
};

// ── 2. Clinical hybrid template ───────────────────────────────

MERGE (t:Text2CypherTemplate {id: 'hybrid_clinical_v1'})
SET t += {
  name:        'HYBRID_CLINICAL',
  domain:      'clinical',
  category:    'hybrid',
  description: 'Clinical: BM25 + vector + SPIKES gate-checked Cypher legs fused via weighted RRF (k=60)',
  phase:       '11',
  cypherQuery: '// BM25 leg\nCALL db.index.fulltext.queryNodes("uckb_fulltext", $query) YIELD node AS n1, score AS bm25Score\nWHERE n1:Technique AND n1.domain CONTAINS "Clinical" AND NOT n1.activationBlocked = true\nWITH n1, bm25Score, row_number() OVER (ORDER BY bm25Score DESC) AS bm25Rank\n// Vector leg\nCALL db.index.vector.queryNodes("uckb_vector", $topK, $queryEmbedding) YIELD node AS n2, score AS vecScore\nWHERE n2.domain CONTAINS "Clinical" AND NOT n2.activationBlocked = true\nWITH n1, bm25Rank, n2, vecScore, row_number() OVER (ORDER BY vecScore DESC) AS vecRank\n// Cypher graph leg (SPIKES gate-aware)\nMATCH (p:ProtocolStep {protocol:"SPIKES"}) WHERE p.stepNumber = $current_step\nMATCH (p)-[:TRIGGERS]->(n3:Technique)\nWHERE NOT EXISTS { MATCH (g:ProtocolGate)-[:GATES]->(p) WHERE g.condition_met = false }\n  AND NOT n3.activationBlocked = true\nWITH n1, bm25Rank, n2, vecRank, n3, n3.evidenceLevel AS cypherScore,\n     row_number() OVER (ORDER BY cypherScore DESC) AS cypherRank\n// RRF fusion (weights: bm25=0.20, vector=0.30, cypher=0.50, k=60)\nWITH coalesce(n1,n2,n3) AS t,\n     0.20/(60+bm25Rank) + 0.30/(60+vecRank) + 0.50/(60+cypherRank) AS rrfScore\nRETURN t.id AS techniqueId, t.name AS techniqueName, rrfScore\nORDER BY rrfScore DESC LIMIT $topK'
};

// ── 3. Negotiation hybrid template ────────────────────────────

MERGE (t:Text2CypherTemplate {id: 'hybrid_negotiation_v1'})
SET t += {
  name:        'HYBRID_NEGOTIATION',
  domain:      'negotiation',
  category:    'hybrid',
  description: 'Negotiation: BM25 + vector (dominant) + SPIN/Harvard Cypher leg fused via weighted RRF (k=60)',
  phase:       '11',
  cypherQuery: '// BM25 leg\nCALL db.index.fulltext.queryNodes("uckb_fulltext", $query) YIELD node AS n1, score AS bm25Score\nWHERE n1:Technique AND n1.domain = "Sales & Negotiation" AND NOT n1.activationBlocked = true\nWITH n1, bm25Score, row_number() OVER (ORDER BY bm25Score DESC) AS bm25Rank\n// Vector leg\nCALL db.index.vector.queryNodes("uckb_vector", $topK, $queryEmbedding) YIELD node AS n2, score AS vecScore\nWHERE n2.domain = "Sales & Negotiation" AND NOT n2.activationBlocked = true\nWITH n1, bm25Rank, n2, vecScore, row_number() OVER (ORDER BY vecScore DESC) AS vecRank\n// Cypher graph leg\nMATCH (n3:Technique) WHERE n3.domain = "Sales & Negotiation"\n  AND NOT (n3)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"crisis_active_domain_state"})\n  AND NOT n3.activationBlocked = true\nWITH n1, bm25Rank, n2, vecRank, n3, n3.evidenceLevel AS cypherScore,\n     row_number() OVER (ORDER BY cypherScore DESC) AS cypherRank\n// RRF fusion (weights: bm25=0.30, vector=0.40, cypher=0.30, k=60)\nWITH coalesce(n1,n2,n3) AS t,\n     0.30/(60+bm25Rank) + 0.40/(60+vecRank) + 0.30/(60+cypherRank) AS rrfScore\nRETURN t.id AS techniqueId, t.name AS techniqueName, rrfScore\nORDER BY rrfScore DESC LIMIT $topK'
};

// ── 4. Legal hybrid template ──────────────────────────────────

MERGE (t:Text2CypherTemplate {id: 'hybrid_legal_v1'})
SET t += {
  name:        'HYBRID_LEGAL',
  domain:      'legal',
  category:    'hybrid',
  description: 'Legal: BM25 (dominant for SA markers) + vector + PEACE-step Cypher leg fused via weighted RRF (k=60). Reid never returned.',
  phase:       '11',
  cypherQuery: '// BM25 leg\nCALL db.index.fulltext.queryNodes("uckb_fulltext", $query) YIELD node AS n1, score AS bm25Score\nWHERE n1:Technique AND n1.domain CONTAINS "Legal" AND NOT n1.activationBlocked = true\nWITH n1, bm25Score, row_number() OVER (ORDER BY bm25Score DESC) AS bm25Rank\n// Vector leg\nCALL db.index.vector.queryNodes("uckb_vector", $topK, $queryEmbedding) YIELD node AS n2, score AS vecScore\nWHERE n2.domain CONTAINS "Legal" AND NOT n2.activationBlocked = true\nWITH n1, bm25Rank, n2, vecScore, row_number() OVER (ORDER BY vecScore DESC) AS vecRank\n// Cypher graph leg (PEACE step-aware, Reid hard-blocked)\nMATCH (s:ProtocolStep {protocol:"PEACE"}) WHERE s.stepNumber = $current_peace_step\nMATCH (s)-[:TRIGGERS]->(n3:Technique)\nWHERE NOT n3.activationBlocked = true\nWITH n1, bm25Rank, n2, vecRank, n3, n3.evidenceLevel AS cypherScore,\n     row_number() OVER (ORDER BY cypherScore DESC) AS cypherRank\n// RRF fusion (weights: bm25=0.40, vector=0.25, cypher=0.35, k=60)\nWITH coalesce(n1,n2,n3) AS t,\n     0.40/(60+bm25Rank) + 0.25/(60+vecRank) + 0.35/(60+cypherRank) AS rrfScore\nRETURN t.id AS techniqueId, t.name AS techniqueName, rrfScore\nORDER BY rrfScore DESC LIMIT $topK'
};

// ── 5. Corporate hybrid template ──────────────────────────────

MERGE (t:Text2CypherTemplate {id: 'hybrid_corporate_v1'})
SET t += {
  name:        'HYBRID_CORPORATE',
  domain:      'corporate',
  category:    'hybrid',
  description: 'Corporate: BM25 + vector + SBI/NVC Cypher leg fused via weighted RRF (k=60). Private-channel guard enforced.',
  phase:       '11',
  cypherQuery: '// BM25 leg\nCALL db.index.fulltext.queryNodes("uckb_fulltext", $query) YIELD node AS n1, score AS bm25Score\nWHERE n1:Technique AND n1.domain = "Corporate & Engineering" AND NOT n1.activationBlocked = true\nWITH n1, bm25Score, row_number() OVER (ORDER BY bm25Score DESC) AS bm25Rank\n// Vector leg\nCALL db.index.vector.queryNodes("uckb_vector", $topK, $queryEmbedding) YIELD node AS n2, score AS vecScore\nWHERE n2.domain = "Corporate & Engineering" AND NOT n2.activationBlocked = true\nWITH n1, bm25Rank, n2, vecScore, row_number() OVER (ORDER BY vecScore DESC) AS vecRank\n// Cypher graph leg (private-channel guard)\nMATCH (n3:Technique) WHERE n3.domain = "Corporate & Engineering"\n  AND NOT (n3)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"corp_emo_public_setting"})\n  AND NOT n3.activationBlocked = true\nWITH n1, bm25Rank, n2, vecRank, n3, n3.evidenceLevel AS cypherScore,\n     row_number() OVER (ORDER BY cypherScore DESC) AS cypherRank\n// RRF fusion (weights: bm25=0.25, vector=0.35, cypher=0.40, k=60)\nWITH coalesce(n1,n2,n3) AS t,\n     0.25/(60+bm25Rank) + 0.35/(60+vecRank) + 0.40/(60+cypherRank) AS rrfScore\nRETURN t.id AS techniqueId, t.name AS techniqueName, rrfScore\nORDER BY rrfScore DESC LIMIT $topK'
};

// ── 6. Education hybrid template ──────────────────────────────

MERGE (t:Text2CypherTemplate {id: 'hybrid_education_v1'})
SET t += {
  name:        'HYBRID_EDUCATION',
  domain:      'education',
  category:    'hybrid',
  description: 'Education: BM25 + vector (dominant for pedagogy) + BKT-state Cypher leg fused via weighted RRF (k=60)',
  phase:       '11',
  cypherQuery: '// BM25 leg\nCALL db.index.fulltext.queryNodes("uckb_fulltext", $query) YIELD node AS n1, score AS bm25Score\nWHERE n1:Technique AND n1.domain = "Education" AND NOT n1.activationBlocked = true\nWITH n1, bm25Score, row_number() OVER (ORDER BY bm25Score DESC) AS bm25Rank\n// Vector leg\nCALL db.index.vector.queryNodes("uckb_vector", $topK, $queryEmbedding) YIELD node AS n2, score AS vecScore\nWHERE n2.domain = "Education" AND NOT n2.activationBlocked = true\nWITH n1, bm25Rank, n2, vecScore, row_number() OVER (ORDER BY vecScore DESC) AS vecRank\n// Cypher graph leg (BKT-state aware)\nMATCH (ks:KnowledgeState) WHERE ks.p_know_range CONTAINS $p_know_bracket\nMATCH (n3:Technique) WHERE n3.domain = "Education"\n  AND n3.bktTrigger CONTAINS $bkt_condition\n  AND NOT (n3)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"edu_emo_low_confidence"})\n  AND NOT n3.activationBlocked = true\nWITH n1, bm25Rank, n2, vecRank, n3, n3.evidenceLevel AS cypherScore,\n     row_number() OVER (ORDER BY cypherScore DESC) AS cypherRank\n// RRF fusion (weights: bm25=0.20, vector=0.40, cypher=0.40, k=60)\nWITH coalesce(n1,n2,n3) AS t,\n     0.20/(60+bm25Rank) + 0.40/(60+vecRank) + 0.40/(60+cypherRank) AS rrfScore\nRETURN t.id AS techniqueId, t.name AS techniqueName, rrfScore\nORDER BY rrfScore DESC LIMIT $topK'
};

// ── Verify ────────────────────────────────────────────────────

MATCH (t:Text2CypherTemplate {category: 'hybrid'})
RETURN count(t) AS hybrid_templates,
       collect(t.name) AS names;

RETURN 'Hybrid templates complete — 6 Text2CypherTemplate nodes with category=hybrid' AS status;
