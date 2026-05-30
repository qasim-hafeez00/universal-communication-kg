// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Cultural Routing Query Library
//
// 5 Cypher query templates implementing cross-cultural routing.
// Parameters use $param notation for driver injection.
// Replace with literals for testing in Neo4j Browser.
//
// Query index:
//   C1 — Cultural Profile Lookup       (profile -> all dimensions + active rules)
//   C2 — Behavioral Style Routing      (style name -> BehavioralStyleProfile + techniques)
//   C3 — Cultural Technique Selector   (profile + domain -> culturally-preferred techniques)
//   C4 — Emblem Disambiguation Gate    (gesture + profile -> interpret or flag mismatch)
//   C5 — Full Cultural Turn (composed) (profile + style + emotional state + domain -> techniques)
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// C1 — Cultural Profile Lookup
//
// Natural language: "What are the full cultural characteristics and active rules
//                    for this cultural profile?"
// Input:  $cultureProfileId (string, e.g. "culture_japan")
// Output: profile properties + all HAS_DIMENSION descriptors + all APPLIES_RULE rules
// ─────────────────────────────────────────────────────────────────────────────

MATCH (cp:CulturalProfile {id: $cultureProfileId})
OPTIONAL MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
OPTIONAL MATCH (cp)-[:APPLIES_RULE]->(rule:CulturalAdaptationRule)
RETURN
  cp.name                         AS cultural_profile,
  cp.lewisModel                   AS lewis_model,
  cp.hallContextLevel             AS hall_context_level,
  cp.faceSaving                   AS face_saving,
  cp.indirectCommunication        AS indirect_communication,
  cp.hofstedePDI                  AS pdi,
  cp.hofstedeIDV                  AS idv,
  cp.hofstedeMAS                  AS mas,
  cp.hofstedeUAI                  AS uai,
  cp.hofstedeLTO                  AS lto,
  cp.hofstedeIVR                  AS ivr,
  cp.timeOrientation              AS time_orientation,
  collect(DISTINCT dim.name)      AS active_dimensions,
  collect(DISTINCT rule.name)     AS active_adaptation_rules
LIMIT 1;


// ─────────────────────────────────────────────────────────────────────────────
// C2 — Behavioral Style Routing
//
// Natural language: "The interlocutor exhibits this communication style. What
//                    profile applies, how should the agent adapt, and what
//                    techniques are recommended?"
// Input:  $communicationStyleName (string, e.g. "Aggressive")
// Output: BehavioralStyleProfile + agentAdaptation + STYLE_SUGGESTS Techniques
// ─────────────────────────────────────────────────────────────────────────────

MATCH (bsp:BehavioralStyleProfile)
WHERE toLower(bsp.primaryStyle) = toLower($communicationStyleName)
OPTIONAL MATCH (bsp)-[:STYLE_SUGGESTS]->(t:Technique)
WHERE NOT t.requiresEmotionalClearance = true
   OR EXISTS {
     MATCH (prereq:Technique {isEmotionalPrerequisite: true})-[:PRECEDES]->(t)
   }
OPTIONAL MATCH (bsp)-[:MAPS_TO_EGO_STATE]->(ego:EgoState)
RETURN
  bsp.name                         AS behavioral_style_profile,
  bsp.primaryStyle                 AS primary_style,
  bsp.agentAdaptation              AS agent_adaptation,
  bsp.preferredEvidence            AS preferred_evidence,
  bsp.contraindicated              AS contraindicated_approaches,
  ego.name                         AS predicted_ego_state,
  ego.agentAction                  AS ego_agent_action,
  collect(DISTINCT t.name)[0..5]   AS suggested_techniques
LIMIT 1;


// ─────────────────────────────────────────────────────────────────────────────
// C3 — Cultural Technique Selector
//
// Natural language: "Given this cultural profile and domain, which techniques
//                    are culturally preferred and safe?"
// Input:  $cultureProfileId (string), $domainName (string, partial match)
// Output: Techniques preferred in profile's dimensional context, doctrine-checked
// ─────────────────────────────────────────────────────────────────────────────

MATCH (cp:CulturalProfile {id: $cultureProfileId})
MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
MATCH (t:Technique)-[:ADAPTS_FOR]->(dim)
WHERE ($domainName = "" OR t.domain IS NULL OR t.domain CONTAINS $domainName)
  AND NOT t.requiresEmotionalClearance = true
   OR EXISTS {
     MATCH (prereq:Technique {isEmotionalPrerequisite: true})-[:PRECEDES]->(t)
   }
WITH cp, collect(DISTINCT {
  technique:    t.name,
  dimension:    dim.name,
  evidence:     t.evidenceLevel,
  latency_ms:   t.avgLatency_ms
}) AS cultural_techniques
OPTIONAL MATCH (cp)-[:APPLIES_RULE]->(rule:CulturalAdaptationRule)
RETURN
  cp.name                          AS cultural_profile,
  cp.lewisModel                    AS lewis_model,
  cp.hallContextLevel              AS context_level,
  collect(DISTINCT rule.name)      AS active_rules,
  cultural_techniques              AS culturally_preferred_techniques
LIMIT 1;


// ─────────────────────────────────────────────────────────────────────────────
// C4 — Emblem Disambiguation Gate
//
// Natural language: "A BehavioralAdaptor emblem gesture was detected. Is this
//                    gesture safe to interpret in the given cultural profile, or
//                    does it require recalibration?"
// Input:  $cultureProfileId (string), $gestureType (string, partial match on gesture property)
// Output: RECALIBRATE_IN rules matching gesture + culture, or "safe to interpret" signal
// ─────────────────────────────────────────────────────────────────────────────

MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})
MATCH (cp:CulturalProfile {id: $cultureProfileId})
MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
OPTIONAL MATCH (ba)-[r:RECALIBRATE_IN]->(dim)
WHERE $gestureType = "" OR r.gesture IS NULL OR toLower(r.gesture) CONTAINS toLower($gestureType)
WITH cp, dim, r,
     CASE WHEN r IS NOT NULL THEN "RECALIBRATE" ELSE "SAFE_TO_INTERPRET" END AS interpretation_action
WHERE interpretation_action = "RECALIBRATE" OR NOT exists {
  MATCH (ba)-[:RECALIBRATE_IN]->(dim2:CulturalContext)
  WHERE (cp)-[:HAS_DIMENSION]->(dim2)
}
RETURN
  cp.name                      AS cultural_profile,
  dim.name                     AS matched_dimension,
  interpretation_action        AS action_required,
  r.gesture                    AS detected_gesture,
  r.normalMeaning              AS normal_interpretation,
  r.reinterpretAs              AS cultural_reinterpretation,
  r.flag                       AS flag,
  r.severity                   AS severity
ORDER BY r.severity DESC
LIMIT 5;


// ─────────────────────────────────────────────────────────────────────────────
// C5 — Full Cultural Turn (composed query)
//
// Natural language: "Given the full cultural reading for this turn, what is
//                    the agent's complete cultural adaptation and next action?"
// Input:  $cultureProfileId (string), $communicationStyleName (string),
//         $currentEmotionalState (string), $domain (string)
// Output: Active cultural rules + behavioral style Techniques + culturally-preferred
//         technique set, doctrine-checked, with gaze recalibration applied
// ─────────────────────────────────────────────────────────────────────────────

// Step 1: Cultural profile + active rules
MATCH (cp:CulturalProfile {id: $cultureProfileId})
MATCH (cp)-[:APPLIES_RULE]->(rule:CulturalAdaptationRule)

// Step 2: Behavioral style profile
OPTIONAL MATCH (bsp:BehavioralStyleProfile)
WHERE toLower(bsp.primaryStyle) = toLower($communicationStyleName)

// Step 3: Current emotional state
MATCH (e:EmotionalState) WHERE toLower(e.name) = toLower($currentEmotionalState)

// Step 4: Cultural dimensions of the profile
MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)

// Step 5: Culturally preferred techniques from ADAPTS_FOR
OPTIONAL MATCH (t_cult:Technique)-[:ADAPTS_FOR]->(dim)
WHERE NOT (t_cult)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t_cult.requiresEmotionalClearance = true
  AND ($domain = "" OR t_cult.domain IS NULL OR t_cult.domain CONTAINS $domain)

// Step 6: BehavioralStyleProfile suggested techniques
OPTIONAL MATCH (bsp)-[:STYLE_SUGGESTS]->(t_style:Technique)
WHERE NOT (t_style)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t_style.requiresEmotionalClearance = true
  AND ($domain = "" OR t_style.domain IS NULL OR t_style.domain CONTAINS $domain)

// Step 7: Gaze recalibration check (suppress deception flag in collectivist/reactive cultures)
OPTIONAL MATCH (facs:FacsMapping {id: "facs_microexpression"})-[rcal:RECALIBRATE_IN]->(dim)
WHERE rcal.signal = "gaze_aversion"

WITH cp, rule, bsp, e, dim, t_cult, t_style, rcal,
     CASE WHEN rcal IS NOT NULL THEN "SUPPRESS_DECEPTION_FLAG" ELSE "STANDARD" END AS gaze_protocol

RETURN
  // Cultural context
  cp.name                              AS cultural_profile,
  cp.lewisModel                        AS lewis_model,
  cp.hallContextLevel                  AS context_level,
  cp.faceSaving                        AS face_saving_required,
  collect(DISTINCT rule.name)[0..3]    AS active_cultural_rules,

  // Behavioral style
  bsp.name                             AS behavioral_style_profile,
  bsp.agentAdaptation                  AS style_adaptation,

  // Emotional state
  e.name                               AS current_emotional_state,

  // Techniques
  collect(DISTINCT t_cult.name)[0..3]  AS culturally_preferred_techniques,
  collect(DISTINCT t_style.name)[0..3] AS style_suggested_techniques,

  // Gaze protocol
  gaze_protocol                        AS gaze_aversion_protocol

ORDER BY cp.name
LIMIT 5;
