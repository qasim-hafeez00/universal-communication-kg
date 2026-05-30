// ============================================================
// UCKB Phase 8 — Script 11: Protocol DAG Structures
// Creates all 9 ProtocolDAG, ProtocolStep, and ProtocolGate nodes
// Run after: 10_education_domain.cypher
//
// DAGs built:
//   1. BCSM (Crisis Dispatch — 5 steps, 4 gates + bypass)
//   2. SPIKES (Clinical — 6 steps, 5 gates + refusal path)
//   3. SPIN (Sales — 4 steps)
//   4. Challenger Sale (Sales — 3 steps)
//   5. Harvard Negotiation (Sales — 4 principles)
//   6. PEACE (Legal — 5 steps, 4 gates)
//   7. SBI (Corporate — 3 steps, 1 gate)
//   8. NVC (Corporate — 4 steps, 1 gate)
//   9. CoachIDL Socratic (Education — 3 steps, 2 gates)
// ============================================================

// ── 1. BCSM Protocol DAG ─────────────────────────────────────

MERGE (d:ProtocolDAG {id: 'bcsm_dag'})
SET d += { name: 'BCSM Protocol', protocol: 'BCSM',
  domain: 'Crisis Dispatch / Emergency',
  description: 'FBI Behavioral Change Stairway Model — 5-step crisis de-escalation protocol.',
  stepCount: 5 };

MERGE (s1:ProtocolStep {id: 'bcsm_step_1'})
SET s1 += { name: 'Active Listening', protocol: 'BCSM', stepNumber: 1,
  description: 'Full attentional processing; reflective feedback; no interruption.', domain: 'Crisis Dispatch / Emergency' };

MERGE (s2:ProtocolStep {id: 'bcsm_step_2'})
SET s2 += { name: 'Empathy', protocol: 'BCSM', stepNumber: 2,
  description: 'Acknowledge emotional reality; validate without endorsing unsupported facts.', domain: 'Crisis Dispatch / Emergency' };

MERGE (s3:ProtocolStep {id: 'bcsm_step_3'})
SET s3 += { name: 'Rapport', protocol: 'BCSM', stepNumber: 3,
  description: 'Build trust and connection; establish common ground.', domain: 'Crisis Dispatch / Emergency' };

MERGE (s4:ProtocolStep {id: 'bcsm_step_4'})
SET s4 += { name: 'Influence', protocol: 'BCSM', stepNumber: 4,
  description: 'Guide behavior through established rapport; propose alternatives.', domain: 'Crisis Dispatch / Emergency' };

MERGE (s5:ProtocolStep {id: 'bcsm_step_5'})
SET s5 += { name: 'Behavioral Change', protocol: 'BCSM', stepNumber: 5,
  description: 'Observable change in caller behavior; safety instruction accepted.', domain: 'Crisis Dispatch / Emergency' };

MERGE (g1:ProtocolGate {id: 'bcsm_gate_1'})
SET g1 += { protocol: 'BCSM', fromStep: 1, toStep: 2,
  condition: 'caller_acknowledged_signal OR speech_rate_normalizes',
  failurePath: 're_engage_active_listening',
  bypassCondition: 'imminent_danger_threshold' };

MERGE (g2:ProtocolGate {id: 'bcsm_gate_2'})
SET g2 += { protocol: 'BCSM', fromStep: 2, toStep: 3,
  condition: 'affect_intensity_drops AND caller_accepts_next_question',
  failurePath: 'repeat_empathy_step',
  bypassCondition: 'imminent_danger_threshold' };

MERGE (g3:ProtocolGate {id: 'bcsm_gate_3'})
SET g3 += { protocol: 'BCSM', fromStep: 3, toStep: 4,
  condition: 'rapport_confirmed AND caller_elaborates',
  failurePath: 'repair_sequence',
  bypassCondition: 'imminent_danger_threshold' };

MERGE (g4:ProtocolGate {id: 'bcsm_gate_4'})
SET g4 += { protocol: 'BCSM', fromStep: 4, toStep: 5,
  condition: 'caller_considering_alternative',
  failurePath: 'reinforce_rapport',
  bypassCondition: 'imminent_danger_threshold' };

MERGE (bypass:ProtocolGate {id: 'bcsm_bypass_imminent_danger'})
SET bypass += { protocol: 'BCSM', name: 'Imminent Danger Override',
  condition: 'imminent_danger_threshold',
  bypassCondition: 'ALWAYS when imminent_danger_threshold is active',
  note: 'Skips all remaining BCSM steps; routes to One-Step Instruction immediately.' };

// PART_OF edges
MATCH (d:ProtocolDAG {id: 'bcsm_dag'}), (s:ProtocolStep {protocol: 'BCSM'})
MERGE (s)-[:PART_OF]->(d);

// PRECEDES edges
MATCH (s1:ProtocolStep {id: 'bcsm_step_1'}), (s2:ProtocolStep {id: 'bcsm_step_2'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'bcsm_step_2'}), (s3:ProtocolStep {id: 'bcsm_step_3'})
MERGE (s2)-[:PRECEDES]->(s3);
MATCH (s3:ProtocolStep {id: 'bcsm_step_3'}), (s4:ProtocolStep {id: 'bcsm_step_4'})
MERGE (s3)-[:PRECEDES]->(s4);
MATCH (s4:ProtocolStep {id: 'bcsm_step_4'}), (s5:ProtocolStep {id: 'bcsm_step_5'})
MERGE (s4)-[:PRECEDES]->(s5);

// GATES edges
MATCH (g:ProtocolGate {id: 'bcsm_gate_1'}), (s:ProtocolStep {id: 'bcsm_step_2'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'bcsm_gate_2'}), (s:ProtocolStep {id: 'bcsm_step_3'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'bcsm_gate_3'}), (s:ProtocolStep {id: 'bcsm_step_4'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'bcsm_gate_4'}), (s:ProtocolStep {id: 'bcsm_step_5'})
MERGE (g)-[:GATES]->(s);

// Link BCSM steps to existing dispatch techniques
MATCH (s:ProtocolStep {id: 'bcsm_step_1'}), (t:Technique {cardId: 'crisis_dispatch_001_active_listening'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'bcsm_step_2'}), (t:Technique {cardId: 'crisis_dispatch_002_empathic_validation'})
MERGE (s)-[:TRIGGERS]->(t);

// ── 2. SPIKES Protocol DAG ────────────────────────────────────

MERGE (d:ProtocolDAG {id: 'spikes_dag'})
SET d += { name: 'SPIKES Protocol', protocol: 'SPIKES',
  domain: 'Clinical / Medical',
  description: 'Clinical bad-news delivery protocol: Setting, Perception, Invitation, Knowledge, Emotion, Strategy.',
  stepCount: 6 };

MERGE (s1:ProtocolStep {id: 'spikes_s'})
SET s1 += { name: 'Setting', protocol: 'SPIKES', stepNumber: 1,
  description: 'Establish private setting; ensure patient is not alone; prepare.', domain: 'Clinical / Medical' };

MERGE (s2:ProtocolStep {id: 'spikes_p'})
SET s2 += { name: 'Perception', protocol: 'SPIKES', stepNumber: 2,
  description: 'Assess patient current understanding before disclosing.', domain: 'Clinical / Medical' };

MERGE (s3:ProtocolStep {id: 'spikes_i'})
SET s3 += { name: 'Invitation', protocol: 'SPIKES', stepNumber: 3,
  description: 'Invite patient to indicate how much information they want. ONLY step where patient can halt information flow.',
  criticalNote: 'ONLY STEP IN UCKB WHERE PATIENT CAN HALT INFORMATION FLOW', domain: 'Clinical / Medical' };

MERGE (s4:ProtocolStep {id: 'spikes_k'})
SET s4 += { name: 'Knowledge', protocol: 'SPIKES', stepNumber: 4,
  description: 'Deliver information in chunks; check understanding after each.', domain: 'Clinical / Medical' };

MERGE (s5:ProtocolStep {id: 'spikes_e'})
SET s5 += { name: 'Emotion', protocol: 'SPIKES', stepNumber: 5,
  description: 'Address emotional response before strategy. CANNOT PROCEED UNTIL EMOTION IS PROCESSED.',
  criticalNote: 'CANNOT PROCEED TO STRATEGY UNTIL EMOTION IS PROCESSED', domain: 'Clinical / Medical' };

MERGE (s6:ProtocolStep {id: 'spikes_str'})
SET s6 += { name: 'Strategy', protocol: 'SPIKES', stepNumber: 6,
  description: 'Discuss treatment plan and next steps after emotional processing.', domain: 'Clinical / Medical' };

MERGE (refusal:ProtocolStep {id: 'spikes_refusal_honored'})
SET refusal += { name: 'Patient Right Not to Know', protocol: 'SPIKES', stepNumber: 0,
  description: 'Invoked when patient declines invitation at Step 3. Honor right to not know; provide supportive care only.',
  domain: 'Clinical / Medical' };

// Gates
MERGE (g:ProtocolGate {id: 'spikes_gate_1'})
SET g += { protocol: 'SPIKES', fromStep: 1, toStep: 2,
  condition: 'privacy_confirmed AND patient_ready', failurePath: 'reestablish_setting' };

MERGE (g:ProtocolGate {id: 'spikes_gate_2'})
SET g += { protocol: 'SPIKES', fromStep: 2, toStep: 3,
  condition: 'baseline_understanding_established', failurePath: 'continue_perception_assessment' };

MERGE (g:ProtocolGate {id: 'spikes_gate_3'})
SET g += { protocol: 'SPIKES', fromStep: 3, toStep: 4,
  condition: 'explicit_verbal_consent_received',
  refusalPath: 'spikes_refusal_honored',
  note: 'ONLY STEP IN UCKB WHERE PATIENT CAN HALT INFORMATION FLOW' };

MERGE (g:ProtocolGate {id: 'spikes_gate_4'})
SET g += { protocol: 'SPIKES', fromStep: 4, toStep: 5,
  condition: 'patient_acknowledged_each_chunk', failurePath: 'repeat_chunk_check' };

MERGE (g:ProtocolGate {id: 'spikes_gate_5'})
SET g += { protocol: 'SPIKES', fromStep: 5, toStep: 6,
  condition: 'emotional_processing_complete',
  note: 'CANNOT PROCEED TO STRATEGY UNTIL EMOTION IS PROCESSED' };

MATCH (d:ProtocolDAG {id: 'spikes_dag'}), (s:ProtocolStep {protocol: 'SPIKES'})
MERGE (s)-[:PART_OF]->(d);

MATCH (s1:ProtocolStep {id: 'spikes_s'}), (s2:ProtocolStep {id: 'spikes_p'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'spikes_p'}), (s3:ProtocolStep {id: 'spikes_i'})
MERGE (s2)-[:PRECEDES]->(s3);
MATCH (s3:ProtocolStep {id: 'spikes_i'}), (s4:ProtocolStep {id: 'spikes_k'})
MERGE (s3)-[:PRECEDES]->(s4);
MATCH (s4:ProtocolStep {id: 'spikes_k'}), (s5:ProtocolStep {id: 'spikes_e'})
MERGE (s4)-[:PRECEDES]->(s5);
MATCH (s5:ProtocolStep {id: 'spikes_e'}), (s6:ProtocolStep {id: 'spikes_str'})
MERGE (s5)-[:PRECEDES]->(s6);

MATCH (g:ProtocolGate {id: 'spikes_gate_1'}), (s:ProtocolStep {id: 'spikes_p'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'spikes_gate_2'}), (s:ProtocolStep {id: 'spikes_i'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'spikes_gate_3'}), (s:ProtocolStep {id: 'spikes_k'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'spikes_gate_4'}), (s:ProtocolStep {id: 'spikes_e'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'spikes_gate_5'}), (s:ProtocolStep {id: 'spikes_str'})
MERGE (g)-[:GATES]->(s);

// ── 3. SPIN Selling Protocol DAG ─────────────────────────────

MERGE (d:ProtocolDAG {id: 'spin_dag'})
SET d += { name: 'SPIN Selling Protocol', protocol: 'SPIN',
  domain: 'Sales & Negotiation',
  description: 'Neil Rackham SPIN: Situation, Problem, Implication, Need-Payoff question sequence.', stepCount: 4 };

MERGE (s1:ProtocolStep {id: 'spin_step_1'})
SET s1 += { name: 'Situation Question', protocol: 'SPIN', stepNumber: 1, domain: 'Sales & Negotiation',
  description: 'Establish facts about buyer current situation and context.' };

MERGE (s2:ProtocolStep {id: 'spin_step_2'})
SET s2 += { name: 'Problem Question', protocol: 'SPIN', stepNumber: 2, domain: 'Sales & Negotiation',
  description: 'Explore buyer difficulties, dissatisfactions, and problems.' };

MERGE (s3:ProtocolStep {id: 'spin_step_3'})
SET s3 += { name: 'Implication Question', protocol: 'SPIN', stepNumber: 3, domain: 'Sales & Negotiation',
  description: 'Develop impact and consequences of buyer problems.' };

MERGE (s4:ProtocolStep {id: 'spin_step_4'})
SET s4 += { name: 'Need-Payoff Question', protocol: 'SPIN', stepNumber: 4, domain: 'Sales & Negotiation',
  description: 'Get buyer to articulate value of solving the problem.' };

MATCH (d:ProtocolDAG {id: 'spin_dag'}), (s:ProtocolStep {protocol: 'SPIN'})
MERGE (s)-[:PART_OF]->(d);

MATCH (s1:ProtocolStep {id: 'spin_step_1'}), (s2:ProtocolStep {id: 'spin_step_2'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'spin_step_2'}), (s3:ProtocolStep {id: 'spin_step_3'})
MERGE (s2)-[:PRECEDES]->(s3);
MATCH (s3:ProtocolStep {id: 'spin_step_3'}), (s4:ProtocolStep {id: 'spin_step_4'})
MERGE (s3)-[:PRECEDES]->(s4);

// ── 4. Challenger Sale Protocol DAG ──────────────────────────

MERGE (d:ProtocolDAG {id: 'challenger_dag'})
SET d += { name: 'Challenger Sale Protocol', protocol: 'ChallengerSale',
  domain: 'Sales & Negotiation',
  description: 'Dixon/Adamson Challenger Sale: Teach, Tailor, Take Control.', stepCount: 3 };

MERGE (s1:ProtocolStep {id: 'ch_step_1'})
SET s1 += { name: 'Teach', protocol: 'ChallengerSale', stepNumber: 1, domain: 'Sales & Negotiation',
  description: 'Teach buyer something new about their business or market.' };

MERGE (s2:ProtocolStep {id: 'ch_step_2'})
SET s2 += { name: 'Tailor', protocol: 'ChallengerSale', stepNumber: 2, domain: 'Sales & Negotiation',
  description: 'Tailor the message to resonate with buyer specific value drivers.' };

MERGE (s3:ProtocolStep {id: 'ch_step_3'})
SET s3 += { name: 'Take Control', protocol: 'ChallengerSale', stepNumber: 3, domain: 'Sales & Negotiation',
  description: 'Maintain control of the conversation and move it forward decisively.' };

MATCH (d:ProtocolDAG {id: 'challenger_dag'}), (s:ProtocolStep {protocol: 'ChallengerSale'})
MERGE (s)-[:PART_OF]->(d);

MATCH (s1:ProtocolStep {id: 'ch_step_1'}), (s2:ProtocolStep {id: 'ch_step_2'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'ch_step_2'}), (s3:ProtocolStep {id: 'ch_step_3'})
MERGE (s2)-[:PRECEDES]->(s3);

// ── 5. Harvard Principled Negotiation DAG ────────────────────

MERGE (d:ProtocolDAG {id: 'harvard_dag'})
SET d += { name: 'Harvard Principled Negotiation', protocol: 'HarvardNegotiation',
  domain: 'Sales & Negotiation',
  description: 'Fisher/Ury Getting to Yes: 4 principles of principled negotiation.', stepCount: 4 };

MERGE (s1:ProtocolStep {id: 'harv_step_1'})
SET s1 += { name: 'Separate People from Problem', protocol: 'HarvardNegotiation', stepNumber: 1, domain: 'Sales & Negotiation' };

MERGE (s2:ProtocolStep {id: 'harv_step_2'})
SET s2 += { name: 'Focus on Interests Not Positions', protocol: 'HarvardNegotiation', stepNumber: 2, domain: 'Sales & Negotiation' };

MERGE (s3:ProtocolStep {id: 'harv_step_3'})
SET s3 += { name: 'Invent Options for Mutual Gain', protocol: 'HarvardNegotiation', stepNumber: 3, domain: 'Sales & Negotiation' };

MERGE (s4:ProtocolStep {id: 'harv_step_4'})
SET s4 += { name: 'Insist on Objective Criteria', protocol: 'HarvardNegotiation', stepNumber: 4, domain: 'Sales & Negotiation' };

MATCH (d:ProtocolDAG {id: 'harvard_dag'}), (s:ProtocolStep {protocol: 'HarvardNegotiation'})
MERGE (s)-[:PART_OF]->(d);

// ── 6. PEACE Protocol DAG ─────────────────────────────────────

MERGE (d:ProtocolDAG {id: 'peace_dag'})
SET d += { name: 'PEACE Protocol', protocol: 'PEACE',
  domain: 'Legal & Investigative',
  description: 'UK Police investigative interview: Preparation, Engage/Explain, Account, Closure, Evaluation.', stepCount: 5 };

MERGE (s1:ProtocolStep {id: 'peace_p'})
SET s1 += { name: 'Preparation', protocol: 'PEACE', stepNumber: 1, domain: 'Legal & Investigative',
  description: 'Define legal objectives; establish points to prove; plan account sequence.' };

MERGE (s2:ProtocolStep {id: 'peace_e1'})
SET s2 += { name: 'Engage and Explain', protocol: 'PEACE', stepNumber: 2, domain: 'Legal & Investigative',
  description: 'Build rapport through transparency; outline process; deception PROHIBITED.',
  constraint: 'deception_by_interviewer_contraindicated_absolute' };

MERGE (s3:ProtocolStep {id: 'peace_a'})
SET s3 += { name: 'Account', protocol: 'PEACE', stepNumber: 3, domain: 'Legal & Investigative',
  description: 'Allow uninterrupted free narrative FIRST; contradictions addressed ONLY after full account.',
  gate: 'full_narrative_before_contradiction_check' };

MERGE (s4:ProtocolStep {id: 'peace_c'})
SET s4 += { name: 'Closure', protocol: 'PEACE', stepNumber: 4, domain: 'Legal & Investigative',
  description: 'Summarise; confirm key points; allow correction.' };

MERGE (s5:ProtocolStep {id: 'peace_e2'})
SET s5 += { name: 'Evaluation', protocol: 'PEACE', stepNumber: 5, domain: 'Legal & Investigative',
  description: 'Compare account against established facts and legal elements.' };

MERGE (g1:ProtocolGate {id: 'peace_gate_1'})
SET g1 += { protocol: 'PEACE', fromStep: 1, toStep: 2,
  condition: 'interview_objectives_defined AND evidence_reviewed' };

MERGE (g2:ProtocolGate {id: 'peace_gate_2'})
SET g2 += { protocol: 'PEACE', fromStep: 2, toStep: 3,
  condition: 'caution_delivered AND rapport_established AND rights_explained' };

MERGE (g3:ProtocolGate {id: 'peace_gate_3'})
SET g3 += { protocol: 'PEACE', fromStep: 3, toStep: 4,
  condition: 'full_narrative_obtained AND no_interruptions_made' };

MERGE (g4:ProtocolGate {id: 'peace_gate_4'})
SET g4 += { protocol: 'PEACE', fromStep: 4, toStep: 5,
  condition: 'summary_confirmed_by_interviewee' };

MATCH (d:ProtocolDAG {id: 'peace_dag'}), (s:ProtocolStep {protocol: 'PEACE'})
MERGE (s)-[:PART_OF]->(d);

MATCH (s1:ProtocolStep {id: 'peace_p'}), (s2:ProtocolStep {id: 'peace_e1'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'peace_e1'}), (s3:ProtocolStep {id: 'peace_a'})
MERGE (s2)-[:PRECEDES]->(s3);
MATCH (s3:ProtocolStep {id: 'peace_a'}), (s4:ProtocolStep {id: 'peace_c'})
MERGE (s3)-[:PRECEDES]->(s4);
MATCH (s4:ProtocolStep {id: 'peace_c'}), (s5:ProtocolStep {id: 'peace_e2'})
MERGE (s4)-[:PRECEDES]->(s5);

MATCH (g:ProtocolGate {id: 'peace_gate_1'}), (s:ProtocolStep {id: 'peace_e1'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'peace_gate_2'}), (s:ProtocolStep {id: 'peace_a'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'peace_gate_3'}), (s:ProtocolStep {id: 'peace_c'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'peace_gate_4'}), (s:ProtocolStep {id: 'peace_e2'})
MERGE (g)-[:GATES]->(s);

// Link PEACE steps to legal technique nodes
MATCH (s:ProtocolStep {id: 'peace_e1'}), (t:Technique {cardId: 'legal_013_rapport_through_transparency'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'peace_a'}), (t:Technique {cardId: 'legal_001_free_narrative_invitation'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'peace_c'}), (t:Technique {cardId: 'legal_011_summary_and_confirm'})
MERGE (s)-[:TRIGGERS]->(t);

// ── 7. SBI Protocol DAG ──────────────────────────────────────

MERGE (d:ProtocolDAG {id: 'sbi_dag'})
SET d += { name: 'SBI Feedback Protocol', protocol: 'SBI',
  domain: 'Corporate & Engineering', stepCount: 3 };

MERGE (s1:ProtocolStep {id: 'sbi_step_1'})
SET s1 += { name: 'Situation', protocol: 'SBI', stepNumber: 1, domain: 'Corporate & Engineering',
  description: 'State when and where — no evaluation.' };

MERGE (s2:ProtocolStep {id: 'sbi_step_2'})
SET s2 += { name: 'Behavior', protocol: 'SBI', stepNumber: 2, domain: 'Corporate & Engineering',
  description: 'State observable behavior only — NO personality attribution.' };

MERGE (s3:ProtocolStep {id: 'sbi_step_3'})
SET s3 += { name: 'Impact', protocol: 'SBI', stepNumber: 3, domain: 'Corporate & Engineering',
  description: 'State the effect on the team, work, or self.' };

MERGE (g:ProtocolGate {id: 'sbi_gate_behavior'})
SET g += { protocol: 'SBI', fromStep: 2, toStep: 3,
  condition: 'behavior_is_observable_not_interpreted',
  note: 'If you cannot film the behavior, it is an interpretation — reframe before proceeding.' };

MATCH (d:ProtocolDAG {id: 'sbi_dag'}), (s:ProtocolStep {protocol: 'SBI'})
MERGE (s)-[:PART_OF]->(d);

MATCH (s1:ProtocolStep {id: 'sbi_step_1'}), (s2:ProtocolStep {id: 'sbi_step_2'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'sbi_step_2'}), (s3:ProtocolStep {id: 'sbi_step_3'})
MERGE (s2)-[:PRECEDES]->(s3);

MATCH (g:ProtocolGate {id: 'sbi_gate_behavior'}), (s:ProtocolStep {id: 'sbi_step_3'})
MERGE (g)-[:GATES]->(s);

MATCH (s:ProtocolStep {id: 'sbi_step_1'}), (t:Technique {cardId: 'corp_001_sbi_situation'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'sbi_step_2'}), (t:Technique {cardId: 'corp_002_sbi_behavior'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'sbi_step_3'}), (t:Technique {cardId: 'corp_003_sbi_impact'})
MERGE (s)-[:TRIGGERS]->(t);

// ── 8. NVC Protocol DAG ──────────────────────────────────────

MERGE (d:ProtocolDAG {id: 'nvc_dag'})
SET d += { name: 'NVC Protocol', protocol: 'NVC',
  domain: 'Corporate & Engineering', stepCount: 4 };

MERGE (s1:ProtocolStep {id: 'nvc_step_1'})
SET s1 += { name: 'Observation', protocol: 'NVC', stepNumber: 1, domain: 'Corporate & Engineering',
  description: 'Factual — no evaluation; observable only.' };

MERGE (s2:ProtocolStep {id: 'nvc_step_2'})
SET s2 += { name: 'Feeling', protocol: 'NVC', stepNumber: 2, domain: 'Corporate & Engineering',
  description: 'Name the emotion experienced — not an interpretation.' };

MERGE (s3:ProtocolStep {id: 'nvc_step_3'})
SET s3 += { name: 'Need', protocol: 'NVC', stepNumber: 3, domain: 'Corporate & Engineering',
  description: 'Universal need behind the feeling — not a strategy.' };

MERGE (s4:ProtocolStep {id: 'nvc_step_4'})
SET s4 += { name: 'Request', protocol: 'NVC', stepNumber: 4, domain: 'Corporate & Engineering',
  description: 'Specific, positive, genuinely refusable request.' };

MERGE (g:ProtocolGate {id: 'nvc_gate_observation'})
SET g += { protocol: 'NVC', fromStep: 1, toStep: 2,
  condition: 'no_interpretations_present',
  note: 'If evaluation is present in observation, rewrite as fact before proceeding.' };

MATCH (d:ProtocolDAG {id: 'nvc_dag'}), (s:ProtocolStep {protocol: 'NVC'})
MERGE (s)-[:PART_OF]->(d);

MATCH (s1:ProtocolStep {id: 'nvc_step_1'}), (s2:ProtocolStep {id: 'nvc_step_2'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'nvc_step_2'}), (s3:ProtocolStep {id: 'nvc_step_3'})
MERGE (s2)-[:PRECEDES]->(s3);
MATCH (s3:ProtocolStep {id: 'nvc_step_3'}), (s4:ProtocolStep {id: 'nvc_step_4'})
MERGE (s3)-[:PRECEDES]->(s4);

MATCH (g:ProtocolGate {id: 'nvc_gate_observation'}), (s:ProtocolStep {id: 'nvc_step_2'})
MERGE (g)-[:GATES]->(s);

MATCH (s:ProtocolStep {id: 'nvc_step_1'}), (t:Technique {cardId: 'corp_009_nvc_observation'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'nvc_step_2'}), (t:Technique {cardId: 'corp_010_nvc_feeling'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'nvc_step_3'}), (t:Technique {cardId: 'corp_011_nvc_need'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'nvc_step_4'}), (t:Technique {cardId: 'corp_012_nvc_request'})
MERGE (s)-[:TRIGGERS]->(t);

// ── 9. Socratic CoachIDL Protocol DAG ────────────────────────

MERGE (d:ProtocolDAG {id: 'coachidl_socratic_dag'})
SET d += { name: 'CoachIDL Socratic Sequence', protocol: 'CoachIDL',
  domain: 'Education', stepCount: 3 };

MERGE (s1:ProtocolStep {id: 'socratic_step_1'})
SET s1 += { name: 'Socratic Opening', protocol: 'CoachIDL', stepNumber: 1, domain: 'Education',
  description: 'Surface current understanding. Requires p_know >= 0.3.' };

MERGE (s2:ProtocolStep {id: 'socratic_step_2'})
SET s2 += { name: 'Socratic Probe', protocol: 'CoachIDL', stepNumber: 2, domain: 'Education',
  description: 'Deepen engagement with partial answer.' };

MERGE (s3:ProtocolStep {id: 'socratic_step_3'})
SET s3 += { name: 'Socratic Challenge or Confirm', protocol: 'CoachIDL', stepNumber: 3, domain: 'Education',
  description: 'Challenge misconception OR confirm understanding.' };

MERGE (g1:ProtocolGate {id: 'coachidl_gate_1'})
SET g1 += { protocol: 'CoachIDL', fromStep: 1, toStep: 2,
  condition: 'partial_answer_produced OR engagement_signal' };

MERGE (g2:ProtocolGate {id: 'coachidl_gate_2'})
SET g2 += { protocol: 'CoachIDL', fromStep: 2, toStep: 3,
  condition: 'reasoning_chain_visible',
  failurePath: 'route_to_scaffold_tier_1' };

MATCH (d:ProtocolDAG {id: 'coachidl_socratic_dag'}), (s:ProtocolStep {protocol: 'CoachIDL'})
MERGE (s)-[:PART_OF]->(d);

MATCH (s1:ProtocolStep {id: 'socratic_step_1'}), (s2:ProtocolStep {id: 'socratic_step_2'})
MERGE (s1)-[:PRECEDES]->(s2);
MATCH (s2:ProtocolStep {id: 'socratic_step_2'}), (s3:ProtocolStep {id: 'socratic_step_3'})
MERGE (s2)-[:PRECEDES]->(s3);

MATCH (g:ProtocolGate {id: 'coachidl_gate_1'}), (s:ProtocolStep {id: 'socratic_step_2'})
MERGE (g)-[:GATES]->(s);
MATCH (g:ProtocolGate {id: 'coachidl_gate_2'}), (s:ProtocolStep {id: 'socratic_step_3'})
MERGE (g)-[:GATES]->(s);

MATCH (s:ProtocolStep {id: 'socratic_step_1'}), (t:Technique {cardId: 'edu_001_socratic_opening'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'socratic_step_2'}), (t:Technique {cardId: 'edu_002_socratic_probe'})
MERGE (s)-[:TRIGGERS]->(t);
MATCH (s:ProtocolStep {id: 'socratic_step_3'}), (t:Technique {cardId: 'edu_003_socratic_challenge'})
MERGE (s)-[:TRIGGERS]->(t);

// ── DAG Integrity Validation (run immediately) ───────────────
MATCH path = (s:ProtocolStep)-[:PRECEDES*]->(s)
RETURN s.id AS cyclic_node, length(path) AS cycle_length,
  'CRITICAL: CYCLE DETECTED' AS severity
LIMIT 10;

RETURN 'Protocol DAG script complete — 9 DAGs created' AS status;
