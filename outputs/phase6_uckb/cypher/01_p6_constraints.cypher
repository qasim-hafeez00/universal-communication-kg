// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 6 — Step 01: Constraints & Indices
//
// Five new node labels: EgoState, FacsMapping, ProsodicFeature,
// BehavioralAdaptor, ModalityWeight
// Safe to re-run — all use IF NOT EXISTS.
// ─────────────────────────────────────────────────────────────────────────────

// ── Unique ID constraints ─────────────────────────────────────────────────────

CREATE CONSTRAINT ego_state_id IF NOT EXISTS
  FOR (e:EgoState) REQUIRE e.id IS UNIQUE;

CREATE CONSTRAINT facs_mapping_id IF NOT EXISTS
  FOR (f:FacsMapping) REQUIRE f.id IS UNIQUE;

CREATE CONSTRAINT prosodic_feature_id IF NOT EXISTS
  FOR (p:ProsodicFeature) REQUIRE p.id IS UNIQUE;

CREATE CONSTRAINT behavioral_adaptor_id IF NOT EXISTS
  FOR (b:BehavioralAdaptor) REQUIRE b.id IS UNIQUE;

CREATE CONSTRAINT modality_weight_id IF NOT EXISTS
  FOR (m:ModalityWeight) REQUIRE m.id IS UNIQUE;

// ── Lookup indices ────────────────────────────────────────────────────────────

CREATE INDEX ego_berne_idx IF NOT EXISTS
  FOR (e:EgoState) ON (e.berneCategory);

CREATE INDEX ego_dysfunctional_idx IF NOT EXISTS
  FOR (e:EgoState) ON (e.isDysfunctional);

CREATE INDEX facs_micro_idx IF NOT EXISTS
  FOR (f:FacsMapping) ON (f.isMicroexpression);

CREATE INDEX prosodic_state_idx IF NOT EXISTS
  FOR (p:ProsodicFeature) ON (p.signalsState);

CREATE INDEX modality_priority_idx IF NOT EXISTS
  FOR (m:ModalityWeight) ON (m.priority);
