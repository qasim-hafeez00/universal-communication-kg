// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 4 — Step 03: Import Core Ontology (.ttl → Neo4j via n10s)
//
// Imports the 5 core ontology files authored in Phase 3 in strict dependency
// order: class+property declarations first, then named individuals.
//
// The file:// URIs reference the /ontology volume mounted in docker-compose.yml.
// If running Neo4j Desktop without Docker, update these paths to:
//   file:///C:/Users/Seraphindra/Documents/communication_kg/outputs/phase3_uckb/uckb-ontology/core/<file>.ttl
//
// Each CALL returns: terminationStatus, triplesLoaded, triplesParsed,
//   namespaces, extraInfo — verify triplesLoaded > 0 after each step.
// ─────────────────────────────────────────────────────────────────────────────


// ── 1. OWL class hierarchy, object properties, data properties ───────────────
// Defines: 8 top-level classes, 5 s-agent-comm classes,
//          11 object properties (edge types), 22 data properties.
CALL n10s.rdf.import.fetch(
  "file:///ontology/core/communication-acts.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed, namespaces
RETURN "communication-acts" AS file,
       terminationStatus, triplesLoaded, triplesParsed, namespaces;


// ── 2. PsychologicalModel individuals ────────────────────────────────────────
// Creates: TransactionalAnalysis, BDI_Model, CAT, RelevanceTheory,
//          KarpmanDramaTriangle, WinnersTriangle, MotivationalInterviewing_Theory,
//          AttachmentTheory, CognitiveLoadTheory, SocialPenetrationTheory, PolyVagalTheory
CALL n10s.rdf.import.fetch(
  "file:///ontology/core/psychological-models.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed
RETURN "psychological-models" AS file, terminationStatus, triplesLoaded, triplesParsed;


// ── 3. CulturalContext individuals ───────────────────────────────────────────
// Creates: 18 Hofstede, Hall, and Lewis dimension instances.
CALL n10s.rdf.import.fetch(
  "file:///ontology/core/cultural-contexts.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed
RETURN "cultural-contexts" AS file, terminationStatus, triplesLoaded, triplesParsed;


// ── 4. EmotionalState individuals (with valence + arousal) ───────────────────
// Creates: 25 named emotional state instances.
// These become target nodes for :TRIGGERED_BY, :RESOLVES, :CONTRAINDICATED_WHEN.
CALL n10s.rdf.import.fetch(
  "file:///ontology/core/emotional-states.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed
RETURN "emotional-states" AS file, terminationStatus, triplesLoaded, triplesParsed;


// ── 5. CommunicationStyle individuals ────────────────────────────────────────
// Creates: Assertive, Passive, Aggressive, PassiveAggressive, Analytical,
//          Expressive, Driver, Amiable, Formal, Informal.
CALL n10s.rdf.import.fetch(
  "file:///ontology/core/communication-styles.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed
RETURN "communication-styles" AS file, terminationStatus, triplesLoaded, triplesParsed;


// ── Post-import: promote Resource nodes to typed Neo4j labels ─────────────────
// n10s creates :Resource nodes for every OWL NamedIndividual.
// The queries below add the domain-specific Neo4j label so that
// MATCH (e:EmotionalState {name: "Panic"}) works without scanning all :Resource.

MATCH (r:Resource)
WHERE r.uri CONTAINS "ontology#"
  AND "CommunicationTechnique" IN labels(r)
SET r:Technique
RETURN count(r) AS techniques_labelled;

MATCH (r:Resource)
WHERE r.uri CONTAINS "ontology#"
  AND "EmotionalState" IN labels(r)
  AND NOT r:Technique
RETURN count(r) AS emotional_states_already_labelled;

MATCH (r:Resource)
WHERE r.uri CONTAINS "ontology#"
  AND "PsychologicalModel" IN labels(r)
RETURN count(r) AS psych_models;

MATCH (r:Resource)
WHERE r.uri CONTAINS "ontology#"
  AND "CulturalContext" IN labels(r)
RETURN count(r) AS cultural_contexts;

MATCH (r:Resource)
WHERE r.uri CONTAINS "ontology#"
  AND "CommunicationStyle" IN labels(r)
RETURN count(r) AS comm_styles;


// ── Spot-check: list all PsychologicalModel individuals ──────────────────────
MATCH (p:PsychologicalModel)
RETURN p.label AS name, p.uri AS iri
ORDER BY name;
