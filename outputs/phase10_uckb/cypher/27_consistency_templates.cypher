// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 27: Consistency Retrieval Library
// Adds 6 Text2CypherTemplate nodes for D-SMART consistency queries.
// Tagged category: 'consistency' — distinct from temporal (Phase 9) and
// domain technique templates (Phase 8).
//
// Template parameters use $param notation (same convention as Phases 8-9).
// ─────────────────────────────────────────────────────────────────────────────


// ── Template 1: ACTIVE_FACTS_SNAPSHOT ────────────────────────────────────────
// "What are the currently live facts in this session's DSM?"

MERGE (t1:Text2CypherTemplate {templateId: 'consistency_active_facts_snapshot'})
SET t1 += {
  name:        'ACTIVE_FACTS_SNAPSHOT',
  category:    'consistency',
  description: 'Returns all non-superseded ConversationFacts for a session ordered by weight descending — the live DSM state',
  parameters:  ['sessionId'],
  cypher: '
MATCH (cf:ConversationFact {sessionId: $sessionId, superseded: false})
OPTIONAL MATCH (cf)-[:EXTRACTED_FROM]->(t:Turn)
RETURN cf.factId AS factId,
       cf.content AS content,
       cf.factType AS type,
       cf.speakerRole AS speaker,
       cf.turnNumber AS turn,
       cf.weight AS weight,
       cf.validFrom AS validFrom,
       t.turnId AS sourceTurn
ORDER BY cf.weight DESC
  ',
  exampleCall: '{sessionId: "demo_session_001"}',
  usedBy:      'RT grounding pass — context loaded before candidate generation'
};


// ── Template 2: GOAL_DRIFT_CHECK ──────────────────────────────────────────────
// "Has the agent drifted from the user goal in this session?"

MERGE (t2:Text2CypherTemplate {templateId: 'consistency_goal_drift_check'})
SET t2 += {
  name:        'GOAL_DRIFT_CHECK',
  category:    'consistency',
  description: 'Returns GoalState for a session — current status, drift turn, confidence score',
  parameters:  ['sessionId'],
  cypher: '
MATCH (s:Session {sessionId: $sessionId})-[:HAS_GOAL]->(gs:GoalState)
RETURN gs.goalId AS goalId,
       gs.goalType AS goalType,
       gs.goalDescription AS description,
       gs.status AS status,
       gs.detectedAt AS detectedAt,
       gs.lastConfirmedAt AS lastConfirmedAt,
       gs.driftDetectedAt AS driftAt,
       gs.confidenceScore AS confidence
  ',
  exampleCall: '{sessionId: "demo_session_003"}',
  usedBy:      'DER computation, goal alignment scoring for ReasoningCandidates'
};


// ── Template 3: PROTOCOL_POSITION_QUERY ──────────────────────────────────────
// "Where is this session in its protocol and are there any deviations?"

MERGE (t3:Text2CypherTemplate {templateId: 'consistency_protocol_position_query'})
SET t3 += {
  name:        'PROTOCOL_POSITION_QUERY',
  category:    'consistency',
  description: 'Returns ProtocolTracker state for a session — current step, deviation count, flagged conflicts',
  parameters:  ['sessionId'],
  cypher: '
MATCH (s:Session {sessionId: $sessionId})-[:HAS_TRACKER]->(pt:ProtocolTracker)
MATCH (pt)-[:TRACKS]->(dag:ProtocolDAG)
OPTIONAL MATCH (pt)-[:FLAGGED_DEVIATION]->(cc:ConsistencyConflict)
RETURN pt.trackerId AS trackerId,
       dag.protocol AS protocol,
       dag.name AS protocolName,
       pt.currentStep AS currentStep,
       pt.currentStepName AS stepName,
       pt.expectedNextStep AS expectedNext,
       pt.deviationCount AS deviations,
       pt.status AS status,
       collect(cc.conflictId) AS flaggedConflicts
  ',
  exampleCall: '{sessionId: "demo_session_002"}',
  usedBy:      'ProtocolTracker.protocolDeviation input to RT candidate scoring'
};


// ── Template 4: CONFLICT_HISTORY ─────────────────────────────────────────────
// "What contradictions has the DSM detected in this session?"

MERGE (t4:Text2CypherTemplate {templateId: 'consistency_conflict_history'})
SET t4 += {
  name:        'CONFLICT_HISTORY',
  category:    'consistency',
  description: 'Returns all ConsistencyConflicts for a session ordered by severity then detection turn',
  parameters:  ['sessionId'],
  cypher: '
MATCH (cc:ConsistencyConflict {sessionId: $sessionId})
RETURN cc.conflictId AS conflictId,
       cc.conflictType AS type,
       cc.severity AS severity,
       cc.description AS description,
       cc.detectedAtTurn AS detectedAt,
       cc.resolutionStrategy AS resolution,
       cc.resolvedAtTurn AS resolvedAt
ORDER BY
  CASE cc.severity WHEN "critical" THEN 1 WHEN "moderate" THEN 2 ELSE 3 END ASC,
  cc.detectedAtTurn ASC
  ',
  exampleCall: '{sessionId: "demo_session_001"}',
  usedBy:      'Supervisor debrief, NLI validation audit, DER computation'
};


// ── Template 5: CANDIDATE_SELECTION_LOG ──────────────────────────────────────
// "What candidates did the RT generate for this turn and why was one chosen?"

MERGE (t5:Text2CypherTemplate {templateId: 'consistency_candidate_selection_log'})
SET t5 += {
  name:        'CANDIDATE_SELECTION_LOG',
  category:    'consistency',
  description: 'Returns all ReasoningCandidates for a session turn with scores — shows RT selection reasoning',
  parameters:  ['sessionId', 'turnNumber'],
  cypher: '
MATCH (rc:ReasoningCandidate {sessionId: $sessionId, turnNumber: $turnNumber})
OPTIONAL MATCH (rc)-[cf:CANDIDATE_FOR]->(t:Turn)
RETURN rc.candidateId AS candidateId,
       rc.responseSketch AS strategy,
       rc.nliScore AS nli,
       rc.goalAlignment AS goalAlign,
       rc.protocolDeviation AS protocolDev,
       rc.compositeScore AS composite,
       rc.selected AS selected,
       cf.rank AS rank
ORDER BY rc.compositeScore DESC
  ',
  exampleCall: '{sessionId: "demo_session_001", turnNumber: 4}',
  usedBy:      'RT explainability layer, agent training, supervisor review'
};


// ── Template 6: CONSISTENCY_REPORT_TREND ─────────────────────────────────────
// "How has the DER score evolved across this session?"

MERGE (t6:Text2CypherTemplate {templateId: 'consistency_report_trend'})
SET t6 += {
  name:        'CONSISTENCY_REPORT_TREND',
  category:    'consistency',
  description: 'Returns all ConsistencyReports for a session ordered by turn — DER score evolution over time',
  parameters:  ['sessionId'],
  cypher: '
MATCH (s:Session {sessionId: $sessionId})-[:HAS_REPORT]->(cr:ConsistencyReport)
RETURN cr.reportId AS reportId,
       cr.turnNumber AS turn,
       cr.derScore AS derScore,
       cr.factCount AS facts,
       cr.conflictCount AS conflicts,
       cr.activeGoals AS activeGoals,
       cr.protocolStep AS protocolStep,
       cr.deviationCount AS deviations
ORDER BY cr.turnNumber ASC
  ',
  exampleCall: '{sessionId: "demo_session_001"}',
  usedBy:      'Post-call quality analysis, DER trend monitoring dashboard'
};


// ── Link consistency templates to SchemaFilterRegistry ───────────────────────
// Linked to all 6 domain registries since D-SMART applies domain-agnostically

MATCH (reg:SchemaFilterRegistry), (t:Text2CypherTemplate)
WHERE t.category = 'consistency'
MERGE (reg)-[:HAS_TEMPLATE]->(t);
