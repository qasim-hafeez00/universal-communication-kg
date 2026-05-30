// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 07: Technique -> CulturalContext ADAPTS_FOR relationships
//
// Links existing Technique nodes to CulturalContext dimensional descriptors
// expressing cultural preference / higher weighting in that context.
//
// Threshold: >=10 ADAPTS_FOR relationships required (AC-6).
// Actual count: 12 target pairs -> each MATCH may produce multiple merges.
//
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// ADAPTS_FOR — Technique -> CulturalContext
// ════════════════════════════════════════════════════════════════════════════

// 1. Active Listening -> Reactive
//    Primary rapport mechanism; outweighs verbal affirmation in reactive cultures
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "active listen"
MATCH (c:CulturalContext) WHERE c.name IN ["Reactive"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Primary rapport mechanism in reactive cultures; weighted higher than verbal affirmation or probing",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 2. Empathic Validation -> CollectivismHigh
//    Face-saving cultures require emotional acknowledgment before task content
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "empath" AND toLower(t.name) CONTAINS "validat"
MATCH (c:CulturalContext) WHERE c.name IN ["High Collectivism","CollectivismHigh"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Face-saving collectivist cultures require emotional acknowledgment of the other party's experience before task content proceeds",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 3. Objective Criteria -> LinearActive
//    Factual framing is the primary legitimacy mechanism in task-oriented cultures
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "objective criteria"
MATCH (c:CulturalContext) WHERE c.name IN ["Linear-Active","LinearActive"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "In linear-active cultures, objective criteria are the primary legitimacy mechanism; emotional appeals are discounted",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 4. Rapport Checkpoint -> MultiActive
//    Relationship-first cultures require rapport verification before task
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "rapport"
MATCH (c:CulturalContext) WHERE c.name IN ["Multi-Active","MultiActive"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Multi-active relationship-first cultures require rapport verification before task content; skipping this is perceived as disrespect",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 5. Motivational Interviewing -> HighContext
//    MI's indirect elicitation matches high-context preference for implicit communication
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "motivational"
MATCH (c:CulturalContext) WHERE c.name IN ["High Context","HighContext"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "MI's non-directive indirect elicitation aligns with high-context preference for implicit rather than explicit communication",
  priority:     2,
  addedInPhase: 7
}]->(c);

// 6. Separate People From Problem -> PowerDistanceHigh
//    Depersonalisation protects face when challenging authority
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "separate people"
MATCH (c:CulturalContext) WHERE c.name IN ["High Power Distance","PowerDistanceHigh"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Depersonalising the problem protects face when the interlocutor holds authority; prevents perceived challenge to hierarchy",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 7. Clarification Question -> HighContext
//    High-context communication requires more clarification to surface implicit intent
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "clarification"
MATCH (c:CulturalContext) WHERE c.name IN ["High Context","HighContext"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "High-context communication relies on implicit meaning; clarification questions are required to surface unstated intent without forcing directness",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 8. Probing Question -> LowContext
//    Direct questioning is culturally expected in low-context cultures
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "probing question"
MATCH (c:CulturalContext) WHERE c.name IN ["Low Context","LowContext"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Low-context cultures expect and appreciate direct questioning; probing is not perceived as aggressive but as engaged",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 9. Reflective Questioning -> Reactive
//    Reactive cultures value careful listening; reflective technique signals engagement
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "reflective"
MATCH (c:CulturalContext) WHERE c.name IN ["Reactive"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Reactive cultures value deliberate, careful listening before responding; reflective technique demonstrates active engagement without premature conclusion",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 10. Reframing -> CollectivismHigh
//     Allows repositioning without direct confrontation — preserves group harmony
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "reframing"
   OR toLower(t.name) CONTAINS "reframe"
MATCH (c:CulturalContext) WHERE c.name IN ["High Collectivism","CollectivismHigh"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Reframing repositions the issue without direct contradiction — preserves group harmony and face in collectivist cultures",
  priority:     2,
  addedInPhase: 7
}]->(c);

// 11. BATNA Development -> IndividualismHigh
//     Individual autonomy cultures respond to alternative optionality framing
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "batna"
   OR (toLower(t.name) CONTAINS "best alternative" AND toLower(t.name) CONTAINS "agreement")
MATCH (c:CulturalContext) WHERE c.name IN ["High Individualism","IndividualismHigh"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Individualist cultures value personal optionality and autonomous decision-making; BATNA framing activates self-determination motivation",
  priority:     2,
  addedInPhase: 7
}]->(c);

// 12. Social Proof -> MultiActive
//     Relationship-oriented cultures influenced by peer norms and in-group examples
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "social proof"
MATCH (c:CulturalContext) WHERE c.name IN ["Multi-Active","MultiActive"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Multi-active relationship-oriented cultures are strongly influenced by in-group peer behaviour; social proof is a high-weight legitimacy mechanism",
  priority:     1,
  addedInPhase: 7
}]->(c);

// 13. Empathic Validation -> HighContext (also preferred in high-context)
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "empath" AND toLower(t.name) CONTAINS "validat"
MATCH (c:CulturalContext) WHERE c.name IN ["High Context","HighContext"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "High-context cultures expect emotional acknowledgment embedded in implicit communication; empathic validation fits naturally",
  priority:     2,
  addedInPhase: 7
}]->(c);

// 14. Grounding -> Reactive
//    Reactive cultures respond well to grounding / anchoring before proceeding
MATCH (t:Technique) WHERE toLower(t.name) CONTAINS "grounding"
MATCH (c:CulturalContext) WHERE c.name IN ["Reactive"]
MERGE (t)-[:ADAPTS_FOR {
  rationale:    "Reactive cultures process carefully before responding; grounding techniques align with their deliberate, considered engagement style",
  priority:     2,
  addedInPhase: 7
}]->(c);

// ════════════════════════════════════════════════════════════════════════════
// PRECEDES links required for AC-7 Phase 1 doctrine compliance
//
// BehavioralStyleProfile STYLE_SUGGESTS reaches techniques with
// requiresEmotionalClearance=true that had no empathy prerequisites.
// Fix: add PRECEDES from isEmotionalPrerequisite=true techniques.
// ════════════════════════════════════════════════════════════════════════════

// Active Listening PRECEDES Authority Evidence
MATCH (prereq:Technique {isEmotionalPrerequisite: true})
WHERE toLower(prereq.name) CONTAINS "active listen"
MATCH (t:Technique {name: "Authority Evidence"})
MERGE (prereq)-[:PRECEDES {
  rationale:    "Authority evidence requires active listening to first understand what evidence the other party finds credible",
  addedInPhase: 7
}]->(t);

// Active Listening PRECEDES BATNA Clarification (requiresEmotionalClearance variant)
MATCH (prereq:Technique {isEmotionalPrerequisite: true})
WHERE toLower(prereq.name) CONTAINS "active listen"
MATCH (t:Technique {name: "BATNA Clarification", requiresEmotionalClearance: true})
MERGE (prereq)-[:PRECEDES {
  rationale:    "BATNA clarification requires active listening to understand the other party's position before exploring alternatives",
  addedInPhase: 7
}]->(t);

// Active Listening PRECEDES Social Proof Evidence
MATCH (prereq:Technique {isEmotionalPrerequisite: true})
WHERE toLower(prereq.name) CONTAINS "active listen"
MATCH (t:Technique {name: "Social Proof Evidence"})
MERGE (prereq)-[:PRECEDES {
  rationale:    "Social proof requires active listening to understand which reference group the interlocutor identifies with",
  addedInPhase: 7
}]->(t);

// Empathic Validation PRECEDES Objection Clarification
MATCH (prereq:Technique {isEmotionalPrerequisite: true})
WHERE toLower(prereq.name) CONTAINS "empath"
MATCH (t:Technique {name: "Objection Clarification"})
MERGE (prereq)-[:PRECEDES {
  rationale:    "Objection clarification requires empathic validation to acknowledge the underlying concern before probing its basis",
  addedInPhase: 7
}]->(t);
