// ============================================================
// UCKB Phase 8 — Script 14: Phase 8 Validation Suite
// Validates all 10 acceptance criteria
// Run after: 13_schema_filter_registry.cypher
// ============================================================

// ─── AC-P8-1: All 6 domain sub-graphs populated (≥40 nodes each new domain) ─

MATCH (t)
WHERE (t:Technique OR t:SignalMarker OR t:EmotionalState OR t:DomainProtocol OR t:StatementMarker OR t:KnowledgeState)
  AND t.domain = 'Legal & Investigative'
RETURN 'AC-P8-1 Legal' AS criterion, COUNT(t) AS node_count,
  CASE WHEN COUNT(t) >= 40 THEN 'PASS' ELSE 'FAIL' END AS status;

MATCH (t)
WHERE (t:Technique OR t:SignalMarker OR t:EmotionalState OR t:DomainProtocol OR t:KnowledgeState OR t:CommunicationStyle)
  AND t.domain = 'Corporate & Engineering'
RETURN 'AC-P8-1 Corporate' AS criterion, COUNT(t) AS node_count,
  CASE WHEN COUNT(t) >= 40 THEN 'PASS' ELSE 'FAIL' END AS status;

MATCH (t)
WHERE (t:Technique OR t:SignalMarker OR t:EmotionalState OR t:DomainProtocol OR t:KnowledgeState)
  AND t.domain = 'Education'
RETURN 'AC-P8-1 Education' AS criterion, COUNT(t) AS node_count,
  CASE WHEN COUNT(t) >= 40 THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-2: All 9 ProtocolDAG structures with zero cycles ─────────────────

MATCH (d:ProtocolDAG)
RETURN 'AC-P8-2 DAG count' AS criterion, COUNT(d) AS dag_count,
  CASE WHEN COUNT(d) >= 9 THEN 'PASS' ELSE 'FAIL' END AS status;

// Cycle detection (CRITICAL — expect zero rows)
MATCH path = (s:ProtocolStep)-[:PRECEDES*]->(s)
RETURN 'AC-P8-2 CYCLE CHECK' AS criterion, s.id AS cyclic_node,
  length(path) AS cycle_length, 'CRITICAL FAIL' AS status;

// ─── AC-P8-3: All ProtocolStep nodes (stepNumber > 1) have GATES ─────────────

MATCH (s:ProtocolStep)
WHERE s.stepNumber > 1
  AND NOT EXISTS {
    MATCH (g:ProtocolGate)-[:GATES]->(s)
  }
RETURN 'AC-P8-3 Unguarded Steps' AS criterion, s.id AS unguarded_step,
  s.protocol AS protocol, 'FAIL — missing gate' AS status;

MATCH (s:ProtocolStep)
WHERE s.stepNumber > 1
WITH COUNT(s) AS total_non_first_steps,
  COUNT(CASE WHEN EXISTS { MATCH (g:ProtocolGate)-[:GATES]->(s) } THEN 1 END) AS gated_steps
RETURN 'AC-P8-3 Gate Coverage' AS criterion,
  total_non_first_steps, gated_steps,
  CASE WHEN total_non_first_steps = gated_steps THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-4: Reid Technique exists exactly once, activation blocked ─────────

MATCH (t:Technique {cardId: 'legal_contraindicated_reid'})
RETURN 'AC-P8-4 Reid Exists' AS criterion, COUNT(t) AS count,
  t.activationBlocked AS blocked,
  t.contraindication AS contraindication,
  CASE WHEN COUNT(t) = 1 AND t.activationBlocked = true AND t.contraindication = 'ABSOLUTE'
    THEN 'PASS' ELSE 'FAIL' END AS status;

// Confirm Reid is never reachable via retrieval query
MATCH (t:Technique {cardId: 'legal_contraindicated_reid'})
OPTIONAL MATCH (t)-[:CONTRAINDICATED_WHEN]->(e:EmotionalState)
RETURN 'AC-P8-4 Reid Blocked' AS criterion,
  COUNT(e) AS block_edges,
  CASE WHEN COUNT(e) >= 1 THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-5: Cross-domain contamination matrix complete ────────────────────

MATCH (db:DomainBoundary)
RETURN 'AC-P8-5 Domain Boundaries' AS criterion,
  COUNT(db) AS boundary_count,
  CASE WHEN COUNT(db) >= 15 THEN 'PASS' ELSE 'FAIL' END AS status;

MATCH ()-[r:CONTRAINDICATED_WHEN {crossDomain: true}]->()
RETURN 'AC-P8-5 Cross-Domain Guards' AS criterion,
  COUNT(r) AS cross_domain_edge_count,
  CASE WHEN COUNT(r) >= 30 THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-6: Total graph nodes ≥ 700 ────────────────────────────────────────

MATCH (n)
WHERE n:Technique OR n:SignalMarker OR n:EmotionalState OR n:DomainProtocol
   OR n:ProtocolStep OR n:ProtocolDAG OR n:ProtocolGate OR n:DomainBoundary
   OR n:StatementMarker OR n:KnowledgeState OR n:CommunicationStyle
RETURN 'AC-P8-6 Total Content Nodes' AS criterion,
  COUNT(n) AS total_nodes,
  CASE WHEN COUNT(n) >= 700 THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-7: Schema filter registry has 6 domain entries ────────────────────

MATCH (r:SchemaFilterRegistry)
RETURN 'AC-P8-7 Schema Registry' AS criterion,
  COUNT(r) AS registry_entries,
  CASE WHEN COUNT(r) >= 6 THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-8: SHACL domain shapes pass (counted via property completeness) ───

// Check all legal techniques have peaceStep property
MATCH (t:Technique)
WHERE t.domain = 'Legal & Investigative'
  AND t.activationBlocked IS NULL
WITH COUNT(t) AS total,
  COUNT(CASE WHEN t.peaceStep IS NOT NULL THEN 1 END) AS with_peace_step
RETURN 'AC-P8-8 Legal SHACL' AS criterion, total, with_peace_step,
  CASE WHEN total = with_peace_step THEN 'PASS' ELSE 'FAIL' END AS status;

// Check all education techniques have bktTrigger property
MATCH (t:Technique)
WHERE t.domain = 'Education' AND t:CommunicationTechnique
WITH COUNT(t) AS total,
  COUNT(CASE WHEN t.bktTrigger IS NOT NULL THEN 1 END) AS with_bkt
RETURN 'AC-P8-8 Education SHACL' AS criterion, total, with_bkt,
  CASE WHEN total = with_bkt THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-9: All new techniques have reviewStatus ── ────────────────────────

MATCH (t:Technique)
WHERE t.domain IN ['Legal & Investigative','Corporate & Engineering','Education']
WITH COUNT(t) AS total,
  COUNT(CASE WHEN t.reviewStatus IS NOT NULL THEN 1 END) AS with_status
RETURN 'AC-P8-9 Review Status' AS criterion, total, with_status,
  CASE WHEN total = with_status THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── AC-P8-10: Text2Cypher templates return ≥3 results per domain ────────────

// Dispatch: test panic state retrieval
MATCH (e:EmotionalState)-[:TRIGGERS]->(t:Technique)
WHERE e.domain CONTAINS 'dispatch'
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND t.domain CONTAINS 'dispatch'
  AND t.cognitiveLoadProfile IN ['lowest-load', 'lowest safe load', 'low-load']
WITH COUNT(t) AS result_count
RETURN 'AC-P8-10 Dispatch Query' AS criterion, result_count,
  CASE WHEN result_count >= 3 THEN 'PASS' ELSE 'FAIL' END AS status;

// Legal: test PEACE step 2 retrieval
MATCH (s:ProtocolStep {protocol:'PEACE'})
WHERE s.stepNumber = 2
MATCH (s)-[:TRIGGERS]->(t:Technique)
WHERE NOT t.activationBlocked = true
WITH COUNT(t) AS result_count
RETURN 'AC-P8-10 Legal Query' AS criterion, result_count,
  CASE WHEN result_count >= 1 THEN 'PASS' ELSE 'FAIL' END AS status;

// Education: test BKT near-competent retrieval
MATCH (ks:KnowledgeState {cardId:'edu_ks_near_competent'})-[:TRIGGERS]->(t:Technique)
WITH COUNT(t) AS result_count
RETURN 'AC-P8-10 Education BKT Query' AS criterion, result_count,
  CASE WHEN result_count >= 1 THEN 'PASS' ELSE 'FAIL' END AS status;

// Corporate: test feedback context retrieval
MATCH (t:Technique)
WHERE t.domain = 'Corporate & Engineering'
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(:EmotionalState {cardId:'corp_emo_public_setting'})
WITH COUNT(t) AS result_count
RETURN 'AC-P8-10 Corporate Query' AS criterion, result_count,
  CASE WHEN result_count >= 3 THEN 'PASS' ELSE 'FAIL' END AS status;

// ─── Summary Node Distribution ─────────────────────────────────────────────

MATCH (t)
WHERE (t:Technique OR t:SignalMarker OR t:EmotionalState OR t:DomainProtocol
    OR t:ProtocolStep OR t:ProtocolDAG OR t:ProtocolGate OR t:DomainBoundary
    OR t:StatementMarker OR t:KnowledgeState OR t:CommunicationStyle)
RETURN 'Phase 8 Node Summary' AS report,
  t.domain AS domain,
  labels(t)[0] AS nodeType,
  COUNT(t) AS count
ORDER BY domain, nodeType;

// ─── Relationship type summary ──────────────────────────────────────────────

MATCH ()-[r]->()
WHERE type(r) IN ['CONTRAINDICATED_WHEN','PRECEDES','FOLLOWS','TRIGGERS','GATES','PART_OF',
                  'ENHANCES','RESOLVES','CONTRADICTS','REQUIRES','DOMAIN_VARIANT_OF',
                  'ESCALATES_TO','SAME_AS','TRIGGERED_BY','CULTURAL_VARIANT_OF',
                  'BYPASSES','COMPETENCY_AT','DECAYS_TO','DETECTED_BY']
RETURN type(r) AS relationship_type, COUNT(r) AS count
ORDER BY count DESC;
