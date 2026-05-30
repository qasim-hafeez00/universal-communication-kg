// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 5 — Step 03: Link DialogueActs to Phase 4 Technique Nodes
//
// Creates:
//   TRIGGERS      — DialogueAct → Technique  (act type activates technique)
//   CONTRAINDICATED_WHEN — DialogueAct → EmotionalState (act blocked in state)
//   REQUIRES_ACT  — Technique → DialogueAct  (technique expects this incoming act)
//
// Depends on: Phase 4 Technique + EmotionalState nodes, Step 02 DialogueAct nodes.
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// TRIGGERS: DialogueAct → Technique
// Rationale: when the agent classifies an incoming utterance as act X,
// these techniques are the appropriate responses.
// ─────────────────────────────────────────────────────────────────────────────

// Request → Active Listening (gather full picture before responding)
MATCH (a:DialogueAct {id: "da_request"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listening"
MERGE (a)-[:TRIGGERS {weight: 0.92, rationale: "Request acts require full attentional processing before response"}]->(t);

// Request → Clarification / Reflective Questioning
MATCH (a:DialogueAct {id: "da_request"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "reflective" OR toLower(t.name) CONTAINS "clarif"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "Request acts often need clarification before execution"}]->(t);

// ClarificationRequest → Reflective Questioning
MATCH (a:DialogueAct {id: "da_clarification_request"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "reflective" OR toLower(t.name) CONTAINS "paraphras"
MERGE (a)-[:TRIGGERS {weight: 0.90, rationale: "Clarification requests are best met with reflective paraphrase to confirm meaning"}]->(t);

// Inform → Active Listening + Paraphrasing (confirm understanding)
MATCH (a:DialogueAct {id: "da_inform"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "paraphras" OR toLower(t.name) CONTAINS "active listen"
MERGE (a)-[:TRIGGERS {weight: 0.88, rationale: "Inform acts require paraphrase to confirm receipt and show understanding"}]->(t);

// Agreement → Empathic Validation (reinforce alignment)
MATCH (a:DialogueAct {id: "da_agreement"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath" OR toLower(t.name) CONTAINS "validat"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "Agreement acts should be reinforced with empathic validation"}]->(t);

// Disagreement → De-escalation techniques
MATCH (a:DialogueAct {id: "da_disagreement"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escal" OR toLower(t.name) CONTAINS "deescal"
   OR toLower(t.name) CONTAINS "motivational" OR toLower(t.name) CONTAINS "mi "
MERGE (a)-[:TRIGGERS {weight: 0.88, rationale: "Disagreement acts signal resistance — Motivational Interviewing and de-escalation reduce reactance"}]->(t);

// Disagreement → Empathic Validation first
MATCH (a:DialogueAct {id: "da_disagreement"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath"
MERGE (a)-[:TRIGGERS {weight: 0.90, rationale: "Phase 1 doctrine: acknowledge before countering — empathy must precede influence when disagreement is detected"}]->(t);

// Proposal → Motivational Interviewing (influence technique requiring prereq)
MATCH (a:DialogueAct {id: "da_proposal"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "motivational"
MERGE (a)-[:TRIGGERS {weight: 0.82, rationale: "Proposal acts require rapport and readiness — MI is the evidence-based bridge"}]->(t);

// DeclineProposal → BATNA / negotiation fallback
MATCH (a:DialogueAct {id: "da_decline_proposal"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "batna" OR toLower(t.name) CONTAINS "harvard"
   OR toLower(t.name) CONTAINS "reframe" OR toLower(t.name) CONTAINS "pivot"
MERGE (a)-[:TRIGGERS {weight: 0.80, rationale: "Declined proposal triggers BATNA evaluation or reframing before next offer"}]->(t);

// DeclineProposal → De-escalation (prevent interaction collapse)
MATCH (a:DialogueAct {id: "da_decline_proposal"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escal" OR toLower(t.name) CONTAINS "deescal"
MERGE (a)-[:TRIGGERS {weight: 0.75, rationale: "Declined proposals risk emotional escalation — de-escalation prevents breakdown"}]->(t);

// AutoNegative → Repair / Reformulation technique
MATCH (a:DialogueAct {id: "da_auto_negative"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "reformulat" OR toLower(t.name) CONTAINS "simplif"
   OR toLower(t.name) CONTAINS "rephras"
MERGE (a)-[:TRIGGERS {weight: 0.88, rationale: "Negative feedback (misunderstanding) triggers reformulation with lower syntactic density"}]->(t);

// AlloNegative → Empathic Validation + Repair
MATCH (a:DialogueAct {id: "da_allo_negative"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath" OR toLower(t.name) CONTAINS "validat"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "AlloNegative evaluation signals the partner judged the act inadequate — empathy before re-attempt"}]->(t);

// ContactCheck → Grounding / Acknowledgement technique
MATCH (a:DialogueAct {id: "da_contact_check"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "ground" OR toLower(t.name) CONTAINS "orient"
   OR toLower(t.name) CONTAINS "acknowledg"
MERGE (a)-[:TRIGGERS {weight: 0.90, rationale: "Contact check indicates possible disconnection — grounding re-establishes shared attention"}]->(t);

// Stalling → Relevance Theory cognitive-load reduction
MATCH (a:DialogueAct {id: "da_stalling"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen" OR toLower(t.name) CONTAINS "open-ended"
   OR toLower(t.name) CONTAINS "open ended" OR toLower(t.name) CONTAINS "wait time"
MERGE (a)-[:TRIGGERS {weight: 0.87, rationale: "Stalling signals cognitive processing load — reduce output density and wait"}]->(t);

// RequestRepair → Paraphrasing
MATCH (a:DialogueAct {id: "da_request_repair"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "paraphras" OR toLower(t.name) CONTAINS "active listen"
MERGE (a)-[:TRIGGERS {weight: 0.90, rationale: "RequestRepair means the agent's prior output was unclear — paraphrase to re-anchor"}]->(t);

// Greeting → Rapport-building techniques
MATCH (a:DialogueAct {id: "da_greeting"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport" OR toLower(t.name) CONTAINS "open"
   OR toLower(t.name) CONTAINS "greeting"
MERGE (a)-[:TRIGGERS {weight: 0.80, rationale: "Greeting opens rapport-building window — first impressions set tone for the session"}]->(t);

// Apology → Empathic Validation + SPIKES Emotion step
MATCH (a:DialogueAct {id: "da_apology"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath" OR toLower(t.name) CONTAINS "spikes"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "Apology acts signal emotional exposure — empathic validation prevents shame spiral"}]->(t);

// Interrupt → De-escalation + Turn management
MATCH (a:DialogueAct {id: "da_interrupt"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escal" OR toLower(t.name) CONTAINS "deescal"
   OR toLower(t.name) CONTAINS "boundary"
MERGE (a)-[:TRIGGERS {weight: 0.82, rationale: "Interruption may signal urgency or hostility — de-escalation with gentle boundary resets turn structure"}]->(t);

// SelfCorrection → Positive feedback / AutoPositive response
MATCH (a:DialogueAct {id: "da_self_correction"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "reinforc" OR toLower(t.name) CONTAINS "affirmation"
   OR toLower(t.name) CONTAINS "validat"
MERGE (a)-[:TRIGGERS {weight: 0.75, rationale: "Self-correction signals vulnerability — positive reinforcement sustains engagement"}]->(t);

// Confirm → Summarize / Closed Question
MATCH (a:DialogueAct {id: "da_confirm"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "summar" OR toLower(t.name) CONTAINS "closed question"
MERGE (a)-[:TRIGGERS {weight: 0.80, rationale: "Confirmation acts benefit from summary to lock shared understanding"}]->(t);

// Disconfirm → Correction + Active Listening
MATCH (a:DialogueAct {id: "da_disconfirm"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen" OR toLower(t.name) CONTAINS "open-ended"
MERGE (a)-[:TRIGGERS {weight: 0.83, rationale: "Disconfirmation requires re-gathering information before re-asserting"}]->(t);


// ─────────────────────────────────────────────────────────────────────────────
// CONTRAINDICATED_WHEN: DialogueAct → EmotionalState
// Phase 1 doctrine: influence acts MUST NOT fire when these states are active.
// ─────────────────────────────────────────────────────────────────────────────

// Proposal contraindicated when Panic — must not attempt influence while caller is panicking
MATCH (a:DialogueAct {id: "da_proposal"})
MATCH (e:EmotionalState)
WHERE toLower(e.name) CONTAINS "panic"
MERGE (a)-[:CONTRAINDICATED_WHEN {reason: "Phase 1 doctrine: influence requires emotional grounding first. Panic = BLOCKED."}]->(e);

// Proposal contraindicated when Dissociation
MATCH (a:DialogueAct {id: "da_proposal"})
MATCH (e:EmotionalState)
WHERE toLower(e.name) CONTAINS "dissociat"
MERGE (a)-[:CONTRAINDICATED_WHEN {reason: "Dissociation prevents informed consent. Route to grounding before any proposal."}]->(e);

// Proposal contraindicated when Grief (acute)
MATCH (a:DialogueAct {id: "da_proposal"})
MATCH (e:EmotionalState)
WHERE toLower(e.name) CONTAINS "grief"
MERGE (a)-[:CONTRAINDICATED_WHEN {reason: "Acute grief impairs decision-making capacity. Empathy and pacing must precede proposals."}]->(e);

// Interrupt contraindicated when Panic (amplifies distress)
MATCH (a:DialogueAct {id: "da_interrupt"})
MATCH (e:EmotionalState)
WHERE toLower(e.name) CONTAINS "panic"
MERGE (a)-[:CONTRAINDICATED_WHEN {reason: "Interrupting a panicking caller escalates distress and breaks trust. Hold turn instead."}]->(e);

// Interrupt contraindicated when Dissociation
MATCH (a:DialogueAct {id: "da_interrupt"})
MATCH (e:EmotionalState)
WHERE toLower(e.name) CONTAINS "dissociat"
MERGE (a)-[:CONTRAINDICATED_WHEN {reason: "Dissociated callers need gentle pacing. Interruption breaks the re-orientation process."}]->(e);


// ─────────────────────────────────────────────────────────────────────────────
// REQUIRES_ACT: Technique → DialogueAct
// The inverse lens: given a technique, what dialogue act must the agent receive
// (or be ready to respond to) for this technique to be applicable?
// ─────────────────────────────────────────────────────────────────────────────

// Active Listening requires detecting Request or Inform
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
MATCH (a:DialogueAct {id: "da_request"})
MERGE (t)-[:REQUIRES_ACT {note: "Active Listening is activated by incoming Request or Inform acts"}]->(a);

MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
MATCH (a:DialogueAct {id: "da_inform"})
MERGE (t)-[:REQUIRES_ACT {note: "Active Listening processes Inform acts to build shared understanding"}]->(a);

// Motivational Interviewing requires Agreement or Retraction (change talk)
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "motivational"
MATCH (a:DialogueAct {id: "da_agreement"})
MERGE (t)-[:REQUIRES_ACT {note: "MI builds on change talk — Agreement signals readiness to move"}]->(a);

MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "motivational"
MATCH (a:DialogueAct {id: "da_disagreement"})
MERGE (t)-[:REQUIRES_ACT {note: "MI addresses resistance represented by Disagreement acts"}]->(a);

// De-escalation techniques are activated by Disagreement + Interrupt
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escal" OR toLower(t.name) CONTAINS "deescal"
MATCH (a:DialogueAct {id: "da_interrupt"})
MERGE (t)-[:REQUIRES_ACT {note: "De-escalation responds to Interrupt and hostility markers"}]->(a);

MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escal" OR toLower(t.name) CONTAINS "deescal"
MATCH (a:DialogueAct {id: "da_disagreement"})
MERGE (t)-[:REQUIRES_ACT {note: "De-escalation responds to Disagreement acts before they escalate"}]->(a);


// ── VERIFY ────────────────────────────────────────────────────────────────────
// MATCH (a:DialogueAct)-[:TRIGGERS]->(t:Technique)
// RETURN a.communicativeFunction AS act, count(t) AS triggered_techniques
// ORDER BY triggered_techniques DESC;
//
// MATCH (a:DialogueAct)-[:CONTRAINDICATED_WHEN]->(e:EmotionalState)
// RETURN a.communicativeFunction, e.name;
