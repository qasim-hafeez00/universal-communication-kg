// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Multimodal Routing Query Library
//
// 5 Cypher query templates implementing non-verbal and multimodal routing.
// Parameters use $param notation for driver injection.
// Replace with literals for testing in Neo4j Browser.
//
// Query index:
//   M1 — Ego State Classification   (SignalMarker → EgoState → agentAction + Technique)
//   M2 — FACS Emotion Routing        (AU codes → FacsMapping → EmotionalState + Technique)
//   M3 — Prosodic Signal Check       (feature + threshold → EmotionalState + Technique)
//   M4 — Multimodal Congruence Gate  (3 channel states → priority resolution via Mehrabian)
//   M5 — Full Nonverbal Turn         (composed — all channels → EgoState + Emotion + Technique)
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// M1 — Ego State Classification
//
// Natural language: "The agent detected this signal marker. What ego state is
//                    the interlocutor in, and what should the agent do?"
// Input:  $signalMarkerName (string — partial match)
// Output: matched EgoState, karpmanRole, winnerTriangleTarget, agentAction,
//         and available Techniques
// ─────────────────────────────────────────────────────────────────────────────

MATCH (sm:SignalMarker)
WHERE toLower(sm.name) CONTAINS toLower($signalMarkerName)
MATCH (sm)-[r:MAPS_TO_EGO_STATE]->(ego:EgoState)
OPTIONAL MATCH (ego)-[:TRIGGERS]->(t:Technique)
RETURN
  sm.name                    AS detected_signal,
  r.confidence               AS detection_confidence,
  ego.name                   AS ego_state,
  ego.berneCategory          AS berne_category,
  ego.karpmanRole            AS karpman_role,
  ego.winnerTriangleTarget   AS winner_triangle_target,
  ego.agentAction            AS prescribed_agent_action,
  collect(DISTINCT t.name)   AS available_techniques
ORDER BY r.confidence DESC
LIMIT 3;


// ─────────────────────────────────────────────────────────────────────────────
// M2 — FACS Emotion Routing
//
// Natural language: "These FACS AU codes were detected. What emotion is present
//                    and what technique should the agent use?"
// Input:  $auCode (int — single AU code for matching; full overlap handled in app)
// Output: matched FacsMapping, emotionLabel, routingAction, TRIGGERS Technique
// ─────────────────────────────────────────────────────────────────────────────

MATCH (f:FacsMapping)
WHERE $auCode IN f.auCodes
   OR f.isMicroexpression = true
MATCH (f)-[:INDICATES_EMOTION]->(es:EmotionalState)
MATCH (f)-[:TRIGGERS]->(t:Technique)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(es)
RETURN
  f.emotionLabel           AS detected_emotion,
  f.auCombination          AS au_combination,
  f.isUnilateral           AS is_unilateral,
  f.isMicroexpression      AS is_microexpression,
  f.routingAction          AS facs_routing_action,
  f.conflictsVerbal        AS conflicts_verbal,
  es.name                  AS emotional_state,
  t.name                   AS technique,
  t.evidenceLevel          AS evidence_level
ORDER BY t.evidenceLevel DESC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// M3 — Prosodic Signal Check
//
// Natural language: "This prosodic feature is above threshold. What emotional
//                    state does it indicate and what technique should be used?"
// Input:  $featureId (string), $signalDirection (string: "drop"|"rise"|"spike"|"high"|"long"|"tremor")
// Output: ProsodicFeature, signalsState, INDICATES_EMOTION EmotionalState, TRIGGERS Technique
// ─────────────────────────────────────────────────────────────────────────────

MATCH (p:ProsodicFeature {id: $featureId})
MATCH (p)-[ie:INDICATES_EMOTION]->(es:EmotionalState)
WHERE $signalDirection = "" OR ie.direction CONTAINS $signalDirection
   OR ie.direction IS NULL
MATCH (p)-[tr:TRIGGERS]->(t:Technique)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(es)
RETURN
  p.name                 AS prosodic_feature,
  p.threshold            AS threshold,
  p.highValueMeaning     AS high_value_meaning,
  p.lowValueMeaning      AS low_value_meaning,
  ie.direction           AS signal_direction,
  ie.confidence          AS detection_confidence,
  es.name                AS signalled_state,
  t.name                 AS technique,
  t.evidenceLevel        AS evidence_level
ORDER BY ie.confidence DESC, t.evidenceLevel DESC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// M4 — Multimodal Congruence Gate
//
// Natural language: "The verbal channel says X, the prosodic channel says Y,
//                    the kinesic channel says Z. What is the dominant signal
//                    and which technique should the agent use?"
// Input:  $verbalStateName (string), $prosodicStateName (string), $kinesicStateName (string)
// Output: congruent or dominant state after Mehrabian priority resolution + Technique
//
// Rule: Applies ONLY to affective (emotional/attitudinal) context.
//       If all three agree → combined. If incongruent → kinesic > paralinguistic > semantic.
// ─────────────────────────────────────────────────────────────────────────────

// Congruence check and priority resolution
MATCH (mk:ModalityWeight {modalityType: "kinesic"})
MATCH (mp:ModalityWeight {modalityType: "paralinguistic"})
MATCH (ms:ModalityWeight {modalityType: "semantic"})
WITH mk, mp, ms,
     $verbalStateName    AS verbal,
     $prosodicStateName  AS prosodic,
     $kinesicStateName   AS kinesic,
     CASE WHEN toLower($verbalStateName) = toLower($prosodicStateName)
               AND toLower($prosodicStateName) = toLower($kinesicStateName)
          THEN "CONGRUENT"
          ELSE "INCONGRUENT"
     END AS congruence_status
WITH mk, mp, ms, verbal, prosodic, kinesic, congruence_status,
     CASE congruence_status
       WHEN "CONGRUENT"   THEN kinesic
       WHEN "INCONGRUENT" THEN
         CASE
           WHEN kinesic  <> ""  THEN kinesic     // kinesic wins (priority 1, weight 0.55)
           WHEN prosodic <> ""  THEN prosodic     // paralinguistic wins (priority 2, weight 0.38)
           ELSE verbal                            // semantic last resort
         END
     END AS dominant_state
MATCH (e:EmotionalState) WHERE toLower(e.name) = toLower(dominant_state)
MATCH (t:Technique)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
RETURN
  congruence_status        AS channel_congruence,
  verbal                   AS verbal_signal,
  prosodic                 AS prosodic_signal,
  kinesic                  AS kinesic_signal,
  dominant_state           AS resolved_dominant_state,
  mk.weight                AS kinesic_weight,
  e.name                   AS active_emotional_state,
  t.name                   AS recommended_technique,
  t.evidenceLevel          AS evidence_level
ORDER BY t.evidenceLevel DESC
LIMIT 3;


// ─────────────────────────────────────────────────────────────────────────────
// M5 — Full Nonverbal Turn (composed query)
//
// Natural language: "Given the full non-verbal reading for this turn, what is
//                    the agent's complete classification and next action?"
// Input:  $domain (string), $egoStateId (string), $facsId (string),
//         $prosodicFeatureId (string), $currentEmotionalState (string)
// Output: EgoState classification + winnerTriangleTarget + FACS emotion +
//         modality-weighted dominant state + safe Technique (with doctrine check)
// ─────────────────────────────────────────────────────────────────────────────

// Step 1: EgoState classification
MATCH (ego:EgoState {id: $egoStateId})

// Step 2: FACS emotion reading
OPTIONAL MATCH (facs:FacsMapping {id: $facsId})
OPTIONAL MATCH (facs)-[:INDICATES_EMOTION]->(facs_state:EmotionalState)

// Step 3: Current emotional state (verbal or composite)
MATCH (e:EmotionalState)
WHERE toLower(e.name) = toLower($currentEmotionalState)

// Step 4: Prosodic feature check
OPTIONAL MATCH (pf:ProsodicFeature {id: $prosodicFeatureId})
OPTIONAL MATCH (pf)-[:INDICATES_EMOTION]->(prosodic_state:EmotionalState)

// Step 5: Dominant state via Mehrabian (kinesic > paralinguistic > verbal)
WITH ego, facs, facs_state, e, pf, prosodic_state,
     CASE
       WHEN facs_state IS NOT NULL THEN facs_state.name
       WHEN prosodic_state IS NOT NULL THEN prosodic_state.name
       ELSE e.name
     END AS dominant_state_name

// Step 6: Find safe Technique given dominant state and ego state
MATCH (dominant_e:EmotionalState)
WHERE toLower(dominant_e.name) = toLower(dominant_state_name)

// From ego state TRIGGERS
MATCH (ego)-[:TRIGGERS]->(t:Technique)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(dominant_e)
  AND NOT t.requiresEmotionalClearance = true
  AND t.domain CONTAINS $domain

// Phase 1 doctrine check — if technique requires emotional clearance, reject
WITH ego, facs, facs_state, e, pf, prosodic_state, dominant_state_name, dominant_e, t
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(dominant_e)

RETURN
  // Classification
  ego.name                        AS ego_state,
  ego.karpmanRole                 AS karpman_role,
  ego.winnerTriangleTarget        AS winner_triangle_target,
  ego.agentAction                 AS prescribed_agent_action,

  // Emotional layer
  e.name                          AS verbal_emotional_state,
  facs_state.name                 AS facs_detected_state,
  prosodic_state.name             AS prosodic_detected_state,
  dominant_state_name             AS dominant_state,
  facs.auCombination              AS au_combination,
  facs.routingAction              AS facs_routing_action,

  // Intention
  t.name                          AS technique,
  t.steps                         AS execution_steps,
  t.evidenceLevel                 AS evidence_level,
  t.avgLatency_ms                 AS latency_ms

ORDER BY t.evidenceLevel DESC, t.avgLatency_ms ASC
LIMIT 3;
