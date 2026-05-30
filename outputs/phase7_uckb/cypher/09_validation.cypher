// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 09: Acceptance Criteria Validation Queries
//
// 8 acceptance criteria matching Phase 4/5/6 validation pattern.
// Run after Steps 01-07 are complete.
//
// AC-1  All 10 CulturalProfile nodes with >=4 Hofstede dimension scores
// AC-2  Each CulturalProfile has >=3 HAS_DIMENSION links to CulturalContext nodes
// AC-3  Each CulturalProfile has >=1 APPLIES_RULE link to a CulturalAdaptationRule
// AC-4  All 7 BehavioralStyleProfile nodes have >=1 STYLE_SUGGESTS link to Technique
// AC-5  adaptor_emblem RECALIBRATE_IN >=3 CulturalContext; facs_microexpression >=2
// AC-6  ADAPTS_FOR relationships (Technique -> CulturalContext) >= 10
// AC-7  Zero Phase 1 doctrine violations in behavioral style routing paths
// AC-8  C5 full cultural turn returns >=1 result for 3 scenarios
// ─────────────────────────────────────────────────────────────────────────────


// ── AC-1: All 10 CulturalProfile nodes with >=4 Hofstede dimension scores ─────
// Expected: total=10, complete=10

MATCH (cp:CulturalProfile)
WITH cp,
     CASE WHEN cp.hofstedePDI IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN cp.hofstedeIDV IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN cp.hofstedeMAS IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN cp.hofstedeUAI IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN cp.hofstedeLTO IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN cp.hofstedeIVR IS NOT NULL THEN 1 ELSE 0 END
     AS hofstede_score_count
RETURN
  count(cp)                                                          AS total_profiles,
  count(CASE WHEN hofstede_score_count >= 4 THEN 1 END)             AS profiles_with_4plus_scores,
  round(100.0 * count(CASE WHEN hofstede_score_count >= 4 THEN 1 END) / count(cp), 1) AS pct;
// PASS if total_profiles = 10 AND pct = 100.0


// ── AC-2: Each CulturalProfile has >=3 HAS_DIMENSION links ────────────────────
// Expected: all 10 profiles with >=3 HAS_DIMENSION links

MATCH (cp:CulturalProfile)
OPTIONAL MATCH (cp)-[:HAS_DIMENSION]->(c:CulturalContext)
WITH cp, count(c) AS dimension_count
RETURN
  count(cp)                                                              AS total_profiles,
  count(CASE WHEN dimension_count >= 3 THEN 1 END)                      AS profiles_with_3plus_dims,
  round(100.0 * count(CASE WHEN dimension_count >= 3 THEN 1 END) / count(cp), 1) AS pct,
  min(dimension_count)                                                   AS min_dimensions;
// PASS if pct = 100.0


// ── AC-3: Each CulturalProfile has >=1 APPLIES_RULE link ─────────────────────
// Expected: all 10 profiles with >=1 APPLIES_RULE link

MATCH (cp:CulturalProfile)
OPTIONAL MATCH (cp)-[:APPLIES_RULE]->(r:CulturalAdaptationRule)
WITH cp, count(r) AS rule_count
RETURN
  count(cp)                                                             AS total_profiles,
  count(CASE WHEN rule_count >= 1 THEN 1 END)                          AS profiles_with_rules,
  round(100.0 * count(CASE WHEN rule_count >= 1 THEN 1 END) / count(cp), 1) AS pct;
// PASS if pct = 100.0


// ── AC-4: All 7 BehavioralStyleProfile nodes have >=1 STYLE_SUGGESTS ─────────
// Expected: 7/7 profiles with >=1 STYLE_SUGGESTS link

MATCH (bsp:BehavioralStyleProfile)
OPTIONAL MATCH (bsp)-[:STYLE_SUGGESTS]->(t:Technique)
WITH bsp, count(t) AS technique_count
RETURN
  count(bsp)                                                                AS total_bsp,
  count(CASE WHEN technique_count >= 1 THEN 1 END)                         AS bsp_with_techniques,
  round(100.0 * count(CASE WHEN technique_count >= 1 THEN 1 END) / count(bsp), 1) AS pct,
  collect({profile: bsp.name, techniques: technique_count})                AS detail;
// PASS if total_bsp = 7 AND pct = 100.0


// ── AC-5: RECALIBRATE_IN coverage ─────────────────────────────────────────────
// adaptor_emblem: >=3 CulturalContext nodes
// facs_microexpression: >=2 CulturalContext nodes

MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})-[r1:RECALIBRATE_IN]->(c1:CulturalContext)
WITH count(DISTINCT c1) AS emblem_count
MATCH (facs:FacsMapping {id: "facs_microexpression"})-[r2:RECALIBRATE_IN]->(c2:CulturalContext)
WITH emblem_count, count(DISTINCT c2) AS microexp_count
RETURN
  emblem_count    AS adaptor_emblem_recalibrate_in_count,
  microexp_count  AS facs_microexpression_recalibrate_in_count;
// PASS if emblem_count >= 3 AND microexp_count >= 2


// ── AC-6: ADAPTS_FOR relationships >= 10 ──────────────────────────────────────
// Expected: count >= 10

MATCH (t:Technique)-[r:ADAPTS_FOR]->(c:CulturalContext)
RETURN
  count(r)                         AS total_adapts_for,
  count(DISTINCT t)                AS distinct_techniques,
  count(DISTINCT c)                AS distinct_cultural_contexts;
// PASS if total_adapts_for >= 10


// ── AC-7: Zero Phase 1 doctrine violations in behavioral style routing ─────────
// Violation: BehavioralStyleProfile STYLE_SUGGESTS a Technique that
// requiresEmotionalClearance = true WITHOUT an empathy-prerequisite preceding it
// Expected: violations = 0

MATCH (bsp:BehavioralStyleProfile)-[:STYLE_SUGGESTS]->(t:Technique)
WHERE t.requiresEmotionalClearance = true
  AND NOT exists {
    MATCH (prereq:Technique {isEmotionalPrerequisite: true})-[:PRECEDES]->(t)
  }
RETURN
  count(*) AS doctrine_violations,
  collect({style_profile: bsp.name, technique: t.name}) AS violation_details;
// PASS if doctrine_violations = 0


// ── AC-8: C5 full cultural turn returns >=1 result for 3 scenarios ────────────

// Scenario A: High-context/face-saving — Japan profile + Distress
MATCH (cp:CulturalProfile {id: "culture_japan"})
MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
MATCH (e:EmotionalState) WHERE toLower(e.name) = "distress"
MATCH (t:Technique)-[:ADAPTS_FOR]->(dim)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
RETURN
  "japan_distress"    AS scenario,
  cp.name             AS profile,
  count(t)            AS technique_count
LIMIT 1;
// PASS if technique_count >= 1

// Scenario B: Low-context/direct — Germany profile + Hostile
MATCH (cp:CulturalProfile {id: "culture_germany"})
MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
MATCH (e:EmotionalState) WHERE toLower(e.name) = "hostile"
MATCH (t:Technique)-[:ADAPTS_FOR]->(dim)
WHERE NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
RETURN
  "germany_hostile"   AS scenario,
  cp.name             AS profile,
  count(t)            AS technique_count
LIMIT 1;
// PASS if technique_count >= 1

// Scenario C: Emblem disambiguation — Arab World profile + adaptor_emblem
MATCH (cp:CulturalProfile {id: "culture_arab_world"})
MATCH (cp)-[:HAS_DIMENSION]->(dim:CulturalContext)
MATCH (ba:BehavioralAdaptor {id: "adaptor_emblem"})-[r:RECALIBRATE_IN]->(dim)
MATCH (rule:CulturalAdaptationRule {id: "rule_emblem_disambiguation"})
MATCH (cp)-[:APPLIES_RULE]->(rule)
RETURN
  "arab_world_emblem_disambiguation"  AS scenario,
  cp.name                             AS profile,
  r.gesture                           AS flagged_gesture,
  r.reinterpretAs                     AS reinterpretation,
  count(*) AS result_count
LIMIT 1;
// PASS if result_count >= 1
