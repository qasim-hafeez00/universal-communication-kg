// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 21: D-SMART Schema
// Constraints + indices for the 6 D-SMART node types:
//   ConversationFact, GoalState, ProtocolTracker,
//   ConsistencyConflict, ReasoningCandidate, ConsistencyReport
//
// All statements use IF NOT EXISTS — safe to re-run.
//
// Execute:
//   docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 \
//     --database neo4j --non-interactive < 21_dsmart_schema.cypher
// ─────────────────────────────────────────────────────────────────────────────


// ── UNIQUENESS CONSTRAINTS ────────────────────────────────────────────────────

// ConversationFact — atomic fact extracted from a Turn by the DSM
CREATE CONSTRAINT conversation_fact_id_unique IF NOT EXISTS
  FOR (cf:ConversationFact) REQUIRE cf.factId IS UNIQUE;

// GoalState — inferred underlying user goal for a session
CREATE CONSTRAINT goal_state_id_unique IF NOT EXISTS
  FOR (gs:GoalState) REQUIRE gs.goalId IS UNIQUE;

// ProtocolTracker — live protocol position with deviation counting
CREATE CONSTRAINT protocol_tracker_id_unique IF NOT EXISTS
  FOR (pt:ProtocolTracker) REQUIRE pt.trackerId IS UNIQUE;

// ConsistencyConflict — detected contradiction logged into the DSM
CREATE CONSTRAINT consistency_conflict_id_unique IF NOT EXISTS
  FOR (cc:ConsistencyConflict) REQUIRE cc.conflictId IS UNIQUE;

// ReasoningCandidate — one RT candidate response path before NLI selection
CREATE CONSTRAINT reasoning_candidate_id_unique IF NOT EXISTS
  FOR (rc:ReasoningCandidate) REQUIRE rc.candidateId IS UNIQUE;

// ConsistencyReport — per-session DER snapshot at a milestone turn
CREATE CONSTRAINT consistency_report_id_unique IF NOT EXISTS
  FOR (cr:ConsistencyReport) REQUIRE cr.reportId IS UNIQUE;


// ── PERFORMANCE INDICES ───────────────────────────────────────────────────────

// ConversationFact — filter by session + superseded status (ACTIVE_FACTS_SNAPSHOT)
CREATE INDEX cf_session_idx IF NOT EXISTS
  FOR (cf:ConversationFact) ON (cf.sessionId);

CREATE INDEX cf_superseded_idx IF NOT EXISTS
  FOR (cf:ConversationFact) ON (cf.superseded);

// ConversationFact — filter by turn for EXTRACTED_FROM traversal
CREATE INDEX cf_turn_idx IF NOT EXISTS
  FOR (cf:ConversationFact) ON (cf.turnNumber);

// GoalState — filter by session + status (GOAL_DRIFT_CHECK)
CREATE INDEX gs_session_idx IF NOT EXISTS
  FOR (gs:GoalState) ON (gs.sessionId);

CREATE INDEX gs_status_idx IF NOT EXISTS
  FOR (gs:GoalState) ON (gs.status);

// ProtocolTracker — filter by session + protocol (PROTOCOL_POSITION_QUERY)
CREATE INDEX pt_session_idx IF NOT EXISTS
  FOR (pt:ProtocolTracker) ON (pt.sessionId);

CREATE INDEX pt_status_idx IF NOT EXISTS
  FOR (pt:ProtocolTracker) ON (pt.status);

// ConsistencyConflict — filter by session + conflictType (CONFLICT_HISTORY)
CREATE INDEX cc_session_idx IF NOT EXISTS
  FOR (cc:ConsistencyConflict) ON (cc.sessionId);

CREATE INDEX cc_severity_idx IF NOT EXISTS
  FOR (cc:ConsistencyConflict) ON (cc.severity);

// ReasoningCandidate — filter by session + turn + selected (CANDIDATE_SELECTION_LOG)
CREATE INDEX rc_session_turn_idx IF NOT EXISTS
  FOR (rc:ReasoningCandidate) ON (rc.sessionId, rc.turnNumber);

CREATE INDEX rc_selected_idx IF NOT EXISTS
  FOR (rc:ReasoningCandidate) ON (rc.selected);

// ConsistencyReport — order by turnNumber for DER trend (CONSISTENCY_REPORT_TREND)
CREATE INDEX cr_session_turn_idx IF NOT EXISTS
  FOR (cr:ConsistencyReport) ON (cr.sessionId, cr.turnNumber);
