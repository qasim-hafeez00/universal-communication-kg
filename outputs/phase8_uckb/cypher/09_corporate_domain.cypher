// ============================================================
// UCKB Phase 8 — Script 09: Corporate / Engineering Domain
// Creates all Corporate nodes and relationships
// Run after: 08_legal_domain.cypher
// ============================================================

// ── CommunicationStyle nodes (Radical Candor quadrants) ──────

MERGE (cs:CommunicationStyle {cardId: 'corp_style_radical_candor'})
SET cs += {
  name: 'Radical Candor',
  domain: 'Corporate & Engineering',
  dimension1: 'care_personally:HIGH',
  dimension2: 'challenge_directly:HIGH',
  targetState: true,
  description: 'Feedback combining genuine personal care with direct, specific challenge. Target state.',
  reviewStatus: 'source_checked'
};

MERGE (cs:CommunicationStyle {cardId: 'corp_style_obnoxious_aggression'})
SET cs += {
  name: 'Obnoxious Aggression',
  domain: 'Corporate & Engineering',
  dimension1: 'care_personally:LOW',
  dimension2: 'challenge_directly:HIGH',
  targetState: false,
  description: 'Challenges directly but without genuine care. Feedback is blunt or contemptuous.',
  detectionSignals: 'contempt_marker; blaming_language; aggressive_facs',
  resolutionPath: 'corp_017_winners_triangle_assertive',
  reviewStatus: 'source_checked'
};

MERGE (cs:CommunicationStyle {cardId: 'corp_style_ruinous_empathy'})
SET cs += {
  name: 'Ruinous Empathy',
  domain: 'Corporate & Engineering',
  dimension1: 'care_personally:HIGH',
  dimension2: 'challenge_directly:LOW',
  targetState: false,
  description: 'Cares personally but avoids direct challenge. Prevents growth.',
  detectionSignals: 'avoidance_substantive_critique; excessive_hedging',
  resolutionPath: 'corp_004_radical_candor_delivery',
  reviewStatus: 'source_checked'
};

MERGE (cs:CommunicationStyle {cardId: 'corp_style_manipulative_insincerity'})
SET cs += {
  name: 'Manipulative Insincerity',
  domain: 'Corporate & Engineering',
  dimension1: 'care_personally:LOW',
  dimension2: 'challenge_directly:LOW',
  targetState: false,
  description: 'Neither cares personally nor challenges directly. Passive-aggressive patterns.',
  detectionSignals: 'passive_aggressive_markers; indirect_critique',
  reviewStatus: 'source_checked'
};

// ── CommunicationTechnique nodes ─────────────────────────────

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_001_sbi_situation'})
SET t += {
  name: 'SBI Situation',
  domain: 'Corporate & Engineering',
  description: 'First step of SBI: state specific observable situation without evaluation.',
  whenToUse: 'Opening step of structured feedback delivery.',
  whenNotToUse: 'Public setting; high emotional arousal.',
  steps: 'State: In [specific situation]...',
  successSignals: 'Recipient nods or confirms they recall the specific event.',
  triggerSignals: 'feedback_delivery_needed; private_setting_confirmed',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'CCL_SBI; ScottRadicalCandor'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_002_sbi_behavior'})
SET t += {
  name: 'SBI Behavior',
  domain: 'Corporate & Engineering',
  description: 'Second step of SBI: describe specific observable behavior without interpretation or personality labelling.',
  whenToUse: 'Second step of feedback delivery.',
  whenNotToUse: 'When behavior cannot be stated without interpretation.',
  steps: 'State: ...you [specific observable action]...',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'CCL_SBI; ScottRadicalCandor'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_003_sbi_impact'})
SET t += {
  name: 'SBI Impact',
  domain: 'Corporate & Engineering',
  description: 'Third step of SBI: describe specific impact on self, team, or work product.',
  whenToUse: 'Final step of SBI sequence.',
  steps: 'State: ...and the impact was [effect on team/work/self].',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'CCL_SBI; ScottRadicalCandor'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_004_radical_candor_delivery'})
SET t += {
  name: 'Radical Candor Delivery',
  domain: 'Corporate & Engineering',
  description: 'Full RC feedback: genuine personal investment plus specific direct challenge via SBI in private channel.',
  whenToUse: 'Any performance feedback in corporate context.',
  whenNotToUse: 'Public setting; care_personally baseline not established.',
  steps: '1) Private channel; 2) Check safety; 3) SBI sequence; 4) Listen; 5) Agree next step.',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'ScottRadicalCandor2017'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_005_private_channel_enforcement'})
SET t += {
  name: 'Private Channel Enforcement',
  domain: 'Corporate & Engineering',
  description: 'Ensures critique is delivered in private channel before any public interaction.',
  whenToUse: 'Any time critique is about to be delivered.',
  whenNotToUse: 'Never skip — this is a precondition.',
  steps: 'Confirm channel is private before delivering critique. If not, defer.',
  cognitiveLoadProfile: 'lowest-load',
  tier: 'Tier 1',
  reviewNotes: 'Only corporate technique with environmental constraint (not emotional-state constraint).',
  reviewStatus: 'source_checked',
  sourceIds: 'ScottRadicalCandor2017'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_006_immediate_feedback'})
SET t += {
  name: 'Immediate Feedback',
  domain: 'Corporate & Engineering',
  description: 'Feedback delivered within 48-hour window while specific detail remains fresh.',
  whenToUse: 'As soon as private setting and calm are available after observed behavior.',
  whenNotToUse: 'High emotional arousal; public setting.',
  steps: 'After observing behavior: wait for calm; find private channel; deliver within 48h.',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'ScottRadicalCandor2017; CCL_SBI'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_007_direct_report_feedback'})
SET t += {
  name: 'Direct Report Feedback',
  domain: 'Corporate & Engineering',
  description: 'Structured feedback from manager to direct report using full SBI with care-personally framing.',
  whenToUse: 'Regular 1:1 sessions; post-incident review.',
  whenNotToUse: 'No established relationship; public setting.',
  steps: '1) Care-personally signal; 2) SBI; 3) Invite response; 4) Co-create action step.',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'ScottRadicalCandor2017'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_008_upward_feedback'})
SET t += {
  name: 'Upward Feedback',
  domain: 'Corporate & Engineering',
  description: 'Feedback from report to manager requiring confirmed psychological safety and SBI structure.',
  whenToUse: 'Manager behavior has observable team impact and safety conditions are met.',
  whenNotToUse: 'Psychological safety not confirmed; punitive culture.',
  cognitiveLoadProfile: 'high-load',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'Edmondson1999PsychSafety; ScottRadicalCandor2017'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_009_nvc_observation'})
SET t += {
  name: 'NVC Observation',
  domain: 'Corporate & Engineering',
  description: 'First step of NVC: state specific observable fact, strictly free from evaluation.',
  whenToUse: 'Opening step of NVC sequence.',
  steps: 'State: When [I see/hear] [specific observable fact]...',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Rosenberg2003NVC'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_010_nvc_feeling'})
SET t += {
  name: 'NVC Feeling',
  domain: 'Corporate & Engineering',
  description: 'Second step of NVC: name the feeling using emotion vocabulary, not interpretations.',
  whenToUse: 'NVC sequence; after observation is stated.',
  steps: 'State: ...I feel [emotion word]...',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Rosenberg2003NVC'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_011_nvc_need'})
SET t += {
  name: 'NVC Need',
  domain: 'Corporate & Engineering',
  description: 'Third step of NVC: articulate underlying need using universal needs vocabulary, not strategy.',
  whenToUse: 'NVC sequence; after feeling stated.',
  steps: 'State: ...because I need [universal need]...',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Rosenberg2003NVC'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_012_nvc_request'})
SET t += {
  name: 'NVC Request',
  domain: 'Corporate & Engineering',
  description: 'Fourth step of NVC: specific, actionable, positive request framed so refusal is genuinely acceptable.',
  whenToUse: 'Final step of NVC; collaborative agreement-building.',
  steps: 'State: ...would you be willing to [specific positive action]?',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Rosenberg2003NVC'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_016_winners_triangle_vulnerable'})
SET t += {
  name: 'Winner''s Triangle: Vulnerable',
  domain: 'Corporate & Engineering',
  description: 'Moves Karpman Victim role to adaptive Vulnerable: acknowledges feelings without helplessness.',
  whenToUse: 'Drama triangle victim pattern detected.',
  steps: 'Acknowledge real difficulty; separate feelings from helplessness; ask: What is one thing within your control here?',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'Choy1990WinnersTriangle; Karpman1968'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_017_winners_triangle_assertive'})
SET t += {
  name: 'Winner''s Triangle: Assertive',
  domain: 'Corporate & Engineering',
  description: 'Moves Karpman Persecutor role to adaptive Assertive: direct and clear without blame or contempt.',
  whenToUse: 'Drama triangle persecutor pattern detected.',
  steps: 'Name behavior; state impact; make specific request — without blame or contempt.',
  cognitiveLoadProfile: 'high-load',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'Choy1990WinnersTriangle; Karpman1968'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_018_winners_triangle_caring'})
SET t += {
  name: 'Winner''s Triangle: Caring',
  domain: 'Corporate & Engineering',
  description: 'Moves Karpman Rescuer role to adaptive Caring: genuine support that empowers agency.',
  whenToUse: 'Drama triangle rescuer pattern; over-helping dynamic.',
  steps: 'Ask: What would be most helpful right now? Coach rather than rescue.',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'Choy1990WinnersTriangle; Karpman1968'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_019_psychological_safety_check'})
SET t += {
  name: 'Psychological Safety Check',
  domain: 'Corporate & Engineering',
  description: 'Pre-feedback gate assessing whether context has sufficient psychological safety to receive direct challenge.',
  whenToUse: 'Before any substantive feedback; before upward feedback.',
  steps: 'Assess: Can people disagree openly? Do errors get punished? Build safety before feedback if unsure.',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Edmondson1999PsychSafety; ScottRadicalCandor2017'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_020_context_setting_feedback'})
SET t += {
  name: 'Context Setting for Feedback',
  domain: 'Corporate & Engineering',
  description: 'Brief framing statement before SBI delivery establishing developmental intent and care-personally signal.',
  whenToUse: 'Any spontaneous feedback delivery; any time intent might be misread.',
  steps: 'Say: I want to share something because I think it will help. Is now a good time?',
  cognitiveLoadProfile: 'low-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'ScottRadicalCandor2017'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_024_criticism_vs_complaint'})
SET t += {
  name: 'Criticism vs Complaint Distinction',
  domain: 'Corporate & Engineering',
  description: 'Meta-technique checking feedback framing: is this criticism (character) or complaint (behavior)? Only complaints are deliverable.',
  whenToUse: 'Before any feedback delivery; internal pre-flight check.',
  steps: 'Test: Remove the behavior — does feedback still claim who the person IS? If yes, rewrite as specific observable behavior.',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 1',
  reviewStatus: 'source_checked',
  sourceIds: 'Gottman1994WhyMarriages; ScottRadicalCandor2017'
};

MERGE (t:Technique:CommunicationTechnique {cardId: 'corp_025_360_feedback_framing'})
SET t += {
  name: '360-Degree Feedback Framing',
  domain: 'Corporate & Engineering',
  description: 'Frames feedback as collected from multiple perspectives to reduce single-source attribution.',
  whenToUse: 'Formal review cycles; multi-source data available.',
  steps: 'Say: I gathered input from several people. The pattern is...',
  cognitiveLoadProfile: 'medium-load',
  tier: 'Tier 2',
  reviewStatus: 'source_checked',
  sourceIds: 'Bracken1997_360'
};

// ── SignalMarker nodes ────────────────────────────────────────

MERGE (sm:SignalMarker {cardId: 'corp_sig_karpman_victim'})
SET sm += { name: 'Karpman Victim Detection', domain: 'Corporate & Engineering',
  description: 'Helplessness, learned powerlessness, persistent external blame without problem-solving.',
  detectionMethod: 'behavioral;linguistic', modality: 'text;voice;video', confidenceThreshold: 0.65, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'corp_sig_karpman_persecutor'})
SET sm += { name: 'Karpman Persecutor Detection', domain: 'Corporate & Engineering',
  description: 'Blaming, criticising, contemptuous patterns with power asymmetry.',
  detectionMethod: 'behavioral;linguistic', modality: 'text;voice;video', confidenceThreshold: 0.65, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'corp_sig_karpman_rescuer'})
SET sm += { name: 'Karpman Rescuer Detection', domain: 'Corporate & Engineering',
  description: 'Consistently takes over others problems, offers unsolicited help, enables dependency.',
  detectionMethod: 'behavioral', modality: 'text;voice;video', confidenceThreshold: 0.60, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'corp_sig_contempt_marker'})
SET sm += { name: 'Contempt Detection', domain: 'Corporate & Engineering',
  description: 'Contempt: eye-roll, dismissive tone, mocking, moral superiority. Gottman highest-severity marker.',
  detectionMethod: 'behavioral;prosodic', modality: 'voice;video', confidenceThreshold: 0.80, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'corp_sig_defensiveness'})
SET sm += { name: 'Defensiveness Detection', domain: 'Corporate & Engineering',
  description: 'Counter-attack, excuse-making, victim stance in response to feedback.',
  detectionMethod: 'behavioral;linguistic', modality: 'text;voice;video', confidenceThreshold: 0.70, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'corp_sig_stonewalling'})
SET sm += { name: 'Stonewalling Detection', domain: 'Corporate & Engineering',
  description: 'Monosyllabic responses, withdrawal, refusal to engage. Triggers repair sequence.',
  detectionMethod: 'behavioral;linguistic', modality: 'text;voice;video', confidenceThreshold: 0.75, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'corp_sig_excessive_hedging'})
SET sm += { name: 'Excessive Hedging', domain: 'Corporate & Engineering',
  description: 'Feedback so qualified that substantive message is obscured. Indicator of Ruinous Empathy.',
  detectionMethod: 'linguistic', modality: 'text;voice', confidenceThreshold: 0.60, reviewStatus: 'source_checked' };

MERGE (sm:SignalMarker {cardId: 'corp_sig_passive_aggressive'})
SET sm += { name: 'Passive-Aggressive Marker', domain: 'Corporate & Engineering',
  description: 'Sarcasm, indirect resistance, agreed-but-not-followed-through. Indicator of Manipulative Insincerity.',
  detectionMethod: 'behavioral;linguistic', modality: 'text;voice;video', confidenceThreshold: 0.55, reviewStatus: 'source_checked' };

// ── EmotionalState nodes ─────────────────────────────────────

MERGE (e:EmotionalState {cardId: 'corp_emo_psychological_safety'})
SET e += { name: 'Psychological Safety Confirmed', domain: 'Corporate & Engineering',
  description: 'Context where interpersonal risk-taking is demonstrably safe.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_high_arousal'})
SET e += { name: 'High Emotional Arousal', domain: 'Corporate & Engineering',
  description: 'Either party in high arousal. Contraindicates immediate feedback.', arousalLevel: 'high', valence: 'negative', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_public_setting'})
SET e += { name: 'Public Setting (Critique Block)', domain: 'Corporate & Engineering',
  description: 'Critique would be in view of others. CONTRAINDICATED for all critique techniques.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_personality_attack_risk'})
SET e += { name: 'Personality Attack Risk', domain: 'Corporate & Engineering',
  description: 'Feedback framing has drifted from behavior to character.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_accountability'})
SET e += { name: 'Accountability State', domain: 'Corporate & Engineering',
  description: 'Recipient understands impact and is open to change. Target state for SBI Impact.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_calm_baseline'})
SET e += { name: 'Calm Baseline', domain: 'Corporate & Engineering',
  description: 'Both parties in regulated state. Prerequisite for assertive Winner Triangle and feedback.', arousalLevel: 'low', valence: 'neutral', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_intervention_required'})
SET e += { name: 'Intervention Required', domain: 'Corporate & Engineering',
  description: 'Contempt has reached severity requiring HR intervention.', arousalLevel: 'high', valence: 'negative', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_repair_required'})
SET e += { name: 'Repair Required', domain: 'Corporate & Engineering',
  description: 'Stonewalling occurred. Repair sequence required before communication resumes.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_further_challenge_active'})
SET e += { name: 'Further Challenge Active (Stonewalling Block)', domain: 'Corporate & Engineering',
  description: 'Stonewalling is active; further challenge CONTRAINDICATED.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_demand'})
SET e += { name: 'Demand (NVC Block)', domain: 'Corporate & Engineering',
  description: 'Request is non-negotiable; refusal not genuinely acceptable. CONTRADICTS NVC Request.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_interpretation_as_fact'})
SET e += { name: 'Interpretation as Fact', domain: 'Corporate & Engineering',
  description: 'Interpretation of intent stated as factual observation. CONTRADICTS NVC Observation.', reviewStatus: 'source_checked' };

MERGE (e:EmotionalState {cardId: 'corp_emo_rescuer_enabling'})
SET e += { name: 'Rescuer Enabling', domain: 'Corporate & Engineering',
  description: 'Solving others problem reinforcing dependency. CONTRADICTS Winner Triangle Caring.', reviewStatus: 'source_checked' };

// ── DomainProtocol nodes ─────────────────────────────────────

MERGE (dp:DomainProtocol {cardId: 'corp_proto_sbi'})
SET dp += { name: 'SBI Feedback Protocol', domain: 'Corporate & Engineering',
  description: 'CCL Situation-Behavior-Impact: 3-step structured feedback ensuring behavioral specificity.', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'corp_proto_nvc'})
SET dp += { name: 'Nonviolent Communication Protocol', domain: 'Corporate & Engineering',
  description: 'Rosenberg NVC: 4-component empathic communication — Observation, Feeling, Need, Request.', reviewStatus: 'source_checked' };

MERGE (dp:DomainProtocol {cardId: 'corp_proto_radical_candor'})
SET dp += { name: 'Radical Candor Protocol', domain: 'Corporate & Engineering',
  description: 'Kim Scott: 4-quadrant model — Care Personally x Challenge Directly. Target: top-right.', reviewStatus: 'source_checked' };

// ── Relationships ─────────────────────────────────────────────

// SBI sequence
MATCH (t1:Technique {cardId: 'corp_001_sbi_situation'})
MATCH (t2:Technique {cardId: 'corp_002_sbi_behavior'})
MERGE (t1)-[:PRECEDES]->(t2);

MATCH (t1:Technique {cardId: 'corp_002_sbi_behavior'})
MATCH (t2:Technique {cardId: 'corp_003_sbi_impact'})
MERGE (t1)-[:PRECEDES]->(t2);

// NVC sequence
MATCH (t1:Technique {cardId: 'corp_009_nvc_observation'})
MATCH (t2:Technique {cardId: 'corp_010_nvc_feeling'})
MERGE (t1)-[:PRECEDES]->(t2);

MATCH (t1:Technique {cardId: 'corp_010_nvc_feeling'})
MATCH (t2:Technique {cardId: 'corp_011_nvc_need'})
MERGE (t1)-[:PRECEDES]->(t2);

MATCH (t1:Technique {cardId: 'corp_011_nvc_need'})
MATCH (t2:Technique {cardId: 'corp_012_nvc_request'})
MERGE (t1)-[:PRECEDES]->(t2);

// Context -> SBI
MATCH (t1:Technique {cardId: 'corp_020_context_setting_feedback'})
MATCH (t2:Technique {cardId: 'corp_001_sbi_situation'})
MERGE (t1)-[:PRECEDES]->(t2);

// RC requires
MATCH (t1:Technique {cardId: 'corp_004_radical_candor_delivery'})
MATCH (t2:Technique {cardId: 'corp_019_psychological_safety_check'})
MERGE (t1)-[:REQUIRES]->(t2);

// Signal triggers
MATCH (sm:SignalMarker {cardId: 'corp_sig_karpman_victim'})
MATCH (t:Technique {cardId: 'corp_016_winners_triangle_vulnerable'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'corp_sig_karpman_persecutor'})
MATCH (t:Technique {cardId: 'corp_017_winners_triangle_assertive'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'corp_sig_karpman_rescuer'})
MATCH (t:Technique {cardId: 'corp_018_winners_triangle_caring'})
MERGE (sm)-[:TRIGGERS]->(t);

MATCH (sm:SignalMarker {cardId: 'corp_sig_contempt_marker'})
MATCH (e:EmotionalState {cardId: 'corp_emo_intervention_required'})
MERGE (sm)-[:ESCALATES_TO]->(e);

MATCH (sm:SignalMarker {cardId: 'corp_sig_stonewalling'})
MATCH (e:EmotionalState {cardId: 'corp_emo_repair_required'})
MERGE (sm)-[:TRIGGERS]->(e);

// Winner Triangle RESOLVES
MATCH (t:Technique {cardId: 'corp_016_winners_triangle_vulnerable'})
MATCH (sm:SignalMarker {cardId: 'corp_sig_karpman_victim'})
MERGE (t)-[:RESOLVES]->(sm);

MATCH (t:Technique {cardId: 'corp_017_winners_triangle_assertive'})
MATCH (sm:SignalMarker {cardId: 'corp_sig_karpman_persecutor'})
MERGE (t)-[:RESOLVES]->(sm);

MATCH (t:Technique {cardId: 'corp_018_winners_triangle_caring'})
MATCH (sm:SignalMarker {cardId: 'corp_sig_karpman_rescuer'})
MERGE (t)-[:RESOLVES]->(sm);

// CONTRAINDICATED edges
MATCH (t:Technique {cardId: 'corp_002_sbi_behavior'})
MATCH (e:EmotionalState {cardId: 'corp_emo_personality_attack_risk'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Behavior step blocked when framing contains personality attribution', severity: 'HIGH'}]->(e);

MATCH (t:Technique {cardId: 'corp_005_private_channel_enforcement'})
MATCH (e:EmotionalState {cardId: 'corp_emo_public_setting'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Critique in public destroys psychological safety', severity: 'CRITICAL'}]->(e);

MATCH (t:Technique {cardId: 'corp_006_immediate_feedback'})
MATCH (e:EmotionalState {cardId: 'corp_emo_high_arousal'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Immediate feedback during arousal degrades reception and relationship', severity: 'HIGH'}]->(e);

MATCH (t:Technique {cardId: 'corp_008_upward_feedback'})
MATCH (e:EmotionalState {cardId: 'corp_emo_public_setting'})
MERGE (t)-[:CONTRAINDICATED_WHEN {reason: 'Upward feedback without psychological safety carries career risk', severity: 'HIGH'}]->(e);

// CONTRADICTS edges
MATCH (t:Technique {cardId: 'corp_009_nvc_observation'})
MATCH (e:EmotionalState {cardId: 'corp_emo_interpretation_as_fact'})
MERGE (t)-[:CONTRADICTS]->(e);

MATCH (t:Technique {cardId: 'corp_012_nvc_request'})
MATCH (e:EmotionalState {cardId: 'corp_emo_demand'})
MERGE (t)-[:CONTRADICTS]->(e);

MATCH (t:Technique {cardId: 'corp_018_winners_triangle_caring'})
MATCH (e:EmotionalState {cardId: 'corp_emo_rescuer_enabling'})
MERGE (t)-[:CONTRADICTS]->(e);

MATCH (t:Technique {cardId: 'corp_024_criticism_vs_complaint'})
MATCH (e:EmotionalState {cardId: 'corp_emo_personality_attack_risk'})
MERGE (t)-[:CONTRADICTS]->(e);

// ENHANCES edges
MATCH (t:Technique {cardId: 'corp_003_sbi_impact'})
MATCH (e:EmotionalState {cardId: 'corp_emo_accountability'})
MERGE (t)-[:ENHANCES]->(e);

MATCH (t:Technique {cardId: 'corp_007_direct_report_feedback'})
MATCH (e:EmotionalState {cardId: 'corp_emo_psychological_safety'})
MERGE (t)-[:ENHANCES]->(e);

MATCH (t:Technique {cardId: 'corp_016_winners_triangle_vulnerable'})
MATCH (e:EmotionalState {cardId: 'corp_emo_psychological_safety'})
MERGE (t)-[:ENHANCES]->(e);

RETURN 'Corporate domain script complete' AS status;
