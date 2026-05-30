// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 04: Prosodic Feature Nodes
//
// Creates 6 ProsodicFeature nodes (voice-channel signal features).
// Updates existing SignalMarker nodes with modality='prosodic' where applicable.
// Links ProsodicFeature → EmotionalState via INDICATES_EMOTION.
// Links ProsodicFeature → Technique via TRIGGERS.
// Safe to re-run — all statements use MERGE or SET (idempotent).
// ─────────────────────────────────────────────────────────────────────────────

// ── prosodic_pitch ────────────────────────────────────────────────────────────
MERGE (p:ProsodicFeature {id: "prosodic_pitch"})
SET p += {
  name:             "Fundamental Frequency (Pitch)",
  featureType:      "frequency",
  extractionDomain: "voice-only",
  highValueMeaning: "anxiety or excitement — rising contour or high variance",
  lowValueMeaning:  "depression or potential deception — monotone or falling contour",
  threshold:        "variance >2 standard deviations from baseline",
  signalsState:     "Fear",
  modality:         "paralinguistic",
  createdInPhase:   6
};

// ── prosodic_speech_rate ──────────────────────────────────────────────────────
MERGE (p:ProsodicFeature {id: "prosodic_speech_rate"})
SET p += {
  name:             "Speech Rate",
  featureType:      "rate",
  extractionDomain: "voice-only",
  highValueMeaning: "anxiety escalation — syllables per second rising above baseline",
  lowValueMeaning:  "cognitive overload or dissociation — syllables per second dropping",
  threshold:        "drop >30% from baseline OR rise >50% from baseline",
  signalsState:     "Dissociated",
  modality:         "paralinguistic",
  createdInPhase:   6
};

// ── prosodic_energy ───────────────────────────────────────────────────────────
MERGE (p:ProsodicFeature {id: "prosodic_energy"})
SET p += {
  name:             "Speech Energy (Amplitude)",
  featureType:      "energy",
  extractionDomain: "multimodal",
  highValueMeaning: "emotional activation and arousal — sudden amplitude spike",
  lowValueMeaning:  "suppression or withdrawal — amplitude below baseline",
  threshold:        "spike >10dB above running mean",
  signalsState:     "Hostile",
  modality:         "paralinguistic",
  createdInPhase:   6
};

// ── prosodic_voice_quality ────────────────────────────────────────────────────
MERGE (p:ProsodicFeature {id: "prosodic_voice_quality"})
SET p += {
  name:             "Voice Quality",
  featureType:      "quality",
  extractionDomain: "voice-only",
  highValueMeaning: "elevated arousal — breathiness, creakiness, or tremor detected",
  lowValueMeaning:  "calm or neutral baseline voice quality",
  threshold:        "tremor or creak exceeds baseline variability by >1.5 sigma",
  signalsState:     "Distress",
  modality:         "paralinguistic",
  createdInPhase:   6
};

// ── prosodic_pause_duration ───────────────────────────────────────────────────
MERGE (p:ProsodicFeature {id: "prosodic_pause_duration"})
SET p += {
  name:             "Pause Duration",
  featureType:      "duration",
  extractionDomain: "voice-only",
  highValueMeaning: "deception processing or trauma recall — latency before answering",
  lowValueMeaning:  "cognitive fluency and engagement — normal latency",
  threshold:        ">400ms before answering a direct question",
  signalsState:     "Distress",
  modality:         "paralinguistic",
  createdInPhase:   6
};

// ── prosodic_filler_frequency ─────────────────────────────────────────────────
MERGE (p:ProsodicFeature {id: "prosodic_filler_frequency"})
SET p += {
  name:             "Filler Word Frequency",
  featureType:      "count",
  extractionDomain: "voice-only",
  highValueMeaning: "working memory load — potential falsehood or confusion (um, uh, like)",
  lowValueMeaning:  "cognitive fluency — low filler baseline",
  threshold:        ">2x baseline filler rate",
  signalsState:     "Cognitive Overload",
  modality:         "paralinguistic",
  createdInPhase:   6
};

// ── Update existing SignalMarker nodes with prosodic modality tag ──────────────
// These SignalMarkers already exist from Phase 2/4 — add the modality='prosodic' flag
// and link them to the relevant ProsodicFeature node via TRIGGERED_BY.

MATCH (sm:SignalMarker)
WHERE toLower(sm.name) CONTAINS "speech rate drop"
   OR sm.id = "crisis_dispatch_030_speech_rate_drop"
SET sm.modality = "prosodic"
WITH sm
MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
MERGE (sm)-[:TRIGGERED_BY {addedInPhase: 6}]->(p);

MATCH (sm:SignalMarker)
WHERE toLower(sm.name) CONTAINS "speech rate spike"
   OR sm.id = "crisis_dispatch_031_speech_rate_spike"
SET sm.modality = "prosodic"
WITH sm
MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
MERGE (sm)-[:TRIGGERED_BY {addedInPhase: 6}]->(p);

MATCH (sm:SignalMarker)
WHERE toLower(sm.name) CONTAINS "filler increase"
   OR sm.id = "crisis_dispatch_032_filler_increase"
SET sm.modality = "prosodic"
WITH sm
MATCH (p:ProsodicFeature {id: "prosodic_filler_frequency"})
MERGE (sm)-[:TRIGGERED_BY {addedInPhase: 6}]->(p);

MATCH (sm:SignalMarker)
WHERE toLower(sm.name) CONTAINS "volume spike"
   OR sm.id = "crisis_dispatch_034_volume_spike"
SET sm.modality = "prosodic"
WITH sm
MATCH (p:ProsodicFeature {id: "prosodic_energy"})
MERGE (sm)-[:TRIGGERED_BY {addedInPhase: 6}]->(p);

// ── INDICATES_EMOTION: ProsodicFeature → EmotionalState ──────────────────────

MATCH (p:ProsodicFeature {id: "prosodic_pitch"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "fear"
MERGE (p)-[:INDICATES_EMOTION {direction: "high-variance", confidence: 0.78, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "dissociated"
MERGE (p)-[:INDICATES_EMOTION {direction: "drop", confidence: 0.85, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "fear"
MERGE (p)-[:INDICATES_EMOTION {direction: "rise", confidence: 0.80, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "cognitive overload"
MERGE (p)-[:INDICATES_EMOTION {direction: "drop", confidence: 0.82, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_energy"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "hostile"
MERGE (p)-[:INDICATES_EMOTION {direction: "spike", confidence: 0.88, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_energy"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "fear"
MERGE (p)-[:INDICATES_EMOTION {direction: "spike", confidence: 0.75, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_voice_quality"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
MERGE (p)-[:INDICATES_EMOTION {direction: "tremor", confidence: 0.82, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_voice_quality"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "overwhelmed"
MERGE (p)-[:INDICATES_EMOTION {direction: "creak", confidence: 0.78, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_pause_duration"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
MERGE (p)-[:INDICATES_EMOTION {direction: "long", confidence: 0.80, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_pause_duration"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "dissociated"
MERGE (p)-[:INDICATES_EMOTION {direction: "long", confidence: 0.77, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_filler_frequency"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "cognitive overload"
MERGE (p)-[:INDICATES_EMOTION {direction: "high", confidence: 0.83, addedInPhase: 6}]->(e);

MATCH (p:ProsodicFeature {id: "prosodic_filler_frequency"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "confused"
MERGE (p)-[:INDICATES_EMOTION {direction: "high", confidence: 0.79, addedInPhase: 6}]->(e);

// ── TRIGGERS: ProsodicFeature → Techniques ────────────────────────────────────

// Speech rate drop (dissociation/overload) → Active Listening + grounding
MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "ground"
   OR toLower(t.name) CONTAINS "empath"
MERGE (p)-[:TRIGGERS {
  weight: 0.88,
  condition: "speech-rate-drop",
  rationale: "Speech rate drop signals dissociation or overload — ground with active listening before advancing",
  addedInPhase: 6
}]->(t);

// Energy spike (anger/fear) → De-escalation
MATCH (p:ProsodicFeature {id: "prosodic_energy"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escal"
   OR toLower(t.name) CONTAINS "deescal"
   OR toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "calm"
MERGE (p)-[:TRIGGERS {
  weight: 0.90,
  condition: "energy-spike",
  rationale: "Energy spike signals emotional activation — de-escalation required before any influence act",
  addedInPhase: 6
}]->(t);

// Pause duration → Empathic Validation + Reflective Questioning
MATCH (p:ProsodicFeature {id: "prosodic_pause_duration"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "reflective"
   OR toLower(t.name) CONTAINS "validat"
   OR toLower(t.name) CONTAINS "active listen"
MERGE (p)-[:TRIGGERS {
  weight: 0.85,
  condition: "pause-over-400ms",
  rationale: "Long pause before direct question signals trauma or deception — validate before probing",
  addedInPhase: 6
}]->(t);

// Filler frequency → Simplify + Clarification
MATCH (p:ProsodicFeature {id: "prosodic_filler_frequency"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "clarif"
   OR toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "reflective"
MERGE (p)-[:TRIGGERS {
  weight: 0.82,
  condition: "filler-above-2x-baseline",
  rationale: "High filler rate signals working memory load — slow pace and clarify before proceeding",
  addedInPhase: 6
}]->(t);
