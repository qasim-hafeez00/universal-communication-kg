// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 01: Constraints + Indices
//
// 3 UNIQUE constraints for new node labels:
//   CulturalProfile, CulturalAdaptationRule, BehavioralStyleProfile
//
// 4 performance indices for common query patterns.
// Safe to re-run — all use IF NOT EXISTS.
// ─────────────────────────────────────────────────────────────────────────────

// ── Unique constraints ────────────────────────────────────────────────────────

CREATE CONSTRAINT culture_profile_id IF NOT EXISTS
FOR (cp:CulturalProfile) REQUIRE cp.id IS UNIQUE;

CREATE CONSTRAINT cultural_adaptation_rule_id IF NOT EXISTS
FOR (r:CulturalAdaptationRule) REQUIRE r.id IS UNIQUE;

CREATE CONSTRAINT behavioral_style_profile_id IF NOT EXISTS
FOR (bsp:BehavioralStyleProfile) REQUIRE bsp.id IS UNIQUE;

// ── Performance indices ───────────────────────────────────────────────────────

// Lewis model lookup (linear-active | multi-active | reactive)
CREATE INDEX cp_lewis_idx IF NOT EXISTS
FOR (cp:CulturalProfile) ON (cp.lewisModel);

// Hall context level lookup (high | low)
CREATE INDEX cp_context_idx IF NOT EXISTS
FOR (cp:CulturalProfile) ON (cp.hallContextLevel);

// Face-saving flag — routes to face-saving protocol gate
CREATE INDEX cp_face_saving_idx IF NOT EXISTS
FOR (cp:CulturalProfile) ON (cp.faceSaving);

// Primary style index — behavioral style routing
CREATE INDEX bsp_style_idx IF NOT EXISTS
FOR (bsp:BehavioralStyleProfile) ON (bsp.primaryStyle);
