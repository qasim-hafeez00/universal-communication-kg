// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 02: Ego State Nodes (Transactional Analysis)
//
// Creates 4 EgoState nodes (Adapted Child, Critical Parent, Nurturing Parent, Adult)
// Links each to existing PsychologicalModel nodes via BELONGS_TO_MODEL
// Links each to relevant Techniques via TRIGGERS (routing actions)
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ── Adapted Child ─────────────────────────────────────────────────────────────
MERGE (e:EgoState {id: "ego_adapted_child"})
SET e += {
  name:                  "Adapted Child",
  berneCategory:         "Child",
  karpmanRole:           "Victim",
  winnerTriangleTarget:  "Vulnerable/Survivor",
  agentAction:           "Encourage explicit need-articulation; do NOT rescue",
  isDysfunctional:       true,
  linguisticMarkers:     ["nobody listens to me", "helpless tone", "pleading requests", "self-deprecation"],
  createdInPhase:        6
};

// ── Critical Parent ───────────────────────────────────────────────────────────
MERGE (e:EgoState {id: "ego_critical_parent"})
SET e += {
  name:                  "Critical Parent",
  berneCategory:         "Parent",
  karpmanRole:           "Persecutor",
  winnerTriangleTarget:  "Assertive",
  agentAction:           "Mirror Adult state; set objective boundaries; never match aggression",
  isDysfunctional:       true,
  linguisticMarkers:     ["it is your fault", "absolutist language", "blame statements", "contemptuous FACS"],
  createdInPhase:        6
};

// ── Nurturing Parent ──────────────────────────────────────────────────────────
MERGE (e:EgoState {id: "ego_nurturing_parent"})
SET e += {
  name:                  "Nurturing Parent",
  berneCategory:         "Parent",
  karpmanRole:           "Rescuer",
  winnerTriangleTarget:  "Caring/Coach",
  agentAction:           "Provide scaffolding; empower the other party to solve their own problem",
  isDysfunctional:       true,
  linguisticMarkers:     ["over-helping", "solving others problems unsolicited", "condescending care"],
  createdInPhase:        6
};

// ── Adult (target state) ──────────────────────────────────────────────────────
MERGE (e:EgoState {id: "ego_adult"})
SET e += {
  name:                  "Adult",
  berneCategory:         "Adult",
  karpmanRole:           "None",
  winnerTriangleTarget:  "Maintain",
  agentAction:           "Reinforce with collaborative dialogue acts and logical sequencing",
  isDysfunctional:       false,
  linguisticMarkers:     ["objective language", "I statements", "factual framing", "measured tone"],
  createdInPhase:        6
};

// ── BELONGS_TO_MODEL: link all EgoStates to Transactional Analysis ────────────
MATCH (ps:PsychologicalModel) WHERE toLower(ps.name) CONTAINS "transactional"
MATCH (e:EgoState)
MERGE (e)-[:BELONGS_TO_MODEL {model: "Transactional Analysis", addedInPhase: 6}]->(ps);

// ── BELONGS_TO_MODEL: 3 dysfunctional states → Karpman Drama Triangle ─────────
MATCH (ps:PsychologicalModel) WHERE toLower(ps.name) CONTAINS "karpman"
MATCH (e:EgoState) WHERE e.isDysfunctional = true
MERGE (e)-[:BELONGS_TO_MODEL {model: "Karpman Drama Triangle", addedInPhase: 6}]->(ps);

// ── BELONGS_TO_MODEL: all EgoStates → Winner's Triangle ──────────────────────
MATCH (ps:PsychologicalModel) WHERE toLower(ps.name) CONTAINS "winner"
MATCH (e:EgoState)
MERGE (e)-[:BELONGS_TO_MODEL {model: "Winner's Triangle", addedInPhase: 6}]->(ps);

// ── TRIGGERS: Adapted Child → empathy + active listening techniques ───────────
MATCH (e:EgoState {id: "ego_adapted_child"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "motivational"
   OR toLower(t.name) CONTAINS "validat"
MERGE (e)-[:TRIGGERS {
  weight: 0.90,
  rationale: "Adapted Child ego state requires empathic validation before any task-oriented technique",
  addedInPhase: 6
}]->(t);

// ── TRIGGERS: Critical Parent → objective boundary + de-personalization ────────
MATCH (e:EgoState {id: "ego_critical_parent"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "objective criteria"
   OR toLower(t.name) CONTAINS "separate people"
   OR toLower(t.name) CONTAINS "assertive"
   OR toLower(t.name) CONTAINS "boundary"
MERGE (e)-[:TRIGGERS {
  weight: 0.88,
  rationale: "Critical Parent state requires objective criteria and de-personalization to prevent escalation",
  addedInPhase: 6
}]->(t);

// ── TRIGGERS: Nurturing Parent → scaffolding + empowering techniques ──────────
MATCH (e:EgoState {id: "ego_nurturing_parent"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "coach"
   OR toLower(t.name) CONTAINS "scaffold"
   OR toLower(t.name) CONTAINS "open"
   OR toLower(t.name) CONTAINS "empower"
   OR toLower(t.name) CONTAINS "motivational"
   OR toLower(t.name) CONTAINS "rapport"
MERGE (e)-[:TRIGGERS {
  weight: 0.82,
  rationale: "Nurturing Parent state requires empowering the other party rather than rescuing them",
  addedInPhase: 6
}]->(t);

// ── TRIGGERS: Adult → collaborative + logical sequencing techniques ───────────
MATCH (e:EgoState {id: "ego_adult"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "collaborat"
   OR toLower(t.name) CONTAINS "logical"
   OR toLower(t.name) CONTAINS "problem solv"
   OR toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "rapport"
MERGE (e)-[:TRIGGERS {
  weight: 0.85,
  rationale: "Adult ego state sustains collaborative dialogue and logical sequencing",
  addedInPhase: 6
}]->(t);
