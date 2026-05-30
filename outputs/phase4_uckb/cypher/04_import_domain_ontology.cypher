// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 4 — Step 04: Import Domain Ontology + Mappings
//
// Imports the 3 domain .ttl files (150 technique individuals) and the
// domain-to-core-mappings.ttl (cross-domain DOMAIN_VARIANT_OF links).
//
// Run AFTER 03_import_core_ontology.cypher.
// ─────────────────────────────────────────────────────────────────────────────


// ── 1. Crisis Dispatch / Emergency domain (60 individuals) ───────────────────
CALL n10s.rdf.import.fetch(
  "file:///ontology/domains/dispatch.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed, extraInfo
RETURN "dispatch" AS domain, terminationStatus, triplesLoaded, triplesParsed, extraInfo;


// ── 2. Sales & Negotiation domain (45 individuals) ───────────────────────────
CALL n10s.rdf.import.fetch(
  "file:///ontology/domains/negotiation.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed, extraInfo
RETURN "negotiation" AS domain, terminationStatus, triplesLoaded, triplesParsed, extraInfo;


// ── 3. Clinical / Medical domain (45 individuals) ────────────────────────────
CALL n10s.rdf.import.fetch(
  "file:///ontology/domains/clinical.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed, extraInfo
RETURN "clinical" AS domain, terminationStatus, triplesLoaded, triplesParsed, extraInfo;


// ── 4. Domain-to-core mappings (DOMAIN_VARIANT_OF cross-links) ───────────────
CALL n10s.rdf.import.fetch(
  "file:///ontology/mappings/domain-to-core-mappings.ttl",
  "Turtle"
) YIELD terminationStatus, triplesLoaded, triplesParsed
RETURN "mappings" AS file, terminationStatus, triplesLoaded, triplesParsed;


// ── Post-import: verify node counts by class ──────────────────────────────────
MATCH (n:Resource)
WITH labels(n) AS lbls, count(n) AS cnt
UNWIND lbls AS lbl
WITH lbl, sum(cnt) AS total
WHERE lbl <> "Resource"
RETURN lbl AS nodeClass, total AS count
ORDER BY total DESC;


// ── Post-import: verify relationship type inventory ───────────────────────────
MATCH ()-[r]->()
RETURN type(r) AS relationshipType, count(r) AS count
ORDER BY count DESC;


// ── Post-import: spot-check one technique individual ──────────────────────────
MATCH (t:Resource {uri: "https://uckb.io/ontology#crisis_dispatch_001_active_listening"})
RETURN t.uri           AS uri,
       t.label         AS label,
       t.cardId        AS cardId,
       t.domain        AS domain,
       t.whenToUse     AS whenToUse,
       t.steps         AS steps,
       t.cognitiveLoadProfile AS cogLoad;


// ── Post-import: verify TRIGGERED_BY relationships exist ─────────────────────
MATCH (s)-[:TRIGGERED_BY]->(t)
RETURN labels(s)[0] AS signalType, s.label AS signal,
       labels(t)[0] AS techniqueType, t.label AS technique
LIMIT 10;


// ── Post-import: count DOMAIN_VARIANT_OF cross-domain links ──────────────────
MATCH (a)-[:DOMAIN_VARIANT_OF]->(b)
RETURN count(*) AS domain_variant_links;
