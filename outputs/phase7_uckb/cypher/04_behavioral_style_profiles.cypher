// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 04: BehavioralStyleProfile nodes + STYLE_SUGGESTS + EgoState cross-links
//
// 7 BehavioralStyleProfile nodes — one per guide communication style archetype.
// STYLE_SUGGESTS links to existing Technique nodes (MERGE, idempotent).
// MAPS_TO_EGO_STATE cross-links where style predicts ego state.
//
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// New PsychologicalModel node for behavioral style taxonomy
// ════════════════════════════════════════════════════════════════════════════

MERGE (m:PsychologicalModel {name: "UCKB Behavioral Style Taxonomy"})
SET m += {theorist: "UCKB composite", domain: "communication-style", createdInPhase: 7};

// ════════════════════════════════════════════════════════════════════════════
// BehavioralStyleProfile nodes
// ════════════════════════════════════════════════════════════════════════════

MERGE (bsp:BehavioralStyleProfile {id: "bsp_assertive"})
SET bsp += {
  name:              "Assertive Profile",
  primaryStyle:      "Assertive",
  agentAdaptation:   "Match directness with mutual respect; collaborative problem-solving; affirm interests before positions",
  preferredEvidence: "mixed",
  contraindicated:   ["emotional_manipulation", "avoidance", "passive_compliance"],
  detectionSignals:  ["direct statements", "I-statements", "clear boundary language", "Assertive Marker"],
  createdInPhase:    7
};

MERGE (bsp:BehavioralStyleProfile {id: "bsp_passive"})
SET bsp += {
  name:              "Passive Profile",
  primaryStyle:      "Passive",
  agentAdaptation:   "Proactively elicit opinions; create psychological safety; use open questions not closed; do not press for immediate decisions",
  preferredEvidence: "emotional",
  contraindicated:   ["pressure_tactics", "confrontation", "direct_challenge", "ultimatums"],
  detectionSignals:  ["self-minimising language", "hedging", "apology markers", "Adapted Child Marker"],
  createdInPhase:    7
};

MERGE (bsp:BehavioralStyleProfile {id: "bsp_aggressive"})
SET bsp += {
  name:              "Aggressive Profile",
  primaryStyle:      "Aggressive",
  agentAdaptation:   "Deploy firm Adult boundaries; never match aggression; redirect to objective data; mirror Critical Parent role with calm Adult state; refuse to interrupt",
  preferredEvidence: "factual",
  contraindicated:   ["emotional_appeals", "capitulation", "counter_aggression", "soft_language"],
  detectionSignals:  ["accusatory you-statements", "interruption pattern", "Volume Spike", "Critical Parent Marker"],
  createdInPhase:    7
};

MERGE (bsp:BehavioralStyleProfile {id: "bsp_passive_aggressive"})
SET bsp += {
  name:              "Passive-Aggressive Profile",
  primaryStyle:      "PassiveAggressive",
  agentAdaptation:   "Ignore sarcasm surface; address literal meaning of statements; force explicit clarity on unstated needs; do not mirror covert hostility",
  preferredEvidence: "factual",
  contraindicated:   ["emotional_framing", "indirect_implication", "metaphor_heavy_language"],
  detectionSignals:  ["sarcasm markers", "backhanded compliments", "blame_language", "ambivalence"],
  createdInPhase:    7
};

MERGE (bsp:BehavioralStyleProfile {id: "bsp_analytical"})
SET bsp += {
  name:              "Analytical Profile",
  primaryStyle:      "Analytical",
  agentAdaptation:   "Disable emotional framing; lead with data, metrics, and verifiable evidence; step-by-step logical sequencing; cite sources",
  preferredEvidence: "factual",
  contraindicated:   ["emotional_appeals", "ambiguous_framing", "anecdotal_evidence", "social_proof_only"],
  detectionSignals:  ["data requests", "precision language", "challenge to evidence", "absolutist_language"],
  createdInPhase:    7
};

MERGE (bsp:BehavioralStyleProfile {id: "bsp_diplomatic"})
SET bsp += {
  name:              "Diplomatic Profile",
  primaryStyle:      "Diplomatic",
  agentAdaptation:   "Synthesize multiple stakeholder positions; integrative summaries; consensus framing; never take sides publicly; bridge viewpoints",
  preferredEvidence: "mixed",
  contraindicated:   ["blunt_confrontation", "winner_loser_framing", "aggressive_positioning"],
  detectionSignals:  ["measured tone", "both-sides language", "consensus seeking", "bridge-building statements"],
  createdInPhase:    7
};

MERGE (bsp:BehavioralStyleProfile {id: "bsp_charismatic"})
SET bsp += {
  name:              "Charismatic Profile",
  primaryStyle:      "Charismatic",
  agentAdaptation:   "Align with high-level vision; aspirational framing; acknowledge authority with substantive content; leverage social proof and peer examples",
  preferredEvidence: "mixed",
  contraindicated:   ["dry_technical_detail", "legalistic_framing", "bureaucratic_language"],
  detectionSignals:  ["vision language", "authority claims", "social proof references", "high energy prosodic"],
  createdInPhase:    7
};

// ════════════════════════════════════════════════════════════════════════════
// BELONGS_TO_MODEL — BehavioralStyleProfile -> PsychologicalModel
// ════════════════════════════════════════════════════════════════════════════

MATCH (m:PsychologicalModel {name: "UCKB Behavioral Style Taxonomy"})
MATCH (bsp:BehavioralStyleProfile)
MERGE (bsp)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(m);

// ════════════════════════════════════════════════════════════════════════════
// STYLE_SUGGESTS — BehavioralStyleProfile -> Technique
// Pattern-matching to existing Technique nodes
// ════════════════════════════════════════════════════════════════════════════

// bsp_assertive -> assertive + objective + collaborative techniques
MATCH (bsp:BehavioralStyleProfile {id: "bsp_assertive"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "objective criteria"
   OR toLower(t.name) CONTAINS "collaborative"
   OR toLower(t.name) CONTAINS "assertive communication"
   OR toLower(t.name) CONTAINS "position interest"
   OR toLower(t.name) CONTAINS "common ground"
MERGE (bsp)-[:STYLE_SUGGESTS {
  rationale: "Assertive style aligns with direct interest-based and collaborative techniques",
  addedInPhase: 7
}]->(t);

// bsp_passive -> active listening + open questions + MI techniques
MATCH (bsp:BehavioralStyleProfile {id: "bsp_passive"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "motivational"
   OR toLower(t.name) CONTAINS "open question"
   OR toLower(t.name) CONTAINS "open-ended question"
   OR toLower(t.name) CONTAINS "empathic validat"
   OR toLower(t.name) CONTAINS "grounding"
MERGE (bsp)-[:STYLE_SUGGESTS {
  rationale: "Passive style requires safety-creating techniques that elicit rather than push",
  addedInPhase: 7
}]->(t);

// bsp_aggressive -> de-escalation + boundaries + empathy first techniques
MATCH (bsp:BehavioralStyleProfile {id: "bsp_aggressive"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "de-escalat"
   OR toLower(t.name) CONTAINS "deescalat"
   OR toLower(t.name) CONTAINS "separate people"
   OR toLower(t.name) CONTAINS "empathic validat"
   OR toLower(t.name) CONTAINS "objective criteria"
   OR toLower(t.name) CONTAINS "active listen"
MERGE (bsp)-[:STYLE_SUGGESTS {
  rationale: "Aggressive style requires boundary-setting and Adult-state mirroring techniques",
  addedInPhase: 7
}]->(t);

// bsp_passive_aggressive -> clarification + probing + reality testing techniques
MATCH (bsp:BehavioralStyleProfile {id: "bsp_passive_aggressive"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "clarification"
   OR toLower(t.name) CONTAINS "probing question"
   OR toLower(t.name) CONTAINS "reality test"
   OR toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "reflective"
MERGE (bsp)-[:STYLE_SUGGESTS {
  rationale: "Passive-aggressive style requires techniques that surface literal meaning and force explicit clarity",
  addedInPhase: 7
}]->(t);

// bsp_analytical -> evidence-based + logical sequencing + data techniques
MATCH (bsp:BehavioralStyleProfile {id: "bsp_analytical"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "objective criteria"
   OR toLower(t.name) CONTAINS "evidence"
   OR toLower(t.name) CONTAINS "logical sequence"
   OR toLower(t.name) CONTAINS "anchoring"
   OR toLower(t.name) CONTAINS "batna"
   OR toLower(t.name) CONTAINS "data"
MERGE (bsp)-[:STYLE_SUGGESTS {
  rationale: "Analytical style demands evidence-first factual framing techniques",
  addedInPhase: 7
}]->(t);

// bsp_diplomatic -> rapport + perspective + integrative techniques
MATCH (bsp:BehavioralStyleProfile {id: "bsp_diplomatic"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport"
   OR toLower(t.name) CONTAINS "perspective"
   OR toLower(t.name) CONTAINS "reframing"
   OR toLower(t.name) CONTAINS "common ground"
   OR toLower(t.name) CONTAINS "summaris"
   OR toLower(t.name) CONTAINS "summariz"
   OR toLower(t.name) CONTAINS "bridg"
MERGE (bsp)-[:STYLE_SUGGESTS {
  rationale: "Diplomatic style maps to consensus-building and multi-stakeholder integration techniques",
  addedInPhase: 7
}]->(t);

// bsp_charismatic -> aspirational + social proof + vision techniques
MATCH (bsp:BehavioralStyleProfile {id: "bsp_charismatic"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "social proof"
   OR toLower(t.name) CONTAINS "inspir"
   OR toLower(t.name) CONTAINS "vision"
   OR toLower(t.name) CONTAINS "motivational"
   OR toLower(t.name) CONTAINS "rapport"
   OR toLower(t.name) CONTAINS "aspirat"
MERGE (bsp)-[:STYLE_SUGGESTS {
  rationale: "Charismatic style aligns with high-energy, vision-aligned, and peer-norm techniques",
  addedInPhase: 7
}]->(t);

// ════════════════════════════════════════════════════════════════════════════
// EgoState cross-links — BehavioralStyleProfile -> EgoState
// Detected style predicts ego state
// ════════════════════════════════════════════════════════════════════════════

// bsp_aggressive style correlates with Critical Parent ego state
MATCH (bsp:BehavioralStyleProfile {id: "bsp_aggressive"})
MATCH (e:EgoState {id: "ego_critical_parent"})
MERGE (bsp)-[:MAPS_TO_EGO_STATE {
  confidence: 0.82,
  markerStrength: "strong",
  rationale: "Aggressive communication pattern is a strong linguistic-kinesic indicator of Critical Parent / Persecutor ego state",
  addedInPhase: 7
}]->(e);

// bsp_passive style correlates with Adapted Child ego state
MATCH (bsp:BehavioralStyleProfile {id: "bsp_passive"})
MATCH (e:EgoState {id: "ego_adapted_child"})
MERGE (bsp)-[:MAPS_TO_EGO_STATE {
  confidence: 0.78,
  markerStrength: "strong",
  rationale: "Passive communication pattern — avoidance, self-minimising, helplessness — signals Adapted Child / Victim ego state",
  addedInPhase: 7
}]->(e);

// bsp_diplomatic / bsp_assertive correlate with Adult ego state
MATCH (bsp:BehavioralStyleProfile) WHERE bsp.id IN ["bsp_diplomatic","bsp_assertive"]
MATCH (e:EgoState {id: "ego_adult"})
MERGE (bsp)-[:MAPS_TO_EGO_STATE {
  confidence: 0.75,
  markerStrength: "moderate",
  rationale: "Assertive and diplomatic styles align with the balanced, fact-grounded Adult ego state",
  addedInPhase: 7
}]->(e);
