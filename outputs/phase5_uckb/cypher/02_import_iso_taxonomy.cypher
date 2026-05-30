// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 5 — Step 02: Import ISO 24617-2 Taxonomy
//
// Creates:
//   6  DialogueDimension nodes (ISO 24617-2 §7 dimensions)
//  33  DialogueAct nodes with all 8 mandatory ISO properties
//  20  FUNCTIONAL_DEPENDENCY relationships (responds-to / initiates)
//  33  BELONGS_TO_DIMENSION relationships
//
// Depends on: 01_da_constraints.cypher (constraints must exist)
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────


// ── DIALOGUE DIMENSIONS (6) ───────────────────────────────────────────────────

MERGE (d:DialogueDimension {id: "dim_task"})
  SET d.name        = "Task",
      d.description = "Acts that directly advance the task or information exchange. The primary functional dimension.";

MERGE (d:DialogueDimension {id: "dim_turn_taking"})
  SET d.name        = "TurnTaking",
      d.description = "Acts that manage the allocation and transfer of speaking turns.";

MERGE (d:DialogueDimension {id: "dim_feedback"})
  SET d.name        = "Feedback",
      d.description = "Acts signalling whether a preceding act has been understood and accepted.";

MERGE (d:DialogueDimension {id: "dim_own_comm"})
  SET d.name        = "OwnComm",
      d.description = "Acts by which a speaker manages their own ongoing contribution (self-repair, stalling).";

MERGE (d:DialogueDimension {id: "dim_partner_comm"})
  SET d.name        = "PartnerComm",
      d.description = "Acts addressing the partner's contribution or communication difficulties.";

MERGE (d:DialogueDimension {id: "dim_social"})
  SET d.name        = "SocialObligations",
      d.description = "Conventional social acts governed by social norms and politeness obligations.";


// ── DIALOGUE ACTS — TASK DIMENSION (11) ──────────────────────────────────────

MERGE (a:DialogueAct {id: "da_request"})
  SET a.communicativeFunction  = "Request",
      a.dimension              = "Task",
      a.description            = "Speaker asks addressee to perform an action or provide information.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = true,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_inform"})
  SET a.communicativeFunction  = "Inform",
      a.dimension              = "Task",
      a.description            = "Speaker asserts a proposition as true for the addressee's benefit.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_confirm"})
  SET a.communicativeFunction  = "Confirm",
      a.dimension              = "Task",
      a.description            = "Speaker verifies or reaffirms a proposition previously asserted.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_disconfirm"})
  SET a.communicativeFunction  = "Disconfirm",
      a.dimension              = "Task",
      a.description            = "Speaker denies or corrects a proposition previously asserted.",
      a.sentiment              = "negative",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_answer"})
  SET a.communicativeFunction  = "Answer",
      a.dimension              = "Task",
      a.description            = "Speaker provides information in direct response to a prior Request.",
      a.sentiment              = "neutral",
      a.certainty              = "uncertain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_agreement"})
  SET a.communicativeFunction  = "Agreement",
      a.dimension              = "Task",
      a.description            = "Speaker commits to or aligns with a proposition or proposal.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = true,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_disagreement"})
  SET a.communicativeFunction  = "Disagreement",
      a.dimension              = "Task",
      a.description            = "Speaker opposes or rejects a proposition or proposal.",
      a.sentiment              = "negative",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = true,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_correction"})
  SET a.communicativeFunction  = "Correction",
      a.dimension              = "Task",
      a.description            = "Speaker replaces an erroneous proposition with a correct one.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_proposal"})
  SET a.communicativeFunction  = "Proposal",
      a.dimension              = "Task",
      a.description            = "Speaker proposes a course of action for addressee to accept or reject. Requires rapport/empathy prerequisite in high-stakes domains.",
      a.sentiment              = "neutral",
      a.certainty              = "uncertain",
      a.conditionality         = "if-then",
      a.typicalSender          = "Agent",
      a.requiresGrounding      = true,
      a.requiresInfluencePrereq = true;

MERGE (a:DialogueAct {id: "da_accept_proposal"})
  SET a.communicativeFunction  = "AcceptProposal",
      a.dimension              = "Task",
      a.description            = "Speaker accepts a previously proposed course of action.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_decline_proposal"})
  SET a.communicativeFunction  = "DeclineProposal",
      a.dimension              = "Task",
      a.description            = "Speaker declines a previously proposed course of action.",
      a.sentiment              = "negative",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = true,
      a.requiresInfluencePrereq = false;


// ── DIALOGUE ACTS — TURN-TAKING DIMENSION (5) ─────────────────────────────────

MERGE (a:DialogueAct {id: "da_offer_turn"})
  SET a.communicativeFunction  = "OfferTurn",
      a.dimension              = "TurnTaking",
      a.description            = "Speaker explicitly offers the speaking turn to the addressee.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Agent",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_take_turn"})
  SET a.communicativeFunction  = "TakeTurn",
      a.dimension              = "TurnTaking",
      a.description            = "Speaker claims the speaking turn.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_hold_turn"})
  SET a.communicativeFunction  = "HoldTurn",
      a.dimension              = "TurnTaking",
      a.description            = "Speaker signals intent to continue their turn (backchannels, fillers).",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_give_turn"})
  SET a.communicativeFunction  = "GiveTurn",
      a.dimension              = "TurnTaking",
      a.description            = "Speaker relinquishes the floor to the addressee.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_interrupt"})
  SET a.communicativeFunction  = "Interrupt",
      a.dimension              = "TurnTaking",
      a.description            = "Speaker takes the floor while the addressee is still speaking.",
      a.sentiment              = "negative",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;


// ── DIALOGUE ACTS — FEEDBACK DIMENSION (5) ────────────────────────────────────

MERGE (a:DialogueAct {id: "da_auto_positive"})
  SET a.communicativeFunction  = "AutoPositive",
      a.dimension              = "Feedback",
      a.description            = "Speaker signals they have understood the preceding utterance (e.g., 'uh-huh', 'okay').",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_auto_negative"})
  SET a.communicativeFunction  = "AutoNegative",
      a.dimension              = "Feedback",
      a.description            = "Speaker signals they have not understood or need clarification.",
      a.sentiment              = "negative",
      a.certainty              = "uncertain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_allo_positive"})
  SET a.communicativeFunction  = "AlloPositive",
      a.dimension              = "Feedback",
      a.description            = "Speaker evaluates the preceding act as adequate or correct.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_allo_negative"})
  SET a.communicativeFunction  = "AlloNegative",
      a.dimension              = "Feedback",
      a.description            = "Speaker evaluates the preceding act as inadequate or incorrect.",
      a.sentiment              = "negative",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_contact_check"})
  SET a.communicativeFunction  = "ContactCheck",
      a.dimension              = "Feedback",
      a.description            = "Speaker verifies that the communication channel is open (e.g., 'Are you still there?').",
      a.sentiment              = "neutral",
      a.certainty              = "uncertain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Agent",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;


// ── DIALOGUE ACTS — OWN-COMM DIMENSION (4) ────────────────────────────────────

MERGE (a:DialogueAct {id: "da_self_correction"})
  SET a.communicativeFunction  = "SelfCorrection",
      a.dimension              = "OwnComm",
      a.description            = "Speaker repairs their own preceding utterance.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_retraction"})
  SET a.communicativeFunction  = "Retraction",
      a.dimension              = "OwnComm",
      a.description            = "Speaker withdraws a previously made commitment or assertion.",
      a.sentiment              = "neutral",
      a.certainty              = "uncertain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_stalling"})
  SET a.communicativeFunction  = "Stalling",
      a.dimension              = "OwnComm",
      a.description            = "Speaker uses fillers or delays to hold the floor while processing (e.g., 'um', 'well...').",
      a.sentiment              = "neutral",
      a.certainty              = "uncertain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_reformulation"})
  SET a.communicativeFunction  = "Reformulation",
      a.dimension              = "OwnComm",
      a.description            = "Speaker restates their own prior utterance with different wording for clarity.",
      a.sentiment              = "neutral",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;


// ── DIALOGUE ACTS — PARTNER-COMM DIMENSION (3) ────────────────────────────────

MERGE (a:DialogueAct {id: "da_request_repair"})
  SET a.communicativeFunction  = "RequestRepair",
      a.dimension              = "PartnerComm",
      a.description            = "Speaker asks the addressee to repair or clarify a problematic utterance.",
      a.sentiment              = "neutral",
      a.certainty              = "uncertain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_indicate_understanding"})
  SET a.communicativeFunction  = "IndicateUnderstanding",
      a.dimension              = "PartnerComm",
      a.description            = "Speaker signals that they have understood the addressee's utterance.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Agent",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_clarification_request"})
  SET a.communicativeFunction  = "ClarificationRequest",
      a.dimension              = "PartnerComm",
      a.description            = "Speaker asks the addressee to elaborate or clarify a specific aspect of their utterance.",
      a.sentiment              = "neutral",
      a.certainty              = "uncertain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;


// ── DIALOGUE ACTS — SOCIAL-OBLIGATIONS DIMENSION (7) ─────────────────────────

MERGE (a:DialogueAct {id: "da_greeting"})
  SET a.communicativeFunction  = "Greeting",
      a.dimension              = "SocialObligations",
      a.description            = "Conventional opening act establishing social contact.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_goodbye"})
  SET a.communicativeFunction  = "Goodbye",
      a.dimension              = "SocialObligations",
      a.description            = "Conventional closing act terminating social contact.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_thanking"})
  SET a.communicativeFunction  = "Thanking",
      a.dimension              = "SocialObligations",
      a.description            = "Speaker expresses gratitude for a prior act by the addressee.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_apology"})
  SET a.communicativeFunction  = "Apology",
      a.dimension              = "SocialObligations",
      a.description            = "Speaker expresses regret for a prior act that affected the addressee negatively.",
      a.sentiment              = "negative",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_approval"})
  SET a.communicativeFunction  = "Approval",
      a.dimension              = "SocialObligations",
      a.description            = "Speaker expresses positive evaluation of the addressee's action or statement.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Agent",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_welcome"})
  SET a.communicativeFunction  = "Welcome",
      a.dimension              = "SocialObligations",
      a.description            = "Speaker accepts the addressee's thanks, indicating the prior act was not burdensome.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Agent",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;

MERGE (a:DialogueAct {id: "da_farewell"})
  SET a.communicativeFunction  = "Farewell",
      a.dimension              = "SocialObligations",
      a.description            = "Speaker signals the end of an interaction with a culturally appropriate closing ritual.",
      a.sentiment              = "positive",
      a.certainty              = "certain",
      a.conditionality         = "unconditional",
      a.typicalSender          = "Either",
      a.requiresGrounding      = false,
      a.requiresInfluencePrereq = false;


// ── BELONGS_TO_DIMENSION RELATIONSHIPS (33) ───────────────────────────────────

// Task
MATCH (a:DialogueAct {id: "da_request"}),       (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_inform"}),         (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_confirm"}),        (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_disconfirm"}),     (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_answer"}),         (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_agreement"}),      (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_disagreement"}),   (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_correction"}),     (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_proposal"}),       (d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_accept_proposal"}),(d:DialogueDimension {id: "dim_task"})       MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_decline_proposal"}),(d:DialogueDimension {id: "dim_task"})      MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
// TurnTaking
MATCH (a:DialogueAct {id: "da_offer_turn"}),     (d:DialogueDimension {id: "dim_turn_taking"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_take_turn"}),      (d:DialogueDimension {id: "dim_turn_taking"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_hold_turn"}),      (d:DialogueDimension {id: "dim_turn_taking"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_give_turn"}),      (d:DialogueDimension {id: "dim_turn_taking"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_interrupt"}),      (d:DialogueDimension {id: "dim_turn_taking"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
// Feedback
MATCH (a:DialogueAct {id: "da_auto_positive"}),  (d:DialogueDimension {id: "dim_feedback"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_auto_negative"}),  (d:DialogueDimension {id: "dim_feedback"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_allo_positive"}),  (d:DialogueDimension {id: "dim_feedback"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_allo_negative"}),  (d:DialogueDimension {id: "dim_feedback"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_contact_check"}),  (d:DialogueDimension {id: "dim_feedback"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
// OwnComm
MATCH (a:DialogueAct {id: "da_self_correction"}),(d:DialogueDimension {id: "dim_own_comm"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_retraction"}),     (d:DialogueDimension {id: "dim_own_comm"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_stalling"}),       (d:DialogueDimension {id: "dim_own_comm"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_reformulation"}),  (d:DialogueDimension {id: "dim_own_comm"})  MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
// PartnerComm
MATCH (a:DialogueAct {id: "da_request_repair"}),         (d:DialogueDimension {id: "dim_partner_comm"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_indicate_understanding"}),  (d:DialogueDimension {id: "dim_partner_comm"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_clarification_request"}),   (d:DialogueDimension {id: "dim_partner_comm"}) MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
// SocialObligations
MATCH (a:DialogueAct {id: "da_greeting"}),       (d:DialogueDimension {id: "dim_social"})    MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_goodbye"}),        (d:DialogueDimension {id: "dim_social"})    MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_thanking"}),       (d:DialogueDimension {id: "dim_social"})    MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_apology"}),        (d:DialogueDimension {id: "dim_social"})    MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_approval"}),       (d:DialogueDimension {id: "dim_social"})    MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_welcome"}),        (d:DialogueDimension {id: "dim_social"})    MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);
MATCH (a:DialogueAct {id: "da_farewell"}),       (d:DialogueDimension {id: "dim_social"})    MERGE (a)-[:BELONGS_TO_DIMENSION]->(d);


// ── FUNCTIONAL_DEPENDENCY RELATIONSHIPS (20) ──────────────────────────────────
// Semantics: (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b)
// means act A is a functional response to act B.

MATCH (a:DialogueAct {id: "da_answer"}),             (b:DialogueAct {id: "da_request"})    MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_confirm"}),            (b:DialogueAct {id: "da_inform"})     MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_disconfirm"}),         (b:DialogueAct {id: "da_inform"})     MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_correction"}),         (b:DialogueAct {id: "da_inform"})     MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_agreement"}),          (b:DialogueAct {id: "da_proposal"})   MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_accept_proposal"}),    (b:DialogueAct {id: "da_proposal"})   MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_decline_proposal"}),   (b:DialogueAct {id: "da_proposal"})   MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_disagreement"}),       (b:DialogueAct {id: "da_proposal"})   MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_auto_positive"}),      (b:DialogueAct {id: "da_inform"})     MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_auto_negative"}),      (b:DialogueAct {id: "da_inform"})     MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_allo_positive"}),      (b:DialogueAct {id: "da_request"})    MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_allo_negative"}),      (b:DialogueAct {id: "da_request"})    MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_welcome"}),            (b:DialogueAct {id: "da_thanking"})   MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_goodbye"}),            (b:DialogueAct {id: "da_greeting"})   MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "initiates"}]->(b);
MATCH (a:DialogueAct {id: "da_farewell"}),           (b:DialogueAct {id: "da_goodbye"})    MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_request_repair"}),     (b:DialogueAct {id: "da_inform"})     MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_clarification_request"}), (b:DialogueAct {id: "da_inform"})  MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_indicate_understanding"}), (b:DialogueAct {id: "da_inform"}) MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_stalling"}),           (b:DialogueAct {id: "da_request"})    MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);
MATCH (a:DialogueAct {id: "da_take_turn"}),          (b:DialogueAct {id: "da_offer_turn"}) MERGE (a)-[:FUNCTIONAL_DEPENDENCY {type: "responds-to"}]->(b);


// ── VERIFY ────────────────────────────────────────────────────────────────────
// MATCH (a:DialogueAct)-[:BELONGS_TO_DIMENSION]->(d:DialogueDimension)
// RETURN d.name AS dimension, count(a) AS acts ORDER BY dimension;
//
// Expected: 6 rows — Task:11, TurnTaking:5, Feedback:5, OwnComm:4, PartnerComm:3, SocialObligations:7
