// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 05: Enrich Existing Nodes
//
// 1. Add 2 new CommunicationStyle nodes (Diplomatic, Charismatic)
// 2. Add agentAdaptation property to all 15 CommunicationStyle nodes
// 3. Add 1 new PsychologicalModel node (UCKB Behavioral Style Taxonomy already in 04)
// 4. Add BELONGS_TO_MODEL from existing CulturalContext nodes to new framework models
// 5. Add PREFERS_STYLE (CulturalContext -> CommunicationStyle)
//
// Safe to re-run — all statements use MERGE or MATCH+SET.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// 1. New CommunicationStyle nodes (2)
// ════════════════════════════════════════════════════════════════════════════

MERGE (cs:CommunicationStyle {name: "Diplomatic"})
SET cs += {
  id: "style_diplomatic",
  description: "Measured, polite tones seeking consensus; minimises friction between stakeholders; bridges divergent viewpoints.",
  agentAdaptation: "Synthesize stakeholder positions; integrative summaries; never take sides publicly; seek consensus framing",
  createdInPhase: 7
};

MERGE (cs:CommunicationStyle {name: "Charismatic"})
SET cs += {
  id: "style_charismatic",
  description: "Combines authority with approachability; projects high social intelligence and vision; inspires rapid intellectual buy-in.",
  agentAdaptation: "Align with high-level vision; aspirational framing; acknowledge authority with substantive content; leverage social proof",
  createdInPhase: 7
};

// ════════════════════════════════════════════════════════════════════════════
// 2. Add agentAdaptation to existing 13 CommunicationStyle nodes
// ════════════════════════════════════════════════════════════════════════════

MATCH (cs:CommunicationStyle {name: "Aggressive"})
SET cs.agentAdaptation = "Deploy firm Adult boundaries; refuse to interrupt; redirect to objective data; never match aggression; mirror calm state";

MATCH (cs:CommunicationStyle {name: "Passive"})
SET cs.agentAdaptation = "Proactively elicit opinions; create psychological safety; use open questions; do not press for immediate decisions";

MATCH (cs:CommunicationStyle {name: "Passive-Aggressive"})
SET cs.agentAdaptation = "Ignore sarcasm; address literal meaning; force explicit clarity on unstated needs; do not mirror covert hostility";

MATCH (cs:CommunicationStyle {name: "Assertive"})
SET cs.agentAdaptation = "Match directness with mutual respect; collaborative problem-solving; affirm interests before positions";

MATCH (cs:CommunicationStyle {name: "Analytical"})
SET cs.agentAdaptation = "Disable emotional framing; lead with data, metrics, verifiable evidence; step-by-step logical sequencing";

MATCH (cs:CommunicationStyle {name: "Amiable"})
SET cs.agentAdaptation = "Build rapport warmly; acknowledge relationship before task; consensus-seek; validate feelings before logic";

MATCH (cs:CommunicationStyle {name: "Driver"})
SET cs.agentAdaptation = "Match decisiveness; be concise; eliminate ambiguity; respect urgency; lead with bottom-line first";

MATCH (cs:CommunicationStyle {name: "Expressive"})
SET cs.agentAdaptation = "Engage emotionally; validate feelings before logic; high-energy acknowledgment; narrative framing over data";

MATCH (cs:CommunicationStyle {name: "Formal"})
SET cs.agentAdaptation = "Maintain formal register throughout; structure responses hierarchically; avoid contractions and casual language";

MATCH (cs:CommunicationStyle {name: "Informal"})
SET cs.agentAdaptation = "Casual rapport-centred tone; flexibility in sequencing; conversational register; deprioritise formality";

// ════════════════════════════════════════════════════════════════════════════
// 3. BELONGS_TO_MODEL — existing CulturalContext nodes -> cultural framework models
// ════════════════════════════════════════════════════════════════════════════

// Hofstede dimensions -> Hofstede model
MATCH (m:PsychologicalModel {name: "Hofstede Cultural Dimensions"})
MATCH (c:CulturalContext) WHERE c.name IN [
  "High Power Distance","Low Power Distance","High Individualism","High Collectivism",
  "High Masculinity","High Femininity","High Uncertainty Avoidance","Low Uncertainty Avoidance",
  "Long-Term Orientation","Short-Term Orientation",
  "PowerDistanceHigh","PowerDistanceLow","IndividualismHigh","CollectivismHigh",
  "MasculinityHigh","FemininityHigh","UncertaintyAvoidanceHigh","UncertaintyAvoidanceLow",
  "LongTermOrientation","ShortTermOrientation"
]
MERGE (c)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(m);

// Hall's context model -> Hall model
MATCH (m:PsychologicalModel {name: "Hall's Context Communication Model"})
MATCH (c:CulturalContext) WHERE c.name IN [
  "High Context","Low Context","HighContext","LowContext"
]
MERGE (c)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(m);

// Lewis model nodes
MATCH (m:PsychologicalModel {name: "Lewis Model of Communication"})
MATCH (c:CulturalContext) WHERE c.name IN [
  "Linear-Active","Multi-Active","Reactive","LinearActive","MultiActive"
]
MERGE (c)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(m);

// Proxemics and time orientation -> Hall model (Hall also defined these)
MATCH (m:PsychologicalModel {name: "Hall's Context Communication Model"})
MATCH (c:CulturalContext) WHERE c.name IN [
  "Monochronic Time","Polychronic Time","High Proxemics","Low Proxemics",
  "MonochronicTime","PolychronicTime","HighProxemics","LowProxemics"
]
MERGE (c)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(m);

// ════════════════════════════════════════════════════════════════════════════
// 4. PREFERS_STYLE — CulturalContext -> CommunicationStyle
// Dimensional context predicts communication style tendency
// ════════════════════════════════════════════════════════════════════════════

// Low Context -> Assertive, Analytical
MATCH (c:CulturalContext) WHERE c.name IN ["Low Context","LowContext"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Assertive","Analytical"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Low-context cultures expect explicit, direct, fact-grounded communication"}]->(cs);

// LinearActive -> Analytical, Driver
MATCH (c:CulturalContext) WHERE c.name IN ["Linear-Active","LinearActive"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Analytical","Driver"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Task-oriented linear-active cultures reward systematic and results-driven communication"}]->(cs);

// MultiActive -> Expressive, Amiable
MATCH (c:CulturalContext) WHERE c.name IN ["Multi-Active","MultiActive"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Expressive","Amiable"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Relationship-first multi-active cultures favour warm, emotionally-engaged communication"}]->(cs);

// Reactive -> Formal, Amiable
MATCH (c:CulturalContext) WHERE c.name IN ["Reactive"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Formal","Amiable"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Reactive cultures listen carefully; formality and warmth build trust before response"}]->(cs);

// IndividualismHigh -> Assertive, Driver
MATCH (c:CulturalContext) WHERE c.name IN ["High Individualism","IndividualismHigh"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Assertive","Driver"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Individualist cultures reward personal autonomy assertion and decisive self-direction"}]->(cs);

// CollectivismHigh -> Amiable, Formal
MATCH (c:CulturalContext) WHERE c.name IN ["High Collectivism","CollectivismHigh"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Amiable","Formal"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Collectivist cultures prioritise in-group harmony and face-preserving formality"}]->(cs);

// PowerDistanceHigh -> Formal (toward authority)
MATCH (c:CulturalContext) WHERE c.name IN ["High Power Distance","PowerDistanceHigh"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Formal","Diplomatic"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "High power distance cultures enforce formal hierarchical communication registers"}]->(cs);

// PowerDistanceLow -> Assertive, Informal
MATCH (c:CulturalContext) WHERE c.name IN ["Low Power Distance","PowerDistanceLow"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Assertive","Informal"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Egalitarian low-PDI cultures expect direct informal communication regardless of role"}]->(cs);

// MasculinityHigh -> Driver, Assertive
MATCH (c:CulturalContext) WHERE c.name IN ["High Masculinity","MasculinityHigh"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Driver","Assertive"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Achievement-oriented masculine cultures reward decisive, results-focused communication"}]->(cs);

// FemininityHigh -> Amiable, Diplomatic
MATCH (c:CulturalContext) WHERE c.name IN ["High Femininity","FemininityHigh"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Amiable","Diplomatic"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Consensus-oriented feminine cultures favour cooperative, caring communication styles"}]->(cs);

// UncertaintyAvoidanceHigh -> Formal, Analytical
MATCH (c:CulturalContext) WHERE c.name IN ["High Uncertainty Avoidance","UncertaintyAvoidanceHigh"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Formal","Analytical"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "UAI cultures use formality and analytical precision as ambiguity-reduction mechanisms"}]->(cs);

// UncertaintyAvoidanceLow -> Expressive, Informal
MATCH (c:CulturalContext) WHERE c.name IN ["Low Uncertainty Avoidance","UncertaintyAvoidanceLow"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Expressive","Informal"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "Low-UAI cultures tolerate ambiguity and reward flexible, spontaneous communication"}]->(cs);

// High Context -> Diplomatic, Amiable
MATCH (c:CulturalContext) WHERE c.name IN ["High Context","HighContext"]
MATCH (cs:CommunicationStyle) WHERE cs.name IN ["Diplomatic","Amiable"]
MERGE (c)-[:PREFERS_STYLE {addedInPhase: 7, rationale: "High-context cultures rely on implicit meaning, relationship, and face-aware communication"}]->(cs);
