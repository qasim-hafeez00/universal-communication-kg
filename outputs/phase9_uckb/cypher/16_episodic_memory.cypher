// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 9 — Step 16: Episodic Memory
// Creates two demo Sessions (one BCSM crisis call + one continuation),
// 7 Turn nodes with detected emotions, an EpisodicMemory summary node,
// and all protocol DAG linkage edges.
//
// Emotional arc of Session 001:
//   panic_acute → panic_acute → distress_verbal → guarded → neutral
// Session 002 continues from step 3 and resolves to cooperative.
//
// All statements use MERGE — safe to re-run (idempotent).
// ─────────────────────────────────────────────────────────────────────────────

// ── Session 001: BCSM Crisis Call ────────────────────────────────────────────

MERGE (s1:Session {sessionId: 'demo_session_001'})
SET s1 += {
  userId:        'demo_user_001',
  domainContext: 'Crisis Dispatch',
  startedAt:     1748390400000,
  endedAt:       1748391900000,
  turnCount:     5,
  outcomeScore:  0.72,
  status:        'interrupted'
};

// ── Turns for Session 001 ─────────────────────────────────────────────────────

MERGE (t1:Turn {turnId: 'turn_s001_01'})
SET t1 += {
  sessionId:              'demo_session_001',
  turnNumber:             1,
  timestamp:              1748390400000,
  speakerRole:            'caller',
  detectedEmotionName:    'panic_acute',
  recommendedTechniqueId: 'crisis_001',
  protocolStepId:         'bcsm_step_1'
};

MERGE (t2:Turn {turnId: 'turn_s001_02'})
SET t2 += {
  sessionId:              'demo_session_001',
  turnNumber:             2,
  timestamp:              1748390700000,
  speakerRole:            'dispatcher',
  detectedEmotionName:    'panic_acute',
  recommendedTechniqueId: 'crisis_002',
  protocolStepId:         'bcsm_step_1'
};

MERGE (t3:Turn {turnId: 'turn_s001_03'})
SET t3 += {
  sessionId:              'demo_session_001',
  turnNumber:             3,
  timestamp:              1748391000000,
  speakerRole:            'caller',
  detectedEmotionName:    'distress_verbal',
  recommendedTechniqueId: 'crisis_003',
  protocolStepId:         'bcsm_step_2'
};

MERGE (t4:Turn {turnId: 'turn_s001_04'})
SET t4 += {
  sessionId:              'demo_session_001',
  turnNumber:             4,
  timestamp:              1748391300000,
  speakerRole:            'dispatcher',
  detectedEmotionName:    'guarded',
  recommendedTechniqueId: 'crisis_004',
  protocolStepId:         'bcsm_step_2'
};

MERGE (t5:Turn {turnId: 'turn_s001_05'})
SET t5 += {
  sessionId:              'demo_session_001',
  turnNumber:             5,
  timestamp:              1748391600000,
  speakerRole:            'caller',
  detectedEmotionName:    'neutral',
  recommendedTechniqueId: 'crisis_005',
  protocolStepId:         'bcsm_step_3'
};

// ── Turn sequential chain ─────────────────────────────────────────────────────

MATCH (ta:Turn {turnId: 'turn_s001_01'}), (tb:Turn {turnId: 'turn_s001_02'})
MERGE (ta)-[:PRECEDES]->(tb);

MATCH (ta:Turn {turnId: 'turn_s001_02'}), (tb:Turn {turnId: 'turn_s001_03'})
MERGE (ta)-[:PRECEDES]->(tb);

MATCH (ta:Turn {turnId: 'turn_s001_03'}), (tb:Turn {turnId: 'turn_s001_04'})
MERGE (ta)-[:PRECEDES]->(tb);

MATCH (ta:Turn {turnId: 'turn_s001_04'}), (tb:Turn {turnId: 'turn_s001_05'})
MERGE (ta)-[:PRECEDES]->(tb);

// ── Session → Turn edges ──────────────────────────────────────────────────────

MATCH (s:Session {sessionId: 'demo_session_001'}), (t:Turn {turnId: 'turn_s001_01'}) MERGE (s)-[:HAS_TURN]->(t);
MATCH (s:Session {sessionId: 'demo_session_001'}), (t:Turn {turnId: 'turn_s001_02'}) MERGE (s)-[:HAS_TURN]->(t);
MATCH (s:Session {sessionId: 'demo_session_001'}), (t:Turn {turnId: 'turn_s001_03'}) MERGE (s)-[:HAS_TURN]->(t);
MATCH (s:Session {sessionId: 'demo_session_001'}), (t:Turn {turnId: 'turn_s001_04'}) MERGE (s)-[:HAS_TURN]->(t);
MATCH (s:Session {sessionId: 'demo_session_001'}), (t:Turn {turnId: 'turn_s001_05'}) MERGE (s)-[:HAS_TURN]->(t);

// ── Turn → EmotionalState detection edges ────────────────────────────────────

MATCH (t:Turn {turnId: 'turn_s001_01'}), (e:EmotionalState {name: 'panic_acute'})
MERGE (t)-[:DETECTED {confidence: 0.93, source: 'prosodic_model'}]->(e);

MATCH (t:Turn {turnId: 'turn_s001_02'}), (e:EmotionalState {name: 'panic_acute'})
MERGE (t)-[:DETECTED {confidence: 0.91, source: 'prosodic_model'}]->(e);

MATCH (t:Turn {turnId: 'turn_s001_03'}), (e:EmotionalState {name: 'distress_verbal'})
MERGE (t)-[:DETECTED {confidence: 0.87, source: 'lexical_model'}]->(e);

MATCH (t:Turn {turnId: 'turn_s001_04'}), (e:EmotionalState {name: 'guarded'})
MERGE (t)-[:DETECTED {confidence: 0.82, source: 'lexical_model'}]->(e);

MATCH (t:Turn {turnId: 'turn_s001_05'}), (e:EmotionalState {name: 'neutral'})
MERGE (t)-[:DETECTED {confidence: 0.78, source: 'prosodic_model'}]->(e);

// ── Session 001 → Protocol DAG linkage ───────────────────────────────────────

MATCH (s:Session {sessionId: 'demo_session_001'}), (dag:ProtocolDAG {id: 'bcsm_dag'})
MERGE (s)-[:ACTIVE_PROTOCOL {activatedAt: 1748390400000}]->(dag);

MATCH (s:Session {sessionId: 'demo_session_001'}), (step:ProtocolStep {id: 'bcsm_step_3'})
MERGE (s)-[:AT_STEP {reachedAt: 1748391600000, completed: false}]->(step);

// ── EpisodicMemory for Session 001 ───────────────────────────────────────────

MERGE (ep:EpisodicMemory {episodeId: 'episode_s001'})
SET ep += {
  sessionId:           'demo_session_001',
  userId:              'demo_user_001',
  startTurnNumber:     1,
  endTurnNumber:       5,
  emotionalArc:        'panic_acute -> panic_acute -> distress_verbal -> guarded -> neutral',
  protocolId:          'BCSM',
  lastCompletedStep:   3,
  protocolCompleted:   false,
  summary:             'Caller de-escalated from acute panic to neutral across 5 turns; BCSM stepped through Active Listening and Rapport phases; interrupted at step 3 (Influence)',
  domainFilter:        'Crisis Dispatch',
  createdAt:           1748391900000
};

MATCH (s:Session {sessionId: 'demo_session_001'}), (ep:EpisodicMemory {episodeId: 'episode_s001'})
MERGE (s)-[:HAS_EPISODE]->(ep);

MATCH (ep:EpisodicMemory {episodeId: 'episode_s001'}), (dag:ProtocolDAG {id: 'bcsm_dag'})
MERGE (ep)-[:TRIGGERED]->(dag);

// ── Session 002: Continuation Call ───────────────────────────────────────────

MERGE (s2:Session {sessionId: 'demo_session_002'})
SET s2 += {
  userId:        'demo_user_001',
  domainContext: 'Crisis Dispatch',
  startedAt:     1748478000000,
  endedAt:       1748479200000,
  turnCount:     2,
  outcomeScore:  0.91,
  status:        'completed',
  resumeProtocol: 'BCSM',
  resumeStep:     3
};

// ── Continuation turns ────────────────────────────────────────────────────────

MERGE (t6:Turn {turnId: 'turn_s002_01'})
SET t6 += {
  sessionId:              'demo_session_002',
  turnNumber:             1,
  timestamp:              1748478000000,
  speakerRole:            'caller',
  detectedEmotionName:    'cooperative',
  recommendedTechniqueId: 'crisis_006',
  protocolStepId:         'bcsm_step_4'
};

MERGE (t7:Turn {turnId: 'turn_s002_02'})
SET t7 += {
  sessionId:              'demo_session_002',
  turnNumber:             2,
  timestamp:              1748478600000,
  speakerRole:            'caller',
  detectedEmotionName:    'compliant',
  recommendedTechniqueId: 'crisis_007',
  protocolStepId:         'bcsm_step_5'
};

MATCH (s:Session {sessionId: 'demo_session_002'}), (t:Turn {turnId: 'turn_s002_01'}) MERGE (s)-[:HAS_TURN]->(t);
MATCH (s:Session {sessionId: 'demo_session_002'}), (t:Turn {turnId: 'turn_s002_02'}) MERGE (s)-[:HAS_TURN]->(t);

MATCH (ta:Turn {turnId: 'turn_s002_01'}), (tb:Turn {turnId: 'turn_s002_02'})
MERGE (ta)-[:PRECEDES]->(tb);

// ── Cross-session FOLLOWS edge ────────────────────────────────────────────────

MATCH (s2:Session {sessionId: 'demo_session_002'}), (s1:Session {sessionId: 'demo_session_001'})
MERGE (s2)-[:FOLLOWS {gapHours: 24.1, sameProtocol: true, resumeStep: 3}]->(s1);

// ── Session 002 → Protocol DAG linkage ───────────────────────────────────────

MATCH (s:Session {sessionId: 'demo_session_002'}), (dag:ProtocolDAG {id: 'bcsm_dag'})
MERGE (s)-[:ACTIVE_PROTOCOL {activatedAt: 1748478000000, resumed: true}]->(dag);

MATCH (s:Session {sessionId: 'demo_session_002'}), (step:ProtocolStep {id: 'bcsm_step_5'})
MERGE (s)-[:AT_STEP {reachedAt: 1748479200000, completed: true}]->(step);

// ── EpisodicMemory for Session 002 ───────────────────────────────────────────

MERGE (ep2:EpisodicMemory {episodeId: 'episode_s002'})
SET ep2 += {
  sessionId:           'demo_session_002',
  userId:              'demo_user_001',
  startTurnNumber:     1,
  endTurnNumber:       2,
  emotionalArc:        'cooperative -> compliant',
  protocolId:          'BCSM',
  lastCompletedStep:   5,
  protocolCompleted:   true,
  summary:             'Continuation call; caller cooperative from first turn; BCSM completed steps 4-5 (Influence and Behavioral Change); full protocol resolution achieved',
  domainFilter:        'Crisis Dispatch',
  createdAt:           1748479200000
};

MATCH (s:Session {sessionId: 'demo_session_002'}), (ep:EpisodicMemory {episodeId: 'episode_s002'})
MERGE (s)-[:HAS_EPISODE]->(ep);

MATCH (ep2:EpisodicMemory {episodeId: 'episode_s002'}), (dag:ProtocolDAG {id: 'bcsm_dag'})
MERGE (ep2)-[:TRIGGERED]->(dag);

// ── TemporalFact nodes — time-stamped observations ───────────────────────────

MERGE (f1:TemporalFact {factId: 'fact_s001_emotion_01'})
SET f1 += {
  factType:    'emotion_detected',
  sessionId:   'demo_session_001',
  timestamp:   1748390400000,
  value:       'panic_acute',
  confidence:  0.93,
  decayRate:   0.15,
  validFrom:   1748390400000,
  validUntil:  null
};

MERGE (f2:TemporalFact {factId: 'fact_s001_technique_01'})
SET f2 += {
  factType:    'technique_applied',
  sessionId:   'demo_session_001',
  timestamp:   1748390400000,
  value:       'crisis_001',
  confidence:  1.0,
  decayRate:   0.05,
  validFrom:   1748390400000,
  validUntil:  null
};

MERGE (f3:TemporalFact {factId: 'fact_s001_gate_01'})
SET f3 += {
  factType:    'protocol_gate_passed',
  sessionId:   'demo_session_001',
  timestamp:   1748391000000,
  value:       'bcsm_gate_1',
  confidence:  1.0,
  decayRate:   0.02,
  validFrom:   1748391000000,
  validUntil:  null
};

MERGE (f4:TemporalFact {factId: 'fact_s001_outcome_01'})
SET f4 += {
  factType:    'outcome_observed',
  sessionId:   'demo_session_001',
  timestamp:   1748391900000,
  value:       'partial_resolution',
  confidence:  0.72,
  decayRate:   0.08,
  validFrom:   1748391900000,
  validUntil:  null
};

MATCH (s:Session {sessionId: 'demo_session_001'}), (f:TemporalFact) WHERE f.sessionId = 'demo_session_001'
MERGE (s)-[:HAS_FACT]->(f);
