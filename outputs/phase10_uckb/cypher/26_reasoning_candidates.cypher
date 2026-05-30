// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 26: Reasoning Candidates
// Creates 15 ReasoningCandidate nodes — the Reasoning Tree (RT) output.
// 3 candidates per turn across 5 key turns (turns 4, 6, 7, 9, 10).
//
// compositeScore = 0.5*nliScore + 0.3*goalAlignment + 0.2*(1 - protocolDeviation)
// Exactly one candidate per turn group has selected=true — always the highest
// compositeScore. This invariant is verified by AC-P10-7 and the SHACL
// SelectionInvariantShape.
//
// CANDIDATE_FOR edge links each candidate to its source Turn.
// ─────────────────────────────────────────────────────────────────────────────


// ════════════════════════════════════════════════════════════════════════════
// TURN 4 — Session 001 (conflict turn: weapon contradiction detected)
// compositeScore formula: 0.5*nli + 0.3*goal + 0.2*(1-deviation)
// ════════════════════════════════════════════════════════════════════════════

// Candidate A: Empathic reframe — acknowledge feeling, redirect to safety concern
// composite = 0.5*0.71 + 0.3*0.88 + 0.2*(1-0.10) = 0.355 + 0.264 + 0.180 = 0.799
MERGE (rc1:ReasoningCandidate {candidateId: 'rc_s001_t04_001'})
SET rc1 += {
  sessionId:         'demo_session_001',
  turnNumber:        4,
  responseSketch:    'Acknowledge subject emotional state, validate concern for sister, redirect to weapon safety',
  nliScore:          0.71,
  protocolDeviation: 0.10,
  goalAlignment:     0.88,
  compositeScore:    0.799,
  selected:          true
};

// Candidate B: Direct confrontation — address weapon admission immediately
// composite = 0.5*0.31 + 0.3*0.45 + 0.2*(1-0.40) = 0.155 + 0.135 + 0.120 = 0.410
MERGE (rc2:ReasoningCandidate {candidateId: 'rc_s001_t04_002'})
SET rc2 += {
  sessionId:         'demo_session_001',
  turnNumber:        4,
  responseSketch:    'Directly address weapon admission, issue safety instruction, demand compliance',
  nliScore:          0.31,
  protocolDeviation: 0.40,
  goalAlignment:     0.45,
  compositeScore:    0.410,
  selected:          false
};

// Candidate C: Clarification request — resolve contradiction before proceeding
// composite = 0.5*0.62 + 0.3*0.72 + 0.2*(1-0.15) = 0.310 + 0.216 + 0.170 = 0.696
MERGE (rc3:ReasoningCandidate {candidateId: 'rc_s001_t04_003'})
SET rc3 += {
  sessionId:         'demo_session_001',
  turnNumber:        4,
  responseSketch:    'Ask clarifying question to resolve presence/weapon contradiction before advancing protocol',
  nliScore:          0.62,
  protocolDeviation: 0.15,
  goalAlignment:     0.72,
  compositeScore:    0.696,
  selected:          false
};

MATCH (rc:ReasoningCandidate {candidateId: 'rc_s001_t04_001'}), (t:Turn {turnId: 'turn_s001_04'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 1}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s001_t04_002'}), (t:Turn {turnId: 'turn_s001_04'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 3}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s001_t04_003'}), (t:Turn {turnId: 'turn_s001_04'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 2}]->(t);


// ════════════════════════════════════════════════════════════════════════════
// TURN 6 — Session 002 (protocol deviation turn: step 4 re-executed)
// ════════════════════════════════════════════════════════════════════════════

// Candidate A: Commitment elicitation — move forward to step 5
// composite = 0.5*0.84 + 0.3*0.91 + 0.2*(1-0.05) = 0.420 + 0.273 + 0.190 = 0.883
MERGE (rc4:ReasoningCandidate {candidateId: 'rc_s002_t06_001'})
SET rc4 += {
  sessionId:         'demo_session_002',
  turnNumber:        6,
  responseSketch:    'Confirm subject readiness, elicit explicit compliance commitment, advance to step 5',
  nliScore:          0.84,
  protocolDeviation: 0.05,
  goalAlignment:     0.91,
  compositeScore:    0.883,
  selected:          true
};

// Candidate B: Repeat empathy validation (the deviation path)
// composite = 0.5*0.67 + 0.3*0.74 + 0.2*(1-0.45) = 0.335 + 0.222 + 0.110 = 0.667
MERGE (rc5:ReasoningCandidate {candidateId: 'rc_s002_t06_002'})
SET rc5 += {
  sessionId:         'demo_session_002',
  turnNumber:        6,
  responseSketch:    'Re-validate empathy statements before commitment — revisit step 4 content',
  nliScore:          0.67,
  protocolDeviation: 0.45,
  goalAlignment:     0.74,
  compositeScore:    0.667,
  selected:          false
};

// Candidate C: Summary and transition
// composite = 0.5*0.79 + 0.3*0.85 + 0.2*(1-0.10) = 0.395 + 0.255 + 0.180 = 0.830
MERGE (rc6:ReasoningCandidate {candidateId: 'rc_s002_t06_003'})
SET rc6 += {
  sessionId:         'demo_session_002',
  turnNumber:        6,
  responseSketch:    'Summarise progress, confirm sister safety, transition to exit commitment',
  nliScore:          0.79,
  protocolDeviation: 0.10,
  goalAlignment:     0.85,
  compositeScore:    0.830,
  selected:          false
};

MATCH (rc:ReasoningCandidate {candidateId: 'rc_s002_t06_001'}), (t:Turn {turnId: 'turn_s002_06'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 1}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s002_t06_002'}), (t:Turn {turnId: 'turn_s002_06'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 3}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s002_t06_003'}), (t:Turn {turnId: 'turn_s002_06'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 2}]->(t);


// ════════════════════════════════════════════════════════════════════════════
// TURN 7 — Session 002 (final turn: compliance confirmed)
// ════════════════════════════════════════════════════════════════════════════

// Candidate A: Affirmation + handoff to officers
// composite = 0.5*0.92 + 0.3*0.96 + 0.2*(1-0.02) = 0.460 + 0.288 + 0.196 = 0.944
MERGE (rc7:ReasoningCandidate {candidateId: 'rc_s002_t07_001'})
SET rc7 += {
  sessionId:         'demo_session_002',
  turnNumber:        7,
  responseSketch:    'Affirm subject courage, confirm compliance, coordinate safe handoff to attending officers',
  nliScore:          0.92,
  protocolDeviation: 0.02,
  goalAlignment:     0.96,
  compositeScore:    0.944,
  selected:          true
};

// Candidate B: Immediate debrief request
// composite = 0.5*0.75 + 0.3*0.81 + 0.2*(1-0.12) = 0.375 + 0.243 + 0.176 = 0.794
MERGE (rc8:ReasoningCandidate {candidateId: 'rc_s002_t07_002'})
SET rc8 += {
  sessionId:         'demo_session_002',
  turnNumber:        7,
  responseSketch:    'Initiate immediate debrief, document subject emotional state, log protocol completion',
  nliScore:          0.75,
  protocolDeviation: 0.12,
  goalAlignment:     0.81,
  compositeScore:    0.794,
  selected:          false
};

// Candidate C: Extended rapport maintenance
// composite = 0.5*0.81 + 0.3*0.88 + 0.2*(1-0.08) = 0.405 + 0.264 + 0.184 = 0.853
MERGE (rc9:ReasoningCandidate {candidateId: 'rc_s002_t07_003'})
SET rc9 += {
  sessionId:         'demo_session_002',
  turnNumber:        7,
  responseSketch:    'Continue rapport building, express gratitude for cooperation, ensure mental health follow-up is offered',
  nliScore:          0.81,
  protocolDeviation: 0.08,
  goalAlignment:     0.88,
  compositeScore:    0.853,
  selected:          false
};

MATCH (rc:ReasoningCandidate {candidateId: 'rc_s002_t07_001'}), (t:Turn {turnId: 'turn_s002_07'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 1}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s002_t07_002'}), (t:Turn {turnId: 'turn_s002_07'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 3}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s002_t07_003'}), (t:Turn {turnId: 'turn_s002_07'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 2}]->(t);


// ════════════════════════════════════════════════════════════════════════════
// TURN 9 — Session 003 (goal drift turn: agent drifted to price objection)
// ════════════════════════════════════════════════════════════════════════════

// Candidate A: Needs clarification — focus on implication questions
// composite = 0.5*0.73 + 0.3*0.82 + 0.2*(1-0.08) = 0.365 + 0.246 + 0.184 = 0.795
MERGE (rc10:ReasoningCandidate {candidateId: 'rc_s003_t09_001'})
SET rc10 += {
  sessionId:         'demo_session_003',
  turnNumber:        9,
  responseSketch:    'Use SPIN Implication question — explore cost of vendor contract gap on operations',
  nliScore:          0.73,
  protocolDeviation: 0.08,
  goalAlignment:     0.82,
  compositeScore:    0.795,
  selected:          true
};

// Candidate B: Price concession discussion (the drift path — low goal alignment)
// composite = 0.5*0.58 + 0.3*0.44 + 0.2*(1-0.35) = 0.290 + 0.132 + 0.130 = 0.552
MERGE (rc11:ReasoningCandidate {candidateId: 'rc_s003_t09_002'})
SET rc11 += {
  sessionId:         'demo_session_003',
  turnNumber:        9,
  responseSketch:    'Engage with budget objection directly — offer pricing flexibility or phased payment',
  nliScore:          0.58,
  protocolDeviation: 0.35,
  goalAlignment:     0.44,
  compositeScore:    0.552,
  selected:          false
};

// Candidate C: CFO stakeholder path
// composite = 0.5*0.69 + 0.3*0.78 + 0.2*(1-0.12) = 0.345 + 0.234 + 0.176 = 0.755
MERGE (rc12:ReasoningCandidate {candidateId: 'rc_s003_t09_003'})
SET rc12 += {
  sessionId:         'demo_session_003',
  turnNumber:        9,
  responseSketch:    'Acknowledge procurement constraint, ask who else is involved in approval — map CFO stakeholder',
  nliScore:          0.69,
  protocolDeviation: 0.12,
  goalAlignment:     0.78,
  compositeScore:    0.755,
  selected:          false
};

MATCH (rc:ReasoningCandidate {candidateId: 'rc_s003_t09_001'}), (t:Turn {turnId: 'turn_s003_09'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 1}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s003_t09_002'}), (t:Turn {turnId: 'turn_s003_09'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 3}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s003_t09_003'}), (t:Turn {turnId: 'turn_s003_09'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 2}]->(t);


// ════════════════════════════════════════════════════════════════════════════
// TURN 10 — Session 003 (recovery + proposal commitment)
// ════════════════════════════════════════════════════════════════════════════

// Candidate A: Need-Payoff close — formalise proposal commitment
// composite = 0.5*0.89 + 0.3*0.93 + 0.2*(1-0.04) = 0.445 + 0.279 + 0.192 = 0.916
MERGE (rc13:ReasoningCandidate {candidateId: 'rc_s003_t10_001'})
SET rc13 += {
  sessionId:         'demo_session_003',
  turnNumber:        10,
  responseSketch:    'Confirm proposal parameters, agree delivery timeline, set follow-up meeting with CFO',
  nliScore:          0.89,
  protocolDeviation: 0.04,
  goalAlignment:     0.93,
  compositeScore:    0.916,
  selected:          true
};

// Candidate B: Urgency framing — vendor contract expiry
// composite = 0.5*0.77 + 0.3*0.84 + 0.2*(1-0.10) = 0.385 + 0.252 + 0.180 = 0.817
MERGE (rc14:ReasoningCandidate {candidateId: 'rc_s003_t10_002'})
SET rc14 += {
  sessionId:         'demo_session_003',
  turnNumber:        10,
  responseSketch:    'Reframe around 60-day vendor expiry urgency — create natural deadline pressure',
  nliScore:          0.77,
  protocolDeviation: 0.10,
  goalAlignment:     0.84,
  compositeScore:    0.817,
  selected:          false
};

// Candidate C: ROI summary close
// composite = 0.5*0.82 + 0.3*0.88 + 0.2*(1-0.07) = 0.410 + 0.264 + 0.186 = 0.860
MERGE (rc15:ReasoningCandidate {candidateId: 'rc_s003_t10_003'})
SET rc15 += {
  sessionId:         'demo_session_003',
  turnNumber:        10,
  responseSketch:    'Deliver ROI summary, quantify operational risk of gap, request proposal sign-off',
  nliScore:          0.82,
  protocolDeviation: 0.07,
  goalAlignment:     0.88,
  compositeScore:    0.860,
  selected:          false
};

MATCH (rc:ReasoningCandidate {candidateId: 'rc_s003_t10_001'}), (t:Turn {turnId: 'turn_s003_10'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 1}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s003_t10_002'}), (t:Turn {turnId: 'turn_s003_10'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 3}]->(t);
MATCH (rc:ReasoningCandidate {candidateId: 'rc_s003_t10_003'}), (t:Turn {turnId: 'turn_s003_10'})
MERGE (rc)-[:CANDIDATE_FOR {rank: 2}]->(t);


// ════════════════════════════════════════════════════════════════════════════
// CONSISTENCY REPORT NODES
// Per-session DER snapshot at milestone turns. HAS_REPORT links to Session.
// ════════════════════════════════════════════════════════════════════════════

MERGE (cr1:ConsistencyReport {reportId: 'crep_s001_t04'})
SET cr1 += {
  sessionId:      'demo_session_001',
  turnNumber:     4,
  derScore:       0.67,
  factCount:      5,
  conflictCount:  2,
  activeGoals:    1,
  protocolStep:   3,
  deviationCount: 0
};

MATCH (s:Session {sessionId: 'demo_session_001'}), (cr:ConsistencyReport {reportId: 'crep_s001_t04'})
MERGE (s)-[:HAS_REPORT]->(cr);

MERGE (cr2:ConsistencyReport {reportId: 'crep_s002_t07'})
SET cr2 += {
  sessionId:      'demo_session_002',
  turnNumber:     7,
  derScore:       0.91,
  factCount:      6,
  conflictCount:  1,
  activeGoals:    0,
  protocolStep:   5,
  deviationCount: 1
};

MATCH (s:Session {sessionId: 'demo_session_002'}), (cr:ConsistencyReport {reportId: 'crep_s002_t07'})
MERGE (s)-[:HAS_REPORT]->(cr);

MERGE (cr3:ConsistencyReport {reportId: 'crep_s003_t10'})
SET cr3 += {
  sessionId:      'demo_session_003',
  turnNumber:     10,
  derScore:       0.88,
  factCount:      5,
  conflictCount:  1,
  activeGoals:    0,
  protocolStep:   4,
  deviationCount: 0
};

MATCH (s:Session {sessionId: 'demo_session_003'}), (cr:ConsistencyReport {reportId: 'crep_s003_t10'})
MERGE (s)-[:HAS_REPORT]->(cr);
