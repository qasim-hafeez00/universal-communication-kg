// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 06: Modality Weight Nodes (Mehrabian 7-38-55)
//
// Creates 3 ModalityWeight nodes encoding the priority ordering for
// conflict resolution when modalities produce incongruent signals.
// Applies ONLY to affective/attitudinal communication (not factual content).
// Creates MODALITY_OVERRIDES chain: kinesic > paralinguistic > semantic.
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ── modality_semantic (7%) ────────────────────────────────────────────────────
MERGE (m:ModalityWeight {id: "modality_semantic"})
SET m += {
  name:         "Semantic Content",
  modalityType: "semantic",
  weight:       0.07,
  priority:     3,
  description:  "The words themselves — lowest priority in affective conflict resolution",
  applyDomain:  "affective",
  createdInPhase: 6
};

// ── modality_paralinguistic (38%) ─────────────────────────────────────────────
MERGE (m:ModalityWeight {id: "modality_paralinguistic"})
SET m += {
  name:         "Paralinguistics",
  modalityType: "paralinguistic",
  weight:       0.38,
  priority:     2,
  description:  "Tone, pitch, speed, volume — overrides semantic content when incongruent in affective contexts",
  applyDomain:  "affective",
  createdInPhase: 6
};

// ── modality_kinesic (55%) ────────────────────────────────────────────────────
MERGE (m:ModalityWeight {id: "modality_kinesic"})
SET m += {
  name:         "Kinesics / Facial Expressions",
  modalityType: "kinesic",
  weight:       0.55,
  priority:     1,
  description:  "Facial expressions and body language — highest priority in affective conflict resolution",
  applyDomain:  "affective",
  createdInPhase: 6
};

// ── MODALITY_OVERRIDES: kinesic overrides both lower channels ─────────────────
MATCH (mk:ModalityWeight {id: "modality_kinesic"})
MATCH (ms:ModalityWeight {id: "modality_semantic"})
MERGE (mk)-[:MODALITY_OVERRIDES {
  weightRatio:       0.55 / 0.07,
  priorityDelta:     2,
  triggerCondition:  "affective incongruence detected — kinesic and semantic signals contradict",
  applyDomain:       "affective",
  addedInPhase:      6
}]->(ms);

MATCH (mk:ModalityWeight {id: "modality_kinesic"})
MATCH (mp:ModalityWeight {id: "modality_paralinguistic"})
MERGE (mk)-[:MODALITY_OVERRIDES {
  weightRatio:       0.55 / 0.38,
  priorityDelta:     1,
  triggerCondition:  "affective incongruence detected — kinesic and paralinguistic signals contradict",
  applyDomain:       "affective",
  addedInPhase:      6
}]->(mp);

// ── MODALITY_OVERRIDES: paralinguistic overrides semantic ─────────────────────
MATCH (mp:ModalityWeight {id: "modality_paralinguistic"})
MATCH (ms:ModalityWeight {id: "modality_semantic"})
MERGE (mp)-[:MODALITY_OVERRIDES {
  weightRatio:       0.38 / 0.07,
  priorityDelta:     1,
  triggerCondition:  "affective incongruence detected — paralinguistic and semantic signals contradict",
  applyDomain:       "affective",
  addedInPhase:      6
}]->(ms);
