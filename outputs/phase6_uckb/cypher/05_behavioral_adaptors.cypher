// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 05: Behavioral Adaptor Nodes
//
// Creates 4 BehavioralAdaptor nodes (kinesic stress indicators).
// Links each to EmotionalState nodes via INDICATES_EMOTION.
// Links each to Techniques via TRIGGERS.
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ── adaptor_self ──────────────────────────────────────────────────────────────
MERGE (b:BehavioralAdaptor {id: "adaptor_self"})
SET b += {
  name:                        "Self-Adaptor",
  adaptorType:                 "self",
  description:                 "Face touching, neck rubbing, hair manipulation — subconscious ANS arousal responses",
  arousalSignal:               "ANS arousal and elevated stress",
  routingAction:               "Activate grounding or de-escalation technique; slow interaction pace",
  requiresCulturalCalibration: false,
  modality:                    "kinesic",
  createdInPhase:              6
};

// ── adaptor_object ────────────────────────────────────────────────────────────
MERGE (b:BehavioralAdaptor {id: "adaptor_object"})
SET b += {
  name:                        "Object-Adaptor",
  adaptorType:                 "object",
  description:                 "Pen clicking, phone manipulation, object fidgeting",
  arousalSignal:               "Boredom or anxiety",
  routingAction:               "Check engagement level; increase interactivity or topic relevance",
  requiresCulturalCalibration: false,
  modality:                    "kinesic",
  createdInPhase:              6
};

// ── adaptor_emblem ────────────────────────────────────────────────────────────
MERGE (b:BehavioralAdaptor {id: "adaptor_emblem"})
SET b += {
  name:                        "Emblem Gesture",
  adaptorType:                 "emblem",
  description:                 "Deliberate culturally-specific gestures with precise semantic translations (thumbs up, head shake)",
  arousalSignal:               "Direct communicative intent — requires cultural calibration before interpretation",
  routingAction:               "Route to cultural calibration check before interpreting; flag for Phase 7 cross-cultural layer",
  requiresCulturalCalibration: true,
  modality:                    "kinesic",
  createdInPhase:              6
};

// ── adaptor_illustrator ───────────────────────────────────────────────────────
MERGE (b:BehavioralAdaptor {id: "adaptor_illustrator"})
SET b += {
  name:                        "Illustrator Gesture",
  adaptorType:                 "illustrator",
  description:                 "Involuntary hand movements tracking verbal rhythm; high rate = fluency; low rate = stress or rehearsed deception",
  arousalSignal:               "High rate = engagement and fluency; low rate = cognitive stress or rehearsed speech",
  routingAction:               "Low rate: flag for deception probe or distress check; high rate: advance interaction normally",
  requiresCulturalCalibration: false,
  modality:                    "kinesic",
  createdInPhase:              6
};

// ── INDICATES_EMOTION ─────────────────────────────────────────────────────────

MATCH (b:BehavioralAdaptor {id: "adaptor_self"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
MERGE (b)-[:INDICATES_EMOTION {confidence: 0.80, modality: "kinesic", addedInPhase: 6}]->(e);

MATCH (b:BehavioralAdaptor {id: "adaptor_self"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "overwhelmed"
MERGE (b)-[:INDICATES_EMOTION {confidence: 0.75, modality: "kinesic", addedInPhase: 6}]->(e);

MATCH (b:BehavioralAdaptor {id: "adaptor_object"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "ambivalent"
MERGE (b)-[:INDICATES_EMOTION {confidence: 0.70, modality: "kinesic", addedInPhase: 6}]->(e);

MATCH (b:BehavioralAdaptor {id: "adaptor_illustrator"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
MERGE (b)-[:INDICATES_EMOTION {confidence: 0.72, modality: "kinesic", condition: "low-rate-deviation", addedInPhase: 6}]->(e);

// ── TRIGGERS ──────────────────────────────────────────────────────────────────

// Self-adaptor → grounding / de-escalation
MATCH (b:BehavioralAdaptor {id: "adaptor_self"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "ground"
   OR toLower(t.name) CONTAINS "de-escal"
   OR toLower(t.name) CONTAINS "deescal"
   OR toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "calm"
MERGE (b)-[:TRIGGERS {
  weight: 0.85,
  rationale: "Self-adaptor signals ANS arousal — slow pace and ground before advancing task",
  addedInPhase: 6
}]->(t);

// Object-adaptor → engagement / rapport
MATCH (b:BehavioralAdaptor {id: "adaptor_object"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport"
   OR toLower(t.name) CONTAINS "open"
   OR toLower(t.name) CONTAINS "engage"
MERGE (b)-[:TRIGGERS {
  weight: 0.75,
  rationale: "Object-adaptor signals boredom or low engagement — increase interactivity with rapport or open questions",
  addedInPhase: 6
}]->(t);

// Emblem → cultural calibration (routes to Phase 7 layer)
MATCH (b:BehavioralAdaptor {id: "adaptor_emblem"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "cultural"
   OR toLower(t.name) CONTAINS "adapt"
   OR toLower(t.name) CONTAINS "clarif"
MERGE (b)-[:TRIGGERS {
  weight: 0.80,
  rationale: "Emblem requires cultural calibration before interpretation — route to cultural adaptation technique",
  addedInPhase: 6
}]->(t);

// Illustrator (low rate) → probing / empathic check
MATCH (b:BehavioralAdaptor {id: "adaptor_illustrator"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "probing"
   OR toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "clarif"
   OR toLower(t.name) CONTAINS "reflective"
MERGE (b)-[:TRIGGERS {
  weight: 0.78,
  condition: "low-rate",
  rationale: "Low illustrator rate signals stress or rehearsed deception — probe with empathic clarification",
  addedInPhase: 6
}]->(t);
