// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 4 — Text2Cypher Query Library
//
// 12 production query templates covering all primary retrieval patterns.
// Each query includes:
//   - Parameter declarations ($param) for driver injection
//   - The exact Cypher pattern described in the guide
//   - A plain-text description of the natural language input it handles
//   - Expected output columns
//
// For testing in Neo4j Browser, replace $param with literal values.
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// Q1 — Technique by Detected Emotional State
//
// Natural language input: "Caller is showing signs of panic"
// Context: Real-time emotional state detected from signal processing
// Returns: Ranked safe techniques for the given state + domain
// ─────────────────────────────────────────────────────────────────────────────
// Parameters: $detectedState (string), $domain (string)

MATCH (e:EmotionalState)
WHERE e.name = $detectedState
   OR toLower(e.name) = toLower($detectedState)
MATCH (t:Technique)
WHERE (t.domain CONTAINS $domain OR $domain = "any")
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
OPTIONAL MATCH (t)-[:TRIGGERED_BY]->(sig:SignalMarker)
RETURN
  t.id                   AS technique_id,
  t.name                 AS technique_name,
  t.steps                AS steps,
  t.cognitiveLoadProfile AS cognitive_load,
  t.evidenceLevel        AS evidence_level,
  t.avgLatency_ms        AS avg_latency_ms,
  t.switchTo             AS fallback_options,
  collect(sig.name)      AS trigger_signals
ORDER BY t.evidenceLevel DESC, t.avgLatency_ms ASC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// Q2 — Technique by Signal Marker
//
// Natural language input: "Agent detected rapid speech rate increase"
// Context: Signal markers detected from prosodic / linguistic analysis
// Returns: Directly triggered techniques + prerequisites
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $signalId (string), $domain (string)

MATCH (sig:SignalMarker)
WHERE sig.id = $signalId
   OR toLower(sig.name) = toLower($signalId)
MATCH (sig)-[:TRIGGERS]->(t:Technique)
WHERE t.domain CONTAINS $domain OR $domain = "any"
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
RETURN
  sig.name               AS detected_signal,
  t.id                   AS technique_id,
  t.name                 AS technique_name,
  t.cognitiveLoadProfile AS cognitive_load,
  t.evidenceLevel        AS evidence_level,
  collect(prereq.name)   AS required_prerequisites
ORDER BY t.evidenceLevel DESC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// Q3 — Full Prerequisite Chain
//
// Natural language input: "What must happen before I can use [technique]?"
// Context: Agent planning multi-turn conversation strategy
// Returns: Ordered prerequisite chain from current technique back to baseline
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $techniqueId (string)

MATCH (t:Technique {id: $techniqueId})
MATCH path = (baseline:Technique {isEmotionalPrerequisite: true})
             -[:PRECEDES|REQUIRES*1..5]->(t)
RETURN
  t.name                              AS target_technique,
  length(path)                        AS chain_depth,
  [n IN nodes(path) | n.name]        AS prerequisite_chain,
  [n IN nodes(path) | n.cognitiveLoadProfile] AS load_profile_chain
ORDER BY chain_depth ASC
LIMIT 3;


// ─────────────────────────────────────────────────────────────────────────────
// Q4 — Domain Protocol Step Sequence
//
// Natural language input: "What are the steps for BCSM in a panic call?"
// Context: Agent needs ordered protocol steps for structured intervention
// Returns: Ordered technique sequence for a named protocol
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $protocolName (string), $domain (string)

MATCH (proto:DomainProtocol)
WHERE toLower(proto.name) CONTAINS toLower($protocolName)
  AND (proto.domain CONTAINS $domain OR $domain = "any")
MATCH path = (proto)-[:PRECEDES*1..10]->(step:Technique)
RETURN
  proto.name                          AS protocol,
  length(path)                        AS step_number,
  step.name                           AS step_name,
  step.steps                          AS execution_instructions,
  step.cognitiveLoadProfile           AS cognitive_load,
  [n IN nodes(path) | n.name]        AS full_sequence_so_far
ORDER BY step_number ASC
LIMIT 15;


// ─────────────────────────────────────────────────────────────────────────────
// Q5 — Contraindication Filter (Multiple Active States)
//
// Natural language input: "Caller is both dissociated and hostile — what's safe?"
// Context: Multiple emotional states detected simultaneously
// Returns: Techniques safe for ALL listed states in given domain
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $states (list of strings), $domain (string)

MATCH (t:Technique)
WHERE t.domain CONTAINS $domain
  AND NOT exists {
    MATCH (t)-[:CONTRAINDICATED_WHEN]->(e:EmotionalState)
    WHERE e.name IN $states
  }
  AND NOT t.requiresEmotionalClearance = true
RETURN
  t.id                   AS technique_id,
  t.name                 AS technique_name,
  t.cognitiveLoadProfile AS cognitive_load,
  t.evidenceLevel        AS evidence_level,
  t.whenToUse            AS when_to_use
ORDER BY t.avgLatency_ms ASC, t.evidenceLevel DESC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// Q6 — Cultural Variant
//
// Natural language input: "Adapt active listening for a high-context culture"
// Context: Cultural context detected from user profile or linguistic signals
// Returns: The culturally adapted variant of a given technique
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $coreTechniqueName (string), $culturalContextCode (string)

MATCH (core:Technique)
WHERE toLower(core.name) = toLower($coreTechniqueName)
MATCH (variant:Technique)-[:CULTURAL_VARIANT_OF]->(core)
MATCH (ctx:CulturalContext)
WHERE ctx.code = $culturalContextCode
   OR toLower(ctx.label) CONTAINS toLower($culturalContextCode)
RETURN
  core.name              AS core_technique,
  variant.name           AS cultural_variant,
  variant.culturalNotes  AS adaptation_notes,
  variant.steps          AS adapted_steps,
  ctx.label              AS cultural_context
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// Q7 — Domain Variant
//
// Natural language input: "What is the clinical version of active listening?"
// Context: Agent switching domains mid-conversation
// Returns: Domain-specific adaptation of a core technique
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $coreTechniqueName (string), $targetDomain (string)

MATCH (core:Technique)
WHERE toLower(core.name) = toLower($coreTechniqueName)
MATCH (variant:Technique)-[:DOMAIN_VARIANT_OF]->(core)
WHERE variant.domain CONTAINS $targetDomain
RETURN
  core.name              AS core_technique,
  variant.name           AS domain_variant,
  variant.domain         AS domain,
  variant.steps          AS domain_specific_steps,
  variant.whenToUse      AS activation_conditions,
  variant.culturalNotes  AS cultural_notes
ORDER BY variant.evidenceLevel DESC
LIMIT 3;


// ─────────────────────────────────────────────────────────────────────────────
// Q8 — Escalation Path
//
// Natural language input: "Active listening is failing — what's next?"
// Context: Current technique is not working; agent needs fallback strategy
// Returns: The escalation chain from current failing technique
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $failingTechniqueId (string)

MATCH (failing:Technique {id: $failingTechniqueId})
OPTIONAL MATCH (failing)-[:ESCALATES_TO]->(escalated:Technique)
OPTIONAL MATCH (failing)-[:RESOLVES]->(state:EmotionalState)
RETURN
  failing.name           AS failing_technique,
  failing.failureSignals AS what_failure_looks_like,
  escalated.name         AS escalate_to,
  escalated.steps        AS escalation_steps,
  failing.switchTo       AS alternative_fallbacks,
  state.name             AS resolves_state
LIMIT 3;


// ─────────────────────────────────────────────────────────────────────────────
// Q9 — Cognitive Load Route (Relevance Theory)
//
// Natural language input: "User is overwhelmed — simplify the strategy"
// Context: Cognitive overload detected via filler words, slow speech, silence
// Returns: Low-complexity techniques appropriate for current domain
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $domain (string), $maxComplexity (string: "low" | "medium")

MATCH (t:Technique)
WHERE t.domain CONTAINS $domain
  AND t.cognitiveComplexity = $maxComplexity
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {name: "Cognitive Overload"})
RETURN
  t.id                   AS technique_id,
  t.name                 AS technique_name,
  t.cognitiveLoadProfile AS load_profile,
  t.steps                AS steps,
  t.evidenceLevel        AS evidence
ORDER BY t.avgLatency_ms ASC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// Q10 — Multi-Hop Strategy Traversal (3-hop)
//
// Natural language input:
//   "Caller panicking, dispatch domain, what is the evidence chain?"
// Context: Full contextual retrieval with chain of reasoning
// Returns: Signal → technique → prerequisite → core anchor with full path
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $signalId (string), $domain (string)

MATCH path = (sig:SignalMarker)
             -[:TRIGGERS]->(t1:Technique)
             -[:REQUIRES]->(t2:Technique)
WHERE (t1.domain CONTAINS $domain OR $domain = "any")
  AND sig.id = $signalId
OPTIONAL MATCH (t1)-[:DOMAIN_VARIANT_OF]->(core:Technique)
RETURN
  sig.name                             AS detected_signal,
  t1.name                              AS triggered_technique,
  t1.steps                             AS technique_steps,
  t2.name                              AS required_prerequisite,
  t2.steps                             AS prerequisite_steps,
  core.name                            AS core_anchor,
  [n IN nodes(path) | n.name]         AS traversal_chain,
  length(path)                         AS hops
ORDER BY hops ASC, t1.evidenceLevel DESC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// Q11 — Safety Gate Check (Phase 1 Doctrine Enforcement)
//
// Natural language input:
//   "Can I use [influence technique] now given current conversation state?"
// Context: Runtime pre-flight check before activating influence technique
// Returns: PASS or FAIL with blocking reason
// ─────────────────────────────────────────────────────────────────────────────
// Parameters: $techniqueId (string), $completedTechniqueIds (list of strings)

MATCH (t:Technique {id: $techniqueId})
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
WITH t, collect(prereq.id) AS requiredPrereqs
WITH t, requiredPrereqs,
     [p IN requiredPrereqs WHERE p IN $completedTechniqueIds] AS satisfiedPrereqs,
     [p IN requiredPrereqs WHERE NOT p IN $completedTechniqueIds] AS unsatisfiedPrereqs
RETURN
  t.name                    AS technique,
  t.requiresEmotionalClearance AS requires_clearance,
  CASE
    WHEN t.requiresEmotionalClearance = true
     AND size(unsatisfiedPrereqs) > 0
    THEN "BLOCKED"
    ELSE "CLEARED"
  END                        AS safety_gate_status,
  unsatisfiedPrereqs         AS missing_prerequisites,
  satisfiedPrereqs           AS completed_prerequisites;


// ─────────────────────────────────────────────────────────────────────────────
// Q12 — Full Dispatch Protocol Query (from Guide §4.5)
//
// Natural language input:
//   "Caller is panicking, speaking rapidly, using victim language"
// Context: Crisis dispatch, real-time, emotional state confirmed
// Returns: Top 5 ranked safe intervention strategies
//
// This is the canonical Text2Cypher example from the UCKB guide.
// ─────────────────────────────────────────────────────────────────────────────
// Parameter: $detectedEmotionalState (string, e.g. "Panic")

MATCH (e:EmotionalState)
WHERE toLower(e.name) = toLower($detectedEmotionalState)
MATCH (t:Technique)
WHERE t.domain CONTAINS "Crisis"
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
OPTIONAL MATCH (t)-[:TRIGGERED_BY]->(sig:SignalMarker)
OPTIONAL MATCH (t)-[:RESOLVES]->(resolved:EmotionalState)
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
RETURN
  t.id                   AS technique_id,
  t.name                 AS technique_name,
  t.steps                AS execution_steps,
  t.cognitiveLoadProfile AS cognitive_load,
  t.catDirection         AS cat_direction,
  t.evidenceLevel        AS evidence_level,
  t.avgLatency_ms        AS latency_ms,
  collect(DISTINCT sig.name)      AS detected_triggers,
  collect(DISTINCT resolved.name) AS states_resolved,
  collect(DISTINCT prereq.name)   AS prerequisites
ORDER BY t.evidenceLevel DESC, t.avgLatency_ms ASC
LIMIT 5;
