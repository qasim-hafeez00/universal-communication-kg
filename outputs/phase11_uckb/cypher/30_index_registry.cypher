// ============================================================
// UCKB Phase 11 — Script 30: Index Registry
// Creates FullTextIndex and VectorIndex metadata nodes.
// The commented-out block at the bottom contains the actual
// Neo4j index creation DDL for a live 5.11+ instance.
// Run after: 29_hybrid_schema.cypher
// ============================================================

// ── FullTextIndex metadata node ───────────────────────────────

MERGE (fti:FullTextIndex {indexId: 'uckb_fulltext_v1'})
SET fti += {
  indexName:           'uckb_fulltext',
  labels:              ['Technique', 'SignalMarker', 'ProtocolStep'],
  fields:              ['name', 'steps', 'whenToUse', 'failureSignals', 'culturalNotes'],
  analyzer:            'standard-no-stopwords',
  queryOperator:       'OR',
  eventuallyConsistent: false,
  version:             '1.0',
  createdPhase:        '11',
  description:         'BM25 Lucene full-text index over UCKB technique and signal text fields'
};

// ── VectorIndex metadata node ─────────────────────────────────

MERGE (vi:VectorIndex {indexId: 'uckb_vector_v1'})
SET vi += {
  indexName:    'uckb_vector',
  label:        'Technique',
  property:     'embedding',
  dims:         384,
  similarity:   'cosine',
  model:        'sentence-transformers/all-MiniLM-L6-v2',
  quantization: 'none',
  version:      '1.0',
  createdPhase: '11',
  description:  '384-dim cosine vector index over Technique.embedding (all-MiniLM-L6-v2)'
};

// ── Co-index relationship (both indices serve the same corpus) ─

MATCH (fti:FullTextIndex {indexId: 'uckb_fulltext_v1'})
MATCH (vi:VectorIndex    {indexId: 'uckb_vector_v1'})
MERGE (fti)-[:CO_INDEX_WITH]->(vi);

// ── Live Neo4j DDL (uncomment and run on a live 5.11+ instance) ──────────────
//
// -- Full-text index:
// CREATE FULLTEXT INDEX uckb_fulltext IF NOT EXISTS
// FOR (n:Technique|SignalMarker|ProtocolStep)
// ON EACH [n.name, n.steps, n.whenToUse, n.failureSignals, n.culturalNotes];
//
// -- Vector index (Neo4j 5.11 – 5.14 syntax):
// CALL db.index.vector.createNodeIndex(
//   'uckb_vector', 'Technique', 'embedding', 384, 'cosine'
// );
//
// -- Vector index (Neo4j 5.15+ declarative syntax):
// CREATE VECTOR INDEX uckb_vector IF NOT EXISTS
// FOR (n:Technique) ON (n.embedding)
// OPTIONS { indexConfig: {
//   `vector.dimensions`: 384,
//   `vector.similarity_function`: 'cosine'
// }};

RETURN 'Index registry complete — 1 FullTextIndex + 1 VectorIndex metadata nodes' AS status;
