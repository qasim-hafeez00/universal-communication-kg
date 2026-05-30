// ============================================================
// UCKB Phase 8 — Script 08: Legal & Investigative Domain
// Creates all Legal/Investigative nodes and relationships
// Run after: 07_validation.cypher (Phase 4)
// ============================================================

// ── Constraints and indices ──────────────────────────────────
CREATE CONSTRAINT legal_technique_id IF NOT EXISTS
  FOR (t:Technique) REQUIRE t.cardId IS UNIQUE;

CREATE CONSTRAINT statement_marker_id IF NOT EXISTS
  FOR (s:StatementMarker) REQUIRE s.cardId IS UNIQUE;

CREATE INDEX legal_domain_idx IF NOT EXISTS
  FOR (t:Technique) ON (t.domain);

CREATE INDEX statement_marker_domain_idx IF NOT EXISTS
  FOR (s:StatementMarker) ON (s.domain);

// ── CommunicationTechnique nodes ─────────────────────────────

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_001_free_narrative_invitation'})
SET t += {
  name: 'Free Narrative Invitation',
  domain: 'Legal & Investigative',
  description: 'Open-ended invitation to produce a free, uninterrupted first-person account in the interviewee''s own words and sequence.',
  whenToUse: 'Account phase of PEACE; immediately after rapport established.',
  whenNotToUse: 'Interviewee is in acute distress; medical attention takes priority.',
  steps: 'Say: Tell me everything you remember, from the beginning, in your own words. Remain silent; do not interrupt.',
  successSignals: 'Interviewee produces extended unprompted narrative; includes sensory detail.',
  failureSignals: 'Interviewee stops prematurely; provides minimal response.',
  triggerSignals: 'account_phase_active; rapport_established',
  cognitiveLoadProfile: 'low-load',
  contraindications: 'Do not interrupt account phase with clarifying questions.',
  tier: 'Tier 1',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'Fisher1992; Geiselman1985; PEACE2000'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_002_cognitive_interview'})
SET t += {
  name: 'Cognitive Interview',
  domain: 'Legal & Investigative',
  description: 'Evidence-based memory retrieval technique: mental context reinstatement, report-everything, temporal-order change, perspective change.',
  whenToUse: 'Witness or victim account is sparse; memory retrieval support needed.',
  whenNotToUse: 'Acute PTSD re-experiencing triggered; false memory risk high.',
  steps: '1) Mental Reinstatement; 2) Report Everything; 3) Change Temporal Order; 4) Change Perspective.',
  successSignals: 'New details emerge; interviewee becomes more fluent.',
  failureSignals: 'Interviewee confused or contradicts earlier account.',
  triggerSignals: 'account_phase_active; sparse_initial_account',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 1',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'Fisher1992; Geiselman1985; Memon1997'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_003_mental_reinstatement'})
SET t += {
  name: 'Mental Reinstatement of Context',
  domain: 'Legal & Investigative',
  description: 'Guides interviewee to mentally return to physical and emotional context of event to enhance episodic memory retrieval.',
  whenToUse: 'Initial account is thin; memory retrieval inhibited by anxiety.',
  whenNotToUse: 'Active flashback state; child witnesses under age 7.',
  steps: 'Ask: Close your eyes. Think about where you were. What could you see, hear, smell? What were you feeling?',
  successSignals: 'Interviewee enters reflective state; produces richer detail.',
  triggerSignals: 'sparse_initial_account; account_phase_active',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 2',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'Fisher1992'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_004_report_everything'})
SET t += {
  name: 'Report Everything Instruction',
  domain: 'Legal & Investigative',
  description: 'Instructs interviewee that all memories are relevant, including partial, uncertain, or trivial details.',
  whenToUse: 'Before free narrative; after rapport established.',
  whenNotToUse: 'Rapport not established; confabulation tendency present.',
  steps: 'Say: Tell me everything, even if it seems trivial or you are not sure. Everything could be important.',
  successSignals: 'Interviewee includes uncertain fragments and peripheral detail.',
  triggerSignals: 'interviewee_filtering_visible; sparse_account',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'Fisher1992; Geiselman1985'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_005_change_temporal_order'})
SET t += {
  name: 'Change Temporal Order',
  domain: 'Legal & Investigative',
  description: 'Asks interviewee to recall events in reverse chronological order, disrupting schema-based confabulation.',
  whenToUse: 'Inconsistency suspected; rehearsed narrative indicated by statement markers.',
  whenNotToUse: 'Fragmented trauma narrative; child witnesses; cognitive impairment.',
  steps: 'After full account: Tell me the same sequence, but start from [later point] and go backwards.',
  cognitiveLoadProfile: 'high-load',
  tier: 'Tier 3',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'Fisher1992; Vrij2008'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_006_change_perspective'})
SET t += {
  name: 'Change Perspective',
  domain: 'Legal & Investigative',
  description: 'Asks interviewee to describe events from a different vantage point to reveal perspective-dependent gaps.',
  whenToUse: 'Account lacks spatial detail; scene geometry is legally relevant.',
  whenNotToUse: 'Suggestible witnesses; children; trauma-linked false memory risk.',
  cognitiveLoadProfile: 'high-load',
  tier: 'Tier 3',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'Fisher1992; Memon1997'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_007_contradiction_challenge'})
SET t += {
  name: 'Contradiction Challenge',
  domain: 'Legal & Investigative',
  description: 'Presents specific factual contradiction between account and evidence, inviting explanation without accusation.',
  whenToUse: 'Full account obtained; specific factual discrepancy identified.',
  whenNotToUse: 'Account phase not complete; acute distress.',
  steps: 'Say: You mentioned X, but our records show Y. Can you help me understand that?',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 2',
  peaceStep: 'Evaluation',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000; Williamson1993'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_008_timeline_clarification'})
SET t += {
  name: 'Timeline Clarification',
  domain: 'Legal & Investigative',
  description: 'Systematically clarifies temporal sequences using open-ended questions to establish chronological coherence.',
  whenToUse: 'Account has temporal gaps or unclear sequencing.',
  steps: 'Ask: Before X happened, what were you doing? And just after X, what happened next?',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 2',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_009_open_ended_probe'})
SET t += {
  name: 'Open-Ended Probe',
  domain: 'Legal & Investigative',
  description: 'Single open-ended follow-up question elaborating on a specific aspect of the free narrative without suggesting content.',
  whenToUse: 'Account phase; any point where elaboration is needed.',
  steps: 'Use: Tell me more about...; Describe...; What happened then?',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000; Fisher1992'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_010_minimal_encourager'})
SET t += {
  name: 'Minimal Encourager',
  domain: 'Legal & Investigative',
  description: 'Minimal non-leading signal that encourages continuation of narrative without directing or evaluating content.',
  whenToUse: 'Throughout account phase to maintain narrative momentum.',
  steps: 'Use: I see; Go on; OK; head nod; brief silence.',
  cognitiveLoadProfile: 'lowest-load',
  tier: 'Tier 1',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_011_summary_and_confirm'})
SET t += {
  name: 'Summary and Confirm',
  domain: 'Legal & Investigative',
  description: 'Summarises interviewee account using their own language, inviting correction and confirmation.',
  whenToUse: 'Closure phase; after full account obtained.',
  steps: 'Say: Let me summarise what you told me... Is that accurate? Is there anything to change or add?',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  peaceStep: 'Closure',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000; Williamson1993'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_012_right_to_silence'})
SET t += {
  name: 'Right to Silence Acknowledgment',
  domain: 'Legal & Investigative',
  description: 'Explicit acknowledgment of right to silence in plain language before interview begins.',
  whenToUse: 'Before any formal interview; always when interviewee is detained.',
  steps: 'Deliver formal caution per jurisdiction; confirm understanding in plain language.',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  peaceStep: 'Engage and Explain',
  reviewStatus: 'source_checked',
  sourceIds: 'PACE1984; Miranda1966; PEACE2000'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_013_rapport_through_transparency'})
SET t += {
  name: 'Rapport Through Transparency',
  domain: 'Legal & Investigative',
  description: 'Builds rapport through honest explanation of interview purpose, process, and rights — no deceptive framing.',
  whenToUse: 'Always; first technique in any PEACE interview.',
  whenNotToUse: 'Never — transparency is non-optional in PEACE.',
  steps: 'Explain: who you are; why interview is happening; what happens to information; rights; duration.',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  peaceStep: 'Engage and Explain',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000; Gudjonsson2003'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_014_non_accusatorial_statement'})
SET t += {
  name: 'Non-Accusatorial Statement',
  domain: 'Legal & Investigative',
  description: 'Presents discrepancies in neutral, non-blaming language that invites explanation rather than defensive shutdown.',
  whenToUse: 'Interviewee shows defensiveness; discrepancy needs clarification.',
  steps: 'Say: There is something I would like to understand better. [Fact]. Can you help me understand that?',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 2',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000; Leo2008'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_015_account_gap_exploration'})
SET t += {
  name: 'Account Gap Exploration',
  domain: 'Legal & Investigative',
  description: 'Identifies and non-accusatorially explores temporal or factual gaps in the interviewee free account.',
  whenToUse: 'Temporal or factual gap identified in free account.',
  steps: 'Say: You mentioned X and then Y. Tell me what happened between those two points.',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 2',
  peaceStep: 'Account',
  reviewStatus: 'source_checked',
  sourceIds: 'PEACE2000; Adams1996'
};

// ── CONTRAINDICATED NODE — Reid Technique ────────────────────
MERGE (t:Technique:CommunicationTechnique {cardId: 'legal_contraindicated_reid'})
SET t += {
  name: 'Reid Technique (CONTRAINDICATED)',
  domain: 'Legal & Investigative',
  activationBlocked: true,
  contraindication: 'ABSOLUTE',
  description: 'Confrontational accusation-based interrogation. NEVER to be used.',
  whenToUse: 'NEVER',
  whenNotToUse: 'ALWAYS — node exists to make the block explicit and queryable.',
  rationale: 'Leo 2008 (false confessions); Kassin 2012 (DNA exonerations); Gudjonsson 2003. Techniques include false evidence claims, minimisation/maximisation, and psychological coercion.',
  tier: 'BLOCKED',
  reviewStatus: 'source_checked'
};

// ── StatementMarker nodes (FBI SA) ───────────────────────────

MERGE (s:StatementMarker {cardId: 'sa_001_verb_tense_shift'})
SET s += {
  name: 'Verb Tense Shift',
  domain: 'Legal & Investigative',
  description: 'Shift from past to present tense mid-narrative.',
  linguisticMarker: 'past-tense narrative interrupted by present-tense verb',
  signalMeaning: 'Re-experiencing OR rehearsed construction of account.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.65,
  reviewStatus: 'source_checked'
};

MERGE (s:StatementMarker {cardId: 'sa_002_pronoun_change'})
SET s += {
  name: 'Pronoun Change',
  domain: 'Legal & Investigative',
  description: 'Shift from I to we mid-narrative without referent introduction.',
  linguisticMarker: 'I -> we pronoun shift without referent introduction',
  signalMeaning: 'Distancing from personal ownership.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.60,
  reviewStatus: 'source_checked'
};

MERGE (s:StatementMarker {cardId: 'sa_003_missing_sequence'})
SET s += {
  name: 'Missing Sequence',
  domain: 'Legal & Investigative',
  description: 'Temporal gap skipping a period relevant to investigation.',
  linguisticMarker: 'and then later...; the next thing I remember...',
  signalMeaning: 'Omission around legally relevant period.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.70,
  reviewStatus: 'source_checked'
};

MERGE (s:StatementMarker {cardId: 'sa_004_temporal_equivocation'})
SET s += {
  name: 'Temporal Equivocation',
  domain: 'Legal & Investigative',
  description: 'Vague temporal language for actions the narrator should know precisely.',
  linguisticMarker: 'about that time; around then',
  signalMeaning: 'Avoidance of precise temporal commitment.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.55,
  reviewStatus: 'source_checked'
};

MERGE (s:StatementMarker {cardId: 'sa_005_lack_of_conviction'})
SET s += {
  name: 'Lack of Conviction',
  domain: 'Legal & Investigative',
  description: 'Epistemic hedging applied to narrator own actions.',
  linguisticMarker: 'I think I...; I believe I...',
  signalMeaning: 'Reduced certainty about own acts.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.60,
  reviewStatus: 'source_checked'
};

MERGE (s:StatementMarker {cardId: 'sa_006_spontaneous_negation'})
SET s += {
  name: 'Spontaneous Negation',
  domain: 'Legal & Investigative',
  description: 'Unprompted denial of guilt not asked about.',
  linguisticMarker: 'I did not [crime] stated without being asked',
  signalMeaning: 'High-confidence deception marker.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.72,
  reviewStatus: 'source_checked'
};

MERGE (s:StatementMarker {cardId: 'sa_007_non_answer_answer'})
SET s += {
  name: 'Non-Answer Answer',
  domain: 'Legal & Investigative',
  description: 'Response addresses different question, avoiding specific asked content.',
  linguisticMarker: 'What I can tell you is...',
  signalMeaning: 'Topic avoidance behavior.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.65,
  reviewStatus: 'source_checked'
};

MERGE (s:StatementMarker {cardId: 'sa_008_involuntary_detail'})
SET s += {
  name: 'Involuntary Detail',
  domain: 'Legal & Investigative',
  description: 'Irrelevant specific details about peripheral elements.',
  linguisticMarker: 'unprompted specific detail on irrelevant element',
  signalMeaning: 'Displacement behavior.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.50,
  reviewStatus: 'source_checked'
};

// ── SignalMarker nodes ────────────────────────────────────────

MERGE (sm:SignalMarker {cardId: 'legal_sig_memory_retrieval'})
SET sm += {
  name: 'Memory Retrieval Signal',
  domain: 'Legal & Investigative',
  description: 'Interviewee enters visible reflective state indicating active episodic memory access.',
  detectionMethod: 'behavioral',
  modality: 'video;voice',
  confidenceThreshold: 0.75,
  reviewStatus: 'source_checked'
};

MERGE (sm:SignalMarker {cardId: 'legal_sig_continued_narrative'})
SET sm += {
  name: 'Continued Narrative Signal',
  domain: 'Legal & Investigative',
  description: 'Interviewee continues unprompted elaboration of account.',
  detectionMethod: 'linguistic',
  modality: 'text;voice',
  confidenceThreshold: 0.80,
  reviewStatus: 'source_checked'
};

// ── EmotionalState nodes ─────────────────────────────────────

MERGE (e:EmotionalState {cardId: 'legal_emo_defensive_state'})
SET e += {
  name: 'Defensive State',
  domain: 'Legal & Investigative',
  description: 'Interviewee exhibits defensive posture: denial, deflection, topic avoidance.',
  arousalLevel: 'medium-high',
  valence: 'negative',
  reviewStatus: 'source_checked'
};

MERGE (e:EmotionalState {cardId: 'legal_emo_trauma_fragmentation_risk'})
SET e += {
  name: 'Trauma Fragmentation Risk',
  domain: 'Legal & Investigative',
  description: 'Trauma-driven memory fragmentation: non-linear account, flashback indicators. Contraindicates Change Temporal Order and Change Perspective.',
  arousalLevel: 'high',
  valence: 'negative',
  reviewStatus: 'source_checked'
};

MERGE (e:EmotionalState {cardId: 'legal_emo_false_memory_risk'})
SET e += {
  name: 'False Memory Risk',
  domain: 'Legal & Investigative',
  description: 'High suggestibility or confabulation tendency. Contraindicates Change Perspective.',
  arousalLevel: 'low',
  valence: 'neutral',
  reviewStatus: 'source_checked'
};

MERGE (e:EmotionalState {cardId: 'legal_emo_coercive_context'})
SET e += {
  name: 'Coercive Context',
  domain: 'Legal & Investigative',
  description: 'Custodial or coercive context. Right to Silence Acknowledgment is mandatory.',
  arousalLevel: 'high',
  valence: 'negative',
  reviewStatus: 'source_checked'
};

MERGE (e:EmotionalState {cardId: 'legal_emo_any_interview_context'})
SET e += {
  name: 'Any Interview Context (Reid Block)',
  domain: 'Legal & Investigative',
  description: 'Covers ALL interview contexts — CONTRAINDICATED_WHEN target for Reid Technique absolute block.',
  reviewStatus: 'source_checked'
};

// ── DomainProtocol nodes ─────────────────────────────────────

MERGE (dp:DomainProtocol {cardId: 'legal_proto_peace'})
SET dp += {
  name: 'PEACE Investigative Interview Framework',
  domain: 'Legal & Investigative',
  description: 'UK Home Office ethical investigative interview framework: Preparation, Engage/Explain, Account, Closure, Evaluation.',
  sourceIds: 'PEACE2000; Williamson1993',
  reviewStatus: 'source_checked'
};

MERGE (dp:DomainProtocol {cardId: 'legal_proto_cognitive_interview'})
SET dp += {
  name: 'Cognitive Interview Protocol',
  domain: 'Legal & Investigative',
  description: '4-component memory retrieval protocol: mental reinstatement, report everything, change temporal order, change perspective.',
  sourceIds: 'Fisher1992; Geiselman1985',
  reviewStatus: 'source_checked'
};

MERGE (dp:DomainProtocol {cardId: 'legal_proto_statement_analysis'})
SET dp += {
  name: 'Scientific Content Analysis (SCAN)',
  domain: 'Legal & Investigative',
  description: 'Linguistic analysis of statements to identify deception, omission, or construction markers.',
  sourceIds: 'Adams1996; Sapir2000',
  reviewStatus: 'source_checked'
};

// ── Relationships ─────────────────────────────────────────────

// PEACE protocol sequencing
MATCH (t1:Technique {cardId: 'legal_001_free_narrative_invitation'})
MATCH (t2:Technique {cardId: 'legal_007_contradiction_challenge'})
MERGE (t1)-[:PRECEDES]->(t2);

MATCH (t1:Technique {cardId: 'legal_001_free_narrative_invitation'})
MATCH (t2:Technique {cardId: 'legal_013_rapport_through_transparency'})
MERGE (t1)-[:REQUIRES]->(t2);

MATCH (t1:Technique {cardId: 'legal_002_cognitive_interview'})
MATCH (t2:Technique {cardId: 'legal_001_free_narrative_invitation'})
MERGE (t1)-[:ENHANCES]->(t2);

MATCH (t1:Technique {cardId: 'legal_003_mental_reinstatement'})
MATCH (sm:SignalMarker {cardId: 'legal_sig_memory_retrieval'})
MERGE (t1)-[:TRIGGERS]->(sm);

MATCH (t1:Technique {cardId: 'legal_010_minimal_encourager'})
MATCH (sm:SignalMarker {cardId: 'legal_sig_continued_narrative'})
MERGE (t1)-[:TRIGGERS]->(sm);

MATCH (t1:Technique {cardId: 'legal_011_summary_and_confirm'})
MATCH (dp:DomainProtocol {cardId: 'legal_proto_peace'})
MERGE (t1)-[:REQUIRES]->(dp);

MATCH (t1:Technique {cardId: 'legal_013_rapport_through_transparency'})
MATCH (t2:Technique {cardId: 'legal_contraindicated_reid'})
MERGE (t1)-[:CONTRADICTS]->(t2);

MATCH (t1:Technique {cardId: 'legal_014_non_accusatorial_statement'})
MATCH (e:EmotionalState {cardId: 'legal_emo_defensive_state'})
MERGE (t1)-[:TRIGGERED_BY]->(e);

MATCH (t1:Technique {cardId: 'legal_015_account_gap_exploration'})
MATCH (t2:Technique {cardId: 'legal_001_free_narrative_invitation'})
MERGE (t1)-[:FOLLOWS]->(t2);

// CONTRAINDICATED edges
MATCH (t:Technique {cardId: 'legal_005_change_temporal_order'})
MATCH (e:EmotionalState {cardId: 'legal_emo_trauma_fragmentation_risk'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Reverse-order recall destabilises traumatised witnesses', severity: 'HIGH'}]->(e);

MATCH (t:Technique {cardId: 'legal_006_change_perspective'})
MATCH (e:EmotionalState {cardId: 'legal_emo_false_memory_risk'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Suggesting viewpoint can create pseudo-memories in suggestible witnesses', severity: 'HIGH'}]->(e);

MATCH (t:Technique {cardId: 'legal_012_right_to_silence'})
MATCH (e:EmotionalState {cardId: 'legal_emo_coercive_context'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Omitting right to silence in coercive context is absolute violation', severity: 'CRITICAL'}]->(e);

// Reid absolute block
MATCH (t:Technique {cardId: 'legal_contraindicated_reid'})
MATCH (e:EmotionalState {cardId: 'legal_emo_any_interview_context'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'ABSOLUTE: false confession risk — Leo 2008, Kassin 2012', severity: 'ABSOLUTE', crossDomain: true}]->(e);

// Domain variant edges
MATCH (t:Technique {cardId: 'legal_009_open_ended_probe'})
MATCH (core:Technique) WHERE core.name = 'Open Question' OR core.cardId CONTAINS 'open_question'
MERGE (t)-[:DOMAIN_VARIANT_OF]->(core);

MATCH (t:Technique {cardId: 'legal_010_minimal_encourager'})
MATCH (dispatch:Technique {cardId: 'crisis_dispatch_001_active_listening'})
MERGE (t)-[:DOMAIN_VARIANT_OF]->(dispatch);

RETURN 'Legal domain script complete' AS status;
