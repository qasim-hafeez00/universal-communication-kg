// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 5 — Step 06: Acceptance Criteria Validation Queries
//
// 8 acceptance criteria matching Phase 4 validation pattern.
// Run after Steps 01-04 are complete.
//
// AC-1  All 6 ISO dimensions present as DialogueDimension nodes
// AC-2  >=30 communicativeFunction types as DialogueAct nodes
// AC-3  >=90% DialogueAct nodes have >=1 TRIGGERS link
// AC-4  DomainSlot nodes per domain == 5 each (Dispatch, Clinical, Sales)
// AC-5  FUNCTIONAL_DEPENDENCY relationships present >= 10
// AC-6  Zero Phase 1 violations (influence acts lacking prereqs in graph)
// AC-7  All DialogueAct nodes carry all 8 ISO mandatory properties
// AC-8  BDI B6 query returns >=1 result per domain
// ─────────────────────────────────────────────────────────────────────────────


// ── AC-1: All 6 ISO Dimensions Present ───────────────────────────────────────
// Expected: count = 6, names = Task|TurnTaking|Feedback|OwnComm|PartnerComm|SocialObligations

MATCH (d:DialogueDimension)
RETURN
  count(d)                AS dimension_count,
  collect(d.name)         AS dimension_names;
// PASS if dimension_count = 6


// ── AC-2: >=30 DialogueAct nodes ──────────────────────────────────────────────
// Expected: count >= 30

MATCH (a:DialogueAct)
RETURN count(a) AS dialogue_act_count;
// PASS if dialogue_act_count >= 30


// ── AC-3: >=90% DialogueActs linked via TRIGGERS ──────────────────────────────
// Expected: linked_pct >= 90.0

MATCH (a:DialogueAct)
WITH count(a) AS total
MATCH (linked:DialogueAct)-[:TRIGGERS]->(:Technique)
WITH total, count(DISTINCT linked) AS linked_count
RETURN
  total                                                     AS total_acts,
  linked_count                                              AS acts_with_triggers,
  round(100.0 * linked_count / total, 1)                    AS linked_pct;
// PASS if linked_pct >= 90.0


// ── AC-4: 5 DomainSlot nodes per domain ──────────────────────────────────────
// Expected: 3 rows each with slot_count = 5

MATCH (s:DomainSlot)
RETURN s.domain AS domain, count(s) AS slot_count
ORDER BY domain;
// PASS if all 3 domains have slot_count = 5


// ── AC-5: >=10 FUNCTIONAL_DEPENDENCY relationships ────────────────────────────
// Expected: count >= 10

MATCH ()-[r:FUNCTIONAL_DEPENDENCY]->()
RETURN count(r) AS functional_dependency_count;
// PASS if functional_dependency_count >= 10


// ── AC-6: Zero Phase 1 Doctrine Violations ────────────────────────────────────
// Checks that no influence-requiring DialogueAct can reach a Technique
// that is marked requiresEmotionalClearance WITHOUT going through a
// grounding/empathy prerequisite first.
//
// A violation is: (influenceAct)-[:TRIGGERS]->(t) where
//   t.requiresEmotionalClearance = true
//   AND there is no (prereq)-[:PRECEDES]->(t) with prereq.isEmotionalPrerequisite = true

MATCH (a:DialogueAct {requiresInfluencePrereq: true})-[:TRIGGERS]->(t:Technique)
WHERE t.requiresEmotionalClearance = true
  AND NOT exists {
    MATCH (prereq:Technique {isEmotionalPrerequisite: true})-[:PRECEDES]->(t)
  }
RETURN
  count(*) AS doctrine_violations,
  collect({act: a.communicativeFunction, technique: t.name}) AS violation_details;
// PASS if doctrine_violations = 0


// ── AC-7: All DialogueAct nodes carry all 8 ISO mandatory properties ──────────
// 8 mandatory properties: communicativeFunction, dimension, sentiment,
// certainty, conditionality, typicalSender, requiresGrounding, requiresInfluencePrereq

MATCH (a:DialogueAct)
WITH a,
     CASE WHEN a.communicativeFunction  IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN a.dimension              IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN a.sentiment              IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN a.certainty              IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN a.conditionality         IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN a.typicalSender          IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN a.requiresGrounding      IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN a.requiresInfluencePrereq IS NOT NULL THEN 1 ELSE 0 END
     AS property_score
RETURN
  count(a)                                                AS total_acts,
  count(CASE WHEN property_score = 8 THEN 1 END)         AS fully_complete,
  count(CASE WHEN property_score < 8 THEN 1 END)         AS incomplete,
  min(property_score)                                     AS min_score,
  round(100.0 * count(CASE WHEN property_score = 8 THEN 1 END) / count(a), 1) AS complete_pct;
// PASS if complete_pct = 100.0


// ── AC-8: BDI B6 query returns >=1 result per domain ─────────────────────────
// Tests B6 for Crisis Dispatch domain with a panic state scenario.
// Expected: >=1 row returned (intention selected)

MATCH (bdi:BDIState {domain: "Crisis Dispatch"})-[:HAS_SLOT]->(s:DomainSlot)
WITH bdi,
     collect({slot: s.slotName, filled: s.filled}) AS slots,
     size([x IN collect(s) WHERE x.filled = false]) AS unfilled_count
MATCH (e:EmotionalState)
WHERE toLower(e.name) CONTAINS "panic"
MATCH (a:DialogueAct)
WHERE NOT (a)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT a.requiresInfluencePrereq = true
MATCH (a)-[:TRIGGERS]->(t:Technique)
WHERE t.domain CONTAINS "Crisis"
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.requiresEmotionalClearance = true
RETURN
  bdi.domain                          AS domain,
  bdi.desireTemplate                  AS agent_desire,
  a.communicativeFunction             AS intended_act,
  t.name                              AS technique_name,
  t.evidenceLevel                     AS evidence_level
ORDER BY t.evidenceLevel DESC
LIMIT 5;
// PASS if >=1 row returned
