// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 03: FACS Action Unit Mappings
//
// Creates 6 FacsMapping nodes (one per FACS-coded emotion).
// Links each to existing EmotionalState nodes via INDICATES_EMOTION.
// Links each to relevant Techniques via TRIGGERS.
// Creates FACS PsychologicalModel node if absent.
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ── FACS PsychologicalModel node (parent framework) ──────────────────────────
MERGE (ps:PsychologicalModel {name: "FACS — Facial Action Coding System"})
ON CREATE SET ps.description = "Ekman and Friesen facial muscle action unit taxonomy for emotion classification",
              ps.createdInPhase = 6;

// ── facs_happiness ────────────────────────────────────────────────────────────
MERGE (f:FacsMapping {id: "facs_happiness"})
SET f += {
  emotionLabel:      "Happiness",
  auCombination:     "AU6+AU12",
  auCodes:           [6, 12],
  isMicroexpression: false,
  durationMs:        null,
  isUnilateral:      false,
  routingAction:     "Positive reinforcement; increase complexity; advance to next protocol step",
  conflictsVerbal:   false,
  modality:          "kinesic",
  createdInPhase:    6
};

// ── facs_sadness ──────────────────────────────────────────────────────────────
MERGE (f:FacsMapping {id: "facs_sadness"})
SET f += {
  emotionLabel:      "Sadness",
  auCombination:     "AU1+AU4+AU15",
  auCodes:           [1, 4, 15],
  isMicroexpression: false,
  durationMs:        null,
  isUnilateral:      false,
  routingAction:     "Empathic pacing; reflective listening; switch to SPIKES Emotion step",
  conflictsVerbal:   false,
  modality:          "kinesic",
  createdInPhase:    6
};

// ── facs_fear ─────────────────────────────────────────────────────────────────
MERGE (f:FacsMapping {id: "facs_fear"})
SET f += {
  emotionLabel:      "Fear",
  auCombination:     "AU1+AU2+AU4+AU5+AU7+AU20+AU26",
  auCodes:           [1, 2, 4, 5, 7, 20, 26],
  isMicroexpression: false,
  durationMs:        null,
  isUnilateral:      false,
  routingAction:     "Activate de-escalation; prevent confrontational assertions; use BCSM Steps 1-2",
  conflictsVerbal:   false,
  modality:          "kinesic",
  createdInPhase:    6
};

// ── facs_anger ────────────────────────────────────────────────────────────────
MERGE (f:FacsMapping {id: "facs_anger"})
SET f += {
  emotionLabel:      "Anger",
  auCombination:     "AU4+AU5+AU7+AU23",
  auCodes:           [4, 5, 7, 23],
  isMicroexpression: false,
  durationMs:        null,
  isUnilateral:      false,
  routingAction:     "Defensive negotiation mode; redirect to Objective Criteria; maintain Adult ego state",
  conflictsVerbal:   true,
  modality:          "kinesic",
  createdInPhase:    6
};

// ── facs_contempt ─────────────────────────────────────────────────────────────
MERGE (f:FacsMapping {id: "facs_contempt"})
SET f += {
  emotionLabel:      "Contempt",
  auCombination:     "AU12+AU14",
  auCodes:           [12, 14],
  isMicroexpression: false,
  durationMs:        null,
  isUnilateral:      true,
  routingAction:     "CRITICAL — flag communication breakdown risk; shift to mutual respect restoration protocol",
  conflictsVerbal:   true,
  modality:          "kinesic",
  createdInPhase:    6
};

// ── facs_microexpression ──────────────────────────────────────────────────────
MERGE (f:FacsMapping {id: "facs_microexpression"})
SET f += {
  emotionLabel:      "Microexpression",
  auCombination:     "any AU <1/15s contradicting baseline",
  auCodes:           [],
  isMicroexpression: true,
  durationMs:        67,
  isUnilateral:      false,
  routingAction:     "Flag domain for deeper probing; do NOT confront directly; increase clarification questions",
  conflictsVerbal:   true,
  modality:          "kinesic",
  createdInPhase:    6
};

// ── BELONGS_TO_MODEL: all FACS mappings → FACS framework ─────────────────────
MATCH (ps:PsychologicalModel {name: "FACS — Facial Action Coding System"})
MATCH (f:FacsMapping)
MERGE (f)-[:BELONGS_TO_MODEL {addedInPhase: 6}]->(ps);

// ── INDICATES_EMOTION links ───────────────────────────────────────────────────

MATCH (f:FacsMapping {id: "facs_happiness"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "calm"
MERGE (f)-[:INDICATES_EMOTION {confidence: 0.92, modalityWeight: 0.55, addedInPhase: 6}]->(e);

MATCH (f:FacsMapping {id: "facs_sadness"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "grief"
MERGE (f)-[:INDICATES_EMOTION {confidence: 0.88, modalityWeight: 0.55, addedInPhase: 6}]->(e);

MATCH (f:FacsMapping {id: "facs_fear"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "fear"
MERGE (f)-[:INDICATES_EMOTION {confidence: 0.91, modalityWeight: 0.55, addedInPhase: 6}]->(e);

MATCH (f:FacsMapping {id: "facs_anger"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "hostile"
MERGE (f)-[:INDICATES_EMOTION {confidence: 0.89, modalityWeight: 0.55, addedInPhase: 6}]->(e);

MATCH (f:FacsMapping {id: "facs_contempt"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "contemptuous"
MERGE (f)-[:INDICATES_EMOTION {confidence: 0.95, modalityWeight: 0.55, addedInPhase: 6}]->(e);

MATCH (f:FacsMapping {id: "facs_microexpression"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
MERGE (f)-[:INDICATES_EMOTION {confidence: 0.75, modalityWeight: 0.55, conflictsVerbal: true, addedInPhase: 6}]->(e);

MATCH (f:FacsMapping {id: "facs_microexpression"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "fear"
MERGE (f)-[:INDICATES_EMOTION {confidence: 0.70, modalityWeight: 0.55, conflictsVerbal: true, addedInPhase: 6}]->(e);

// ── TRIGGERS: FACS mappings → Techniques ──────────────────────────────────────

// Happiness → advance protocol — affirmation / rapport
MATCH (f:FacsMapping {id: "facs_happiness"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport" OR toLower(t.name) CONTAINS "affirm"
MERGE (f)-[:TRIGGERS {weight: 0.80, rationale: "Happiness FACS confirms engagement — reinforce and advance", addedInPhase: 6}]->(t);

// Sadness → SPIKES Emotion step / Empathic Validation
MATCH (f:FacsMapping {id: "facs_sadness"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "spikes"
   OR toLower(t.name) CONTAINS "reflective"
   OR toLower(t.name) CONTAINS "validat"
MERGE (f)-[:TRIGGERS {weight: 0.92, rationale: "Sadness FACS requires empathic pacing before any task act", addedInPhase: 6}]->(t);

// Fear → De-escalation / BCSM
MATCH (f:FacsMapping {id: "facs_fear"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escal"
   OR toLower(t.name) CONTAINS "deescal"
   OR toLower(t.name) CONTAINS "bcsm"
   OR toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "grounding"
   OR toLower(t.name) CONTAINS "calm"
MERGE (f)-[:TRIGGERS {weight: 0.95, rationale: "Fear FACS activates de-escalation pathway; Phase 1 empathy prereq required", addedInPhase: 6}]->(t);

// Anger → Objective Criteria / Separate People
MATCH (f:FacsMapping {id: "facs_anger"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "objective criteria"
   OR toLower(t.name) CONTAINS "separate people"
   OR toLower(t.name) CONTAINS "assertive"
   OR toLower(t.name) CONTAINS "empath"
MERGE (f)-[:TRIGGERS {weight: 0.90, rationale: "Anger FACS routes to Objective Criteria after empathy; never match aggression", addedInPhase: 6}]->(t);

// Contempt → mutual respect restoration / active listening
MATCH (f:FacsMapping {id: "facs_contempt"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "respect"
   OR toLower(t.name) CONTAINS "rapport"
MERGE (f)-[:TRIGGERS {weight: 0.93, rationale: "Contempt FACS is breakdown signal — active listening and respect restoration are the only safe paths", addedInPhase: 6}]->(t);

// Microexpression → clarification / probing questions
MATCH (f:FacsMapping {id: "facs_microexpression"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "clarif"
   OR toLower(t.name) CONTAINS "probing"
   OR toLower(t.name) CONTAINS "open"
   OR toLower(t.name) CONTAINS "reflective"
MERGE (f)-[:TRIGGERS {weight: 0.85, rationale: "Microexpression signals hidden affect — increase clarification; never direct confrontation", addedInPhase: 6}]->(t);
