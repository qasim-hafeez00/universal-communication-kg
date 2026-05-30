// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 06: Emblem Recalibration (RECALIBRATE_IN)
//
// Fulfills the Phase 6 open hook:
//   adaptor_emblem.requiresCulturalCalibration = true
//
// Adds RECALIBRATE_IN relationships:
//   BehavioralAdaptor (adaptor_emblem) -> CulturalContext
//   FacsMapping (facs_microexpression) -> CulturalContext
//
// Each relationship carries gesture/signal-specific recalibration metadata.
// Rationale: from guide — gaze aversion is culturally politeness in Japan,
// Black American, Turkish-Dutch, South Asian, East African, Indigenous cultures.
//
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// RECALIBRATE_IN — adaptor_emblem -> CulturalContext
// ════════════════════════════════════════════════════════════════════════════

// Thumbs-up offensive in Middle East / Arab cultures
MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Power Distance","PowerDistanceHigh"]
MERGE (ba)-[:RECALIBRATE_IN {
  gesture:       "thumbs_up",
  normalMeaning: "approval_western",
  reinterpretAs: "offensive_gesture_Middle_East",
  flag:          "cultural_mismatch_risk",
  severity:      "high",
  addedInPhase:  7
}]->(c);

// Head-shake = agreement in South Asia (India, Pakistan, Bangladesh, Sri Lanka)
MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Collectivism","CollectivismHigh"]
MERGE (ba)-[:RECALIBRATE_IN {
  gesture:       "head_shake_lateral",
  normalMeaning: "disagreement_western",
  reinterpretAs: "agreement_South_Asia",
  flag:          "cultural_mismatch_risk",
  severity:      "high",
  addedInPhase:  7
}]->(c);

// Sustained eye contact = aggression in many East Asian + reactive cultures
MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})
MATCH (c:CulturalContext) WHERE c.name IN ["Reactive"]
MERGE (ba)-[:RECALIBRATE_IN {
  gesture:       "sustained_direct_eye_contact",
  normalMeaning: "confidence_western",
  reinterpretAs: "aggression_or_disrespect_East_Asian",
  flag:          "cultural_mismatch_risk",
  severity:      "moderate",
  addedInPhase:  7
}]->(c);

// General high-context emblem rule: all emblems require calibration
MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Context","HighContext"]
MERGE (ba)-[:RECALIBRATE_IN {
  gesture:       "any_emblem",
  normalMeaning: "culture_specific",
  reinterpretAs: "verify_before_interpreting",
  flag:          "always_verify",
  severity:      "moderate",
  addedInPhase:  7
}]->(c);

// OK gesture (circle with thumb+index) = money (Japan), zero/worthless (France), obscene (Brazil/Turkey)
MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})
MATCH (c:CulturalContext) WHERE c.name IN ["Multi-Active","MultiActive"]
MERGE (ba)-[:RECALIBRATE_IN {
  gesture:       "ok_circle_gesture",
  normalMeaning: "okay_approval_western",
  reinterpretAs: "money_Japan_OR_obscene_Brazil_Turkey",
  flag:          "cultural_mismatch_risk",
  severity:      "high",
  addedInPhase:  7
}]->(c);

// ════════════════════════════════════════════════════════════════════════════
// RECALIBRATE_IN — facs_microexpression -> CulturalContext
// Gaze aversion recalibration per guide (gaze aversion ≠ deception)
// ════════════════════════════════════════════════════════════════════════════

// Gaze aversion = cultural politeness in collectivist cultures
// (Black American, Turkish-Dutch, South Asian, East African, Indigenous cultures)
MATCH (facs:FacsMapping {id: "facs_microexpression"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Collectivism","CollectivismHigh"]
MERGE (facs)-[:RECALIBRATE_IN {
  signal:        "gaze_aversion",
  normalRoute:   "deception_indicator_flag",
  reinterpretAs: "cultural_politeness_marker",
  suppressFlag:  "deception_flag",
  rationale:     "Police accuracy on gaze-aversion deception cue is at chance level (52-54%); in collectivist cultures averted gaze signals respect not deception",
  addedInPhase:  7
}]->(c);

// Gaze aversion = active respect in reactive cultures (Japan, East Asia)
MATCH (facs:FacsMapping {id: "facs_microexpression"})
MATCH (c:CulturalContext) WHERE c.name IN ["Reactive"]
MERGE (facs)-[:RECALIBRATE_IN {
  signal:        "gaze_aversion",
  normalRoute:   "deception_indicator_flag",
  reinterpretAs: "cultural_respect_marker",
  suppressFlag:  "deception_flag",
  rationale:     "In reactive cultures (Japan, Korea, parts of East Africa) sustained gaze is aggressive; aversion signals active respectful listening",
  addedInPhase:  7
}]->(c);

// Gaze aversion = deference in high-context cultures
MATCH (facs:FacsMapping {id: "facs_microexpression"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Context","HighContext"]
MERGE (facs)-[:RECALIBRATE_IN {
  signal:        "gaze_aversion",
  normalRoute:   "deception_indicator_flag",
  reinterpretAs: "deference_signal",
  suppressFlag:  "deception_flag",
  rationale:     "High-context cultures communicate deference and respect through indirect gaze; investigative interpretation must be suppressed",
  addedInPhase:  7
}]->(c);

// ════════════════════════════════════════════════════════════════════════════
// RECALIBRATE_IN — facs_sadness -> PolychronicTime
// Extended grief expression is culturally expected (do not rush to resolution)
// ════════════════════════════════════════════════════════════════════════════

MATCH (facs:FacsMapping {id: "facs_sadness"})
MATCH (c:CulturalContext) WHERE c.name IN ["Polychronic Time","PolychronicTime","Multi-Active","MultiActive"]
MERGE (facs)-[:RECALIBRATE_IN {
  signal:        "extended_sadness_expression",
  normalRoute:   "immediate_empathic_response_then_advance",
  reinterpretAs: "culturally_normative_extended_grief_expression",
  flag:          "do_not_rush_to_resolution",
  rationale:     "Multi-active and polychronic cultures allow extended emotional expression; rushing to resolution is perceived as dismissive",
  addedInPhase:  7
}]->(c);
