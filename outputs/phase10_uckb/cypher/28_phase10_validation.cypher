// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 10 — Step 28: Validation Suite
// 10 acceptance-criteria verification queries for live Neo4j execution.
// Run after loading scripts 21-27.
//
// Each query is self-contained and returns a result that maps to one AC.
// For automated validation use validate_phase10.py instead.
// ─────────────────────────────────────────────────────────────────────────────


// ── AC-P10-1: All 6 D-SMART node types present ───────────────────────────────
// Expect: 6 rows, all counts >= 1

MATCH (n)
WHERE n:ConversationFact OR n:GoalState OR n:ProtocolTracker
   OR n:ConsistencyConflict OR n:ReasoningCandidate OR n:ConsistencyReport
WITH labels(n)[0] AS nodeType, count(n) AS cnt
RETURN nodeType, cnt
ORDER BY nodeType;


// ── AC-P10-2: ConversationFact extraction completeness ───────────────────────
// Expect: total >= 15, all have factType+speakerRole+validFrom, all linked via EXTRACTED_FROM

MATCH (cf:ConversationFact)
WITH count(cf) AS total,
     count(cf.factType) AS withType,
     count(cf.speakerRole) AS withSpeaker,
     count(cf.validFrom) AS withValidFrom
OPTIONAL MATCH (cf2:ConversationFact)-[:EXTRACTED_FROM]->(t:Turn)
WITH total, withType, withSpeaker, withValidFrom, count(cf2) AS withEdge
RETURN total, withType, withSpeaker, withValidFrom, withEdge;


// ── AC-P10-3: CONTRADICTS edges — factual conflicts ───────────────────────────
// Expect: factualConflicts >= 2, each has exactly 2 ConversationFact endpoints

MATCH (cc:ConsistencyConflict {conflictType: 'factual'})
WITH count(cc) AS factualConflicts
OPTIONAL MATCH (a:ConversationFact)-[r:CONTRADICTS]->(b:ConversationFact)
RETURN factualConflicts, count(r) AS contradictsEdges;


// ── AC-P10-4: SUPERSEDES edges — temporal invalidation ───────────────────────
// Expect: supersedesEdges >= 3, all target nodes have superseded=true

MATCH (newer:ConversationFact)-[s:SUPERSEDES]->(older:ConversationFact)
WITH count(s) AS supersedesEdges,
     count(CASE WHEN older.superseded = true THEN 1 END) AS targetsFlagged
RETURN supersedesEdges, targetsFlagged;


// ── AC-P10-5: GoalState coverage and drift scenario ──────────────────────────
// Expect: total=3, all have goalType+status+confidenceScore, >= 1 drifted

MATCH (gs:GoalState)
WITH count(gs) AS total,
     count(gs.goalType) AS withGoalType,
     count(gs.status) AS withStatus,
     count(CASE WHEN gs.confidenceScore >= 0.0 AND gs.confidenceScore <= 1.0 THEN 1 END) AS validConf,
     count(CASE WHEN gs.status = 'drifted' THEN 1 END) AS driftedCount,
     count(CASE WHEN gs.driftDetectedAt IS NOT NULL AND gs.status <> 'drifted' THEN 1 END) AS withDriftTurn
RETURN total, withGoalType, withStatus, validConf, driftedCount, withDriftTurn;


// ── AC-P10-6: ProtocolTracker linked to ProtocolDAG ──────────────────────────
// Expect: total=3, tracksEdges=3, all protocolIds matched

MATCH (pt:ProtocolTracker)
WITH count(pt) AS total
OPTIONAL MATCH (pt2:ProtocolTracker)-[:TRACKS]->(dag:ProtocolDAG)
WITH total, count(pt2) AS tracksEdges,
     collect(DISTINCT pt2.protocolId) AS trackedIds,
     collect(DISTINCT dag.protocol) AS dagNames
RETURN total, tracksEdges, trackedIds, dagNames;


// ── AC-P10-7: ReasoningCandidate NLI selection invariant ─────────────────────
// Expect: total >= 15, all scores in [0,1], exactly 1 selected per session+turn group

MATCH (rc:ReasoningCandidate)
WITH count(rc) AS total,
     count(CASE WHEN rc.nliScore >= 0.0 AND rc.nliScore <= 1.0 THEN 1 END) AS validNLI,
     count(CASE WHEN rc.goalAlignment >= 0.0 AND rc.goalAlignment <= 1.0 THEN 1 END) AS validGoal,
     count(CASE WHEN rc.protocolDeviation >= 0.0 AND rc.protocolDeviation <= 1.0 THEN 1 END) AS validDev,
     count(CASE WHEN rc.compositeScore >= 0.0 AND rc.compositeScore <= 1.0 THEN 1 END) AS validComposite
MATCH (rc2:ReasoningCandidate {selected: true})
WITH total, validNLI, validGoal, validDev, validComposite, count(rc2) AS selectedCount
MATCH (rc3:ReasoningCandidate)
WITH total, validNLI, validGoal, validDev, validComposite, selectedCount,
     count(DISTINCT [rc3.sessionId, rc3.turnNumber]) AS turnGroups
RETURN total, validNLI, validGoal, validDev, validComposite, selectedCount, turnGroups;


// ── AC-P10-8: ConsistencyReport DER scores and HAS_REPORT edges ──────────────
// Expect: total >= 3, all derScore in [0,1], all linked via HAS_REPORT

MATCH (cr:ConsistencyReport)
WITH count(cr) AS total,
     count(CASE WHEN cr.derScore >= 0.0 AND cr.derScore <= 1.0 THEN 1 END) AS validDER
OPTIONAL MATCH (s:Session)-[:HAS_REPORT]->(cr2:ConsistencyReport)
WITH total, validDER, count(cr2) AS linkedReports
RETURN total, validDER, linkedReports;


// ── AC-P10-9: Protocol deviation detection ────────────────────────────────────
// Expect: >= 1 ProtocolTracker with deviationCount > 0,
//         >= 1 FLAGGED_DEVIATION edge to a protocol ConsistencyConflict

MATCH (pt:ProtocolTracker)
WHERE pt.deviationCount > 0
WITH count(pt) AS devTrackers, collect(pt.trackerId) AS devTrackerIds
OPTIONAL MATCH (pt2:ProtocolTracker)-[fd:FLAGGED_DEVIATION]->(cc:ConsistencyConflict {conflictType: 'protocol'})
RETURN devTrackers, devTrackerIds, count(fd) AS flaggedDeviations;


// ── AC-P10-10: 6 consistency Text2CypherTemplate nodes ───────────────────────
// Expect: exactly 6 with category='consistency', all 6 names present

MATCH (t:Text2CypherTemplate {category: 'consistency'})
RETURN count(t) AS total, collect(t.name) AS names
ORDER BY t.name;
