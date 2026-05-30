// ============================================================
// UCKB Phase 8 — Script 13: Domain Schema Filter Registry
// Seeds domain-specific schema filter nodes used by Text2Cypher
// Run after: 12_cross_domain_guards.cypher
// ============================================================

// ── SchemaFilterRegistry nodes ───────────────────────────────

MERGE (r:SchemaFilterRegistry {domain: 'dispatch'})
SET r += {
  name: 'Dispatch Schema Filter',
  primaryDomains: 'Crisis Dispatch / Emergency;psychological_states;de_escalation',
  alwaysInclude: 'EmotionalState;SignalMarker',
  blockedDomains: 'Sales & Negotiation;Corporate & Engineering;Education',
  protocolDags: 'BCSM',
  signalMarkersScope: 'panic_state;hostile_state;dissociation_risk;grief_marker;suicidality_marker;psychosis_indicator;call_drop_risk',
  text2cypherTemplate: 'MATCH (e:EmotionalState)-[:TRIGGERS]->(t:Technique) WHERE e.domain CONTAINS "dispatch" AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e) AND t.domain CONTAINS "dispatch" AND t.cognitiveLoadProfile IN ["lowest-load","lowest safe load","low-load"] RETURN t ORDER BY t.evidenceLevel DESC LIMIT 5',
  updatedPhase: '8'
};

MERGE (r:SchemaFilterRegistry {domain: 'clinical'})
SET r += {
  name: 'Clinical Schema Filter',
  primaryDomains: 'Clinical / Medical;psychological_states',
  alwaysInclude: 'EmotionalState;SignalMarker;consent_architecture',
  blockedDomains: 'Sales & Negotiation;Corporate & Engineering',
  protocolDags: 'SPIKES;MI',
  signalMarkersScope: 'grief_marker;teach_back_failure;repair_request;nodding_no_restate',
  text2cypherTemplate: 'MATCH (p:ProtocolStep {protocol:"SPIKES", stepNumber:$current_step}) WHERE NOT EXISTS { MATCH (g:ProtocolGate)-[:GATES]->(p) WHERE g.condition_met = false } MATCH (p)-[:TRIGGERS|REQUIRES]->(t:Technique) RETURN t, p.gateCondition AS gate_status',
  updatedPhase: '8'
};

MERGE (r:SchemaFilterRegistry {domain: 'negotiation'})
SET r += {
  name: 'Negotiation Schema Filter',
  primaryDomains: 'Sales & Negotiation;psychological_states',
  alwaysInclude: 'EmotionalState;SignalMarker',
  blockedDomains: 'Crisis Dispatch / Emergency',
  protocolDags: 'SPIN;ChallengerSale;HarvardNegotiation',
  signalMarkersScope: 'buying_signal;objection;stalling',
  text2cypherTemplate: 'MATCH (t:Technique) WHERE t.domain = "Sales & Negotiation" AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"crisis_active_domain_state"}) RETURN t ORDER BY t.evidenceLevel DESC LIMIT 5',
  updatedPhase: '8'
};

MERGE (r:SchemaFilterRegistry {domain: 'legal'})
SET r += {
  name: 'Legal Schema Filter',
  primaryDomains: 'Legal & Investigative',
  alwaysInclude: 'StatementMarker;EmotionalState;psychological_states',
  blockedDomains: 'Sales & Negotiation;Corporate & Engineering',
  protocolDags: 'PEACE;CognitiveInterview',
  signalMarkersScope: 'sa_001_verb_tense_shift;sa_002_pronoun_change;sa_003_missing_sequence;sa_004_temporal_equivocation;sa_005_lack_of_conviction;sa_006_spontaneous_negation;sa_007_non_answer_answer;sa_008_involuntary_detail',
  text2cypherTemplate: 'MATCH (s:ProtocolStep {protocol:"PEACE"}) WHERE s.stepNumber = $current_peace_step MATCH (s)-[:TRIGGERS]->(t:Technique) WHERE NOT t.activationBlocked = true RETURN t ORDER BY s.stepNumber ASC',
  updatedPhase: '8'
};

MERGE (r:SchemaFilterRegistry {domain: 'corporate'})
SET r += {
  name: 'Corporate Schema Filter',
  primaryDomains: 'Corporate & Engineering;psychological_states',
  alwaysInclude: 'EmotionalState;SignalMarker;CommunicationStyle',
  blockedDomains: 'Crisis Dispatch / Emergency;Legal & Investigative',
  protocolDags: 'SBI;NVC;RadicalCandor',
  signalMarkersScope: 'corp_sig_contempt_marker;corp_sig_defensiveness;corp_sig_stonewalling;corp_sig_karpman_victim;corp_sig_karpman_persecutor;corp_sig_karpman_rescuer',
  text2cypherTemplate: 'MATCH (e:EmotionalState {cardId:"corp_emo_psychological_safety"}) MATCH (t:Technique) WHERE t.domain = "Corporate & Engineering" AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"corp_emo_public_setting"}) RETURN t ORDER BY t.tier ASC LIMIT 5',
  updatedPhase: '8'
};

MERGE (r:SchemaFilterRegistry {domain: 'education'})
SET r += {
  name: 'Education Schema Filter',
  primaryDomains: 'Education;knowledge_states',
  alwaysInclude: 'EmotionalState;SignalMarker;KnowledgeState',
  blockedDomains: 'Crisis Dispatch / Emergency;Legal & Investigative',
  protocolDags: 'CoachIDL;SocraticSequence',
  signalMarkersScope: 'edu_sig_cognitive_load;edu_sig_confusion;edu_sig_memory_decay;edu_sig_partial_answer;edu_sig_wrong_answer',
  text2cypherTemplate: 'MATCH (ks:KnowledgeState) WHERE ks.p_know_range CONTAINS $p_know_bracket MATCH (t:Technique) WHERE t.domain = "Education" AND t.bktTrigger CONTAINS $bkt_condition AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:"edu_emo_low_confidence"}) RETURN t ORDER BY t.tier ASC LIMIT 3',
  updatedPhase: '8'
};

// ── Domain-specific Text2Cypher query templates as nodes ─────

MERGE (q:Text2CypherTemplate {id: 'dispatch_panic_query'})
SET q += {
  domain: 'dispatch',
  description: 'Primary dispatch: find lowest-load techniques for panic/hostile state',
  cypherTemplate: 'MATCH (e:EmotionalState)-[:TRIGGERS]->(t:Technique) WHERE e.domain CONTAINS "dispatch" AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e) AND t.cognitiveLoadProfile IN ["lowest-load","lowest safe load","low-load"] RETURN t ORDER BY t.tier ASC LIMIT 5',
  phase: '8'
};

MERGE (q:Text2CypherTemplate {id: 'clinical_spikes_step_query'})
SET q += {
  domain: 'clinical',
  description: 'SPIKES step-aware retrieval: return techniques for current step, gate-validated',
  cypherTemplate: 'MATCH (p:ProtocolStep {protocol:"SPIKES"}) WHERE p.stepNumber = $step MATCH (p)-[:TRIGGERS]->(t:Technique) WHERE NOT EXISTS { MATCH (g:ProtocolGate)-[:GATES]->(p) WHERE g.condition_met = false } RETURN t',
  phase: '8'
};

MERGE (q:Text2CypherTemplate {id: 'legal_peace_step_query'})
SET q += {
  domain: 'legal',
  description: 'PEACE step-aware retrieval: return techniques for current step, Reid never returned',
  cypherTemplate: 'MATCH (s:ProtocolStep {protocol:"PEACE"}) WHERE s.stepNumber = $step MATCH (s)-[:TRIGGERS]->(t:Technique) WHERE NOT t.activationBlocked = true RETURN t ORDER BY s.stepNumber ASC',
  phase: '8'
};

MERGE (q:Text2CypherTemplate {id: 'education_bkt_query'})
SET q += {
  domain: 'education',
  description: 'BKT-aware retrieval: match CoachIDL act to p_know bracket',
  cypherTemplate: 'MATCH (ks:KnowledgeState) MATCH (dp:DomainProtocol) WHERE dp.domain = "Education" AND dp.bktTrigger CONTAINS $bkt_condition RETURN dp ORDER BY dp.name ASC',
  phase: '8'
};

MERGE (q:Text2CypherTemplate {id: 'cross_domain_contamination_check'})
SET q += {
  domain: 'all',
  description: 'Pre-retrieval contamination check: confirm technique not blocked in active domain',
  cypherTemplate: 'MATCH (t:Technique {cardId: $technique_id}) MATCH (active:EmotionalState {cardId: $active_domain_state}) RETURN NOT EXISTS { MATCH (t)-[:CONTRAINDICATED_WHEN]->(active) } AS safe_to_use',
  phase: '8'
};

RETURN 'Schema filter registry script complete — 6 domain filters + 5 templates' AS status;
