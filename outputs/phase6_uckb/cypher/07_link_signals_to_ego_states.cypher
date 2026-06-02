// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 07: Wire SignalMarkers → EgoStates (MAPS_TO_EGO_STATE)
//                         Wire Techniques → EgoStates (RESOLVES_EGO_STATE)
//
// MAPS_TO_EGO_STATE: existing SignalMarker nodes → EgoState (>=10 required for AC-5)
// RESOLVES_EGO_STATE: Technique → EgoState (target Adult, >=6 required)
// Safe to re-run — all statements use MERGE or MATCH+SET.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// MAPS_TO_EGO_STATE  (SignalMarker → EgoState)
// ════════════════════════════════════════════════════════════════════════════

// 1. Adapted Child Marker → ego_adapted_child
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "adapted child"
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.95,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// 2. Critical Parent Marker → ego_critical_parent
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "critical parent"
MATCH (e:EgoState {id: "ego_critical_parent"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.95,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// 3. Nurturing Parent Marker → ego_nurturing_parent
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "nurturing parent"
MATCH (e:EgoState {id: "ego_nurturing_parent"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.95,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// 4. Self-Blame Marker → ego_adapted_child (victim/helpless state)
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "self-blame"
   OR toLower(sm.name) CONTAINS "self blame"
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.88,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// 5. Contempt Marker → ego_critical_parent (persecutor role)
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "contempt"
MATCH (e:EgoState {id: "ego_critical_parent"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.85,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// 6. absolutist_language → ego_critical_parent
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "absolutist"
   OR (sm.cardId = "absolutist_language" OR sm.id = "absolutist_language")
MATCH (e:EgoState {id: "ego_critical_parent"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.87,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// 7. blame_language → ego_critical_parent
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "blame"
   OR (sm.cardId = "blame_language" OR sm.id = "blame_language")
MATCH (e:EgoState {id: "ego_critical_parent"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.90,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// 8. Filler Increase (prosodic) → ego_adapted_child (overwhelmed/child state)
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "filler"
   OR (sm.cardId IN ["crisis_dispatch_032_filler_increase"] OR sm.id IN ["crisis_dispatch_032_filler_increase"])
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.72,
  markerStrength: "moderate",
  addedInPhase: 6
}]->(e);

// 9. Speech Rate Drop → ego_adapted_child (dissociation → child regression)
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "speech rate drop"
   OR (sm.cardId = "crisis_dispatch_030_speech_rate_drop" OR sm.id = "crisis_dispatch_030_speech_rate_drop")
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.75,
  markerStrength: "moderate",
  addedInPhase: 6
}]->(e);

// 10. ambivalence / Ambivalent signal → ego_adapted_child (conflicted child state)
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "ambivalen"
   OR (sm.cardId = "ambivalence" OR sm.id = "ambivalence")
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.68,
  markerStrength: "moderate",
  addedInPhase: 6
}]->(e);

// 11. anxiety_signal → ego_adapted_child (anxious child state)
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "anxiety"
   OR (sm.cardId = "anxiety_signal" OR sm.id = "anxiety_signal")
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.73,
  markerStrength: "moderate",
  addedInPhase: 6
}]->(e);

// 12. Dissociation Risk Marker → ego_adapted_child
MATCH (sm:SignalMarker) WHERE toLower(sm.name) CONTAINS "dissociat"
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (sm)-[:MAPS_TO_EGO_STATE {
  confidence: 0.82,
  markerStrength: "strong",
  addedInPhase: 6
}]->(e);

// ════════════════════════════════════════════════════════════════════════════
// RESOLVES_EGO_STATE  (Technique → EgoState target)
// Expresses: "this technique is the clinical path toward moving the
// interlocutor to the Adult (target) state"
// ════════════════════════════════════════════════════════════════════════════

// Active Listening → resolves ego_adapted_child → ego_adult
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "active listen"
MATCH (from_e:EgoState {id: "ego_adapted_child"})
MATCH (to_e:EgoState {id: "ego_adult"})
MERGE (t)-[:RESOLVES_EGO_STATE {
  fromEgoState: "Adapted Child",
  targetEgoState: "Adult",
  rationale: "Active listening validates without rescuing — enables transition to Adult state",
  addedInPhase: 6
}]->(to_e);

// Empathic Validation → resolves ego_adapted_child → ego_adult
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "empath" AND toLower(t.name) CONTAINS "validat"
MATCH (to_e:EgoState {id: "ego_adult"})
MERGE (t)-[:RESOLVES_EGO_STATE {
  fromEgoState: "Adapted Child",
  targetEgoState: "Adult",
  rationale: "Empathic validation acknowledges need without rescuing — scaffolds Adult emergence",
  addedInPhase: 6
}]->(to_e);

// Motivational Interviewing → resolves ego_adapted_child → ego_adult
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "motivational"
MATCH (to_e:EgoState {id: "ego_adult"})
MERGE (t)-[:RESOLVES_EGO_STATE {
  fromEgoState: "Adapted Child",
  targetEgoState: "Adult",
  rationale: "MI evokes the interlocutor's own Adult motivation rather than supplying external rescue",
  addedInPhase: 6
}]->(to_e);

// Objective Criteria → resolves ego_critical_parent → ego_adult
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "objective criteria"
MATCH (to_e:EgoState {id: "ego_adult"})
MERGE (t)-[:RESOLVES_EGO_STATE {
  fromEgoState: "Critical Parent",
  targetEgoState: "Adult",
  rationale: "Objective criteria replace blame-based framing with factual Adult discourse",
  addedInPhase: 6
}]->(to_e);

// Separate People From Problem → resolves ego_critical_parent → ego_adult
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "separate people"
MATCH (to_e:EgoState {id: "ego_adult"})
MERGE (t)-[:RESOLVES_EGO_STATE {
  fromEgoState: "Critical Parent",
  targetEgoState: "Adult",
  rationale: "Depersonalizing the problem de-activates the Persecutor role and enables Adult problem-solving",
  addedInPhase: 6
}]->(to_e);

// Rapport-building → resolves ego_nurturing_parent → ego_adult
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "rapport"
MATCH (to_e:EgoState {id: "ego_adult"})
MERGE (t)-[:RESOLVES_EGO_STATE {
  fromEgoState: "Nurturing Parent",
  targetEgoState: "Adult",
  rationale: "Balanced rapport shifts over-helping to mutual engagement — scaffolds Adult interaction",
  addedInPhase: 6
}]->(to_e);

// ════════════════════════════════════════════════════════════════════════════
// PRECEDES links required for AC-7 Phase 1 doctrine compliance
//
// Techniques that requiresEmotionalClearance=true must have an empathy-
// prerequisite technique PRECEDES them, or they violate the doctrine.
// These three techniques are reachable from EgoState TRIGGERS and need prereqs.
// ════════════════════════════════════════════════════════════════════════════

// Active Listening PRECEDES Rapport Checkpoint
MATCH (prereq:Technique {isEmotionalPrerequisite: true})
WHERE toLower(prereq.name) CONTAINS "active listen"
MATCH (t:Technique {name: "Rapport Checkpoint"})
MERGE (prereq)-[:PRECEDES {
  rationale: "Rapport Checkpoint requires active listening as emotional prerequisite",
  addedInPhase: 6
}]->(t);

// Active Listening PRECEDES Anchoring with Objective Criteria
MATCH (prereq:Technique {isEmotionalPrerequisite: true})
WHERE toLower(prereq.name) CONTAINS "active listen"
MATCH (t:Technique {name: "Anchoring with Objective Criteria"})
MERGE (prereq)-[:PRECEDES {
  rationale: "Objective criteria anchoring requires active listening to surface the other party's criteria first",
  addedInPhase: 6
}]->(t);

// Empathic Validation PRECEDES Objection Validation
MATCH (prereq:Technique {isEmotionalPrerequisite: true})
WHERE toLower(prereq.name) CONTAINS "empath"
MATCH (t:Technique {name: "Objection Validation"})
MERGE (prereq)-[:PRECEDES {
  rationale: "Objection validation requires empathic validation before addressing objection content",
  addedInPhase: 6
}]->(t);
