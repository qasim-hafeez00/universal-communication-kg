// ============================================================
// UCKB Phase 11 — Script 32: Hybrid Query Templates
// 6 HybridQuery nodes, one per domain.
// Each section is a fully self-contained Cypher statement with
// its own MATCH clauses — no cross-statement variable sharing.
// Run after: 31_fusion_config.cypher
// ============================================================

// ── 1. Dispatch ───────────────────────────────────────────────

MATCH (fti:FullTextIndex  {indexId: 'uckb_fulltext_v1'})
MATCH (vi:VectorIndex     {indexId: 'uckb_vector_v1'})
MATCH (fc:FusionConfig         {domain: 'dispatch'})
MATCH (sfr:SchemaFilterRegistry {domain: 'dispatch'})
MERGE (hq:HybridQuery {queryId: 'hq_dispatch_v1'})
SET hq += {
  domain:           'dispatch',
  description:      'Hybrid retrieval for crisis dispatch: panic / hostile / dissociation states',
  bm25Fields:       ['name', 'steps', 'whenToUse', 'failureSignals'],
  vectorProperty:   'embedding',
  cypherTemplate:   'MATCH (e:EmotionalState) WHERE toLower(e.name) = toLower($detectedState) MATCH (t:Technique) WHERE t.domain CONTAINS "Crisis" AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e) AND NOT t.activationBlocked = true RETURN t, t.evidenceLevel AS score ORDER BY score DESC LIMIT $topK',
  defaultTopK:      5,
  version:          '1.0',
  createdPhase:     '11'
}
MERGE (hq)-[:USES_FUSION]   ->(fc)
MERGE (hq)-[:QUERIES_INDEX] ->(fti)
MERGE (hq)-[:QUERIES_INDEX] ->(vi)
MERGE (hq)-[:FILTERS_BY]    ->(sfr);

// ── 2. Clinical ───────────────────────────────────────────────

MATCH (fti:FullTextIndex  {indexId: 'uckb_fulltext_v1'})
MATCH (vi:VectorIndex     {indexId: 'uckb_vector_v1'})
MATCH (fc:FusionConfig         {domain: 'clinical'})
MATCH (sfr:SchemaFilterRegistry {domain: 'clinical'})
MERGE (hq:HybridQuery {queryId: 'hq_clinical_v1'})
SET hq += {
  domain:           'clinical',
  description:      'Hybrid retrieval for clinical: SPIKES gate-aware, empathy-weighted',
  bm25Fields:       ['name', 'steps', 'whenToUse', 'culturalNotes'],
  vectorProperty:   'embedding',
  cypherTemplate:   'MATCH (p:ProtocolStep {protocol:"SPIKES"}) WHERE p.stepNumber = $current_step MATCH (p)-[:TRIGGERS]->(t:Technique) WHERE NOT EXISTS { MATCH (g:ProtocolGate)-[:GATES]->(p) WHERE g.condition_met = false } AND NOT t.activationBlocked = true RETURN t, t.evidenceLevel AS score ORDER BY score DESC LIMIT $topK',
  defaultTopK:      5,
  version:          '1.0',
  createdPhase:     '11'
}
MERGE (hq)-[:USES_FUSION]   ->(fc)
MERGE (hq)-[:QUERIES_INDEX] ->(fti)
MERGE (hq)-[:QUERIES_INDEX] ->(vi)
MERGE (hq)-[:FILTERS_BY]    ->(sfr);

// ── 3. Negotiation ────────────────────────────────────────────

MATCH (fti:FullTextIndex  {indexId: 'uckb_fulltext_v1'})
MATCH (vi:VectorIndex     {indexId: 'uckb_vector_v1'})
MATCH (fc:FusionConfig         {domain: 'negotiation'})
MATCH (sfr:SchemaFilterRegistry {domain: 'negotiation'})
MERGE (hq:HybridQuery {queryId: 'hq_negotiation_v1'})
SET hq += {
  domain:           'negotiation',
  description:      'Hybrid retrieval for sales/negotiation: intent-aware, SPIN/Challenger/Harvard',
  bm25Fields:       ['name', 'steps', 'whenToUse', 'failureSignals'],
  vectorProperty:   'embedding',
  cypherTemplate:   'MATCH (t:Technique) WHERE t.domain = "Sales & Negotiation" AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"crisis_active_domain_state"}) AND NOT t.activationBlocked = true RETURN t, t.evidenceLevel AS score ORDER BY score DESC LIMIT $topK',
  defaultTopK:      5,
  version:          '1.0',
  createdPhase:     '11'
}
MERGE (hq)-[:USES_FUSION]   ->(fc)
MERGE (hq)-[:QUERIES_INDEX] ->(fti)
MERGE (hq)-[:QUERIES_INDEX] ->(vi)
MERGE (hq)-[:FILTERS_BY]    ->(sfr);

// ── 4. Legal ──────────────────────────────────────────────────

MATCH (fti:FullTextIndex  {indexId: 'uckb_fulltext_v1'})
MATCH (vi:VectorIndex     {indexId: 'uckb_vector_v1'})
MATCH (fc:FusionConfig         {domain: 'legal'})
MATCH (sfr:SchemaFilterRegistry {domain: 'legal'})
MERGE (hq:HybridQuery {queryId: 'hq_legal_v1'})
SET hq += {
  domain:           'legal',
  description:      'Hybrid retrieval for legal/investigative: PEACE-aware, Reid hard-blocked',
  bm25Fields:       ['name', 'steps', 'whenToUse', 'failureSignals'],
  vectorProperty:   'embedding',
  cypherTemplate:   'MATCH (s:ProtocolStep {protocol:"PEACE"}) WHERE s.stepNumber = $current_peace_step MATCH (s)-[:TRIGGERS]->(t:Technique) WHERE NOT t.activationBlocked = true RETURN t, t.evidenceLevel AS score ORDER BY s.stepNumber ASC LIMIT $topK',
  defaultTopK:      5,
  version:          '1.0',
  createdPhase:     '11'
}
MERGE (hq)-[:USES_FUSION]   ->(fc)
MERGE (hq)-[:QUERIES_INDEX] ->(fti)
MERGE (hq)-[:QUERIES_INDEX] ->(vi)
MERGE (hq)-[:FILTERS_BY]    ->(sfr);

// ── 5. Corporate ──────────────────────────────────────────────

MATCH (fti:FullTextIndex  {indexId: 'uckb_fulltext_v1'})
MATCH (vi:VectorIndex     {indexId: 'uckb_vector_v1'})
MATCH (fc:FusionConfig         {domain: 'corporate'})
MATCH (sfr:SchemaFilterRegistry {domain: 'corporate'})
MERGE (hq:HybridQuery {queryId: 'hq_corporate_v1'})
SET hq += {
  domain:           'corporate',
  description:      'Hybrid retrieval for corporate: SBI/NVC/Radical Candor, private-channel guard',
  bm25Fields:       ['name', 'steps', 'whenToUse', 'culturalNotes'],
  vectorProperty:   'embedding',
  cypherTemplate:   'MATCH (t:Technique) WHERE t.domain = "Corporate & Engineering" AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"corp_emo_public_setting"}) AND NOT t.activationBlocked = true RETURN t, t.tier AS tier_score, t.evidenceLevel AS score ORDER BY tier_score ASC, score DESC LIMIT $topK',
  defaultTopK:      5,
  version:          '1.0',
  createdPhase:     '11'
}
MERGE (hq)-[:USES_FUSION]   ->(fc)
MERGE (hq)-[:QUERIES_INDEX] ->(fti)
MERGE (hq)-[:QUERIES_INDEX] ->(vi)
MERGE (hq)-[:FILTERS_BY]    ->(sfr);

// ── 6. Education ──────────────────────────────────────────────

MATCH (fti:FullTextIndex  {indexId: 'uckb_fulltext_v1'})
MATCH (vi:VectorIndex     {indexId: 'uckb_vector_v1'})
MATCH (fc:FusionConfig         {domain: 'education'})
MATCH (sfr:SchemaFilterRegistry {domain: 'education'})
MERGE (hq:HybridQuery {queryId: 'hq_education_v1'})
SET hq += {
  domain:           'education',
  description:      'Hybrid retrieval for education: BKT-aware, scaffolding tier-aware',
  bm25Fields:       ['name', 'steps', 'whenToUse', 'failureSignals'],
  vectorProperty:   'embedding',
  cypherTemplate:   'MATCH (ks:KnowledgeState) WHERE ks.p_know_range CONTAINS $p_know_bracket MATCH (t:Technique) WHERE t.domain = "Education" AND t.bktTrigger CONTAINS $bkt_condition AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"edu_emo_low_confidence"}) AND NOT t.activationBlocked = true RETURN t, t.evidenceLevel AS score ORDER BY t.tier ASC, score DESC LIMIT $topK',
  defaultTopK:      5,
  version:          '1.0',
  createdPhase:     '11'
}
MERGE (hq)-[:USES_FUSION]   ->(fc)
MERGE (hq)-[:QUERIES_INDEX] ->(fti)
MERGE (hq)-[:QUERIES_INDEX] ->(vi)
MERGE (hq)-[:FILTERS_BY]    ->(sfr);

RETURN 'Hybrid queries complete — 6 HybridQuery nodes with USES_FUSION + QUERIES_INDEX + FILTERS_BY edges' AS status;
