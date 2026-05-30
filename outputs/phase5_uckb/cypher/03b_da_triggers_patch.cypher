// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 5 — Step 03b: Additional TRIGGERS for remaining DialogueActs
//
// Patch to bring AC-3 TRIGGERS coverage from 51% to 100%.
// Covers acts that manage conversational structure, confirmation, and closure.
// All TRIGGERS use broad toLower matches to survive technique name variations.
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// Answer → Active Listening (agent listens to the incoming answer before responding)
MATCH (a:DialogueAct {id: "da_answer"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
MERGE (a)-[:TRIGGERS {weight: 0.87, rationale: "Answer acts require full attentional processing to register the content"}]->(t);

// Correction → Active Listening + Empathic Validation (speaker corrected the agent — acknowledge first)
MATCH (a:DialogueAct {id: "da_correction"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen" OR toLower(t.name) CONTAINS "empath"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "Correction acts signal error — acknowledge gracefully before adjusting"}]->(t);

// AcceptProposal → Rapport + Affirmation (reinforce the acceptance to sustain commitment)
MATCH (a:DialogueAct {id: "da_accept_proposal"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport" OR toLower(t.name) CONTAINS "affirm"
   OR toLower(t.name) CONTAINS "empath"
MERGE (a)-[:TRIGGERS {weight: 0.82, rationale: "Accepted proposals must be reinforced to lock in commitment"}]->(t);

// OfferTurn → Active Listening (agent offers turn — must now listen)
MATCH (a:DialogueAct {id: "da_offer_turn"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
MERGE (a)-[:TRIGGERS {weight: 0.88, rationale: "Offering the turn shifts agent to full listening mode"}]->(t);

// TakeTurn → Active Listening (speaker takes turn — agent must process incoming)
MATCH (a:DialogueAct {id: "da_take_turn"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen" OR toLower(t.name) CONTAINS "empath"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "TakeTurn means the human is speaking — agent activates full listening"}]->(t);

// HoldTurn → Active Listening (speaker is still forming thought — wait and listen)
MATCH (a:DialogueAct {id: "da_hold_turn"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen"
MERGE (a)-[:TRIGGERS {weight: 0.90, rationale: "HoldTurn means the human is mid-utterance — do not interrupt, maintain full attention"}]->(t);

// GiveTurn → Open-ended question / Rapport (agent receives floor — best to invite with open question)
MATCH (a:DialogueAct {id: "da_give_turn"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport" OR toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "open"
MERGE (a)-[:TRIGGERS {weight: 0.80, rationale: "GiveTurn hands floor back to agent — rapport or open question sustains engagement"}]->(t);

// AutoPositive → Empathic Validation (agent received positive feedback — validate and continue)
MATCH (a:DialogueAct {id: "da_auto_positive"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath" OR toLower(t.name) CONTAINS "validat"
   OR toLower(t.name) CONTAINS "affirm"
MERGE (a)-[:TRIGGERS {weight: 0.78, rationale: "AutoPositive confirms understanding — validate and advance the task"}]->(t);

// AlloPositive → Affirmation / Rapport (partner judged act as adequate — reinforce)
MATCH (a:DialogueAct {id: "da_allo_positive"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "affirm" OR toLower(t.name) CONTAINS "rapport"
   OR toLower(t.name) CONTAINS "empath"
MERGE (a)-[:TRIGGERS {weight: 0.80, rationale: "AlloPositive signals the agent's output was judged adequate — reinforce rapport before advancing"}]->(t);

// Retraction → Active Listening (speaker withdrew a prior statement — re-gather without judgment)
MATCH (a:DialogueAct {id: "da_retraction"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "active listen" OR toLower(t.name) CONTAINS "reflective"
   OR toLower(t.name) CONTAINS "empath"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "Retraction indicates changed position — active listening re-establishes shared ground"}]->(t);

// Reformulation → Paraphrasing / Active Listening (speaker rephrased for clarity — confirm comprehension)
MATCH (a:DialogueAct {id: "da_reformulation"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "paraphras" OR toLower(t.name) CONTAINS "active listen"
   OR toLower(t.name) CONTAINS "reflective"
MERGE (a)-[:TRIGGERS {weight: 0.88, rationale: "Reformulation signals the speaker is clarifying — paraphrase to confirm the new wording is understood"}]->(t);

// IndicateUnderstanding → Empathic Validation (partner confirmed they understood — validate and advance)
MATCH (a:DialogueAct {id: "da_indicate_understanding"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath" OR toLower(t.name) CONTAINS "validat"
   OR toLower(t.name) CONTAINS "active listen"
MERGE (a)-[:TRIGGERS {weight: 0.85, rationale: "IndicateUnderstanding confirms comprehension — empathic validation before next task act"}]->(t);

// Goodbye → Rapport Checkpoint (closing act — run rapport check before ending)
MATCH (a:DialogueAct {id: "da_goodbye"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport" OR toLower(t.name) CONTAINS "summary"
MERGE (a)-[:TRIGGERS {weight: 0.75, rationale: "Goodbye/closing requires a rapport checkpoint and summary to end on shared understanding"}]->(t);

// Thanking → Empathic Validation / Affirmation (acknowledge the gratitude warmly)
MATCH (a:DialogueAct {id: "da_thanking"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "empath" OR toLower(t.name) CONTAINS "affirm"
   OR toLower(t.name) CONTAINS "validat"
MERGE (a)-[:TRIGGERS {weight: 0.80, rationale: "Thanking acts open a warmth window — empathic validation sustains the relationship"}]->(t);

// Approval → Affirmation (speaker approved agent's act — reinforce with matched warmth)
MATCH (a:DialogueAct {id: "da_approval"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "affirm" OR toLower(t.name) CONTAINS "empath"
   OR toLower(t.name) CONTAINS "rapport"
MERGE (a)-[:TRIGGERS {weight: 0.78, rationale: "Approval acts signal alignment — affirmation reciprocates and sustains trust"}]->(t);

// Welcome → Rapport / Active Listening (agent welcomed — use rapport-building to open)
MATCH (a:DialogueAct {id: "da_welcome"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport" OR toLower(t.name) CONTAINS "active listen"
MERGE (a)-[:TRIGGERS {weight: 0.80, rationale: "Welcome acts open relational space — rapport-building before task acts"}]->(t);

// Farewell → Rapport Checkpoint / Summary (final structured close)
MATCH (a:DialogueAct {id: "da_farewell"})
MATCH (t:Technique)
WHERE toLower(t.name) CONTAINS "rapport" OR toLower(t.name) CONTAINS "summary"
   OR toLower(t.name) CONTAINS "reflective"
MERGE (a)-[:TRIGGERS {weight: 0.75, rationale: "Farewell triggers a summary reflection to close with shared understanding"}]->(t);


// ── VERIFY ────────────────────────────────────────────────────────────────────
// MATCH (a:DialogueAct)
// OPTIONAL MATCH (a)-[:TRIGGERS]->(:Technique)
// WITH a, count(*) AS triggers
// RETURN count(a) AS total,
//        count(CASE WHEN triggers > 0 THEN 1 END) AS with_triggers,
//        round(100.0 * count(CASE WHEN triggers > 0 THEN 1 END) / count(a), 1) AS pct;
// Expected: pct >= 90.0 (target: 100.0)
