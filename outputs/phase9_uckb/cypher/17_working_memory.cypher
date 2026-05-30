// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 9 — Step 17: Working Memory
// Creates WorkingMemorySlot nodes for demo_session_001 (5 active + 2 stale).
// Stale slots have ttl in the past so STALE_MEMORY query template can find them.
//
// TTL values:
//   Active slots:  ttl = 1748477999999  (approx 24h after session start)
//   Stale slots:   ttl = 1748390399000  (1 second before session start — already expired)
//
// All statements use MERGE — safe to re-run (idempotent).
// ─────────────────────────────────────────────────────────────────────────────

// ── Active WorkingMemorySlots for Session 001 ─────────────────────────────────

MERGE (wm1:WorkingMemorySlot {slotId: 'wm_s001_domain'})
SET wm1 += {
  sessionId:   'demo_session_001',
  key:         'active_domain',
  value:       'Crisis Dispatch',
  updatedAt:   1748390400000,
  ttl:         1748477999999,
  domain:      'Crisis Dispatch'
};

MERGE (wm2:WorkingMemorySlot {slotId: 'wm_s001_protocol'})
SET wm2 += {
  sessionId:   'demo_session_001',
  key:         'active_protocol',
  value:       'BCSM',
  updatedAt:   1748390400000,
  ttl:         1748477999999,
  domain:      'Crisis Dispatch'
};

MERGE (wm3:WorkingMemorySlot {slotId: 'wm_s001_step'})
SET wm3 += {
  sessionId:   'demo_session_001',
  key:         'current_step',
  value:       '3',
  updatedAt:   1748391600000,
  ttl:         1748477999999,
  domain:      'Crisis Dispatch'
};

MERGE (wm4:WorkingMemorySlot {slotId: 'wm_s001_emotion'})
SET wm4 += {
  sessionId:   'demo_session_001',
  key:         'caller_emotional_state',
  value:       'neutral',
  updatedAt:   1748391600000,
  ttl:         1748477999999,
  domain:      'Crisis Dispatch'
};

MERGE (wm5:WorkingMemorySlot {slotId: 'wm_s001_outcome'})
SET wm5 += {
  sessionId:   'demo_session_001',
  key:         'session_outcome',
  value:       'partial_resolution',
  updatedAt:   1748391900000,
  ttl:         1748477999999,
  domain:      'Crisis Dispatch'
};

// ── Stale WorkingMemorySlots (TTL already expired — for STALE_MEMORY query) ──

MERGE (wm6:WorkingMemorySlot {slotId: 'wm_stale_001'})
SET wm6 += {
  sessionId:   'demo_session_stale',
  key:         'active_domain',
  value:       'Clinical',
  updatedAt:   1748304000000,
  ttl:         1748390399000,
  domain:      'Clinical'
};

MERGE (wm7:WorkingMemorySlot {slotId: 'wm_stale_002'})
SET wm7 += {
  sessionId:   'demo_session_stale',
  key:         'active_protocol',
  value:       'SPIKES',
  updatedAt:   1748304000000,
  ttl:         1748390399000,
  domain:      'Clinical'
};

// ── Session → WorkingMemorySlot edges ────────────────────────────────────────

MATCH (s:Session {sessionId: 'demo_session_001'}), (wm:WorkingMemorySlot)
WHERE wm.sessionId = 'demo_session_001'
MERGE (s)-[:HAS_SLOT]->(wm);

// ── Reusable WorkingMemory CRUD patterns (documented as comments) ─────────────

// UPSERT a slot:
//   MERGE (wm:WorkingMemorySlot {sessionId: $sid, key: $key})
//   ON CREATE SET wm.slotId = $sid + '_' + $key, wm.domain = $domain
//   SET wm.value = $value, wm.updatedAt = timestamp(), wm.ttl = timestamp() + $ttlMs;

// READ snapshot of all active slots:
//   MATCH (s:Session {sessionId: $sid})-[:HAS_SLOT]->(wm:WorkingMemorySlot)
//   WHERE wm.ttl > timestamp()
//   RETURN wm.key AS slot, wm.value AS value ORDER BY wm.updatedAt DESC;

// TTL cleanup (mark expired; actual deletion is optional):
//   MATCH (wm:WorkingMemorySlot)
//   WHERE wm.ttl < timestamp()
//   SET wm.status = 'stale'
//   RETURN count(wm) AS marked_stale;
