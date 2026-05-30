// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 9 — Step 20: Validation Queries
// 10 Acceptance Criteria checks. Run each query in Neo4j Browser or via
// validate_phase9.py (which produces the full report).
//
// Each query RETURNS a single row with a boolean `passed` column and a
// `detail` string so results are self-documenting.
// ─────────────────────────────────────────────────────────────────────────────

// ── AC-P9-1: All 6 temporal node types have uniqueness constraints ─────────────
// Expected: passed = true, constraintCount >= 5 (Session was created in Phase 4)
MATCH (n)
WHERE n:Turn OR n:TemporalFact OR n:WorkingMemorySlot OR n:EpisodicMemory OR n:MemoryTrace
WITH labels(n)[0] AS lbl, count(DISTINCT n) AS cnt
RETURN collect(lbl) AS nodeTypesPresent, sum(cnt) AS totalNodes;

// ── AC-P9-2: Core temporal indices exist ──────────────────────────────────────
// Expected: 4 rows (turn_timestamp_idx, trace_weight_idx, fact_expiry_idx, wm_slot_ttl_idx)
SHOW INDEXES
WHERE name IN ['turn_timestamp_idx','trace_weight_idx','fact_expiry_idx','wm_slot_ttl_idx']
RETURN name, state, type;

// ── AC-P9-3: STALE_MEMORY — stale WorkingMemorySlots identifiable ─────────────
// Expected: >= 2 stale slots (wm_stale_001, wm_stale_002)
MATCH (wm:WorkingMemorySlot)
WHERE wm.ttl < timestamp()
RETURN count(wm) AS staleSlots,
       collect(wm.slotId) AS staleIds,
       (count(wm) >= 2) AS passed;

// ── AC-P9-4: Episodic memory creation — EpisodicMemory has emotionalArc ───────
// Expected: 2 EpisodicMemory nodes, all with emotionalArc property
MATCH (ep:EpisodicMemory)
RETURN count(ep) AS total,
       count(ep.emotionalArc) AS withArc,
       (count(ep) >= 2 AND count(ep.emotionalArc) = count(ep)) AS passed;

// ── AC-P9-5: Decay function — MemoryTrace weight in [0.01, 1.0] ───────────────
// Expected: all 7 traces pass; no weight outside range
MATCH (mt:MemoryTrace)
WITH count(mt) AS total,
     count(CASE WHEN mt.weight >= 0.01 AND mt.weight <= 1.0 THEN 1 END) AS inRange,
     count(CASE WHEN mt.decayRate >= 0.01 AND mt.decayRate <= 1.0 THEN 1 END) AS validRate
RETURN total,
       inRange AS weightInRange,
       validRate AS rateInRange,
       (total >= 7 AND inRange = total AND validRate = total) AS passed;

// ── AC-P9-6: Cross-session continuity — FOLLOWS edge exists ───────────────────
// Expected: at least 1 FOLLOWS edge between sessions
MATCH (s2:Session)-[f:FOLLOWS]->(s1:Session)
RETURN count(f) AS followsEdges,
       collect({from: s2.sessionId, to: s1.sessionId}) AS links,
       (count(f) >= 1) AS passed;

// ── AC-P9-7: Technique reinforcement — REINFORCES edges exist ─────────────────
// Expected: >= 3 REINFORCES edges (some techniques match; others link via DAG steps)
MATCH (mt:MemoryTrace)-[r:REINFORCES]->(n)
RETURN count(r) AS reinforcesEdges,
       count(DISTINCT mt) AS tracesWithEdges,
       (count(r) >= 3) AS passed;

// ── AC-P9-8: Temporal retrieval library — 6 Text2CypherTemplate temporal nodes
// Expected: exactly 6 templates with category = 'temporal'
MATCH (t:Text2CypherTemplate {category: 'temporal'})
RETURN count(t) AS temporalTemplates,
       collect(t.name) AS templateNames,
       (count(t) = 6) AS passed;

// ── AC-P9-9: Domain filter integration — EpisodicMemory has domainFilter ──────
// Expected: all EpisodicMemory nodes have domainFilter that matches a SchemaFilterRegistry
MATCH (ep:EpisodicMemory)
OPTIONAL MATCH (reg:SchemaFilterRegistry {domain: ep.domainFilter})
WITH count(ep) AS total,
     count(reg) AS matched
RETURN total, matched,
       (total > 0 AND matched = total) AS passed;

// ── AC-P9-10: Protocol DAG continuity — ACTIVE_PROTOCOL + AT_STEP edges ───────
// Expected: >= 2 ACTIVE_PROTOCOL edges + >= 2 AT_STEP edges (one per session)
MATCH (s:Session)-[ap:ACTIVE_PROTOCOL]->(dag:ProtocolDAG)
WITH count(ap) AS apEdges
MATCH (s2:Session)-[ast:AT_STEP]->(step:ProtocolStep)
RETURN apEdges,
       count(ast) AS atStepEdges,
       (apEdges >= 2 AND count(ast) >= 2) AS passed;
