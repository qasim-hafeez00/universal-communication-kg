// ============================================================
// UCKB Phase 8 — Script 10: Education Domain
// Creates all Education nodes, BKT states, and CoachIDL acts
// Run after: 09_corporate_domain.cypher
// ============================================================

// ── KnowledgeState nodes (BKT model) ─────────────────────────

MERGE (ks:KnowledgeState {cardId: 'edu_ks_novice'})
SET ks += {
  name: 'BKT: Novice State',
  domain: 'Education',
  description: 'Student has no or minimal prior knowledge. p_know = 0.0-0.2. Triggers Direct Instruction.',
  p_know_range: '0.0-0.2',
  triggeredAct: 'direct_instruction',
  reviewStatus: 'source_checked'
};

MERGE (ks:KnowledgeState {cardId: 'edu_ks_partial'})
SET ks += {
  name: 'BKT: Partial Knowledge State',
  domain: 'Education',
  description: 'Student has partial knowledge; can engage but needs support. p_know = 0.2-0.5. Triggers Scaffold.',
  p_know_range: '0.2-0.5',
  triggeredAct: 'scaffolded_hint',
  reviewStatus: 'source_checked'
};

MERGE (ks:KnowledgeState {cardId: 'edu_ks_near_competent'})
SET ks += {
  name: 'BKT: Near-Competent State',
  domain: 'Education',
  description: 'Student has developing knowledge; productive struggle possible. p_know = 0.3-0.75. Triggers Socratic.',
  p_know_range: '0.3-0.75',
  triggeredAct: 'socratic_question',
  reviewStatus: 'source_checked'
};

MERGE (ks:KnowledgeState {cardId: 'edu_ks_mastered'})
SET ks += {
  name: 'BKT: Mastered State',
  domain: 'Education',
  description: 'Student demonstrated mastery in original context. p_know > 0.85. Triggers Transfer Probe.',
  p_know_range: '> 0.85',
  p_learn: 0.3,
  p_guess: 0.25,
  p_slip: 0.1,
  p_forget: 0.05,
  triggeredAct: 'transfer_probe; spaced_rep_schedule',
  reviewStatus: 'source_checked'
};

MERGE (ks:KnowledgeState {cardId: 'edu_ks_transfer_confirmed'})
SET ks += {
  name: 'BKT: Transfer Confirmed State',
  domain: 'Education',
  description: 'Student demonstrated transfer to novel context. Final state. p_know > 0.90.',
  p_know_range: '> 0.90',
  triggeredAct: 'spaced_rep_schedule_extended',
  reviewStatus: 'source_checked'
};

// ── CommunicationTechnique nodes ─────────────────────────────

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_001_socratic_opening'})
SET t += {
  name: 'Socratic Opening Question',
  domain: 'Education',
  description: 'Open question to surface student current understanding before deeper engagement.',
  whenToUse: 'Student has partial knowledge (BKT p_know 0.3-0.75); developing toward mastery.',
  whenNotToUse: 'p_know < 0.3; student has no baseline to draw on.',
  steps: 'Ask: What do you already know about [concept]? or What would you expect to happen if...?',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'p_know >= 0.3',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Socrates_Method; Collins1989CognitiveTutoring'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_002_socratic_probe'})
SET t += {
  name: 'Socratic Probe',
  domain: 'Education',
  description: 'Follow-up question probing assumptions and reasoning chains in a partial answer.',
  whenToUse: 'Student has produced partial answer with retrievable reasoning.',
  whenNotToUse: 'Student in confusion spiral; shift to scaffold first.',
  steps: 'Ask: Why do you think that? What evidence supports that? What would change if X were different?',
  cognitiveLoadProfile: 'medium-load',
  bktTrigger: 'partial_answer_signal',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Collins1989CognitiveTutoring; Graesser1995tutordialogue'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_003_socratic_challenge'})
SET t += {
  name: 'Socratic Challenge',
  domain: 'Education',
  description: 'Counter-example that destabilises a confidently held misconception through productive cognitive conflict.',
  whenToUse: 'Student has high-confidence misconception needing productive destabilisation.',
  whenNotToUse: 'Student already low confidence.',
  steps: 'Introduce counter-case: What would you say about [counter-example]? Does your answer still hold?',
  cognitiveLoadProfile: 'high-load',
  bktTrigger: 'confident_wrong_answer AND p_know > 0.5',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'VanLehn2011tutoring; Graesser1995tutordialogue'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_004_scaffolded_hint_t1'})
SET t += {
  name: 'Scaffolded Hint Tier 1',
  domain: 'Education',
  description: 'Lightest scaffolding: reactivates prerequisite knowledge without revealing solution path.',
  whenToUse: 'Student is stuck but has prerequisite knowledge to work with.',
  whenNotToUse: 'p_know < 0.2 — prerequisite gap too large; use Direct Instruction.',
  steps: 'Ask: What do you know about [prerequisite]? or What is the first thing you need to figure out?',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'confusion_signal AND p_know > 0.2',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Wood1976Scaffolding; VanLehn2011tutoring'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_005_scaffolded_hint_t2'})
SET t += {
  name: 'Scaffolded Hint Tier 2',
  domain: 'Education',
  description: 'Heavier scaffolding: reveals solution approach without giving the final answer.',
  whenToUse: 'After Tier 1 hint fails.',
  whenNotToUse: 'Tier 1 not attempted first.',
  steps: 'Say: The approach here is to [method]. Try applying that and see what you get.',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'tier1_hint_failed',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'Wood1976Scaffolding; VanLehn2011tutoring'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_006_scaffolded_hint_t3'})
SET t += {
  name: 'Scaffolded Hint Tier 3',
  domain: 'Education',
  description: 'Near-complete scaffolding: reveals almost all of answer structure, leaving final inference.',
  whenToUse: 'After Tier 2 fails.',
  whenNotToUse: 'Tier 2 not attempted.',
  steps: 'Say: You need [near-complete structure]; what goes in the last part?',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'tier2_hint_failed',
  tier: 'Tier 3',
  reviewStatus: 'source_checked',
  sourceIds: 'Wood1976Scaffolding; VanLehn2011tutoring'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_007_direct_instruction'})
SET t += {
  name: 'Direct Instruction',
  domain: 'Education',
  description: 'Agent explicitly teaches concept when prerequisite gap prevents self-discovery.',
  whenToUse: 'BKT p_know < 0.3; all scaffold tiers exhausted.',
  whenNotToUse: 'Near-competent state; productive struggle is possible.',
  steps: 'State: [Concept] means [definition/rule]. Key things to remember: [1, 2, 3].',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'p_know < 0.3 OR tier3_hint_failed',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Rosenshine1987DirectInstruction; VanLehn2011tutoring'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_008_worked_example'})
SET t += {
  name: 'Worked Example',
  domain: 'Education',
  description: 'Agent demonstrates technique application step-by-step before asking student to apply independently.',
  whenToUse: 'After direct instruction; student requests show me how.',
  whenNotToUse: 'Near-mastery state; modelling reduces productive challenge.',
  steps: 'Walk through: Here is how to apply [concept]: [step-by-step]. Now you try a similar one.',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'after_direct_instruction OR example_requested',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Sweller1988CognitiveLoad; VanLehn2011tutoring'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_010_spaced_rep_prompt'})
SET t += {
  name: 'Spaced Repetition Prompt',
  domain: 'Education',
  description: 'Retrieval practice prompt for previously mastered concept at optimum interval.',
  whenToUse: 'BKT mastery confirmed AND time-since-last exceeds decay threshold.',
  whenNotToUse: 'Concept not yet mastered.',
  steps: 'Say: Let us revisit something you learned earlier — [concept]. Can you tell me what it involves?',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'p_know > 0.85 AND time_since_last > p_forget_threshold',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Ebbinghaus1885; Cepeda2006SpacedPractice; Corbett1994BKT'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_011_error_correction'})
SET t += {
  name: 'Error Correction',
  domain: 'Education',
  description: 'Specific targeted correction identifying exact wrong element, explaining why, redirecting to correct understanding.',
  whenToUse: 'Any wrong answer, misconception, or slip detected.',
  steps: '[Specific element] is not quite right because [reason]. The correct understanding is [correction].',
  cognitiveLoadProfile: 'low-load',
  bktTrigger: 'wrong_answer AND p_slip_high',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'VanLehn2011tutoring; Corbett1994BKT'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_012_transfer_probe'})
SET t += {
  name: 'Transfer Probe',
  domain: 'Education',
  description: 'Tests whether mastered knowledge transfers to novel context — validates genuine mastery vs context-bound performance.',
  whenToUse: 'After mastery in original context.',
  whenNotToUse: 'Mastery not established.',
  steps: 'Say: Now, in a different situation — [novel context] — how would you apply [concept]?',
  cognitiveLoadProfile: 'medium-load',
  bktTrigger: 'p_know > 0.85 AND mastery_claim',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'Haskell2001Transfer; VanLehn2011tutoring'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'edu_013_praise_for_effort'})
SET t += {
  name: 'Praise for Effort',
  domain: 'Education',
  description: 'Specific praise targeting effort, strategy, or persistence — not outcome or innate ability.',
  whenToUse: 'Effort, strategy, or persistence is visible.',
  whenNotToUse: 'When praising ability not effort — rephrase first.',
  steps: 'Say: I can see you worked hard to figure that out or The strategy you used was effective.',
  cognitiveLoadProfile: 'lowest-load',
  bktTrigger: 'effort_signal; persistence_after_difficulty',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Dweck2006Mindset; Mueller1998PraiseMotivation'
};

// ── CoachIDL DomainProtocol nodes ────────────────────────────

MERGE (dp:DomainProtocol {cardId: 'edu_coachidl_direct_instruction'})
SET dp += { name: 'CoachIDL: Direct Instruction Act', domain: 'Education',
  description: 'Agent teaches concept. Triggered when p_know < 0.3.', bktTrigger: 'p_know < 0.3', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'edu_coachidl_socratic_question'})
SET dp += { name: 'CoachIDL: Socratic Question Act', domain: 'Education',
  description: 'Agent poses question to elicit reasoning. Triggered when 0.3 <= p_know <= 0.75.', bktTrigger: '0.3 <= p_know <= 0.75', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'edu_coachidl_scaffolded_hint'})
SET dp += { name: 'CoachIDL: Scaffolded Hint Act', domain: 'Education',
  description: 'Agent provides partial info. Triggered when confusion AND p_know > 0.2.', bktTrigger: 'confusion_signal AND p_know > 0.2', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'edu_coachidl_spaced_rep'})
SET dp += { name: 'CoachIDL: Spaced Repetition Act', domain: 'Education',
  description: 'Agent prompts recall. Triggered when p_know > 0.85 AND time > decay threshold.', bktTrigger: 'p_know > 0.85 AND time_since_last > decay_threshold', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'edu_coachidl_error_correction'})
SET dp += { name: 'CoachIDL: Error Correction Act', domain: 'Education',
  description: 'Agent corrects misconception. Triggered when wrong answer AND p_slip > 0.3.', bktTrigger: 'wrong_answer AND p_slip > 0.3', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'edu_coachidl_worked_example'})
SET dp += { name: 'CoachIDL: Worked Example Act', domain: 'Education',
  description: 'Agent demonstrates technique. Triggered when example requested OR conceptual gap.', bktTrigger: 'example_requested OR post_instruction_gap', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'edu_coachidl_transfer_probe'})
SET dp += { name: 'CoachIDL: Transfer Probe Act', domain: 'Education',
  description: 'Agent tests novel-context application. Triggered when p_know > 0.85.', bktTrigger: 'p_know > 0.85 AND mastery_asserted', reviewStatus: 'source_checked' };

// ── SignalMarker nodes ────────────────────────────────────────

MERGE (sm:SignalMarker {cardId: 'edu_sig_confusion'})
SET sm += { name: 'Confusion Signal', domain: 'Education',
  description: 'Contradictory statements; I don''t know; question reversal; long silence.',
  detectionMethod: 'linguistic;behavioral', modality: 'text;voice', confidenceThreshold: 0.70, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'edu_sig_partial_answer'})
SET sm += { name: 'Partial Answer', domain: 'Education',
  description: 'Answer has correct elements but is incomplete or lacks full reasoning.',
  detectionMethod: 'linguistic', modality: 'text;voice', confidenceThreshold: 0.75, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'edu_sig_confident_wrong_answer'})
SET sm += { name: 'Confident Wrong Answer', domain: 'Education',
  description: 'Wrong answer with high apparent confidence; no hedging; may push back if questioned.',
  detectionMethod: 'linguistic;prosodic', modality: 'text;voice', confidenceThreshold: 0.72, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'edu_sig_wrong_answer'})
SET sm += { name: 'Wrong Answer', domain: 'Education',
  description: 'Factually incorrect answer; neutral or low confidence level.',
  detectionMethod: 'linguistic', modality: 'text;voice', confidenceThreshold: 0.85, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'edu_sig_memory_decay'})
SET sm += { name: 'Memory Decay Signal', domain: 'Education',
  description: 'Time since last recall of mastered concept exceeds BKT p_forget threshold.',
  detectionMethod: 'temporal', modality: 'system', confidenceThreshold: 1.0, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'edu_sig_effort_signal'})
SET sm += { name: 'Effort Signal', domain: 'Education',
  description: 'Multiple attempts; self-correction; extended engagement; persisting after failure.',
  detectionMethod: 'behavioral;linguistic', modality: 'text;voice', confidenceThreshold: 0.65, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'edu_sig_cognitive_load'})
SET sm += { name: 'High Cognitive Load', domain: 'Education',
  description: 'Multiple simultaneous errors; extremely brief responses; explicit overwhelm; latency spike.',
  detectionMethod: 'linguistic;behavioral', modality: 'text;voice', confidenceThreshold: 0.65, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'edu_sig_prerequisite_gap'})
SET sm += { name: 'Prerequisite Gap', domain: 'Education',
  description: 'Student cannot engage with current concept; prerequisite has p_know < 0.3.',
  detectionMethod: 'system;linguistic', modality: 'system', confidenceThreshold: 0.80, reviewStatus: 'source_checked' };

// ── EmotionalState nodes ─────────────────────────────────────

MERGE (e:EmotionalState {cardId: 'edu_emo_low_confidence'})
SET e += { name: 'Low Confidence', domain: 'Education',
  description: 'Hesitant, self-deprecating, reluctant to attempt. CONTRAINDICATED target for Socratic Challenge.',
  arousalLevel: 'low', valence: 'negative', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'edu_emo_shame_response'})
SET e += { name: 'Shame Response', domain: 'Education',
  description: 'Experiencing shame about error or gap. CONTRADICTED by Error Correction.',
  arousalLevel: 'high', valence: 'negative', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'edu_emo_comprehension'})
SET e += { name: 'Comprehension State', domain: 'Education',
  description: 'Active comprehension: engaged, following, building mental model.',
  arousalLevel: 'medium', valence: 'positive', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'edu_emo_flow_state'})
SET e += { name: 'Flow State', domain: 'Education',
  description: 'Optimal challenge-skill balance, intrinsic engagement. Minimize interruptions.',
  arousalLevel: 'medium', valence: 'positive', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'edu_emo_frustration'})
SET e += { name: 'Frustration State', domain: 'Education',
  description: 'Frustration from extended unsuccessful struggle. Triggers scaffold increase.',
  arousalLevel: 'medium-high', valence: 'negative', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'edu_emo_disengagement'})
SET e += { name: 'Disengagement', domain: 'Education',
  description: 'Minimal responses; off-topic; no attempt at prompts. Requires rapport repair.',
  arousalLevel: 'low', valence: 'negative', reviewStatus: 'source_checked' };

// ── Relationships ─────────────────────────────────────────────

// Socratic sequence
MATCH (t1:Technique {cardId: 'edu_001_socratic_opening'})
MATCH (t2:Technique {cardId: 'edu_002_socratic_probe'})
MERGE (t1)-[:PRECEDES]->(t2);

// Scaffold sequence
MATCH (t1:Technique {cardId: 'edu_004_scaffolded_hint_t1'})
MATCH (t2:Technique {cardId: 'edu_005_scaffolded_hint_t2'})
MERGE (t1)-[:PRECEDES]->(t2);

MATCH (t1:Technique {cardId: 'edu_005_scaffolded_hint_t2'})
MATCH (t2:Technique {cardId: 'edu_006_scaffolded_hint_t3'})
MERGE (t1)-[:PRECEDES]->(t2);

MATCH (t1:Technique {cardId: 'edu_006_scaffolded_hint_t3'})
MATCH (t2:Technique {cardId: 'edu_007_direct_instruction'})
MERGE (t1)-[:PRECEDES]->(t2);

MATCH (t1:Technique {cardId: 'edu_007_direct_instruction'})
MATCH (t2:Technique {cardId: 'edu_008_worked_example'})
MERGE (t1)-[:PRECEDES]->(t2);

// BKT state TRIGGERS
MATCH (ks:KnowledgeState {cardId: 'edu_ks_near_competent'})
MATCH (t:Technique {cardId: 'edu_001_socratic_opening'})
MERGE (ks)-[:TRIGGERS]->(t);

MATCH (ks:KnowledgeState {cardId: 'edu_ks_mastered'})
MATCH (t:Technique {cardId: 'edu_012_transfer_probe'})
MERGE (ks)-[:TRIGGERS]->(t);

MATCH (ks:KnowledgeState {cardId: 'edu_ks_mastered'})
MATCH (t:Technique {cardId: 'edu_010_spaced_rep_prompt'})
MERGE (ks)-[:TRIGGERS]->(t);

// Signal TRIGGERS
MATCH (sm:SignalMarker {cardId: 'edu_sig_confusion'})
MATCH (t:Technique {cardId: 'edu_004_scaffolded_hint_t1'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'edu_sig_partial_answer'})
MATCH (t:Technique {cardId: 'edu_002_socratic_probe'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'edu_sig_confident_wrong_answer'})
MATCH (t:Technique {cardId: 'edu_003_socratic_challenge'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'edu_sig_wrong_answer'})
MATCH (t:Technique {cardId: 'edu_011_error_correction'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'edu_sig_memory_decay'})
MATCH (t:Technique {cardId: 'edu_010_spaced_rep_prompt'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'edu_sig_effort_signal'})
MATCH (t:Technique {cardId: 'edu_013_praise_for_effort'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'edu_sig_prerequisite_gap'})
MATCH (t:Technique {cardId: 'edu_007_direct_instruction'})
MERGE (sm)-[:TRIGGERS]->(t);

// CONTRAINDICATED
MATCH (t:Technique {cardId: 'edu_003_socratic_challenge'})
MATCH (e:EmotionalState {cardId: 'edu_emo_low_confidence'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Challenge only high-confidence wrong answers; challenges low-confidence state causes shutdown', severity: 'HIGH'}]->(e);

// CONTRADICTS
MATCH (t:Technique {cardId: 'edu_011_error_correction'})
MATCH (e:EmotionalState {cardId: 'edu_emo_shame_response'})
MERGE (t)-[:CONTRADICTS]->(e);

// ENHANCES
MATCH (t:Technique {cardId: 'edu_008_worked_example'})
MATCH (e:EmotionalState {cardId: 'edu_emo_comprehension'})
MERGE (t)-[:ENHANCES]->(e);

// DOMAIN_VARIANT_OF
MATCH (t:Technique {cardId: 'edu_013_praise_for_effort'})
MATCH (clinical:Technique) WHERE clinical.name = 'Affirmation' AND clinical.domain CONTAINS 'Clinical'
MERGE (t)-[:DOMAIN_VARIANT_OF]->(clinical);

// REQUIRES
MATCH (t:Technique {cardId: 'edu_010_spaced_rep_prompt'})
MATCH (ks:KnowledgeState {cardId: 'edu_ks_mastered'})
MERGE (t)-[:REQUIRES]->(ks);

RETURN 'Education domain script complete' AS status;
