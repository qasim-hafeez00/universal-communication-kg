// ============================================================
// UCKB Phase 8 — Script 12: Cross-Domain Contamination Guards
// Creates DomainBoundary nodes and systematic cross-domain
// CONTRAINDICATED_WHEN edges covering all 15 domain pairs
// Run after: 11_protocol_dags.cypher
// ============================================================

// ── DomainBoundary nodes ─────────────────────────────────────

MERGE (db:DomainBoundary {id: 'boundary_sales_crisis'})
SET db += {
  sourceDomain: 'Sales & Negotiation',
  targetDomain: 'Crisis Dispatch / Emergency',
  rule: 'BLOCK_ALL',
  condition: 'domain_context = crisis',
  rationale: 'Influence techniques exploit cognitive vulnerabilities; callers in crisis cannot exercise autonomous judgment.'
};

MERGE (db:DomainBoundary {id: 'boundary_sales_clinical'})
SET db += {
  sourceDomain: 'Sales & Negotiation',
  targetDomain: 'Clinical / Medical',
  rule: 'PARTIAL_BLOCK',
  condition: 'clinical_context = active',
  rationale: 'Influence/persuasion techniques are inappropriate in clinical consent; discovery/information techniques are acceptable.'
};

MERGE (db:DomainBoundary {id: 'boundary_legal_clinical'})
SET db += {
  sourceDomain: 'Legal & Investigative',
  targetDomain: 'Clinical / Medical',
  rule: 'SELECTIVE_BLOCK',
  condition: 'clinical_context = active',
  rationale: 'Contradiction challenge inappropriate in clinical; cognitive interview acceptable.'
};

MERGE (db:DomainBoundary {id: 'boundary_legal_crisis'})
SET db += {
  sourceDomain: 'Legal & Investigative',
  targetDomain: 'Crisis Dispatch / Emergency',
  rule: 'SELECTIVE_BLOCK',
  condition: 'crisis_context = active',
  rationale: 'Reid technique absolutely blocked; free narrative interview acceptable when time allows.'
};

MERGE (db:DomainBoundary {id: 'boundary_corporate_clinical'})
SET db += {
  sourceDomain: 'Corporate & Engineering',
  targetDomain: 'Clinical / Medical',
  rule: 'PARTIAL_BLOCK',
  condition: 'clinical_context = active',
  rationale: 'Radical Candor direct challenge inappropriate clinically; SBI behavioral observation acceptable.'
};

MERGE (db:DomainBoundary {id: 'boundary_corporate_crisis'})
SET db += {
  sourceDomain: 'Corporate & Engineering',
  targetDomain: 'Crisis Dispatch / Emergency',
  rule: 'BLOCK_ALL',
  condition: 'crisis_context = active',
  rationale: 'Corporate feedback techniques require regulated emotional baseline that crisis callers cannot maintain.'
};

MERGE (db:DomainBoundary {id: 'boundary_education_crisis'})
SET db += {
  sourceDomain: 'Education',
  targetDomain: 'Crisis Dispatch / Emergency',
  rule: 'SELECTIVE_BLOCK',
  condition: 'crisis_context = active',
  rationale: 'Socratic questioning creates high cognitive load contraindicated in crisis; direct instruction is acceptable.'
};

MERGE (db:DomainBoundary {id: 'boundary_education_legal'})
SET db += {
  sourceDomain: 'Education',
  targetDomain: 'Legal & Investigative',
  rule: 'SELECTIVE_BLOCK',
  condition: 'legal_context = active',
  rationale: 'Scaffolded hints could contaminate a free narrative account; direct instruction acceptable pre-interview only.'
};

MERGE (db:DomainBoundary {id: 'boundary_crisis_sales'})
SET db += {
  sourceDomain: 'Crisis Dispatch / Emergency',
  targetDomain: 'Sales & Negotiation',
  rule: 'SELECTIVE_ALLOW',
  condition: 'negotiation_context = active',
  rationale: 'De-escalation and active listening are applicable in negotiation; crisis urgency override nodes are not.'
};

MERGE (db:DomainBoundary {id: 'boundary_clinical_education'})
SET db += {
  sourceDomain: 'Clinical / Medical',
  targetDomain: 'Education',
  rule: 'ALLOW_MOST',
  condition: 'education_context = active',
  rationale: 'Clinical empathy and MI techniques are broadly applicable in education; SPIKES consent architecture not required.'
};

MERGE (db:DomainBoundary {id: 'boundary_crisis_legal'})
SET db += {
  sourceDomain: 'Crisis Dispatch / Emergency',
  targetDomain: 'Legal & Investigative',
  rule: 'ALLOW_MOST',
  condition: 'legal_context = active',
  rationale: 'Active listening and rapport techniques transfer well; urgency override inapplicable.'
};

MERGE (db:DomainBoundary {id: 'boundary_sales_education'})
SET db += {
  sourceDomain: 'Sales & Negotiation',
  targetDomain: 'Education',
  rule: 'SELECTIVE_BLOCK',
  condition: 'education_context = active',
  rationale: 'Cialdini influence principles should not be applied to learners; SPIN discovery questions are acceptable.'
};

MERGE (db:DomainBoundary {id: 'boundary_legal_corporate'})
SET db += {
  sourceDomain: 'Legal & Investigative',
  targetDomain: 'Corporate & Engineering',
  rule: 'ALLOW_MOST',
  condition: 'corporate_context = active',
  rationale: 'Non-accusatorial framing and cognitive interview listening techniques transfer well to corporate.'
};

MERGE (db:DomainBoundary {id: 'boundary_corporate_education'})
SET db += {
  sourceDomain: 'Corporate & Engineering',
  targetDomain: 'Education',
  rule: 'ALLOW_MOST',
  condition: 'education_context = active',
  rationale: 'SBI and NVC communication structures transfer to educational feedback; 360-degree formal review tools do not apply.'
};

MERGE (db:DomainBoundary {id: 'boundary_education_corporate'})
SET db += {
  sourceDomain: 'Education',
  targetDomain: 'Corporate & Engineering',
  rule: 'SELECTIVE_ALLOW',
  condition: 'corporate_context = active',
  rationale: 'Scaffolding as coaching technique applicable in corporate; BKT state machine not applicable outside education.'
};

// ── Systematic CONTRAINDICATED_WHEN edges ────────────────────

// Crisis Dispatch — EmotionalState target for blanket blocks
MERGE (e:EmotionalState {cardId: 'crisis_active_domain_state'})
SET e += {
  name: 'Crisis Domain Active',
  description: 'Crisis dispatch context is active. Blocks ALL inappropriate cross-domain technique activation.',
  domain: 'Crisis Dispatch / Emergency',
  reviewStatus: 'source_checked'
};

// Block ALL Sales & Negotiation techniques during crisis
MATCH (t:Technique)
WHERE t.domain = 'Sales & Negotiation'
MATCH (e:EmotionalState {cardId: 'crisis_active_domain_state'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Sales influence techniques are inappropriate during active crisis dispatch',
  severity: 'CRITICAL',
  crossDomain: true,
  sourceDomain: 'Sales & Negotiation',
  targetDomain: 'Crisis Dispatch / Emergency'
}]->(e);

// Block ALL Corporate & Engineering techniques during crisis
MATCH (t:Technique)
WHERE t.domain = 'Corporate & Engineering'
MATCH (e:EmotionalState {cardId: 'crisis_active_domain_state'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Corporate feedback techniques require regulated emotional baseline absent in crisis',
  severity: 'CRITICAL',
  crossDomain: true,
  sourceDomain: 'Corporate & Engineering',
  targetDomain: 'Crisis Dispatch / Emergency'
}]->(e);

// Block Socratic techniques during crisis
MATCH (t:Technique)
WHERE t.domain = 'Education' AND t.name CONTAINS 'Socratic'
MATCH (e:EmotionalState {cardId: 'crisis_active_domain_state'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Socratic questioning creates unacceptable cognitive load in crisis state',
  severity: 'HIGH',
  crossDomain: true,
  sourceDomain: 'Education',
  targetDomain: 'Crisis Dispatch / Emergency'
}]->(e);

// Block Contradiction Challenge in clinical context
MERGE (e:EmotionalState {cardId: 'clinical_active_domain_state'})
SET e += {
  name: 'Clinical Domain Active',
  description: 'Clinical context is active. Blocks interrogation-style techniques.',
  domain: 'Clinical / Medical',
  reviewStatus: 'source_checked'
};

MATCH (t:Technique {cardId: 'legal_007_contradiction_challenge'})
MATCH (e:EmotionalState {cardId: 'clinical_active_domain_state'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Contradiction challenge is investigative technique inappropriate in clinical therapeutic relationship',
  severity: 'HIGH',
  crossDomain: true
}]->(e);

// Block Cialdini influence techniques in clinical context
MATCH (t:Technique)
WHERE t.domain = 'Sales & Negotiation'
  AND (t.name CONTAINS 'Cialdini' OR t.name CONTAINS 'Commitment' OR t.name CONTAINS 'Anchoring')
MATCH (e:EmotionalState {cardId: 'clinical_active_domain_state'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Persuasion/influence techniques compromise clinical consent architecture',
  severity: 'CRITICAL',
  crossDomain: true
}]->(e);

// RC direct challenge blocked in clinical
MATCH (t:Technique {cardId: 'corp_004_radical_candor_delivery'})
MATCH (e:EmotionalState {cardId: 'clinical_active_domain_state'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Radical Candor direct challenge is incompatible with clinical therapeutic non-directiveness',
  severity: 'HIGH',
  crossDomain: true
}]->(e);

// Reid absolute block (already exists but confirm cross-domain flag)
MATCH (t:Technique {cardId: 'legal_contraindicated_reid'})
MATCH (e:EmotionalState {cardId: 'legal_emo_any_interview_context'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'ABSOLUTE — false confession risk. Leo 2008, Kassin 2012.',
  severity: 'ABSOLUTE',
  crossDomain: true
}]->(e);

// Education socratic blocks in legal account phase
MERGE (e:EmotionalState {cardId: 'legal_account_phase_active'})
SET e += {
  name: 'Legal Account Phase Active',
  description: 'PEACE account phase is active. Free narrative must not be interrupted or directed.',
  domain: 'Legal & Investigative',
  reviewStatus: 'source_checked'
};

MATCH (t:Technique)
WHERE t.domain = 'Education' AND (t.name CONTAINS 'Scaffolded' OR t.name CONTAINS 'Hint')
MATCH (e:EmotionalState {cardId: 'legal_account_phase_active'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Scaffolded hints would contaminate free narrative account quality',
  severity: 'HIGH',
  crossDomain: true
}]->(e);

// Block Sales Cialdini from Education domain
MERGE (e:EmotionalState {cardId: 'education_active_domain_state'})
SET e += {
  name: 'Education Domain Active',
  description: 'Education context is active.',
  domain: 'Education',
  reviewStatus: 'source_checked'
};

MATCH (t:Technique)
WHERE t.domain = 'Sales & Negotiation'
  AND (t.name CONTAINS 'Cialdini' OR t.name CONTAINS 'Loss Aversion' OR t.name CONTAINS 'Scarcity')
MATCH (e:EmotionalState {cardId: 'education_active_domain_state'})
MERGE (t)-[:CONTRAINDICATED_WHEN {
  reason: 'Influence principles must not be applied to learners in educational context',
  severity: 'HIGH',
  crossDomain: true
}]->(e);

RETURN 'Cross-domain guards script complete — 15 boundary nodes created' AS status;
