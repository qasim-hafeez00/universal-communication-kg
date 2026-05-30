// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 24: Protocol Trackers
// Creates 3 ProtocolTracker nodes (one per Phase 9 demo session) and links:
//   Session  -[:HAS_TRACKER]->  ProtocolTracker
//   ProtocolTracker -[:TRACKS]-> ProtocolDAG
//
// Session 001: BCSM, on-track, interrupted at step 3
// Session 002: BCSM, deviated (step 4 repeated), completed
// Session 003: SPIN, on-track, completed at step 4
//
// Session 002 deviationCount=1 satisfies AC-P10-9 (>= 1 tracker with deviation).
// FLAGGED_DEVIATION edge is created in 25_conflict_detection.cypher.
// ─────────────────────────────────────────────────────────────────────────────


// ── ProtocolTracker: Session 001 — BCSM (interrupted at step 3) ──────────────

MERGE (pt1:ProtocolTracker {trackerId: 'tracker_s001_bcsm'})
SET pt1 += {
  sessionId:            'demo_session_001',
  protocolId:           'bcsm_dag',
  currentStep:          3,
  currentStepName:      'Empathy Validation',
  lastTransitionTurn:   3,
  expectedNextStep:     4,
  deviationCount:       0,
  status:               'on_track'
};

MATCH (s:Session {sessionId: 'demo_session_001'}), (pt:ProtocolTracker {trackerId: 'tracker_s001_bcsm'})
MERGE (s)-[:HAS_TRACKER]->(pt);

MATCH (pt:ProtocolTracker {trackerId: 'tracker_s001_bcsm'}), (dag:ProtocolDAG {protocol: 'BCSM'})
MERGE (pt)-[:TRACKS]->(dag);


// ── ProtocolTracker: Session 002 — BCSM (step 4 repeated, completed) ─────────

MERGE (pt2:ProtocolTracker {trackerId: 'tracker_s002_bcsm'})
SET pt2 += {
  sessionId:            'demo_session_002',
  protocolId:           'bcsm_dag',
  currentStep:          5,
  currentStepName:      'Commitment Elicitation',
  lastTransitionTurn:   6,
  expectedNextStep:     6,
  deviationCount:       1,
  status:               'deviated'
};

// Note: step 4 (Empathy Validation) was re-executed after step 5 was already
// reached, causing a backward deviation. The ProtocolTracker registered this
// at turn 6 and a ConsistencyConflict was raised (cc_s002_001, severity=minor).

MATCH (s:Session {sessionId: 'demo_session_002'}), (pt:ProtocolTracker {trackerId: 'tracker_s002_bcsm'})
MERGE (s)-[:HAS_TRACKER]->(pt);

MATCH (pt:ProtocolTracker {trackerId: 'tracker_s002_bcsm'}), (dag:ProtocolDAG {protocol: 'BCSM'})
MERGE (pt)-[:TRACKS]->(dag);


// ── ProtocolTracker: Session 003 — SPIN (completed cleanly at step 4) ────────

MERGE (pt3:ProtocolTracker {trackerId: 'tracker_s003_spin'})
SET pt3 += {
  sessionId:            'demo_session_003',
  protocolId:           'spin_dag',
  currentStep:          4,
  currentStepName:      'Need-Payoff',
  lastTransitionTurn:   10,
  expectedNextStep:     5,
  deviationCount:       0,
  status:               'completed'
};

MATCH (s:Session {sessionId: 'demo_session_003'}), (pt:ProtocolTracker {trackerId: 'tracker_s003_spin'})
MERGE (s)-[:HAS_TRACKER]->(pt);

MATCH (pt:ProtocolTracker {trackerId: 'tracker_s003_spin'}), (dag:ProtocolDAG {protocol: 'SPIN'})
MERGE (pt)-[:TRACKS]->(dag);
