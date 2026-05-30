// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 03: CulturalAdaptationRule nodes + APPLIES_RULE
//
// 10 CulturalAdaptationRule nodes encoding behavioral changes the agent
// applies per cultural profile or dimensional context.
//
// APPLIES_RULE fires from:
//   - Named CulturalProfile nodes (specific cultures)
//   - Abstract CulturalContext dimensional nodes (dimension-level firing)
//
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// CulturalAdaptationRule nodes
// ════════════════════════════════════════════════════════════════════════════

MERGE (r:CulturalAdaptationRule {id: "rule_face_saving"})
SET r += {
  name:          "Face-Saving Protocol",
  trigger:       "CollectivismHigh + HighContext",
  agentBehavior: "Phrase rejection indirectly; never publicly contradict; offer alternatives rather than outright refusals; preserve the other party's social image",
  rationale:     "In collectivist high-context cultures, public loss of face is a severe social transgression that permanently damages relationship capital",
  appliesWhen:   ["CollectivismHigh", "HighContext"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_indirect_rejection"})
SET r += {
  name:          "Indirect Rejection Phrasing",
  trigger:       "HighContext + Reactive",
  agentBehavior: "Interpret 'that may be difficult' or 'we will consider it' as polite refusals; do not press for explicit no; accept indirect declination without escalation",
  rationale:     "High-context reactive cultures use indirect phrasing to decline without confrontation; pressing for explicit refusal is culturally aggressive",
  appliesWhen:   ["HighContext", "Reactive"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_deference_authority"})
SET r += {
  name:          "Deference to Authority Register",
  trigger:       "PowerDistanceHigh",
  agentBehavior: "Use formal titles and honorifics; apply passive constructions; do not challenge superior's framing directly; present alternatives as additions not contradictions",
  rationale:     "High power distance cultures expect hierarchical deference; challenging authority directly is perceived as disrespectful and damages legitimacy",
  appliesWhen:   ["PowerDistanceHigh"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_relationship_first"})
SET r += {
  name:          "Relationship-First Sequencing",
  trigger:       "MultiActive + PolychronicTime",
  agentBehavior: "Begin all turns with rapport-building before task content; validate personal connection; do not rush to agenda; allow conversational digression",
  rationale:     "Multi-active polychronic cultures treat relationship investment as a prerequisite to productive task engagement; task-first sequencing signals disrespect",
  appliesWhen:   ["MultiActive", "PolychronicTime"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_direct_explicit"})
SET r += {
  name:          "Direct Explicit Communication",
  trigger:       "LowContext + LinearActive",
  agentBehavior: "State requirements explicitly; avoid implication or indirection; confirm understanding with numbered steps; do not assume shared context",
  rationale:     "Low-context linear-active cultures expect all meaning to be verbally explicit; relying on implication is interpreted as evasion or incompetence",
  appliesWhen:   ["LowContext", "LinearActive"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_formal_register"})
SET r += {
  name:          "Formal Register Enforcement",
  trigger:       "PowerDistanceHigh + UncertaintyAvoidanceHigh",
  agentBehavior: "Maintain formal register throughout; avoid contractions, casual language, or humour; structure responses hierarchically with clear headings",
  rationale:     "High power distance + high uncertainty avoidance cultures use formality as a trust signal and ambiguity-reduction mechanism",
  appliesWhen:   ["PowerDistanceHigh", "UncertaintyAvoidanceHigh"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_data_evidence"})
SET r += {
  name:          "Evidence-First Framing",
  trigger:       "LinearActive + IndividualismHigh",
  agentBehavior: "Lead with data, metrics, and verifiable claims; emotional appeals are low-weight; cite sources; use logical if-then structures",
  rationale:     "Linear-active individualist cultures legitimise decisions through data and logic; emotional framing is perceived as manipulative or weak",
  appliesWhen:   ["LinearActive", "IndividualismHigh"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_gaze_recalibration"})
SET r += {
  name:          "Gaze Aversion Recalibration",
  trigger:       "CollectivismHigh or Reactive",
  agentBehavior: "Suppress gaze-aversion deception detection flag; reinterpret as cultural politeness or deference marker; do not route to deception protocol",
  rationale:     "In Japanese, East African, Black American, Turkish-Dutch, South Asian, and Indigenous cultures averted gaze is a sign of respect not deception; police accuracy on this cue is at chance level (52-54%)",
  appliesWhen:   ["CollectivismHigh", "Reactive"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_emblem_disambiguation"})
SET r += {
  name:          "Emblem Gesture Disambiguation",
  trigger:       "adaptor_emblem detected in any cultural context",
  agentBehavior: "Cross-reference emblem gesture against CulturalProfile before interpreting; flag ambiguous emblems; thumbs-up is offensive in Middle East; head-shake means yes in South Asia; sustained eye contact signals aggression in East Asian contexts",
  rationale:     "Emblem gestures have culture-specific semantic translations that directly contradict their Western interpretations; misinterpretation causes relationship rupture",
  appliesWhen:   ["all"],
  createdInPhase: 7
};

MERGE (r:CulturalAdaptationRule {id: "rule_silence_respect"})
SET r += {
  name:          "Silence-as-Respect Protocol",
  trigger:       "Reactive + HighContext",
  agentBehavior: "Do not fill silences with filler content; treat pause >3s as active consideration not disengagement; do not interpret silence as evasion or discomfort",
  rationale:     "Reactive high-context cultures use silence as active listening and deliberate consideration; filling silence is perceived as disrespectful impatience",
  appliesWhen:   ["Reactive", "HighContext"],
  createdInPhase: 7
};

// ════════════════════════════════════════════════════════════════════════════
// APPLIES_RULE — CulturalProfile -> CulturalAdaptationRule
// ════════════════════════════════════════════════════════════════════════════

// rule_face_saving -> High-context collectivist cultures
MATCH (r:CulturalAdaptationRule {id: "rule_face_saving"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_japan","culture_china","culture_arab_world","culture_india","culture_east_africa","culture_latin_america"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_indirect_rejection -> reactive / high-context cultures
MATCH (r:CulturalAdaptationRule {id: "rule_indirect_rejection"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_japan","culture_china","culture_east_africa","culture_india"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_deference_authority -> high power distance cultures
MATCH (r:CulturalAdaptationRule {id: "rule_deference_authority"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_japan","culture_arab_world","culture_india","culture_china","culture_east_africa","culture_latin_america"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_relationship_first -> multi-active polychronic cultures
MATCH (r:CulturalAdaptationRule {id: "rule_relationship_first"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_latin_america","culture_arab_world","culture_india","culture_east_africa"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_direct_explicit -> low-context linear-active cultures
MATCH (r:CulturalAdaptationRule {id: "rule_direct_explicit"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_usa","culture_germany","culture_nordic","culture_uk"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_formal_register -> high PDI + high UAI cultures
MATCH (r:CulturalAdaptationRule {id: "rule_formal_register"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_japan","culture_arab_world","culture_germany"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_data_evidence -> linear-active + individualist cultures
MATCH (r:CulturalAdaptationRule {id: "rule_data_evidence"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_usa","culture_germany","culture_nordic","culture_uk"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_gaze_recalibration -> collectivist + reactive cultures (gaze aversion = politeness)
MATCH (r:CulturalAdaptationRule {id: "rule_gaze_recalibration"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_japan","culture_east_africa","culture_china","culture_india"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_emblem_disambiguation -> all cultures (emblem always requires calibration)
MATCH (r:CulturalAdaptationRule {id: "rule_emblem_disambiguation"})
MATCH (cp:CulturalProfile)
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_silence_respect -> reactive + high-context cultures
MATCH (r:CulturalAdaptationRule {id: "rule_silence_respect"})
MATCH (cp:CulturalProfile) WHERE cp.id IN ["culture_japan","culture_china","culture_east_africa"]
MERGE (cp)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// ════════════════════════════════════════════════════════════════════════════
// APPLIES_RULE — CulturalContext dimensional nodes -> CulturalAdaptationRule
// Rules fire on dimension match (not just named profile)
// ════════════════════════════════════════════════════════════════════════════

// rule_face_saving fires on CollectivismHigh or HighContext dimension
MATCH (r:CulturalAdaptationRule {id: "rule_face_saving"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Collectivism","High Context","CollectivismHigh","HighContext"]
MERGE (c)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_deference_authority fires on PowerDistanceHigh
MATCH (r:CulturalAdaptationRule {id: "rule_deference_authority"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Power Distance","PowerDistanceHigh"]
MERGE (c)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_relationship_first fires on MultiActive or PolychronicTime
MATCH (r:CulturalAdaptationRule {id: "rule_relationship_first"})
MATCH (c:CulturalContext) WHERE c.name IN ["Multi-Active","Polychronic Time","MultiActive","PolychronicTime"]
MERGE (c)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_direct_explicit fires on LowContext or LinearActive
MATCH (r:CulturalAdaptationRule {id: "rule_direct_explicit"})
MATCH (c:CulturalContext) WHERE c.name IN ["Low Context","Linear-Active","LowContext","LinearActive"]
MERGE (c)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_silence_respect fires on Reactive or HighContext
MATCH (r:CulturalAdaptationRule {id: "rule_silence_respect"})
MATCH (c:CulturalContext) WHERE c.name IN ["Reactive","High Context","HighContext"]
MERGE (c)-[:APPLIES_RULE {addedInPhase: 7}]->(r);

// rule_gaze_recalibration fires on CollectivismHigh (covers Turkish-Dutch, Black American communities)
MATCH (r:CulturalAdaptationRule {id: "rule_gaze_recalibration"})
MATCH (c:CulturalContext) WHERE c.name IN ["High Collectivism","Reactive","CollectivismHigh","Reactive"]
MERGE (c)-[:APPLIES_RULE {addedInPhase: 7}]->(r);
