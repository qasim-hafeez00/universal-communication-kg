// ============================================================
// UCKB Phase 11 — Script 33: Retrieval Legs + Hybrid Results
// 18 RetrievalLeg nodes (3 legs × 6 domains) and 6 HybridResult
// nodes with pre-computed weighted-RRF scores.
//
// Each domain section is ONE self-contained Cypher statement
// (single semicolon) so all variables stay in scope.
//
// Weighted RRF:  rrfScore = Σ_i  w_i / (k + rank_i)  k = 60
//   dispatch:    0.15/61 + 0.25/62 + 0.60/61 = 0.016327
//   clinical:    0.20/62 + 0.30/61 + 0.50/61 = 0.016341
//   negotiation: 0.30/61 + 0.40/61 + 0.30/62 = 0.016314
//   legal:       0.40/61 + 0.25/62 + 0.35/61 = 0.016327
//   corporate:   0.25/62 + 0.35/61 + 0.40/61 = 0.016327
//   education:   0.20/63 + 0.40/61 + 0.40/61 = 0.016289
//
// Run after: 32_hybrid_queries.cypher
// ============================================================


// ════════════════════════════════════════════════════════════
// DISPATCH  — "caller panicking, weapon mentioned"
// t_bcsm_minimal_enc | BM25 r=1, vector r=2, cypher r=1
// rrfScore = 0.016327
// ════════════════════════════════════════════════════════════

MATCH (hq:HybridQuery {queryId: 'hq_dispatch_v1'})
MATCH (sfr:SchemaFilterRegistry {domain: 'dispatch'})
MERGE (rl1:RetrievalLeg {legId: 'leg_dispatch_bm25_01'})
SET rl1 += {
  queryId: 'hq_dispatch_v1', legType: 'bm25', rank: 1, rawScore: 4.812,
  techniqueId: 't_bcsm_minimal_enc', techniqueName: 'Minimal Encouragers (BCSM Step 2)',
  queryText: 'caller panicking weapon mentioned', domain: 'dispatch', createdPhase: '11'
}
MERGE (rl2:RetrievalLeg {legId: 'leg_dispatch_vector_01'})
SET rl2 += {
  queryId: 'hq_dispatch_v1', legType: 'vector', rank: 2, rawScore: 0.847,
  techniqueId: 't_bcsm_minimal_enc', techniqueName: 'Minimal Encouragers (BCSM Step 2)',
  queryText: 'caller panicking weapon mentioned', domain: 'dispatch', createdPhase: '11'
}
MERGE (rl3:RetrievalLeg {legId: 'leg_dispatch_cypher_01'})
SET rl3 += {
  queryId: 'hq_dispatch_v1', legType: 'cypher', rank: 1, rawScore: 0.94,
  techniqueId: 't_bcsm_minimal_enc', techniqueName: 'Minimal Encouragers (BCSM Step 2)',
  queryText: 'detectedState=Panic domain=dispatch', domain: 'dispatch', createdPhase: '11'
}
MERGE (hr1:HybridResult {resultId: 'hresult_dispatch_01'})
SET hr1 += {
  queryId: 'hq_dispatch_v1', domain: 'dispatch',
  techniqueId: 't_bcsm_minimal_enc', techniqueName: 'Minimal Encouragers (BCSM Step 2)',
  fusedRank: 1, rrfScore: 0.016327,
  legBM25Rank: 1, legVectorRank: 2, legCypherRank: 1,
  safetyValidated: true, activationBlocked: false,
  queryText: 'caller panicking weapon mentioned', createdPhase: '11'
}
MERGE (hq)-[:HAS_LEG]->(rl1)
MERGE (hq)-[:HAS_LEG]->(rl2)
MERGE (hq)-[:HAS_LEG]->(rl3)
MERGE (hr1)-[:PRODUCED_BY]->(rl1)
MERGE (hr1)-[:PRODUCED_BY]->(rl2)
MERGE (hr1)-[:PRODUCED_BY]->(rl3)
MERGE (rl1)-[:FUSED_INTO]->(hr1)
MERGE (rl2)-[:FUSED_INTO]->(hr1)
MERGE (rl3)-[:FUSED_INTO]->(hr1)
MERGE (hr1)-[:SAFE_FOR]->(sfr);


// ════════════════════════════════════════════════════════════
// CLINICAL  — "patient resistant to bad news, oncologist"
// t_spikes_empathy_response | BM25 r=2, vector r=1, cypher r=1
// rrfScore = 0.016341
// ════════════════════════════════════════════════════════════

MATCH (hq:HybridQuery {queryId: 'hq_clinical_v1'})
MATCH (sfr:SchemaFilterRegistry {domain: 'clinical'})
MERGE (rl4:RetrievalLeg {legId: 'leg_clinical_bm25_01'})
SET rl4 += {
  queryId: 'hq_clinical_v1', legType: 'bm25', rank: 2, rawScore: 3.291,
  techniqueId: 't_spikes_empathy_response', techniqueName: 'SPIKES Empathy Response (Step E)',
  queryText: 'patient resistant bad news oncologist', domain: 'clinical', createdPhase: '11'
}
MERGE (rl5:RetrievalLeg {legId: 'leg_clinical_vector_01'})
SET rl5 += {
  queryId: 'hq_clinical_v1', legType: 'vector', rank: 1, rawScore: 0.891,
  techniqueId: 't_spikes_empathy_response', techniqueName: 'SPIKES Empathy Response (Step E)',
  queryText: 'patient resistant bad news oncologist', domain: 'clinical', createdPhase: '11'
}
MERGE (rl6:RetrievalLeg {legId: 'leg_clinical_cypher_01'})
SET rl6 += {
  queryId: 'hq_clinical_v1', legType: 'cypher', rank: 1, rawScore: 0.91,
  techniqueId: 't_spikes_empathy_response', techniqueName: 'SPIKES Empathy Response (Step E)',
  queryText: 'current_step=4 protocol=SPIKES', domain: 'clinical', createdPhase: '11'
}
MERGE (hr2:HybridResult {resultId: 'hresult_clinical_01'})
SET hr2 += {
  queryId: 'hq_clinical_v1', domain: 'clinical',
  techniqueId: 't_spikes_empathy_response', techniqueName: 'SPIKES Empathy Response (Step E)',
  fusedRank: 1, rrfScore: 0.016341,
  legBM25Rank: 2, legVectorRank: 1, legCypherRank: 1,
  safetyValidated: true, activationBlocked: false,
  queryText: 'patient resistant to bad news, oncologist', createdPhase: '11'
}
MERGE (hq)-[:HAS_LEG]->(rl4)
MERGE (hq)-[:HAS_LEG]->(rl5)
MERGE (hq)-[:HAS_LEG]->(rl6)
MERGE (hr2)-[:PRODUCED_BY]->(rl4)
MERGE (hr2)-[:PRODUCED_BY]->(rl5)
MERGE (hr2)-[:PRODUCED_BY]->(rl6)
MERGE (rl4)-[:FUSED_INTO]->(hr2)
MERGE (rl5)-[:FUSED_INTO]->(hr2)
MERGE (rl6)-[:FUSED_INTO]->(hr2)
MERGE (hr2)-[:SAFE_FOR]->(sfr);


// ════════════════════════════════════════════════════════════
// NEGOTIATION — "prospect stalling on price objection"
// t_spin_implication_q | BM25 r=1, vector r=1, cypher r=2
// rrfScore = 0.016314
// ════════════════════════════════════════════════════════════

MATCH (hq:HybridQuery {queryId: 'hq_negotiation_v1'})
MATCH (sfr:SchemaFilterRegistry {domain: 'negotiation'})
MERGE (rl7:RetrievalLeg {legId: 'leg_negotiation_bm25_01'})
SET rl7 += {
  queryId: 'hq_negotiation_v1', legType: 'bm25', rank: 1, rawScore: 5.437,
  techniqueId: 't_spin_implication_q', techniqueName: 'SPIN Implication Question',
  queryText: 'prospect stalling price objection', domain: 'negotiation', createdPhase: '11'
}
MERGE (rl8:RetrievalLeg {legId: 'leg_negotiation_vector_01'})
SET rl8 += {
  queryId: 'hq_negotiation_v1', legType: 'vector', rank: 1, rawScore: 0.874,
  techniqueId: 't_spin_implication_q', techniqueName: 'SPIN Implication Question',
  queryText: 'prospect stalling price objection', domain: 'negotiation', createdPhase: '11'
}
MERGE (rl9:RetrievalLeg {legId: 'leg_negotiation_cypher_01'})
SET rl9 += {
  queryId: 'hq_negotiation_v1', legType: 'cypher', rank: 2, rawScore: 0.88,
  techniqueId: 't_spin_implication_q', techniqueName: 'SPIN Implication Question',
  queryText: 'domain=negotiation evidenceLevel DESC', domain: 'negotiation', createdPhase: '11'
}
MERGE (hr3:HybridResult {resultId: 'hresult_negotiation_01'})
SET hr3 += {
  queryId: 'hq_negotiation_v1', domain: 'negotiation',
  techniqueId: 't_spin_implication_q', techniqueName: 'SPIN Implication Question',
  fusedRank: 1, rrfScore: 0.016314,
  legBM25Rank: 1, legVectorRank: 1, legCypherRank: 2,
  safetyValidated: true, activationBlocked: false,
  queryText: 'prospect stalling on price objection', createdPhase: '11'
}
MERGE (hq)-[:HAS_LEG]->(rl7)
MERGE (hq)-[:HAS_LEG]->(rl8)
MERGE (hq)-[:HAS_LEG]->(rl9)
MERGE (hr3)-[:PRODUCED_BY]->(rl7)
MERGE (hr3)-[:PRODUCED_BY]->(rl8)
MERGE (hr3)-[:PRODUCED_BY]->(rl9)
MERGE (rl7)-[:FUSED_INTO]->(hr3)
MERGE (rl8)-[:FUSED_INTO]->(hr3)
MERGE (rl9)-[:FUSED_INTO]->(hr3)
MERGE (hr3)-[:SAFE_FOR]->(sfr);


// ════════════════════════════════════════════════════════════
// LEGAL — "subject using pronoun changes and verb tense shifts"
// t_peace_probing | BM25 r=1, vector r=2, cypher r=1
// rrfScore = 0.016327
// ════════════════════════════════════════════════════════════

MATCH (hq:HybridQuery {queryId: 'hq_legal_v1'})
MATCH (sfr:SchemaFilterRegistry {domain: 'legal'})
MERGE (rl10:RetrievalLeg {legId: 'leg_legal_bm25_01'})
SET rl10 += {
  queryId: 'hq_legal_v1', legType: 'bm25', rank: 1, rawScore: 6.104,
  techniqueId: 't_peace_probing', techniqueName: 'PEACE Probing Questions (Step A — Account)',
  queryText: 'subject pronoun changes verb tense shifts', domain: 'legal', createdPhase: '11'
}
MERGE (rl11:RetrievalLeg {legId: 'leg_legal_vector_01'})
SET rl11 += {
  queryId: 'hq_legal_v1', legType: 'vector', rank: 2, rawScore: 0.813,
  techniqueId: 't_peace_probing', techniqueName: 'PEACE Probing Questions (Step A — Account)',
  queryText: 'subject pronoun changes verb tense shifts', domain: 'legal', createdPhase: '11'
}
MERGE (rl12:RetrievalLeg {legId: 'leg_legal_cypher_01'})
SET rl12 += {
  queryId: 'hq_legal_v1', legType: 'cypher', rank: 1, rawScore: 0.92,
  techniqueId: 't_peace_probing', techniqueName: 'PEACE Probing Questions (Step A — Account)',
  queryText: 'current_peace_step=3 activationBlocked=false', domain: 'legal', createdPhase: '11'
}
MERGE (hr4:HybridResult {resultId: 'hresult_legal_01'})
SET hr4 += {
  queryId: 'hq_legal_v1', domain: 'legal',
  techniqueId: 't_peace_probing', techniqueName: 'PEACE Probing Questions (Step A — Account)',
  fusedRank: 1, rrfScore: 0.016327,
  legBM25Rank: 1, legVectorRank: 2, legCypherRank: 1,
  safetyValidated: true, activationBlocked: false,
  queryText: 'subject using pronoun changes and verb tense shifts', createdPhase: '11'
}
MERGE (hq)-[:HAS_LEG]->(rl10)
MERGE (hq)-[:HAS_LEG]->(rl11)
MERGE (hq)-[:HAS_LEG]->(rl12)
MERGE (hr4)-[:PRODUCED_BY]->(rl10)
MERGE (hr4)-[:PRODUCED_BY]->(rl11)
MERGE (hr4)-[:PRODUCED_BY]->(rl12)
MERGE (rl10)-[:FUSED_INTO]->(hr4)
MERGE (rl11)-[:FUSED_INTO]->(hr4)
MERGE (rl12)-[:FUSED_INTO]->(hr4)
MERGE (hr4)-[:SAFE_FOR]->(sfr);


// ════════════════════════════════════════════════════════════
// CORPORATE — "team member displaying defensiveness in code review"
// t_sbi_feedback | BM25 r=2, vector r=1, cypher r=1
// rrfScore = 0.016327
// ════════════════════════════════════════════════════════════

MATCH (hq:HybridQuery {queryId: 'hq_corporate_v1'})
MATCH (sfr:SchemaFilterRegistry {domain: 'corporate'})
MERGE (rl13:RetrievalLeg {legId: 'leg_corporate_bm25_01'})
SET rl13 += {
  queryId: 'hq_corporate_v1', legType: 'bm25', rank: 2, rawScore: 3.628,
  techniqueId: 't_sbi_feedback', techniqueName: 'SBI Feedback (Situation-Behavior-Impact)',
  queryText: 'team member defensiveness code review', domain: 'corporate', createdPhase: '11'
}
MERGE (rl14:RetrievalLeg {legId: 'leg_corporate_vector_01'})
SET rl14 += {
  queryId: 'hq_corporate_v1', legType: 'vector', rank: 1, rawScore: 0.862,
  techniqueId: 't_sbi_feedback', techniqueName: 'SBI Feedback (Situation-Behavior-Impact)',
  queryText: 'team member defensiveness code review', domain: 'corporate', createdPhase: '11'
}
MERGE (rl15:RetrievalLeg {legId: 'leg_corporate_cypher_01'})
SET rl15 += {
  queryId: 'hq_corporate_v1', legType: 'cypher', rank: 1, rawScore: 0.89,
  techniqueId: 't_sbi_feedback', techniqueName: 'SBI Feedback (Situation-Behavior-Impact)',
  queryText: 'domain=corporate NOT public_setting activationBlocked=false', domain: 'corporate', createdPhase: '11'
}
MERGE (hr5:HybridResult {resultId: 'hresult_corporate_01'})
SET hr5 += {
  queryId: 'hq_corporate_v1', domain: 'corporate',
  techniqueId: 't_sbi_feedback', techniqueName: 'SBI Feedback (Situation-Behavior-Impact)',
  fusedRank: 1, rrfScore: 0.016327,
  legBM25Rank: 2, legVectorRank: 1, legCypherRank: 1,
  safetyValidated: true, activationBlocked: false,
  queryText: 'team member displaying defensiveness in code review', createdPhase: '11'
}
MERGE (hq)-[:HAS_LEG]->(rl13)
MERGE (hq)-[:HAS_LEG]->(rl14)
MERGE (hq)-[:HAS_LEG]->(rl15)
MERGE (hr5)-[:PRODUCED_BY]->(rl13)
MERGE (hr5)-[:PRODUCED_BY]->(rl14)
MERGE (hr5)-[:PRODUCED_BY]->(rl15)
MERGE (rl13)-[:FUSED_INTO]->(hr5)
MERGE (rl14)-[:FUSED_INTO]->(hr5)
MERGE (rl15)-[:FUSED_INTO]->(hr5)
MERGE (hr5)-[:SAFE_FOR]->(sfr);


// ════════════════════════════════════════════════════════════
// EDUCATION — "student making systematic errors on fractions, low confidence"
// t_scaffold_tier1 | BM25 r=3, vector r=1, cypher r=1
// rrfScore = 0.016289
// ════════════════════════════════════════════════════════════

MATCH (hq:HybridQuery {queryId: 'hq_education_v1'})
MATCH (sfr:SchemaFilterRegistry {domain: 'education'})
MERGE (rl16:RetrievalLeg {legId: 'leg_education_bm25_01'})
SET rl16 += {
  queryId: 'hq_education_v1', legType: 'bm25', rank: 3, rawScore: 2.814,
  techniqueId: 't_scaffold_tier1', techniqueName: 'Scaffolded Hint Tier 1 (Minimal Support)',
  queryText: 'student systematic errors fractions low confidence', domain: 'education', createdPhase: '11'
}
MERGE (rl17:RetrievalLeg {legId: 'leg_education_vector_01'})
SET rl17 += {
  queryId: 'hq_education_v1', legType: 'vector', rank: 1, rawScore: 0.878,
  techniqueId: 't_scaffold_tier1', techniqueName: 'Scaffolded Hint Tier 1 (Minimal Support)',
  queryText: 'student systematic errors fractions low confidence', domain: 'education', createdPhase: '11'
}
MERGE (rl18:RetrievalLeg {legId: 'leg_education_cypher_01'})
SET rl18 += {
  queryId: 'hq_education_v1', legType: 'cypher', rank: 1, rawScore: 0.86,
  techniqueId: 't_scaffold_tier1', techniqueName: 'Scaffolded Hint Tier 1 (Minimal Support)',
  queryText: 'p_know_bracket=low bkt_condition=mastery_lt_0.4', domain: 'education', createdPhase: '11'
}
MERGE (hr6:HybridResult {resultId: 'hresult_education_01'})
SET hr6 += {
  queryId: 'hq_education_v1', domain: 'education',
  techniqueId: 't_scaffold_tier1', techniqueName: 'Scaffolded Hint Tier 1 (Minimal Support)',
  fusedRank: 1, rrfScore: 0.016289,
  legBM25Rank: 3, legVectorRank: 1, legCypherRank: 1,
  safetyValidated: true, activationBlocked: false,
  queryText: 'student making systematic errors on fractions, low confidence', createdPhase: '11'
}
MERGE (hq)-[:HAS_LEG]->(rl16)
MERGE (hq)-[:HAS_LEG]->(rl17)
MERGE (hq)-[:HAS_LEG]->(rl18)
MERGE (hr6)-[:PRODUCED_BY]->(rl16)
MERGE (hr6)-[:PRODUCED_BY]->(rl17)
MERGE (hr6)-[:PRODUCED_BY]->(rl18)
MERGE (rl16)-[:FUSED_INTO]->(hr6)
MERGE (rl17)-[:FUSED_INTO]->(hr6)
MERGE (rl18)-[:FUSED_INTO]->(hr6)
MERGE (hr6)-[:SAFE_FOR]->(sfr);


// ── Summary ────────────────────────────────────────────────────

MATCH (rl:RetrievalLeg) WITH count(rl) AS legs
MATCH (hr:HybridResult) WITH legs, count(hr) AS results
RETURN legs AS retrieval_legs, results AS hybrid_results,
       'Retrieval legs and hybrid results complete' AS status;
