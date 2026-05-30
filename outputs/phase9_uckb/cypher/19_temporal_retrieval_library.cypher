// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 9 — Step 19: Temporal Retrieval Library
// Adds 6 Text2CypherTemplate nodes for temporal memory queries.
// These extend the Phase 8 SchemaFilterRegistry pattern and are tagged
// category: 'temporal' to distinguish them from domain technique queries.
//
// Template parameters use $param notation (same convention as Phase 8).
// ─────────────────────────────────────────────────────────────────────────────

// ── Template 1: RECENT_EMOTIONAL_ARC ─────────────────────────────────────────
// "What emotional states has the caller shown in this session?"

MERGE (t1:Text2CypherTemplate {templateId: 'temporal_recent_emotional_arc'})
SET t1 += {
  name:        'RECENT_EMOTIONAL_ARC',
  category:    'temporal',
  description: 'Returns the last N emotional states detected in a session, ordered newest-first',
  parameters:  ['sessionId', 'limit'],
  cypher: '
MATCH (s:Session {sessionId: $sessionId})-[:HAS_TURN]->(turn:Turn)
MATCH (turn)-[:DETECTED]->(e:EmotionalState)
RETURN turn.turnNumber AS turnNum,
       e.name AS emotion,
       turn.timestamp AS ts,
       turn.speakerRole AS speaker
ORDER BY turn.timestamp DESC
LIMIT $limit
  ',
  exampleCall: '{sessionId: "demo_session_001", limit: 5}',
  usedBy:      'BCSM crisis escalation monitor, clinical SPIKES consent gate'
};

// ── Template 2: TECHNIQUE_SUCCESS_RATE ────────────────────────────────────────
// "Which techniques have worked best for this user in this domain?"

MERGE (t2:Text2CypherTemplate {templateId: 'temporal_technique_success_rate'})
SET t2 += {
  name:        'TECHNIQUE_SUCCESS_RATE',
  category:    'temporal',
  description: 'Returns technique success rates for a user in a domain, sorted by decayed weight',
  parameters:  ['userId', 'domain'],
  cypher: '
MATCH (mt:MemoryTrace {userId: $userId, domain: $domain})-[:REINFORCES]->(tech:Technique)
RETURN tech.name AS technique,
       tech.cardId AS cardId,
       mt.successCount AS successes,
       mt.failCount AS failures,
       round(100.0 * mt.successCount / (mt.successCount + mt.failCount + 0.001), 1) AS successPct,
       round(mt.weight, 4) AS decayedWeight,
       mt.lastUsed AS lastUsed
ORDER BY mt.weight DESC
LIMIT 10
  ',
  exampleCall: '{userId: "demo_user_001", domain: "Crisis Dispatch"}',
  usedBy:      'Technique selection bias, personalised recommendation layer'
};

// ── Template 3: WORKING_MEMORY_SNAPSHOT ──────────────────────────────────────
// "What is the current state of this session's working memory?"

MERGE (t3:Text2CypherTemplate {templateId: 'temporal_working_memory_snapshot'})
SET t3 += {
  name:        'WORKING_MEMORY_SNAPSHOT',
  category:    'temporal',
  description: 'Returns all non-expired WorkingMemorySlots for a session, newest-first',
  parameters:  ['sessionId'],
  cypher: '
MATCH (s:Session {sessionId: $sessionId})-[:HAS_SLOT]->(wm:WorkingMemorySlot)
WHERE wm.ttl > timestamp()
RETURN wm.key AS slot,
       wm.value AS value,
       wm.domain AS domain,
       wm.updatedAt AS updatedAt,
       wm.ttl - timestamp() AS msUntilExpiry
ORDER BY wm.updatedAt DESC
  ',
  exampleCall: '{sessionId: "demo_session_001"}',
  usedBy:      'Agent context reconstruction, protocol resume after interruption'
};

// ── Template 4: STALE_MEMORY ─────────────────────────────────────────────────
// "Which working memory slots are expired and should be cleaned up?"

MERGE (t4:Text2CypherTemplate {templateId: 'temporal_stale_memory'})
SET t4 += {
  name:        'STALE_MEMORY',
  category:    'temporal',
  description: 'Identifies WorkingMemorySlots whose TTL has expired; for cleanup or archiving',
  parameters:  [],
  cypher: '
MATCH (wm:WorkingMemorySlot)
WHERE wm.ttl < timestamp()
RETURN wm.sessionId AS session,
       wm.key AS slot,
       wm.value AS lastValue,
       wm.domain AS domain,
       wm.ttl AS expiredAt,
       timestamp() - wm.ttl AS overdueMs
ORDER BY wm.ttl ASC
  ',
  exampleCall: '{}',
  usedBy:      'Memory housekeeping job, session garbage collection'
};

// ── Template 5: SESSION_SUMMARY ───────────────────────────────────────────────
// "Give me a full summary of this session including protocol status."

MERGE (t5:Text2CypherTemplate {templateId: 'temporal_session_summary'})
SET t5 += {
  name:        'SESSION_SUMMARY',
  category:    'temporal',
  description: 'Returns session metadata, active protocol + step, and episodic memory arc for one session',
  parameters:  ['sessionId'],
  cypher: '
MATCH (s:Session {sessionId: $sessionId})
OPTIONAL MATCH (s)-[:ACTIVE_PROTOCOL]->(dag:ProtocolDAG)
OPTIONAL MATCH (s)-[:AT_STEP]->(step:ProtocolStep)
OPTIONAL MATCH (s)-[:HAS_EPISODE]->(ep:EpisodicMemory)
RETURN s.sessionId AS id,
       s.userId AS userId,
       s.domainContext AS domain,
       s.status AS status,
       s.outcomeScore AS outcomeScore,
       dag.name AS protocol,
       dag.protocol AS protocolCode,
       step.name AS currentStep,
       step.stepNumber AS stepNumber,
       ep.emotionalArc AS emotionalArc,
       ep.summary AS summary,
       ep.protocolCompleted AS completed
  ',
  exampleCall: '{sessionId: "demo_session_001"}',
  usedBy:      'Post-call debrief, supervisor dashboard, next-session context loading'
};

// ── Template 6: USER_HISTORY ──────────────────────────────────────────────────
// "What have the last 5 sessions for this user looked like?"

MERGE (t6:Text2CypherTemplate {templateId: 'temporal_user_history'})
SET t6 += {
  name:        'USER_HISTORY',
  category:    'temporal',
  description: 'Returns last N sessions for a user with emotional arcs and outcome scores, newest-first',
  parameters:  ['userId', 'limit'],
  cypher: '
MATCH (s:Session {userId: $userId})
OPTIONAL MATCH (s)-[:HAS_EPISODE]->(ep:EpisodicMemory)
OPTIONAL MATCH (s)-[:ACTIVE_PROTOCOL]->(dag:ProtocolDAG)
RETURN s.sessionId AS sessionId,
       s.startedAt AS startedAt,
       s.domainContext AS domain,
       s.status AS status,
       s.outcomeScore AS outcomeScore,
       dag.protocol AS protocol,
       ep.emotionalArc AS emotionalArc,
       ep.lastCompletedStep AS lastStep,
       ep.protocolCompleted AS completed
ORDER BY s.startedAt DESC
LIMIT $limit
  ',
  exampleCall: '{userId: "demo_user_001", limit: 5}',
  usedBy:      'Cross-session pattern learning, user adaptation profile'
};

// ── Link temporal templates to SchemaFilterRegistry (Crisis domain) ───────────

MATCH (reg:SchemaFilterRegistry {domain: 'Crisis Dispatch'}), (t:Text2CypherTemplate)
WHERE t.category = 'temporal'
MERGE (reg)-[:HAS_TEMPLATE]->(t);
