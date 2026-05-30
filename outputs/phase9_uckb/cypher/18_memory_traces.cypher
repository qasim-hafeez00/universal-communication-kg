// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 9 — Step 18: Memory Traces
// Creates MemoryTrace nodes for the 7 techniques used in demo sessions 001+002.
// Links each trace to its Technique node via REINFORCES.
// Implements temporal decay: weight = initialWeight * exp(-decayRate * ageHours)
//
// Decay rates (λ per hour):
//   Crisis techniques: 0.08  (high urgency → faster relevance decay)
//   Clinical:          0.04  (moderate decay)
//   Corporate:         0.02  (slow decay — stable effectiveness)
//
// ageHours for demo data: 24.5h from session_001 start to now
//   weight = initialWeight * exp(-0.08 * 24.5) ≈ initialWeight * 0.140
// ─────────────────────────────────────────────────────────────────────────────

// ── MemoryTrace nodes ─────────────────────────────────────────────────────────

// Techniques crisis_001 through crisis_007 map to BCSM DAG step techniques.
// OPTIONAL MATCH ensures traces are created even if a Technique node has a
// slightly different cardId — the REINFORCES edge is only written when matched.

MERGE (mt1:MemoryTrace {traceId: 'trace_u001_crisis_001'})
SET mt1 += {
  userId:         'demo_user_001',
  techniqueCardId: 'crisis_001',
  domain:         'Crisis Dispatch',
  successCount:   3,
  failCount:      0,
  lastUsed:       1748390400000,
  initialWeight:  0.95,
  weight:         0.133,
  decayRate:      0.08,
  ageHours:       24.5
};

MERGE (mt2:MemoryTrace {traceId: 'trace_u001_crisis_002'})
SET mt2 += {
  userId:         'demo_user_001',
  techniqueCardId: 'crisis_002',
  domain:         'Crisis Dispatch',
  successCount:   3,
  failCount:      1,
  lastUsed:       1748390700000,
  initialWeight:  0.92,
  weight:         0.129,
  decayRate:      0.08,
  ageHours:       24.5
};

MERGE (mt3:MemoryTrace {traceId: 'trace_u001_crisis_003'})
SET mt3 += {
  userId:         'demo_user_001',
  techniqueCardId: 'crisis_003',
  domain:         'Crisis Dispatch',
  successCount:   2,
  failCount:      1,
  lastUsed:       1748391000000,
  initialWeight:  0.88,
  weight:         0.123,
  decayRate:      0.08,
  ageHours:       24.5
};

MERGE (mt4:MemoryTrace {traceId: 'trace_u001_crisis_004'})
SET mt4 += {
  userId:         'demo_user_001',
  techniqueCardId: 'crisis_004',
  domain:         'Crisis Dispatch',
  successCount:   2,
  failCount:      0,
  lastUsed:       1748391300000,
  initialWeight:  0.90,
  weight:         0.126,
  decayRate:      0.08,
  ageHours:       24.5
};

MERGE (mt5:MemoryTrace {traceId: 'trace_u001_crisis_005'})
SET mt5 += {
  userId:         'demo_user_001',
  techniqueCardId: 'crisis_005',
  domain:         'Crisis Dispatch',
  successCount:   4,
  failCount:      0,
  lastUsed:       1748391600000,
  initialWeight:  0.85,
  weight:         0.119,
  decayRate:      0.08,
  ageHours:       24.5
};

MERGE (mt6:MemoryTrace {traceId: 'trace_u001_crisis_006'})
SET mt6 += {
  userId:         'demo_user_001',
  techniqueCardId: 'crisis_006',
  domain:         'Crisis Dispatch',
  successCount:   5,
  failCount:      0,
  lastUsed:       1748478000000,
  initialWeight:  0.93,
  weight:         0.130,
  decayRate:      0.08,
  ageHours:       24.5
};

MERGE (mt7:MemoryTrace {traceId: 'trace_u001_crisis_007'})
SET mt7 += {
  userId:         'demo_user_001',
  techniqueCardId: 'crisis_007',
  domain:         'Crisis Dispatch',
  successCount:   5,
  failCount:      0,
  lastUsed:       1748478600000,
  initialWeight:  0.96,
  weight:         0.134,
  decayRate:      0.08,
  ageHours:       24.5
};

// ── REINFORCES edges — connect traces to Technique nodes ─────────────────────

MATCH (mt:MemoryTrace {traceId: 'trace_u001_crisis_001'})
OPTIONAL MATCH (tech:Technique)
WHERE tech.cardId = mt.techniqueCardId OR tech.id = mt.techniqueCardId
WITH mt, tech WHERE tech IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed}]->(tech);

MATCH (mt:MemoryTrace {traceId: 'trace_u001_crisis_002'})
OPTIONAL MATCH (tech:Technique)
WHERE tech.cardId = mt.techniqueCardId OR tech.id = mt.techniqueCardId
WITH mt, tech WHERE tech IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed}]->(tech);

MATCH (mt:MemoryTrace {traceId: 'trace_u001_crisis_003'})
OPTIONAL MATCH (tech:Technique)
WHERE tech.cardId = mt.techniqueCardId OR tech.id = mt.techniqueCardId
WITH mt, tech WHERE tech IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed}]->(tech);

MATCH (mt:MemoryTrace {traceId: 'trace_u001_crisis_004'})
OPTIONAL MATCH (tech:Technique)
WHERE tech.cardId = mt.techniqueCardId OR tech.id = mt.techniqueCardId
WITH mt, tech WHERE tech IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed}]->(tech);

MATCH (mt:MemoryTrace {traceId: 'trace_u001_crisis_005'})
OPTIONAL MATCH (tech:Technique)
WHERE tech.cardId = mt.techniqueCardId OR tech.id = mt.techniqueCardId
WITH mt, tech WHERE tech IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed}]->(tech);

MATCH (mt:MemoryTrace {traceId: 'trace_u001_crisis_006'})
OPTIONAL MATCH (tech:Technique)
WHERE tech.cardId = mt.techniqueCardId OR tech.id = mt.techniqueCardId
WITH mt, tech WHERE tech IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed}]->(tech);

MATCH (mt:MemoryTrace {traceId: 'trace_u001_crisis_007'})
OPTIONAL MATCH (tech:Technique)
WHERE tech.cardId = mt.techniqueCardId OR tech.id = mt.techniqueCardId
WITH mt, tech WHERE tech IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed}]->(tech);

// ── Also link traces to ProtocolStep triggers (technique≈step when no cardId match) ─

MATCH (mt:MemoryTrace)
WHERE mt.userId = 'demo_user_001' AND mt.domain = 'Crisis Dispatch'
OPTIONAL MATCH (step:ProtocolStep {protocol: 'BCSM'})
WHERE step.stepNumber = toInteger(right(mt.techniqueCardId, 1))
  AND NOT (mt)-[:REINFORCES]->()
WITH mt, step WHERE step IS NOT NULL
MERGE (mt)-[:REINFORCES {successCount: mt.successCount, lastReinforced: mt.lastUsed, viaDagStep: true}]->(step);

// ── Verify decay formula is consistent ────────────────────────────────────────
// Query to confirm: weight ≈ initialWeight * exp(-decayRate * ageHours)
// MATCH (mt:MemoryTrace)
// RETURN mt.traceId,
//        round(mt.initialWeight * exp(-mt.decayRate * mt.ageHours), 3) AS expectedWeight,
//        round(mt.weight, 3) AS storedWeight,
//        abs(mt.weight - mt.initialWeight * exp(-mt.decayRate * mt.ageHours)) < 0.001 AS consistent;
