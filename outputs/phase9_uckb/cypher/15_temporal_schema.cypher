// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 9 — Step 15: Temporal Memory Schema
// Constraints + indices for the 6 Graphiti temporal node types.
//
// Note: Session constraint and session_timestamp_idx were already created in
// Phase 4 (01_init_constraints.cypher). All statements use IF NOT EXISTS.
//
// Execute:
//   docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 \
//     --database neo4j --non-interactive < 15_temporal_schema.cypher
// ─────────────────────────────────────────────────────────────────────────────


// ── UNIQUENESS CONSTRAINTS ────────────────────────────────────────────────────

// Turn — individual dialogue exchange within a Session
CREATE CONSTRAINT turn_id_unique IF NOT EXISTS
  FOR (t:Turn) REQUIRE t.turnId IS UNIQUE;

// TemporalFact — time-stamped observation (emotion detected, technique applied)
CREATE CONSTRAINT temporal_fact_id_unique IF NOT EXISTS
  FOR (f:TemporalFact) REQUIRE f.factId IS UNIQUE;

// WorkingMemorySlot — live key-value context for an active Session
CREATE CONSTRAINT wm_slot_id_unique IF NOT EXISTS
  FOR (w:WorkingMemorySlot) REQUIRE w.slotId IS UNIQUE;

// EpisodicMemory — compressed summary of a completed or interrupted Session
CREATE CONSTRAINT episode_id_unique IF NOT EXISTS
  FOR (e:EpisodicMemory) REQUIRE e.episodeId IS UNIQUE;

// MemoryTrace — cross-session learned effectiveness record per userId × technique
CREATE CONSTRAINT memory_trace_id_unique IF NOT EXISTS
  FOR (m:MemoryTrace) REQUIRE m.traceId IS UNIQUE;


// ── PERFORMANCE INDICES ───────────────────────────────────────────────────────

// Turn timestamp — temporal ordering queries within a Session
CREATE INDEX turn_timestamp_idx IF NOT EXISTS
  FOR (t:Turn) ON (t.timestamp);

// Turn session scope — fetch all turns for a given session quickly
CREATE INDEX turn_session_idx IF NOT EXISTS
  FOR (t:Turn) ON (t.sessionId);

// MemoryTrace weight — ORDER BY weight DESC for top-N retrieval
CREATE INDEX trace_weight_idx IF NOT EXISTS
  FOR (m:MemoryTrace) ON (m.weight);

// MemoryTrace userId+domain composite — user-scoped technique ranking
CREATE INDEX trace_user_domain_idx IF NOT EXISTS
  FOR (m:MemoryTrace) ON (m.userId, m.domain);

// TemporalFact expiry — STALE_MEMORY cleanup queries
CREATE INDEX fact_expiry_idx IF NOT EXISTS
  FOR (f:TemporalFact) ON (f.validUntil);

// TemporalFact session+type — fast filter within a session
CREATE INDEX fact_session_type_idx IF NOT EXISTS
  FOR (f:TemporalFact) ON (f.sessionId, f.factType);

// WorkingMemorySlot TTL — stale slot cleanup
CREATE INDEX wm_slot_ttl_idx IF NOT EXISTS
  FOR (w:WorkingMemorySlot) ON (w.ttl);

// WorkingMemorySlot session+key — snapshot query
CREATE INDEX wm_slot_session_key_idx IF NOT EXISTS
  FOR (w:WorkingMemorySlot) ON (w.sessionId, w.key);

// EpisodicMemory domain filter — domain-scoped retrieval
CREATE INDEX episode_domain_idx IF NOT EXISTS
  FOR (e:EpisodicMemory) ON (e.domainFilter);

// EpisodicMemory userId — user history retrieval
CREATE INDEX episode_user_idx IF NOT EXISTS
  FOR (e:EpisodicMemory) ON (e.userId);


// ── VERIFY ────────────────────────────────────────────────────────────────────
// After running:
//   SHOW CONSTRAINTS WHERE name IN [
//     'turn_id_unique','temporal_fact_id_unique','wm_slot_id_unique',
//     'episode_id_unique','memory_trace_id_unique'
//   ];
//   SHOW INDEXES WHERE name IN [
//     'turn_timestamp_idx','turn_session_idx','trace_weight_idx',
//     'fact_expiry_idx','wm_slot_ttl_idx','episode_domain_idx'
//   ];
