// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 4 — Step 07: Acceptance Criteria Validation
//
// Run AFTER all ingestion (steps 03-06) and safety annotations (step 05).
// Each block maps to one acceptance criterion (AC-1 through AC-10).
// Expected output is labelled for each check.
// ─────────────────────────────────────────────────────────────────────────────


// ── AC-1: 150 technique cards across node labels ──────────────────────────────
// Expected: total ≥ 150 across Technique + DomainProtocol + EmotionalState + SignalMarker
MATCH (n)
WHERE n:Technique OR n:DomainProtocol OR n:EmotionalState OR n:SignalMarker OR n:CommunicationStyle
RETURN "AC-1" AS check,
       labels(n)[0] AS label,
       count(n) AS count
ORDER BY count DESC;

// ── AC-2: Domain distribution of Technique nodes ─────────────────────────────
// Expected: 60 Crisis, 45 Sales, 45 Clinical
MATCH (t:Technique)
RETURN "AC-2" AS check,
       t.domain AS domain,
       count(t) AS count
ORDER BY count DESC;

// ── AC-3: All 11 locked relationship types present ───────────────────────────
// Expected: every type shows count > 0
UNWIND [
  "REQUIRES", "ENHANCES", "CONTRADICTS",
  "DOMAIN_VARIANT_OF", "CULTURAL_VARIANT_OF",
  "CONTRAINDICATED_WHEN", "ESCALATES_TO",
  "RESOLVES", "TRIGGERED_BY", "PRECEDES", "FOLLOWS"
] AS expectedType
OPTIONAL MATCH ()-[r]->()
WHERE type(r) = expectedType
RETURN "AC-3" AS check,
       expectedType AS relationship_type,
       count(r) AS count,
       CASE WHEN count(r) > 0 THEN "PASS" ELSE "FAIL" END AS status
ORDER BY expectedType;

// ── AC-4: Zero orphan Technique nodes ────────────────────────────────────────
// Expected: 0 orphan nodes
MATCH (t:Technique)
WHERE NOT (t)-[]-()
RETURN "AC-4" AS check,
       count(t) AS orphan_count,
       CASE WHEN count(t) = 0 THEN "PASS" ELSE "FAIL" END AS status;

// ── AC-5: Uniqueness constraints enforced ────────────────────────────────────
// Expected: 9+ constraints shown as ONLINE
SHOW CONSTRAINTS
YIELD name, type, labelsOrTypes, properties, state
RETURN "AC-5" AS check, name, labelsOrTypes, properties, state
ORDER BY name;

// ── AC-6: Performance indices created ────────────────────────────────────────
// Expected: 11+ indices shown as ONLINE
SHOW INDEXES
YIELD name, type, labelsOrTypes, properties, state
WHERE type <> "LOOKUP"
RETURN "AC-6" AS check, name, type, labelsOrTypes, properties, state
ORDER BY name;

// ── AC-7: Safety gate — zero Phase 1 doctrine violations ─────────────────────
// Expected: 0 rows returned
MATCH (influence:Technique {requiresEmotionalClearance: true})
WHERE NOT exists {
  MATCH (influence)-[:REQUIRES|FOLLOWS|PRECEDES*1..4]->(prereq:Technique)
  WHERE prereq.isEmotionalPrerequisite = true
}
RETURN "AC-7" AS check,
       count(influence) AS doctrine_violations,
       CASE WHEN count(influence) = 0 THEN "PASS" ELSE "FAIL" END AS status,
       collect(influence.name) AS violating_techniques;

// ── AC-8: Track A Resource nodes linked to Track B Technique nodes ────────────
// (Only applies after ingest_phase2_cypher.py has run Track B ingestion)
// Expected: every Resource with a cardId has a matching Technique node
MATCH (r:Resource)
WHERE r.cardId IS NOT NULL
OPTIONAL MATCH (t:Technique {id: r.cardId})
WITH count(r) AS resource_count,
     count(t) AS linked_count
RETURN "AC-8" AS check,
       resource_count,
       linked_count,
       CASE WHEN resource_count = linked_count THEN "PASS" ELSE "FAIL" END AS status;

// ── AC-9: Text2Cypher Q12 returns results ────────────────────────────────────
// Expected: ≥ 3 results for "Panic" in dispatch domain
MATCH (e:EmotionalState)
WHERE toLower(e.name) = "panic"
MATCH (t:Technique)
WHERE t.domain CONTAINS "Crisis"
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
WITH count(t) AS result_count
RETURN "AC-9" AS check,
       result_count AS dispatch_panic_results,
       CASE WHEN result_count >= 3 THEN "PASS" ELSE "FAIL" END AS status;

// ── AC-10: Cognitive load tags applied ───────────────────────────────────────
// Expected: all techniques have cognitiveComplexity tag
MATCH (t:Technique)
RETURN "AC-10" AS check,
       count(t) AS total_techniques,
       count(t.cognitiveComplexity) AS techniques_with_load_tag,
       CASE WHEN count(t) = count(t.cognitiveComplexity) THEN "PASS" ELSE "PARTIAL" END AS status;


// ── Full summary: all relationship types with counts ─────────────────────────
MATCH ()-[r]->()
RETURN type(r) AS relationship_type, count(r) AS total
ORDER BY total DESC;

// ── Full summary: all node labels with counts ─────────────────────────────────
MATCH (n)
UNWIND labels(n) AS lbl
RETURN lbl AS node_label, count(n) AS total
ORDER BY total DESC;
