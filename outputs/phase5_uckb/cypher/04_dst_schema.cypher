// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 5 — Step 04: Dialogue State Tracking (DST) Schema
//
// Creates:
//   15 DomainSlot nodes     (5 slots × 3 domains)
//    3 BDIState nodes       (Belief-Desire-Intention templates, one per domain)
//   15 HAS_SLOT groupings   (domain → slots)
//
// DST slots define the structured information the agent must track during
// each multi-turn conversation. BDI templates define how the agent reasons
// about its next action given the current slot state.
//
// Depends on: 01_da_constraints.cypher
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────


// ── DOMAIN SLOTS — CRISIS DISPATCH (5) ───────────────────────────────────────

MERGE (s:DomainSlot {id: "slot_dispatch_location"})
  SET s.slotName    = "location",
      s.domain      = "Crisis Dispatch",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "street_address|gps_coords|landmark|unknown",
      s.description = "Physical location of the emergency. Required for dispatch routing.";

MERGE (s:DomainSlot {id: "slot_dispatch_emergency_type"})
  SET s.slotName    = "emergency_type",
      s.domain      = "Crisis Dispatch",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "medical|fire|violent_crime|mental_health|traffic|other",
      s.description = "Nature of the emergency determining resource dispatch.";

MERGE (s:DomainSlot {id: "slot_dispatch_emotional_state"})
  SET s.slotName    = "caller_emotional_state",
      s.domain      = "Crisis Dispatch",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "calm|anxious|panic|dissociated|hostile|grief",
      s.description = "Current emotional state of the caller — drives routing through de-escalation protocols.";

MERGE (s:DomainSlot {id: "slot_dispatch_compliance"})
  SET s.slotName    = "compliance_level",
      s.domain      = "Crisis Dispatch",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "cooperative|resistant|dissociated",
      s.description = "Degree of caller cooperation with agent instructions.";

MERGE (s:DomainSlot {id: "slot_dispatch_protocol_step"})
  SET s.slotName    = "current_protocol_step",
      s.domain      = "Crisis Dispatch",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "BCSM_1_Contact|BCSM_2_Empathy|BCSM_3_Rapport|BCSM_4_Influence|BCSM_5_Change",
      s.description = "Current step in the Behavioral Change Stairway Model (BCSM) protocol.";


// ── DOMAIN SLOTS — CLINICAL / MEDICAL (5) ────────────────────────────────────

MERGE (s:DomainSlot {id: "slot_clinical_patient_concern"})
  SET s.slotName    = "patient_concern",
      s.domain      = "Clinical",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "diagnosis_news|treatment_decision|prognosis|pain_management|end_of_life|other",
      s.description = "Primary clinical concern that prompted the conversation.";

MERGE (s:DomainSlot {id: "slot_clinical_emotional_state"})
  SET s.slotName    = "caller_emotional_state",
      s.domain      = "Clinical",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "calm|anxious|denial|grief|anger|acceptance",
      s.description = "Patient or family member's emotional state — determines SPIKES step.";

MERGE (s:DomainSlot {id: "slot_clinical_compliance"})
  SET s.slotName    = "compliance_level",
      s.domain      = "Clinical",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "cooperative|resistant|ambivalent|dissociated",
      s.description = "Patient engagement with the clinical conversation.";

MERGE (s:DomainSlot {id: "slot_clinical_consent"})
  SET s.slotName    = "informed_consent",
      s.domain      = "Clinical",
      s.valueType   = "boolean",
      s.filled      = false,
      s.validValues = "true|false|pending",
      s.description = "Whether informed consent for the discussed procedure or disclosure has been obtained.";

MERGE (s:DomainSlot {id: "slot_clinical_protocol_step"})
  SET s.slotName    = "current_protocol_step",
      s.domain      = "Clinical",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "SPIKES_S|SPIKES_P|SPIKES_I|SPIKES_K|SPIKES_E|SPIKES_S2",
      s.description = "Current step in the SPIKES protocol for breaking bad news.";


// ── DOMAIN SLOTS — SALES & NEGOTIATION (5) ───────────────────────────────────

MERGE (s:DomainSlot {id: "slot_sales_buyer_stage"})
  SET s.slotName    = "buyer_stage",
      s.domain      = "Sales",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "awareness|interest|evaluation|decision|purchase",
      s.description = "Buyer's current stage in the decision funnel — determines SPIN question type.";

MERGE (s:DomainSlot {id: "slot_sales_objection"})
  SET s.slotName    = "active_objection",
      s.domain      = "Sales",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "price|timing|authority|need|trust|none",
      s.description = "The buyer's current primary objection category.";

MERGE (s:DomainSlot {id: "slot_sales_emotional_state"})
  SET s.slotName    = "caller_emotional_state",
      s.domain      = "Sales",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "curious|skeptical|interested|resistant|convinced",
      s.description = "Buyer's emotional disposition in the current turn.";

MERGE (s:DomainSlot {id: "slot_sales_compliance"})
  SET s.slotName    = "compliance_level",
      s.domain      = "Sales",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "cooperative|resistant|ambivalent",
      s.description = "Buyer's openness to the agent's framing and suggestions.";

MERGE (s:DomainSlot {id: "slot_sales_protocol_step"})
  SET s.slotName    = "current_protocol_step",
      s.domain      = "Sales",
      s.valueType   = "string",
      s.filled      = false,
      s.validValues = "SPIN_Situation|SPIN_Problem|SPIN_Implication|SPIN_NeedPayoff",
      s.description = "Current step in the SPIN Selling question sequence.";


// ── BDI STATE TEMPLATES (3) ───────────────────────────────────────────────────

MERGE (b:BDIState {id: "bdi_crisis"})
  SET b.domain             = "Crisis Dispatch",
      b.beliefTemplate     = "caller_emotional_state + location_slot_status + compliance_level + current_protocol_step",
      b.desireTemplate     = "caller_reaches_calm_cooperative_state_with_location_confirmed",
      b.intentionTemplate  = "execute_next_BCSM_step_given_current_belief_state",
      b.description        = "BDI template for Crisis Dispatch: safety first, emotional grounding before influence.";

MERGE (b:BDIState {id: "bdi_clinical"})
  SET b.domain             = "Clinical",
      b.beliefTemplate     = "patient_concern + informed_consent_status + emotional_state + current_SPIKES_step",
      b.desireTemplate     = "patient_understands_news_and_consents_to_next_step",
      b.intentionTemplate  = "execute_next_SPIKES_step_with_empathy_prerequisite_satisfied",
      b.description        = "BDI template for Clinical: truth-telling with compassion, consent before disclosure.";

MERGE (b:BDIState {id: "bdi_sales"})
  SET b.domain             = "Sales",
      b.beliefTemplate     = "buyer_stage + active_objection + emotional_state + compliance_level",
      b.desireTemplate     = "buyer_reaches_conviction_with_objections_resolved",
      b.intentionTemplate  = "execute_next_SPIN_step_matching_buyer_stage",
      b.description        = "BDI template for Sales: objection handling through needs clarification before proposals.";


// ── HAS_SLOT GROUPINGS ────────────────────────────────────────────────────────
// Link BDIState to its domain slots for fast DST lookups

// Crisis Dispatch
MATCH (b:BDIState {id: "bdi_crisis"}), (s:DomainSlot {id: "slot_dispatch_location"})         MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_crisis"}), (s:DomainSlot {id: "slot_dispatch_emergency_type"})    MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_crisis"}), (s:DomainSlot {id: "slot_dispatch_emotional_state"})   MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_crisis"}), (s:DomainSlot {id: "slot_dispatch_compliance"})        MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_crisis"}), (s:DomainSlot {id: "slot_dispatch_protocol_step"})     MERGE (b)-[:HAS_SLOT]->(s);

// Clinical
MATCH (b:BDIState {id: "bdi_clinical"}), (s:DomainSlot {id: "slot_clinical_patient_concern"}) MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_clinical"}), (s:DomainSlot {id: "slot_clinical_emotional_state"}) MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_clinical"}), (s:DomainSlot {id: "slot_clinical_compliance"})      MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_clinical"}), (s:DomainSlot {id: "slot_clinical_consent"})         MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_clinical"}), (s:DomainSlot {id: "slot_clinical_protocol_step"})   MERGE (b)-[:HAS_SLOT]->(s);

// Sales
MATCH (b:BDIState {id: "bdi_sales"}), (s:DomainSlot {id: "slot_sales_buyer_stage"})           MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_sales"}), (s:DomainSlot {id: "slot_sales_objection"})             MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_sales"}), (s:DomainSlot {id: "slot_sales_emotional_state"})       MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_sales"}), (s:DomainSlot {id: "slot_sales_compliance"})            MERGE (b)-[:HAS_SLOT]->(s);
MATCH (b:BDIState {id: "bdi_sales"}), (s:DomainSlot {id: "slot_sales_protocol_step"})         MERGE (b)-[:HAS_SLOT]->(s);


// ── LINK SLOTS TO RELEVANT DIALOGUE ACTS (slot-fill requests) ────────────────
// When a slot is unfilled, the agent should issue a Request act for that slot.
// REQUIRES_ACT captures which DialogueAct is needed to fill each slot.

MATCH (s:DomainSlot {id: "slot_dispatch_location"}),      (a:DialogueAct {id: "da_request"})  MERGE (s)-[:REQUIRES_ACT {note: "Location slot must be filled via a Request act"}]->(a);
MATCH (s:DomainSlot {id: "slot_dispatch_emergency_type"}), (a:DialogueAct {id: "da_request"})  MERGE (s)-[:REQUIRES_ACT {note: "Emergency type slot must be filled via a Request act"}]->(a);
MATCH (s:DomainSlot {id: "slot_clinical_patient_concern"}),(a:DialogueAct {id: "da_request"})  MERGE (s)-[:REQUIRES_ACT {note: "Patient concern slot must be filled via a Request act"}]->(a);
MATCH (s:DomainSlot {id: "slot_clinical_consent"}),        (a:DialogueAct {id: "da_confirm"})  MERGE (s)-[:REQUIRES_ACT {note: "Consent slot filled by a Confirm act from the patient"}]->(a);
MATCH (s:DomainSlot {id: "slot_sales_buyer_stage"}),       (a:DialogueAct {id: "da_clarification_request"}) MERGE (s)-[:REQUIRES_ACT {note: "Buyer stage inferred from ClarificationRequest exchanges"}]->(a);
MATCH (s:DomainSlot {id: "slot_sales_objection"}),         (a:DialogueAct {id: "da_disagreement"}) MERGE (s)-[:REQUIRES_ACT {note: "Active objection surfaces via Disagreement acts"}]->(a);


// ── VERIFY ────────────────────────────────────────────────────────────────────
// MATCH (b:BDIState)-[:HAS_SLOT]->(s:DomainSlot)
// RETURN b.domain, collect(s.slotName) AS slots ORDER BY b.domain;
//
// Expected: 3 rows, each with 5 slots.
//
// MATCH (s:DomainSlot {domain: "Crisis Dispatch"})
// RETURN s.slotName, s.validValues;
