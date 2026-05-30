// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 22: Conversation Facts
// Creates 18 ConversationFact nodes extracted from the Phase 9 demo sessions
// and links each to its source Turn via EXTRACTED_FROM.
//
// Session 001 (BCSM crisis, interrupted):  6 facts across turns 1-4
// Session 002 (BCSM continuation, done):   6 facts across turns 5-7
// Session 003 (SPIN sales, done):          6 facts across turns 8-10
//
// Facts with superseded=false are live DSM state.
// Facts with superseded=true have been invalidated by a newer fact
// (SUPERSEDES edges are created in 25_conflict_detection.cypher).
//
// All statements use MERGE — idempotent.
// ─────────────────────────────────────────────────────────────────────────────


// ════════════════════════════════════════════════════════════════════════════
// SESSION 001 — BCSM Crisis (turns 1-4)
// ════════════════════════════════════════════════════════════════════════════

// ── Turn 1 facts ──────────────────────────────────────────────────────────────

MERGE (cf1:ConversationFact {factId: 'cf_s001_t01_001'})
SET cf1 += {
  sessionId:   'demo_session_001',
  content:     'Subject states sister is inside the apartment',
  factType:    'information',
  speakerRole: 'caller',
  turnNumber:  1,
  validFrom:   1,
  validUntil:  9999,
  weight:      0.82,
  superseded:  false
};

MERGE (cf2:ConversationFact {factId: 'cf_s001_t01_002'})
SET cf2 += {
  sessionId:   'demo_session_001',
  content:     'Subject states motive is domestic dispute over custody',
  factType:    'position',
  speakerRole: 'caller',
  turnNumber:  1,
  validFrom:   1,
  validUntil:  9999,
  weight:      0.79,
  superseded:  false
};

// ── Turn 2 facts ──────────────────────────────────────────────────────────────

MERGE (cf3:ConversationFact {factId: 'cf_s001_t02_001'})
SET cf3 += {
  sessionId:   'demo_session_001',
  content:     'Subject claims to be unarmed',
  factType:    'information',
  speakerRole: 'caller',
  turnNumber:  2,
  validFrom:   2,
  validUntil:  4,
  weight:      0.0,
  superseded:  true
};

// ── Turn 3 facts ──────────────────────────────────────────────────────────────

MERGE (cf4:ConversationFact {factId: 'cf_s001_t03_001'})
SET cf4 += {
  sessionId:   'demo_session_001',
  content:     'Subject agrees to speak calmly and not escalate',
  factType:    'commitment',
  speakerRole: 'caller',
  turnNumber:  3,
  validFrom:   3,
  validUntil:  9999,
  weight:      0.74,
  superseded:  false
};

MERGE (cf5:ConversationFact {factId: 'cf_s001_t03_002'})
SET cf5 += {
  sessionId:   'demo_session_001',
  content:     'Subject denies having entered the apartment',
  factType:    'denial',
  speakerRole: 'caller',
  turnNumber:  3,
  validFrom:   3,
  validUntil:  9999,
  weight:      0.71,
  superseded:  false
};

// ── Turn 4 facts ──────────────────────────────────────────────────────────────

MERGE (cf6:ConversationFact {factId: 'cf_s001_t04_001'})
SET cf6 += {
  sessionId:   'demo_session_001',
  content:     'Subject admits to holding a knife',
  factType:    'information',
  speakerRole: 'caller',
  turnNumber:  4,
  validFrom:   4,
  validUntil:  9999,
  weight:      0.88,
  superseded:  false
};

// ── EXTRACTED_FROM edges — Session 001 ───────────────────────────────────────

MATCH (cf:ConversationFact {factId: 'cf_s001_t01_001'}), (t:Turn {turnId: 'turn_s001_01'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748390400000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s001_t01_002'}), (t:Turn {turnId: 'turn_s001_01'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748390400000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s001_t02_001'}), (t:Turn {turnId: 'turn_s001_02'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748390700000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s001_t03_001'}), (t:Turn {turnId: 'turn_s001_03'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748391000000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s001_t03_002'}), (t:Turn {turnId: 'turn_s001_03'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748391000000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s001_t04_001'}), (t:Turn {turnId: 'turn_s001_04'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748391300000}]->(t);


// ════════════════════════════════════════════════════════════════════════════
// SESSION 002 — BCSM Continuation (turns 5-7)
// ════════════════════════════════════════════════════════════════════════════

// ── Turn 5 facts ──────────────────────────────────────────────────────────────

MERGE (cf7:ConversationFact {factId: 'cf_s002_t05_001'})
SET cf7 += {
  sessionId:   'demo_session_002',
  content:     'Subject agrees to put down the knife and step back',
  factType:    'commitment',
  speakerRole: 'caller',
  turnNumber:  5,
  validFrom:   5,
  validUntil:  9999,
  weight:      0.91,
  superseded:  false
};

MERGE (cf8:ConversationFact {factId: 'cf_s002_t05_002'})
SET cf8 += {
  sessionId:   'demo_session_002',
  content:     'Subject states primary concern is seeing their child',
  factType:    'position',
  speakerRole: 'caller',
  turnNumber:  5,
  validFrom:   5,
  validUntil:  9999,
  weight:      0.87,
  superseded:  false
};

// ── Turn 6 facts ──────────────────────────────────────────────────────────────

MERGE (cf9:ConversationFact {factId: 'cf_s002_t06_001'})
SET cf9 += {
  sessionId:   'demo_session_002',
  content:     'Subject confirms sister is unharmed and cooperative',
  factType:    'information',
  speakerRole: 'caller',
  turnNumber:  6,
  validFrom:   6,
  validUntil:  9999,
  weight:      0.84,
  superseded:  false
};

MERGE (cf10:ConversationFact {factId: 'cf_s002_t06_002'})
SET cf10 += {
  sessionId:   'demo_session_002',
  content:     'Subject agrees to exit the building without resistance',
  factType:    'commitment',
  speakerRole: 'caller',
  turnNumber:  6,
  validFrom:   6,
  validUntil:  9999,
  weight:      0.89,
  superseded:  false
};

// ── Turn 7 facts ──────────────────────────────────────────────────────────────

MERGE (cf11:ConversationFact {factId: 'cf_s002_t07_001'})
SET cf11 += {
  sessionId:   'demo_session_002',
  content:     'Subject reports feeling heard and respected by negotiator',
  factType:    'information',
  speakerRole: 'caller',
  turnNumber:  7,
  validFrom:   7,
  validUntil:  9999,
  weight:      0.76,
  superseded:  false
};

MERGE (cf12:ConversationFact {factId: 'cf_s002_t07_002'})
SET cf12 += {
  sessionId:   'demo_session_002',
  content:     'Subject complies with officer instructions and surrenders peacefully',
  factType:    'commitment',
  speakerRole: 'caller',
  turnNumber:  7,
  validFrom:   7,
  validUntil:  9999,
  weight:      0.93,
  superseded:  false
};

// ── EXTRACTED_FROM edges — Session 002 ───────────────────────────────────────

MATCH (cf:ConversationFact {factId: 'cf_s002_t05_001'}), (t:Turn {turnId: 'turn_s002_05'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748480400000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s002_t05_002'}), (t:Turn {turnId: 'turn_s002_05'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748480400000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s002_t06_001'}), (t:Turn {turnId: 'turn_s002_06'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748480700000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s002_t06_002'}), (t:Turn {turnId: 'turn_s002_06'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748480700000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s002_t07_001'}), (t:Turn {turnId: 'turn_s002_07'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748481000000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s002_t07_002'}), (t:Turn {turnId: 'turn_s002_07'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748481000000}]->(t);


// ════════════════════════════════════════════════════════════════════════════
// SESSION 003 — SPIN Sales (turns 8-10)
// ════════════════════════════════════════════════════════════════════════════

// ── Turn 8 facts ──────────────────────────────────────────────────────────────

MERGE (cf13:ConversationFact {factId: 'cf_s003_t08_001'})
SET cf13 += {
  sessionId:   'demo_session_003',
  content:     'Prospect states budget cycle closes end of Q3',
  factType:    'information',
  speakerRole: 'prospect',
  turnNumber:  8,
  validFrom:   8,
  validUntil:  9999,
  weight:      0.81,
  superseded:  false
};

MERGE (cf14:ConversationFact {factId: 'cf_s003_t08_002'})
SET cf14 += {
  sessionId:   'demo_session_003',
  content:     'Current vendor contract expires in 60 days',
  factType:    'information',
  speakerRole: 'prospect',
  turnNumber:  8,
  validFrom:   8,
  validUntil:  9999,
  weight:      0.78,
  superseded:  false
};

// ── Turn 9 facts ──────────────────────────────────────────────────────────────

MERGE (cf15:ConversationFact {factId: 'cf_s003_t09_001'})
SET cf15 += {
  sessionId:   'demo_session_003',
  content:     'Prospect agrees to schedule an internal review meeting',
  factType:    'commitment',
  speakerRole: 'prospect',
  turnNumber:  9,
  validFrom:   9,
  validUntil:  9999,
  weight:      0.85,
  superseded:  false
};

MERGE (cf16:ConversationFact {factId: 'cf_s003_t09_002'})
SET cf16 += {
  sessionId:   'demo_session_003',
  content:     'Prospect claims there is no budget flexibility this quarter',
  factType:    'position',
  speakerRole: 'prospect',
  turnNumber:  9,
  validFrom:   9,
  validUntil:  10,
  weight:      0.0,
  superseded:  true
};

// ── Turn 10 facts ─────────────────────────────────────────────────────────────

MERGE (cf17:ConversationFact {factId: 'cf_s003_t10_001'})
SET cf17 += {
  sessionId:   'demo_session_003',
  content:     'CFO approval is required for all new vendor engagements',
  factType:    'information',
  speakerRole: 'prospect',
  turnNumber:  10,
  validFrom:   10,
  validUntil:  9999,
  weight:      0.73,
  superseded:  false
};

MERGE (cf18:ConversationFact {factId: 'cf_s003_t10_002'})
SET cf18 += {
  sessionId:   'demo_session_003',
  content:     'Prospect requests a formal proposal to be delivered by Friday',
  factType:    'commitment',
  speakerRole: 'prospect',
  turnNumber:  10,
  validFrom:   10,
  validUntil:  9999,
  weight:      0.94,
  superseded:  false
};

// ── EXTRACTED_FROM edges — Session 003 ───────────────────────────────────────

MATCH (cf:ConversationFact {factId: 'cf_s003_t08_001'}), (t:Turn {turnId: 'turn_s003_08'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748566800000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s003_t08_002'}), (t:Turn {turnId: 'turn_s003_08'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748566800000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s003_t09_001'}), (t:Turn {turnId: 'turn_s003_09'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748567100000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s003_t09_002'}), (t:Turn {turnId: 'turn_s003_09'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748567100000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s003_t10_001'}), (t:Turn {turnId: 'turn_s003_10'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748567400000}]->(t);

MATCH (cf:ConversationFact {factId: 'cf_s003_t10_002'}), (t:Turn {turnId: 'turn_s003_10'})
MERGE (cf)-[:EXTRACTED_FROM {extractedAt: 1748567400000}]->(t);
