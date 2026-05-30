// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 5 — BDI Query Library
//
// 6 Cypher query templates implementing Belief-Desire-Intention agent reasoning.
// These queries are called by the domain agent at each conversation turn to
// determine the next committed dialogue act and technique.
//
// Parameters use $param notation for driver injection.
// Replace with literals for testing in Neo4j Browser.
//
// Query index:
//   B1 — Belief Assembly        (slot state → current beliefs)
//   B2 — Desire Resolution      (protocol + emotional state → target state)
//   B3 — Intention Selection    (beliefs + desire → next DialogueAct + Technique)
//   B4 — DST Slot Fill Check    (which slots are unfilled and what act to issue)
//   B5 — Act-State Safety Gate  (is the intended act safe right now?)
//   B6 — Full BDI Turn          (composed query, one call per conversation turn)
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// B1 — Belief Assembly
//
// Natural language: "What does the agent currently know about this conversation?"
// Input:  $domain (string), $filledSlots (map of slotName → currentValue)
// Output: structured belief state with filled/unfilled slot inventory
// ─────────────────────────────────────────────────────────────────────────────
// Parameters: $domain (string)

MATCH (b:BDIState {domain: $domain})-[:HAS_SLOT]->(s:DomainSlot)
RETURN
  b.domain                    AS domain,
  b.beliefTemplate            AS belief_template,
  collect({
    slot:        s.slotName,
    filled:      s.filled,
    validValues: s.validValues,
    valueType:   s.valueType
  })                          AS slot_inventory,
  size([x IN collect(s) WHERE x.filled = true])  AS slots_filled,
  size([x IN collect(s) WHERE x.filled = false]) AS slots_unfilled
ORDER BY domain;


// ─────────────────────────────────────────────────────────────────────────────
// B2 — Desire Resolution
//
// Natural language: "What is the agent trying to achieve in this conversation?"
// Input:  $domain (string), $currentProtocolStep (string), $emotionalState (string)
// Output: desired end-state + blocking conditions
// ─────────────────────────────────────────────────────────────────────────────
// Parameters: $domain (string), $currentProtocolStep (string), $emotionalState (string)

MATCH (b:BDIState {domain: $domain})
MATCH (proto:DomainProtocol)
WHERE proto.domain CONTAINS $domain
  AND toLower(proto.name) CONTAINS toLower($currentProtocolStep)
OPTIONAL MATCH (e:EmotionalState)
WHERE toLower(e.name) = toLower($emotionalState)
OPTIONAL MATCH (blocked:Technique)-[:CONTRAINDICATED_WHEN]->(e)
RETURN
  b.desireTemplate              AS agent_desire,
  proto.name                    AS active_protocol,
  proto.description             AS protocol_goal,
  e.name                        AS current_emotional_state,
  e.valence                     AS emotional_valence,
  collect(DISTINCT blocked.name) AS blocked_techniques
LIMIT 1;


// ─────────────────────────────────────────────────────────────────────────────
// B3 — Intention Selection
//
// Natural language: "What should the agent do next given what it knows and wants?"
// Input:  $domain, $emotionalState, $currentProtocolStep, $completedTechniqueIds
// Output: ranked next DialogueAct + Technique pairing
// ─────────────────────────────────────────────────────────────────────────────
// Parameters: $domain (string), $emotionalState (string),
//             $currentProtocolStep (string), $completedTechniqueIds (list of strings)

MATCH (e:EmotionalState)
WHERE toLower(e.name) = toLower($emotionalState)
MATCH (a:DialogueAct)
WHERE NOT (a)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT a.requiresInfluencePrereq = true
MATCH (a)-[:TRIGGERS]->(t:Technique)
WHERE t.domain CONTAINS $domain
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
WITH a, t, e,
     collect(prereq.id) AS requiredPrereqs,
     $completedTechniqueIds AS completed
WITH a, t, e, requiredPrereqs, completed,
     [p IN requiredPrereqs WHERE NOT p IN completed] AS unsatisfied
WHERE size(unsatisfied) = 0
RETURN
  a.communicativeFunction       AS next_dialogue_act,
  a.dimension                   AS act_dimension,
  t.id                          AS technique_id,
  t.name                        AS technique_name,
  t.steps                       AS execution_steps,
  t.cognitiveLoadProfile        AS cognitive_load,
  t.evidenceLevel               AS evidence_level,
  t.avgLatency_ms               AS latency_ms
ORDER BY t.evidenceLevel DESC, t.avgLatency_ms ASC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// B4 — DST Slot Fill Check
//
// Natural language: "Which information slots are still missing, and what
//                    dialogue act should the agent use to fill them?"
// Input:  $domain (string)
// Output: unfilled slots with the DialogueAct needed to fill each
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $domain (string)

MATCH (b:BDIState {domain: $domain})-[:HAS_SLOT]->(s:DomainSlot)
WHERE s.filled = false
OPTIONAL MATCH (s)-[:REQUIRES_ACT]->(a:DialogueAct)
RETURN
  s.slotName                    AS unfilled_slot,
  s.valueType                   AS value_type,
  s.validValues                 AS valid_values,
  s.description                 AS slot_description,
  a.communicativeFunction       AS required_act,
  a.dimension                   AS act_dimension
ORDER BY s.slotName;


// ─────────────────────────────────────────────────────────────────────────────
// B5 — Act-State Safety Gate
//
// Natural language: "Is it safe for the agent to issue this dialogue act right now?"
// Input:  $actId (string), $currentEmotionalState (string), $completedTechniqueIds (list)
// Output: CLEARED or BLOCKED with blocking reason
// ─────────────────────────────────────────────────────────────────────────────
// Parameters: $actId (string), $currentEmotionalState (string),
//             $completedTechniqueIds (list of strings)

MATCH (a:DialogueAct {id: $actId})
OPTIONAL MATCH (e:EmotionalState)
WHERE toLower(e.name) = toLower($currentEmotionalState)
OPTIONAL MATCH (a)-[:CONTRAINDICATED_WHEN]->(blocked_state:EmotionalState)
WHERE toLower(blocked_state.name) = toLower($currentEmotionalState)
OPTIONAL MATCH (a)-[:TRIGGERS]->(t:Technique)-[:REQUIRES]->(prereq:Technique)
WITH a, e, blocked_state,
     collect(DISTINCT prereq.id)         AS requiredPrereqs,
     $completedTechniqueIds              AS completed
WITH a, e, blocked_state, requiredPrereqs, completed,
     [p IN requiredPrereqs WHERE NOT p IN completed] AS unsatisfied
RETURN
  a.communicativeFunction               AS intended_act,
  a.requiresInfluencePrereq             AS needs_influence_prereq,
  e.name                                AS current_state,
  CASE
    WHEN blocked_state IS NOT NULL
    THEN "BLOCKED — act contraindicated in current emotional state"
    WHEN a.requiresInfluencePrereq = true AND size(unsatisfied) > 0
    THEN "BLOCKED — influence prerequisite not satisfied"
    ELSE "CLEARED"
  END                                   AS safety_gate_status,
  blocked_state.name                    AS contraindicated_state,
  unsatisfied                           AS missing_prerequisites;


// ─────────────────────────────────────────────────────────────────────────────
// B6 — Full BDI Turn (composed query)
//
// Natural language: "Given the full conversation state, what is the agent's
//                    complete Belief/Desire/Intention triple for this turn?"
// Input:  $domain, $emotionalState, $currentProtocolStep, $completedTechniqueIds
// Output: belief summary + desire + intention (DialogueAct + Technique)
//
// This is the primary query called once per conversation turn by the agent.
// ─────────────────────────────────────────────────────────────────────────────
// Parameters: $domain (string), $emotionalState (string),
//             $currentProtocolStep (string), $completedTechniqueIds (list)

MATCH (bdi:BDIState {domain: $domain})-[:HAS_SLOT]->(s:DomainSlot)
WITH bdi,
     collect({slot: s.slotName, filled: s.filled}) AS slots,
     size([x IN collect(s) WHERE x.filled = false]) AS unfilled_count

// Belief: slot inventory + protocol position
WITH bdi, slots, unfilled_count,
     bdi.beliefTemplate  AS belief_frame,
     bdi.desireTemplate  AS desire_frame

// Intention: safe next act given current emotional state
MATCH (e:EmotionalState)
WHERE toLower(e.name) = toLower($emotionalState)
MATCH (a:DialogueAct)
WHERE NOT (a)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT a.requiresInfluencePrereq = true
MATCH (a)-[:TRIGGERS]->(t:Technique)
WHERE t.domain CONTAINS $domain
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
WITH bdi, slots, unfilled_count, belief_frame, desire_frame, a, t, e,
     collect(DISTINCT prereq.id)    AS requiredPrereqs,
     $completedTechniqueIds         AS completed
WITH bdi, slots, unfilled_count, belief_frame, desire_frame, a, t, e,
     requiredPrereqs, completed,
     [p IN requiredPrereqs WHERE NOT p IN completed] AS unsatisfied
WHERE size(unsatisfied) = 0
RETURN
  // BELIEF
  bdi.domain                          AS domain,
  belief_frame                        AS belief_template,
  slots                               AS slot_state,
  unfilled_count                      AS unfilled_slots,

  // DESIRE
  desire_frame                        AS agent_desire,

  // INTENTION
  a.communicativeFunction             AS intended_dialogue_act,
  a.dimension                         AS act_dimension,
  t.id                                AS technique_id,
  t.name                              AS technique_name,
  t.steps                             AS execution_steps,
  t.cognitiveLoadProfile              AS cognitive_load,
  t.evidenceLevel                     AS evidence_level,
  t.avgLatency_ms                     AS latency_ms,
  e.name                              AS current_emotional_state

ORDER BY t.evidenceLevel DESC, t.avgLatency_ms ASC
LIMIT 3;
