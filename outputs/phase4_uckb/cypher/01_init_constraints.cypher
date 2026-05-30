// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 4 — Step 01: Uniqueness Constraints + Performance Indices
//
// Run this FIRST, before any data import or n10s initialization.
// Every MERGE and MATCH in subsequent scripts depends on these constraints.
// All statements use IF NOT EXISTS so the script is safe to re-run.
//
// Execute in Neo4j Browser or:
//   docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 < 01_init_constraints.cypher
// ─────────────────────────────────────────────────────────────────────────────


// ── UNIQUENESS CONSTRAINTS ────────────────────────────────────────────────────

// Core knowledge nodes
CREATE CONSTRAINT technique_id_unique      IF NOT EXISTS
  FOR (t:Technique)         REQUIRE t.id         IS UNIQUE;

CREATE CONSTRAINT domain_protocol_id       IF NOT EXISTS
  FOR (d:DomainProtocol)    REQUIRE d.id         IS UNIQUE;

CREATE CONSTRAINT emotional_state_name     IF NOT EXISTS
  FOR (e:EmotionalState)    REQUIRE e.name       IS UNIQUE;

CREATE CONSTRAINT cultural_context_code    IF NOT EXISTS
  FOR (c:CulturalContext)   REQUIRE c.code       IS UNIQUE;

CREATE CONSTRAINT signal_marker_id         IF NOT EXISTS
  FOR (m:SignalMarker)      REQUIRE m.id         IS UNIQUE;

CREATE CONSTRAINT comm_style_name          IF NOT EXISTS
  FOR (s:CommunicationStyle) REQUIRE s.name      IS UNIQUE;

CREATE CONSTRAINT psych_model_name         IF NOT EXISTS
  FOR (p:PsychologicalModel) REQUIRE p.name      IS UNIQUE;

// Runtime / session nodes (needed from Phase 9 onward; defined here for schema completeness)
CREATE CONSTRAINT session_id_unique        IF NOT EXISTS
  FOR (s:Session)           REQUIRE s.sessionId  IS UNIQUE;

CREATE CONSTRAINT dialogue_act_id          IF NOT EXISTS
  FOR (a:DialogueAct)       REQUIRE a.id         IS UNIQUE;

// n10s RDF resource node — required by Neosemantics BEFORE any RDF import
CREATE CONSTRAINT n10s_unique_uri          IF NOT EXISTS
  FOR (r:Resource)          REQUIRE r.uri        IS UNIQUE;


// ── PERFORMANCE INDICES ───────────────────────────────────────────────────────

// Technique lookups by domain (most frequent query filter)
CREATE INDEX technique_domain_idx          IF NOT EXISTS
  FOR (t:Technique)         ON (t.domain);

// Class label index (used in cross-class traversal)
CREATE INDEX technique_class_idx           IF NOT EXISTS
  FOR (t:Technique)         ON (t.classLabel);

// Tier index (Tier 1 fast-path)
CREATE INDEX technique_tier_idx            IF NOT EXISTS
  FOR (t:Technique)         ON (t.tier);

// Evidence + latency composite — serves ORDER BY evidenceLevel DESC, avgLatency_ms ASC
CREATE INDEX technique_evidence_latency    IF NOT EXISTS
  FOR (t:Technique)         ON (t.evidenceLevel, t.avgLatency_ms);

// Review status (used in curation workflows)
CREATE INDEX technique_review_idx          IF NOT EXISTS
  FOR (t:Technique)         ON (t.reviewStatus);

// Emotional state dimensional index — serves valence/arousal routing
CREATE INDEX emotion_arousal_idx           IF NOT EXISTS
  FOR (e:EmotionalState)    ON (e.valence, e.arousal);

// Signal marker modality+type (multi-modal signal routing)
CREATE INDEX signal_type_idx               IF NOT EXISTS
  FOR (m:SignalMarker)      ON (m.modality, m.type);

// Domain protocol domain filter
CREATE INDEX domain_protocol_domain_idx    IF NOT EXISTS
  FOR (d:DomainProtocol)    ON (d.domain);

// Session timestamp (needed for Phase 9 Graphiti temporal memory)
CREATE INDEX session_timestamp_idx         IF NOT EXISTS
  FOR (s:Session)           ON (s.startedAt);

// Cognitive load profile index (Relevance Theory routing)
CREATE INDEX technique_cognitive_load_idx  IF NOT EXISTS
  FOR (t:Technique)         ON (t.cognitiveLoadProfile);

// Safety clearance flag (Phase 1 doctrine enforcement queries)
CREATE INDEX technique_safety_flag_idx     IF NOT EXISTS
  FOR (t:Technique)         ON (t.requiresEmotionalClearance);


// ── VERIFY ────────────────────────────────────────────────────────────────────
// Run after script to confirm all constraints and indices are active:
//
//   SHOW CONSTRAINTS;
//   SHOW INDEXES;
