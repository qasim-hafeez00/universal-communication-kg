// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 4 — Step 02: Neosemantics (n10s) Graph Configuration
//
// Run AFTER 01_init_constraints.cypher and BEFORE any RDF import.
// This initializes n10s with the exact settings required for UCKB ontology
// structure: clean property names, array multi-values, and dual label+node
// RDF type handling.
//
// IMPORTANT: n10s graphconfig can only be initialized ONCE per database.
// To change config, run: CALL n10s.graphconfig.drop(); then re-init.
// ─────────────────────────────────────────────────────────────────────────────


// ── Initialize n10s graph configuration ──────────────────────────────────────
CALL n10s.graphconfig.init({

  // Strip namespace URIs from property names.
  // "https://uckb.io/ontology#cardId" → "cardId"
  // "http://www.w3.org/2000/01/rdf-schema#label" → "label"
  handleVocabUris: "IGNORE",

  // Store multi-valued RDF properties as Neo4j arrays.
  // The properties listed in multivalPropList will always be arrays,
  // even when only one value is present.
  handleMultival: "ARRAY",
  multivalPropList: [
    "whenToUse",
    "whenNotToUse",
    "successSignals",
    "failureSignals",
    "triggerSignals",
    "switchTo",
    "domainVariants",
    "dialogueActLinks",
    "sourceIds"
  ],

  // Create both a Neo4j label AND a Resource node for each rdf:type.
  // This means uckb:CommunicationTechnique individuals get both:
  //   - a :CommunicationTechnique label (for direct MATCH)
  //   - a :Resource node linked via :rdf__type (for OWL provenance)
  handleRDFTypes: "LABELS_AND_NODES",

  // Do not append language tags to literal values (@en, @fr, etc.)
  keepLangTag: false,

  // Do not preserve custom XSD datatype annotations in property names
  keepCustomDataTypes: false

});

// ── Verify configuration was stored correctly ─────────────────────────────────
CALL n10s.graphconfig.show()
YIELD param, value
RETURN param, value
ORDER BY param;


// ── Namespace mappings ────────────────────────────────────────────────────────
// Register UCKB namespace prefix so IRIs are displayed cleanly in the browser.

CALL n10s.nsprefixes.add("uckb",  "https://uckb.io/ontology#");
CALL n10s.nsprefixes.add("sac",   "https://www.w3.org/community/s-agent-comm/ontology#");
CALL n10s.nsprefixes.add("owl",   "http://www.w3.org/2002/07/owl#");
CALL n10s.nsprefixes.add("rdfs",  "http://www.w3.org/2000/01/rdf-schema#");
CALL n10s.nsprefixes.add("sh",    "http://www.w3.org/ns/shacl#");
CALL n10s.nsprefixes.add("skos",  "http://www.w3.org/2004/02/skos/core#");
CALL n10s.nsprefixes.add("dc",    "http://purl.org/dc/elements/1.1/");

CALL n10s.nsprefixes.list()
YIELD prefix, namespace
RETURN prefix, namespace
ORDER BY prefix;
