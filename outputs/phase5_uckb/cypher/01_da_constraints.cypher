// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 5 — Step 01: DialogueAct, DST & BDI Constraints + Indices
//
// Phase 4 already declared: dialogue_act_id (DialogueAct.id UNIQUE)
// Phase 5 extends with new node labels required for DST and BDI.
//
// Safe to re-run — all statements use IF NOT EXISTS.
//
// Execute via:
//   docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 < 01_da_constraints.cypher
// ─────────────────────────────────────────────────────────────────────────────


// ── UNIQUENESS CONSTRAINTS ────────────────────────────────────────────────────

// DialogueDimension — one node per ISO 24617-2 dimension (6 total)
CREATE CONSTRAINT dialogue_dimension_id    IF NOT EXISTS
  FOR (d:DialogueDimension) REQUIRE d.id  IS UNIQUE;

// DomainSlot — one node per slot per domain (15 total: 5 × 3 domains)
CREATE CONSTRAINT domain_slot_id           IF NOT EXISTS
  FOR (s:DomainSlot)        REQUIRE s.id  IS UNIQUE;

// BDIState — one template node per domain (3 total)
CREATE CONSTRAINT bdi_state_id             IF NOT EXISTS
  FOR (b:BDIState)          REQUIRE b.id  IS UNIQUE;

// DialogueState — runtime node per session (schema constraint for Phase 9+)
CREATE CONSTRAINT dialogue_state_id        IF NOT EXISTS
  FOR (ds:DialogueState)    REQUIRE ds.id IS UNIQUE;


// ── PERFORMANCE INDICES ───────────────────────────────────────────────────────

// DialogueAct lookup by ISO dimension name (most frequent traversal filter)
CREATE INDEX da_dimension_idx              IF NOT EXISTS
  FOR (a:DialogueAct)       ON (a.dimension);

// DialogueAct lookup by communicativeFunction (used in classification queries)
CREATE INDEX da_function_idx               IF NOT EXISTS
  FOR (a:DialogueAct)       ON (a.communicativeFunction);

// DialogueAct influence-prereq flag (Phase 1 doctrine safety gate)
CREATE INDEX da_influence_prereq_idx       IF NOT EXISTS
  FOR (a:DialogueAct)       ON (a.requiresInfluencePrereq);

// DomainSlot by domain + slotName (DST slot fill lookup)
CREATE INDEX slot_domain_idx               IF NOT EXISTS
  FOR (s:DomainSlot)        ON (s.domain, s.slotName);

// DomainSlot filled status (fast unfilled-slot scan)
CREATE INDEX slot_filled_idx               IF NOT EXISTS
  FOR (s:DomainSlot)        ON (s.domain, s.filled);

// BDIState by domain (BDI template retrieval)
CREATE INDEX bdi_domain_idx                IF NOT EXISTS
  FOR (b:BDIState)          ON (b.domain);

// DialogueState session lookup (Phase 9 temporal memory hook)
CREATE INDEX dialogue_state_session_idx    IF NOT EXISTS
  FOR (ds:DialogueState)    ON (ds.sessionId, ds.domain);


// ── VERIFY ────────────────────────────────────────────────────────────────────
// After running, confirm with:
//   SHOW CONSTRAINTS YIELD name, type, labelsOrTypes, properties
//     WHERE 'DialogueDimension' IN labelsOrTypes
//        OR 'DomainSlot'        IN labelsOrTypes
//        OR 'BDIState'          IN labelsOrTypes
//        OR 'DialogueState'     IN labelsOrTypes;
//   SHOW INDEXES YIELD name WHERE name STARTS WITH 'da_' OR name STARTS WITH 'slot_' OR name STARTS WITH 'bdi_';
