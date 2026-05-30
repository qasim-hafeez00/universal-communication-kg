// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 25: Conflict Detection
// Creates 4 ConsistencyConflict nodes and the edges that formalise them:
//
//   CONTRADICTS  — ConversationFact → ConversationFact (logical incompatibility)
//   SUPERSEDES   — ConversationFact → ConversationFact (temporal invalidation)
//   FLAGGED_DEVIATION — ProtocolTracker → ConsistencyConflict (protocol error)
//
// Conflict summary:
//   cc_s001_001  factual  critical  — presence vs. denial contradiction (Session 001)
//   cc_s001_002  factual  moderate  — weapon status contradiction (resolved by SUPERSEDES)
//   cc_s002_001  protocol minor     — BCSM step 4 repeated (Session 002)
//   cc_s003_001  goal     moderate  — goal drift at turn 9 (Session 003)
// ─────────────────────────────────────────────────────────────────────────────


// ════════════════════════════════════════════════════════════════════════════
// CONFLICT 1 — cc_s001_001
// Factual contradiction: "sister inside apartment" vs "denies entering"
// Facts: cf_s001_t01_001 CONTRADICTS cf_s001_t03_002
// Strategy: clarify — negotiator asked clarifying question at turn 4
// ════════════════════════════════════════════════════════════════════════════

MERGE (cc1:ConsistencyConflict {conflictId: 'cc_s001_001'})
SET cc1 += {
  sessionId:          'demo_session_001',
  conflictType:       'factual',
  severity:           'critical',
  description:        'Subject stated sister is inside apartment (turn 1) but denied entering the apartment (turn 3) — mutually exclusive claims',
  detectedAtTurn:     3,
  resolutionStrategy: 'clarify',
  resolvedAtTurn:     4
};

MATCH (cf_a:ConversationFact {factId: 'cf_s001_t01_001'}),
      (cf_b:ConversationFact {factId: 'cf_s001_t03_002'})
MERGE (cf_a)-[:CONTRADICTS {detectedAtTurn: 3, conflictId: 'cc_s001_001'}]->(cf_b);

MATCH (cf_a:ConversationFact {factId: 'cf_s001_t03_002'}),
      (cf_b:ConversationFact {factId: 'cf_s001_t01_001'})
MERGE (cf_a)-[:CONTRADICTS {detectedAtTurn: 3, conflictId: 'cc_s001_001'}]->(cf_b);


// ════════════════════════════════════════════════════════════════════════════
// CONFLICT 2 — cc_s001_002
// Factual contradiction: "claims unarmed" (turn 2) vs "admits holding knife" (turn 4)
// Resolution: temporal invalidation — newer fact supersedes older
// ════════════════════════════════════════════════════════════════════════════

MERGE (cc2:ConsistencyConflict {conflictId: 'cc_s001_002'})
SET cc2 += {
  sessionId:          'demo_session_001',
  conflictType:       'factual',
  severity:           'moderate',
  description:        'Subject claimed unarmed at turn 2 but admitted holding a knife at turn 4',
  detectedAtTurn:     4,
  resolutionStrategy: 'supersede',
  resolvedAtTurn:     4
};

// CONTRADICTS bidirectional
MATCH (cf_a:ConversationFact {factId: 'cf_s001_t02_001'}),
      (cf_b:ConversationFact {factId: 'cf_s001_t04_001'})
MERGE (cf_a)-[:CONTRADICTS {detectedAtTurn: 4, conflictId: 'cc_s001_002'}]->(cf_b);

MATCH (cf_a:ConversationFact {factId: 'cf_s001_t04_001'}),
      (cf_b:ConversationFact {factId: 'cf_s001_t02_001'})
MERGE (cf_a)-[:CONTRADICTS {detectedAtTurn: 4, conflictId: 'cc_s001_002'}]->(cf_b);

// SUPERSEDES — newer fact invalidates older (temporal edge invalidation)
MATCH (newer:ConversationFact {factId: 'cf_s001_t04_001'}),
      (older:ConversationFact {factId: 'cf_s001_t02_001'})
MERGE (newer)-[:SUPERSEDES {
  supersededAtTurn: 4,
  reason:           'Subject corrected prior claim; later admission is more reliable'
}]->(older);


// ════════════════════════════════════════════════════════════════════════════
// CONFLICT 3 — cc_s002_001
// Protocol deviation: BCSM step 4 (Empathy Validation) repeated after step 5
// FLAGGED_DEVIATION links ProtocolTracker → ConsistencyConflict
// ════════════════════════════════════════════════════════════════════════════

MERGE (cc3:ConsistencyConflict {conflictId: 'cc_s002_001'})
SET cc3 += {
  sessionId:          'demo_session_002',
  conflictType:       'protocol',
  severity:           'minor',
  description:        'BCSM step 4 (Empathy Validation) was re-executed after step 5 had already been reached — backward step deviation',
  detectedAtTurn:     6,
  resolutionStrategy: 'flag',
  resolvedAtTurn:     null
};

MATCH (pt:ProtocolTracker {trackerId: 'tracker_s002_bcsm'}),
      (cc:ConsistencyConflict {conflictId: 'cc_s002_001'})
MERGE (pt)-[:FLAGGED_DEVIATION {deviationStep: 4}]->(cc);


// ════════════════════════════════════════════════════════════════════════════
// CONFLICT 4 — cc_s003_001
// Goal drift: agent drifted to price objection at turn 9 instead of goal
// SUPERSEDES edges formalise the budget flexibility flip
// ════════════════════════════════════════════════════════════════════════════

MERGE (cc4:ConsistencyConflict {conflictId: 'cc_s003_001'})
SET cc4 += {
  sessionId:          'demo_session_003',
  conflictType:       'goal',
  severity:           'moderate',
  description:        'Agent drifted to surface-level price objection at turn 9; prospect later revealed flexibility via formal proposal request (turn 10)',
  detectedAtTurn:     9,
  resolutionStrategy: 'supersede',
  resolvedAtTurn:     10
};

// The "no budget flexibility" position (t09_002) is superseded by the
// "requests formal proposal" commitment (t10_002) — implicit budget approval
MATCH (newer:ConversationFact {factId: 'cf_s003_t10_002'}),
      (older:ConversationFact {factId: 'cf_s003_t09_002'})
MERGE (newer)-[:SUPERSEDES {
  supersededAtTurn: 10,
  reason:           'Formal proposal request implies budget flexibility contrary to prior position'
}]->(older);
