// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 09: Acceptance Criteria Validation Queries
//
// 8 acceptance criteria matching Phase 4/5 validation pattern.
// Run after Steps 01-07 are complete.
//
// AC-1  All 4 EgoState nodes present with all 6 required properties
// AC-2  >=6 FacsMapping nodes with auCombination and routingAction
// AC-3  >=6 ProsodicFeature nodes with threshold value set
// AC-4  All 4 EgoState nodes have >=1 TRIGGERS link to a Technique
// AC-5  MAPS_TO_EGO_STATE relationships (SignalMarker → EgoState) >= 10
// AC-6  INDICATES_EMOTION relationships (FacsMapping + ProsodicFeature → EmotionalState) >= 10
// AC-7  Zero Phase 1 doctrine violations in ego-state routing paths
// AC-8  M5 full nonverbal turn returns >=1 result for 3 scenarios
// ─────────────────────────────────────────────────────────────────────────────


// ── AC-1: All 4 EgoState nodes with all 6 required properties ────────────────
// Expected: total=4, complete=4

MATCH (e:EgoState)
WITH e,
     CASE WHEN e.berneCategory        IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN e.karpmanRole          IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN e.winnerTriangleTarget IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN e.linguisticMarkers    IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN e.agentAction          IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN e.isDysfunctional      IS NOT NULL THEN 1 ELSE 0 END
     AS score
RETURN
  count(e)                                                       AS total_ego_states,
  count(CASE WHEN score = 6 THEN 1 END)                         AS complete_ego_states,
  round(100.0 * count(CASE WHEN score = 6 THEN 1 END) / count(e), 1) AS pct;
// PASS if total_ego_states = 4 AND pct = 100.0


// ── AC-2: >=6 FacsMapping nodes with auCombination AND routingAction ──────────
// Expected: count >= 6

MATCH (f:FacsMapping)
WHERE f.auCombination IS NOT NULL AND f.routingAction IS NOT NULL
RETURN count(f) AS facs_complete;
// PASS if facs_complete >= 6


// ── AC-3: >=6 ProsodicFeature nodes with threshold value set ──────────────────
// Expected: count >= 6

MATCH (p:ProsodicFeature)
WHERE p.threshold IS NOT NULL
RETURN count(p) AS prosodic_with_threshold;
// PASS if prosodic_with_threshold >= 6


// ── AC-4: All 4 EgoState nodes have >=1 TRIGGERS link ────────────────────────
// Expected: ego_states_with_triggers = 4, pct = 100.0

MATCH (e:EgoState)
OPTIONAL MATCH (e)-[:TRIGGERS]->(t:Technique)
WITH e, count(t) AS trigger_count
RETURN
  count(e)                                                              AS total_ego_states,
  count(CASE WHEN trigger_count > 0 THEN 1 END)                        AS ego_states_with_triggers,
  round(100.0 * count(CASE WHEN trigger_count > 0 THEN 1 END) / count(e), 1) AS pct;
// PASS if pct = 100.0


// ── AC-5: MAPS_TO_EGO_STATE relationships >= 10 ───────────────────────────────
// Expected: count >= 10

MATCH ()-[r:MAPS_TO_EGO_STATE]->()
RETURN count(r) AS maps_to_ego_state_count;
// PASS if maps_to_ego_state_count >= 10


// ── AC-6: INDICATES_EMOTION relationships >= 10 ───────────────────────────────
// Counts relationships from FacsMapping AND ProsodicFeature combined
// Expected: total >= 10

MATCH (source)-[r:INDICATES_EMOTION]->(es:EmotionalState)
WHERE source:FacsMapping OR source:ProsodicFeature OR source:BehavioralAdaptor
RETURN
  count(r)                            AS total_indicates_emotion,
  count(CASE WHEN source:FacsMapping          THEN 1 END) AS from_facs,
  count(CASE WHEN source:ProsodicFeature      THEN 1 END) AS from_prosodic,
  count(CASE WHEN source:BehavioralAdaptor    THEN 1 END) AS from_adaptor;
// PASS if total_indicates_emotion >= 10


// ── AC-7: Zero Phase 1 doctrine violations in ego-state routing paths ─────────
// Violation: EgoState TRIGGERS a Technique that requiresEmotionalClearance = true
// WITHOUT an empathy-prerequisite Technique preceding it.
// Same pattern as Phase 5 AC-6.
// Expected: violations = 0

MATCH (ego:EgoState)-[:TRIGGERS]->(t:Technique)
WHERE t.requiresEmotionalClearance = true
  AND NOT exists {
    MATCH (prereq:Technique {isEmotionalPrerequisite: true})-[:PRECEDES]->(t)
  }
RETURN
  count(*) AS doctrine_violations,
  collect({ego_state: ego.name, technique: t.name}) AS violation_details;
// PASS if doctrine_violations = 0


// ── AC-8: M5 full nonverbal turn returns >=1 result per scenario ──────────────
// Tests 3 scenarios inline as separate queries:

// Scenario A: verbal-only (no FACS/prosodic) — ego_adapted_child, Distress state
MATCH (ego:EgoState {id: "ego_adapted_child"})
MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
MATCH (ego)-[:TRIGGERS]->(t:Technique)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
RETURN
  ego.name          AS ego_state,
  "Distress"        AS scenario,
  count(t)          AS technique_count
LIMIT 1;
// PASS if technique_count >= 1

// Scenario B: prosodic-incongruent — speech rate drop + verbal "calm"
MATCH (p:ProsodicFeature {id: "prosodic_speech_rate"})
MATCH (p)-[ie:INDICATES_EMOTION]->(prosodic_state:EmotionalState)
WHERE ie.direction = "drop"
MATCH (ego:EgoState {id: "ego_adapted_child"})
MATCH (ego)-[:TRIGGERS]->(t:Technique)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(prosodic_state)
  AND NOT t.requiresEmotionalClearance = true
RETURN
  "prosodic_speech_rate_drop"  AS scenario,
  prosodic_state.name          AS dominant_state,
  count(t)                     AS technique_count
LIMIT 1;
// PASS if technique_count >= 1

// Scenario C: FACS anger — ego_critical_parent + FACS anger signal
MATCH (facs:FacsMapping {id: "facs_anger"})
MATCH (facs)-[:INDICATES_EMOTION]->(facs_state:EmotionalState)
MATCH (ego:EgoState {id: "ego_critical_parent"})
MATCH (ego)-[:TRIGGERS]->(t:Technique)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(facs_state)
  AND NOT t.requiresEmotionalClearance = true
RETURN
  "facs_anger"              AS scenario,
  facs_state.name           AS facs_dominant_state,
  ego.winnerTriangleTarget  AS winner_target,
  count(t)                  AS technique_count
LIMIT 1;
// PASS if technique_count >= 1
