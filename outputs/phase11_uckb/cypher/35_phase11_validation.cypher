// ============================================================
// UCKB Phase 11 — Script 35: Validation Suite
// 10 acceptance criteria queries for Neo4j.
// Run after all scripts 29-34 have been ingested.
// ============================================================

// ── AC-P11-1: All 6 Phase 11 node types present ──────────────

MATCH (n)
WHERE n:FullTextIndex OR n:VectorIndex OR n:FusionConfig
   OR n:HybridQuery   OR n:RetrievalLeg OR n:HybridResult
WITH labels(n)[0] AS lbl, count(n) AS cnt
RETURN lbl, cnt ORDER BY lbl;
// Expected: FullTextIndex=1, VectorIndex=1, FusionConfig=6,
//           HybridQuery=6, RetrievalLeg=18, HybridResult=6


// ── AC-P11-2: FullTextIndex fields and analyzer ───────────────

MATCH (fti:FullTextIndex)
RETURN fti.indexId AS indexId,
       fti.labels AS labels,
       fti.fields AS fields,
       fti.analyzer AS analyzer;
// Expected: labels contains Technique; fields contains name/steps/whenToUse;
//           analyzer = standard-no-stopwords


// ── AC-P11-3: VectorIndex dims, similarity, model ────────────

MATCH (vi:VectorIndex)
RETURN vi.indexId AS indexId,
       vi.dims AS dims,
       vi.similarity AS similarity,
       vi.model AS model;
// Expected: dims=384, similarity=cosine, model contains all-MiniLM-L6-v2
// NOTE: Technique.embedding population is validated by validate_phase11.py
//       (reads generate_embeddings output — >= 100 Technique embeddings required)


// ── AC-P11-4: FusionConfig weight sums = 1.0 ─────────────────

MATCH (fc:FusionConfig)
RETURN fc.domain AS domain,
       fc.k AS k,
       round(fc.bm25Weight + fc.vectorWeight + fc.cypherWeight, 6) AS weight_sum
ORDER BY domain;
// Expected: 6 rows, all k=60, all weight_sum=1.0


// ── AC-P11-5: HybridQuery has all required edges ─────────────

MATCH (hq:HybridQuery)
OPTIONAL MATCH (hq)-[:USES_FUSION]->(fc:FusionConfig)
OPTIONAL MATCH (hq)-[:QUERIES_INDEX]->(fti:FullTextIndex)
OPTIONAL MATCH (hq)-[:QUERIES_INDEX]->(vi:VectorIndex)
OPTIONAL MATCH (hq)-[:FILTERS_BY]->(sfr:SchemaFilterRegistry)
RETURN hq.queryId AS queryId,
       hq.domain AS domain,
       fc.domain IS NOT NULL AS hasFusionConfig,
       fti.indexId IS NOT NULL AS hasFullTextIndex,
       vi.indexId IS NOT NULL AS hasVectorIndex,
       sfr.domain IS NOT NULL AS hasSchemaFilter,
       hq.cypherTemplate IS NOT NULL AS hasCypherTemplate,
       hq.bm25Fields IS NOT NULL AS hasBM25Fields,
       hq.vectorProperty IS NOT NULL AS hasVectorProperty
ORDER BY domain;
// Expected: all boolean fields = true for all 6 rows


// ── AC-P11-6: RetrievalLeg count, legType, rank ──────────────

MATCH (rl:RetrievalLeg)
RETURN count(rl) AS total,
       count(CASE WHEN rl.legType IN ['bm25','vector','cypher'] THEN 1 END) AS validLegTypes,
       count(CASE WHEN rl.rank >= 1 THEN 1 END) AS validRanks,
       collect(DISTINCT rl.legType) AS distinctLegTypes
ORDER BY total;
// Expected: total=18, validLegTypes=18, validRanks=18


// ── AC-P11-7: HybridResult count, safetyValidated, not activationBlocked ──

MATCH (hr:HybridResult)
RETURN count(hr) AS total,
       count(CASE WHEN hr.safetyValidated = true THEN 1 END) AS safetyValidated,
       count(CASE WHEN hr.activationBlocked = false THEN 1 END) AS notBlocked,
       count(CASE WHEN hr.fusedRank = 1 THEN 1 END) AS topRankResults
ORDER BY total;
// Expected: total=6, safetyValidated=6, notBlocked=6, topRankResults=6


// ── AC-P11-8: RRF formula verification ───────────────────────

MATCH (hr:HybridResult)
OPTIONAL MATCH (fc:FusionConfig {domain: hr.domain})
RETURN hr.resultId AS resultId,
       hr.domain AS domain,
       hr.rrfScore AS storedScore,
       round(
         fc.bm25Weight   / (fc.k + hr.legBM25Rank)   +
         fc.vectorWeight / (fc.k + hr.legVectorRank)  +
         fc.cypherWeight / (fc.k + hr.legCypherRank), 6
       ) AS computedScore,
       abs(hr.rrfScore - (
         fc.bm25Weight   / (fc.k + hr.legBM25Rank)   +
         fc.vectorWeight / (fc.k + hr.legVectorRank)  +
         fc.cypherWeight / (fc.k + hr.legCypherRank)
       )) AS delta
ORDER BY hr.domain;
// Expected: all delta < 0.001


// ── AC-P11-9: Cross-domain safety ────────────────────────────

MATCH (hr:HybridResult)
MATCH (sfr:SchemaFilterRegistry {domain: hr.domain})
WHERE sfr.blockedDomains IS NOT NULL
WITH hr, split(sfr.blockedDomains, ';') AS blocked
MATCH (t:Technique {id: hr.techniqueId})
WHERE any(b IN blocked WHERE t.domain CONTAINS b)
RETURN hr.resultId AS violation, hr.techniqueId, t.domain, sfr.blockedDomains;
// Expected: 0 rows (no cross-domain violations)


// ── AC-P11-10: Hybrid templates — 6 with category='hybrid' ───

MATCH (t:Text2CypherTemplate {category: 'hybrid'})
RETURN count(t) AS total,
       collect(t.name) AS names,
       count(CASE WHEN t.cypherQuery CONTAINS 'rrfScore' THEN 1 END) AS withRRFOrdering,
       count(CASE WHEN t.cypherQuery CONTAINS 'ORDER BY rrfScore' THEN 1 END) AS withOrderBy
ORDER BY total;
// Expected: total=6, withOrderBy=6


// ── Full Phase 11 node inventory ─────────────────────────────

MATCH (n)
WHERE n:FullTextIndex OR n:VectorIndex OR n:FusionConfig
   OR n:HybridQuery   OR n:RetrievalLeg OR n:HybridResult
RETURN labels(n)[0] AS type, count(n) AS count
ORDER BY type;

MATCH (n) RETURN count(n) AS total_graph_nodes;
// Expected: ~1187 total nodes (1143 baseline + 44 new)
