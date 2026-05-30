// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 4 — Step 05: Phase 1 Doctrine Safety Constraints
//
// This script encodes the non-bypass sequencing rule from Phase 1 §8.1:
//
//   "emotional grounding comes before influence. The agent may gather urgent
//    safety facts when needed, but it must not attempt persuasion, compliance
//    pressure, or proposal framing until the user has been sufficiently
//    acknowledged, stabilized, and oriented."
//
//   Required path:
//     Signal detection → emotional state estimate → safety/risk context →
//     active listening or grounding → empathy/rapport →
//     task clarification → proposal or instruction
//
// Implementation approach:
//   1. Tag all influence-oriented techniques with requiresEmotionalClearance = true
//   2. Verify every tagged technique has a REQUIRES/FOLLOWS path to an
//      empathy/rapport prerequisite (doctrine violation check)
//   3. Create the runtime safety gate query that filters techniques at call time
//   4. Create CONTRAINDICATED_WHEN links for the most critical safety rules
//
// Run AFTER 04_import_domain_ontology.cypher.
// ─────────────────────────────────────────────────────────────────────────────


// ── 1. Tag influence-oriented techniques ─────────────────────────────────────
// A technique is "influence-oriented" if its whenToUse or steps describe
// persuasion, commitment, closing, compliance pressure, or proposal framing.

MATCH (t:Technique)
WHERE any(x IN t.whenToUse WHERE
       toLower(x) CONTAINS "persuasion"    OR
       toLower(x) CONTAINS "commitment"    OR
       toLower(x) CONTAINS "close"         OR
       toLower(x) CONTAINS "closing"       OR
       toLower(x) CONTAINS "compliance"    OR
       toLower(x) CONTAINS "anchor"        OR
       toLower(x) CONTAINS "concession"    OR
       toLower(x) CONTAINS "counter"       OR
       toLower(x) CONTAINS "propose"       OR
       toLower(x) CONTAINS "proposal"
     )
  OR toLower(t.steps) CONTAINS "anchor"
  OR toLower(t.steps) CONTAINS "propose"
  OR toLower(t.steps) CONTAINS "close"
SET t.requiresEmotionalClearance = true
RETURN count(t) AS influence_techniques_tagged;


// ── 2. Tag all crisis/clinical safety-critical techniques ────────────────────
// These require additional protection: empathy and grounding MUST come first.

MATCH (t:Technique)
WHERE t.domain CONTAINS "Crisis"
   OR t.domain CONTAINS "Clinical"
SET t.safetyCriticalDomain = true
RETURN count(t) AS safety_critical_techniques_tagged;


// ── 3. Tag grounding/empathy baseline techniques ──────────────────────────────
// These are the PREREQUISITE anchors that must appear before influence.

MATCH (t:Technique)
WHERE t.name IN [
  "Active Listening",
  "Empathic Validation",
  "Grounding",
  "Rapport",
  "Empathy",
  "Tactical Empathy",
  "Reflective Listening",
  "Motivational Listening"
]
SET t.isEmotionalPrerequisite = true
RETURN count(t) AS prerequisite_anchors_tagged;


// ── 4. Doctrine violation audit ───────────────────────────────────────────────
// Find influence techniques that have NO path to an empathy/rapport prerequisite.
// Expected result after correct ingestion: 0 rows (zero violations).

MATCH (influence:Technique {requiresEmotionalClearance: true})
WHERE NOT exists {
  MATCH (influence)-[:REQUIRES|FOLLOWS|PRECEDES*1..4]->(prereq:Technique)
  WHERE prereq.isEmotionalPrerequisite = true
}
RETURN influence.id            AS doctrine_violation,
       influence.name          AS technique_name,
       influence.domain        AS domain,
       "FAIL: no empathy/rapport prerequisite chain found" AS reason
ORDER BY domain, technique_name;


// ── 5. Doctrine passing techniques (informational) ───────────────────────────
MATCH (influence:Technique {requiresEmotionalClearance: true})
WHERE exists {
  MATCH (influence)-[:REQUIRES|FOLLOWS|PRECEDES*1..4]->(prereq:Technique)
  WHERE prereq.isEmotionalPrerequisite = true
}
RETURN count(influence) AS influence_techniques_with_valid_prerequisite_chain;


// ── 6. Critical CONTRAINDICATED_WHEN safety links ────────────────────────────
// Create safety edges from high-arousal influence techniques to the
// emotional states that absolutely block their use.

// Suicidal ideation blocks all persuasion and compliance techniques
MATCH (t:Technique {requiresEmotionalClearance: true})
MATCH (e:EmotionalState {name: "Suicidal Ideation"})
MERGE (t)-[r:CONTRAINDICATED_WHEN]->(e)
ON CREATE SET r.source = "phase1_doctrine", r.severity = "critical"
RETURN count(r) AS suicidal_ideation_blocks_created;

// Active psychotic episode blocks all persuasion techniques
MATCH (t:Technique {requiresEmotionalClearance: true})
MATCH (e:EmotionalState {name: "Active Psychotic Episode"})
MERGE (t)-[r:CONTRAINDICATED_WHEN]->(e)
ON CREATE SET r.source = "phase1_doctrine", r.severity = "critical"
RETURN count(r) AS psychotic_episode_blocks_created;

// Dissociated state blocks directive/instruction techniques
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "instruct"
   OR toLower(t.name) CONTAINS "direct"
   OR toLower(t.name) CONTAINS "command"
MATCH (e:EmotionalState {name: "Dissociated"})
MERGE (t)-[r:CONTRAINDICATED_WHEN]->(e)
ON CREATE SET r.source = "phase1_doctrine", r.severity = "high"
RETURN count(r) AS dissociation_blocks_created;

// Panic state blocks high-complexity/multi-step techniques
MATCH (t:Technique)
WHERE t.cognitiveLoadProfile CONTAINS "high"
  AND (t.domain CONTAINS "Crisis" OR t.domain CONTAINS "Clinical")
MATCH (e:EmotionalState {name: "Panic"})
MERGE (t)-[r:CONTRAINDICATED_WHEN]->(e)
ON CREATE SET r.source = "phase1_doctrine_cognitive_load", r.severity = "high"
RETURN count(r) AS panic_high_load_blocks_created;


// ── 7. Cognitive load routing tags ───────────────────────────────────────────
// Tag techniques by cognitive complexity level for Relevance Theory routing.
// Low-load techniques are preferred when CognitiveOverload is detected.

MATCH (t:Technique)
WHERE t.cognitiveLoadProfile CONTAINS "lowest"
   OR t.cognitiveLoadProfile CONTAINS "low"
SET t.cognitiveComplexity = "low"
RETURN count(t) AS low_complexity_tagged;

MATCH (t:Technique)
WHERE t.cognitiveLoadProfile CONTAINS "medium"
  AND NOT t.cognitiveLoadProfile CONTAINS "low"
SET t.cognitiveComplexity = "medium"
RETURN count(t) AS medium_complexity_tagged;

MATCH (t:Technique)
WHERE t.cognitiveLoadProfile CONTAINS "high"
  AND NOT t.cognitiveLoadProfile CONTAINS "low"
  AND NOT t.cognitiveLoadProfile CONTAINS "medium"
SET t.cognitiveComplexity = "high"
RETURN count(t) AS high_complexity_tagged;


// ── 8. CAT convergence/divergence tags ───────────────────────────────────────
// Tag techniques with their Communication Accommodation Theory direction.

MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport"
   OR toLower(t.name) CONTAINS "mirror"
   OR toLower(t.name) CONTAINS "empat"
   OR toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "reflective"
SET t.catDirection = "convergence"
RETURN count(t) AS convergence_techniques_tagged;

MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "boundary"
   OR toLower(t.name) CONTAINS "assertive"
   OR toLower(t.name) CONTAINS "adult state"
   OR toLower(t.name) CONTAINS "neutral"
SET t.catDirection = "divergence"
RETURN count(t) AS divergence_techniques_tagged;


// ── 9. Final safety audit summary ────────────────────────────────────────────
MATCH (t:Technique)
RETURN
  count(t)                                                       AS total_techniques,
  count(t.requiresEmotionalClearance)                           AS influence_techniques,
  count(t.isEmotionalPrerequisite)                              AS prerequisite_anchors,
  count(t.safetyCriticalDomain)                                 AS safety_critical_domain,
  count(t.cognitiveComplexity)                                  AS cognitive_complexity_tagged,
  count(t.catDirection)                                         AS cat_direction_tagged;
