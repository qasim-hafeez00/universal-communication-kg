// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 23: Goal Tracking
// Creates 3 GoalState nodes (one per Phase 9 demo session) and links each
// to its Session via HAS_GOAL.
//
// Session 001: safety goal — active (interrupted before resolution)
// Session 002: rapport goal — resolved (cooperative surrender achieved)
// Session 003: agreement goal — drifted at turn 9, recovered at turn 10
//
// The Session 003 drift scenario satisfies AC-P10-5 (>= 1 drifted goal).
// ─────────────────────────────────────────────────────────────────────────────


// ── GoalState: Session 001 — Safety (BCSM crisis, interrupted) ───────────────

MERGE (gs1:GoalState {goalId: 'goal_s001_primary'})
SET gs1 += {
  sessionId:         'demo_session_001',
  goalType:          'safety',
  goalDescription:   'De-escalate subject and ensure no harm to self, sister, or officers',
  status:            'active',
  detectedAt:        1,
  lastConfirmedAt:   3,
  driftDetectedAt:   null,
  confidenceScore:   0.83
};

MATCH (s:Session {sessionId: 'demo_session_001'}), (gs:GoalState {goalId: 'goal_s001_primary'})
MERGE (s)-[:HAS_GOAL {inferredAt: 1748390400000}]->(gs);


// ── GoalState: Session 002 — Rapport (BCSM continuation, completed) ──────────

MERGE (gs2:GoalState {goalId: 'goal_s002_primary'})
SET gs2 += {
  sessionId:         'demo_session_002',
  goalType:          'rapport',
  goalDescription:   'Maintain cooperative tone and achieve peaceful voluntary exit',
  status:            'resolved',
  detectedAt:        5,
  lastConfirmedAt:   7,
  driftDetectedAt:   null,
  confidenceScore:   0.96
};

MATCH (s:Session {sessionId: 'demo_session_002'}), (gs:GoalState {goalId: 'goal_s002_primary'})
MERGE (s)-[:HAS_GOAL {inferredAt: 1748480400000}]->(gs);


// ── GoalState: Session 003 — Agreement (SPIN sales, drifted then resolved) ───

MERGE (gs3:GoalState {goalId: 'goal_s003_primary'})
SET gs3 += {
  sessionId:         'demo_session_003',
  goalType:          'agreement',
  goalDescription:   'Progress prospect toward formal proposal commitment and next meeting',
  status:            'resolved',
  detectedAt:        8,
  lastConfirmedAt:   10,
  driftDetectedAt:   9,
  confidenceScore:   0.91
};

// Goal drift note: at turn 9 the agent briefly engaged with surface-level
// price objection rather than the underlying procurement constraint (CFO
// approval). The RT detected this drift via goal alignment drop to 0.44,
// flagged it, and recovered at turn 10 by redirecting to the proposal path.

MATCH (s:Session {sessionId: 'demo_session_003'}), (gs:GoalState {goalId: 'goal_s003_primary'})
MERGE (s)-[:HAS_GOAL {inferredAt: 1748566800000}]->(gs);
