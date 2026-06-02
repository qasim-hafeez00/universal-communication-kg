// All read-only Cypher queries matching the live Neo4j schema.
// Single catch-all approach: covers every node type via coalesce of all known ID props.
//
// WHY we exclude only structural OWL nodes (Class, ObjectProperty, etc.)
// and NOT NamedIndividual / Resource:
//   Many business nodes (Technique, EmotionalState, PsychologicalModel, …) were
//   imported via n10s (neosemantics) and carry :NamedIndividual and :Resource labels
//   alongside their domain label. Excluding by those labels drops 200+ valid nodes.

// All ID properties across every phase.
// ORDER IS CRITICAL: specific primary keys must come before FK references.
// e.g. sessionId is stored as FK on Turn/EpisodicMemory/WorkingMemorySlot/etc.
// so turnId/episodeId/slotId MUST come before sessionId.
// queryId is stored as FK on RetrievalLeg/HybridResult so legId/resultId MUST come first.
const ALL_ID_COALESCE = `coalesce(
    n.cardId,      n.legId,       n.resultId,    n.indexId,
    n.turnId,      n.episodeId,   n.slotId,      n.traceId,
    n.factId,      n.goalId,      n.trackerId,   n.conflictId,
    n.candidateId, n.reportId,    n.templateId,
    n.queryId,     n.id,          n.sessionId,   n.uri,         n.domain
  )`;

// All properties that could hold a human-readable name — ordered by most descriptive first.
// n.label is last before fallbacks: OWL-imported nodes (Technique) may only have label, not name.
const ALL_NAME_COALESCE = `coalesce(
    n.name, n.communicativeFunction, n.emotionLabel, n.content,
    n.goalDescription, n.description, n.currentStepName, n.responseSketch,
    n.condition, n.slotName, n.key, n.label, n.sessionId, n.domain
  )`;

// Domain inference CASE — covers every node type across all phases
const DOMAIN_CASE = `
  CASE
    WHEN n.domain IS NOT NULL THEN n.domain
    WHEN n:ConversationFact OR n:GoalState OR n:ProtocolTracker
         OR n:ConsistencyConflict OR n:ReasoningCandidate
         OR n:ConsistencyReport                                             THEN 'Consistency'
    WHEN n:Session OR n:Turn OR n:EpisodicMemory OR n:WorkingMemorySlot
         OR n:MemoryTrace OR n:TemporalFact                                THEN 'Memory'
    WHEN n:FullTextIndex OR n:VectorIndex OR n:FusionConfig OR n:HybridQuery
         OR n:RetrievalLeg OR n:HybridResult OR n:SchemaFilterRegistry     THEN 'Retrieval'
    WHEN n:ProtocolStep OR n:ProtocolDAG OR n:ProtocolGate
         OR n:DomainProtocol                                               THEN 'Protocol'
    WHEN n:Text2CypherTemplate OR n:DomainSlot OR n:DomainBoundary         THEN 'Schema'
    WHEN n:DialogueAct                                                     THEN 'Dialogue Acts'
    WHEN n:EmotionalState OR n:EgoState OR n:PsychologicalModel
         OR n:BDIState OR n:KnowledgeState                                 THEN 'Psychological'
    WHEN n:CulturalProfile OR n:CulturalAdaptationRule OR n:CulturalContext
         OR n:BehavioralStyleProfile OR n:BehavioralAdaptor
         OR n:ModalityWeight                                               THEN 'Cultural'
    WHEN n:FacsMapping OR n:ProsodicFeature OR n:DialogueDimension
         OR n:DialogueState OR n:CommunicationStyle                        THEN 'Multimodal'
    ELSE 'Schema'
  END`;

// Deterministic filter: requires at least one non-structural label.
// Using labels(n)[0] was non-deterministic — Neo4j label order is not guaranteed.
// any() over all labels is safe regardless of order.
const STRUCTURAL_LABELS = `['Resource','NamedIndividual','Class','ObjectProperty',
     'DatatypeProperty','Ontology','_GraphConfig','_NsPrefDef']`;

const EXCLUDE_WHERE = `NOT (n:Class OR n:ObjectProperty OR n:DatatypeProperty
       OR n:Ontology OR n:_GraphConfig OR n:_NsPrefDef)
  AND any(lbl IN labels(n) WHERE NOT lbl IN ${STRUCTURAL_LABELS})`;

export const Q_ALL_NODES = `
MATCH (n)
WHERE ${EXCLUDE_WHERE}
WITH n,
  ${ALL_ID_COALESCE}   AS nodeId,
  ${ALL_NAME_COALESCE} AS nodeName
WHERE nodeId IS NOT NULL AND nodeName IS NOT NULL
RETURN
  nodeId                                          AS id,
  nodeName                                        AS name,
  ${DOMAIN_CASE}                                  AS domain,
  [lbl IN labels(n) WHERE NOT lbl IN ${STRUCTURAL_LABELS}][0] AS type,
  COUNT { (n)-[]-() }                             AS degree
`;

// Edge coalesce: same ordering as node coalesce — specific PKs before FK references
const SRC_COALESCE = `coalesce(
    a.cardId,      a.legId,       a.resultId,    a.indexId,
    a.turnId,      a.episodeId,   a.slotId,      a.traceId,
    a.factId,      a.goalId,      a.trackerId,   a.conflictId,
    a.candidateId, a.reportId,    a.templateId,
    a.queryId,     a.id,          a.sessionId,   a.uri,         a.domain)`;

const TGT_COALESCE = `coalesce(
    b.cardId,      b.legId,       b.resultId,    b.indexId,
    b.turnId,      b.episodeId,   b.slotId,      b.traceId,
    b.factId,      b.goalId,      b.trackerId,   b.conflictId,
    b.candidateId, b.reportId,    b.templateId,
    b.queryId,     b.id,          b.sessionId,   b.uri,         b.domain)`;

const EDGE_STRUCTURAL = `['Resource','NamedIndividual','Class','ObjectProperty',
        'DatatypeProperty','Ontology','_GraphConfig','_NsPrefDef']`;

const EDGE_EXCLUDE = `any(lbl IN labels(a) WHERE NOT lbl IN ${EDGE_STRUCTURAL})
  AND any(lbl IN labels(b) WHERE NOT lbl IN ${EDGE_STRUCTURAL})`;

export const Q_ALL_EDGES = `
MATCH (a)-[r]->(b)
WHERE ${EDGE_EXCLUDE}
  AND NOT type(r) IN ['SAME_AS', 'domain', 'range', 'type', 'subClassOf',
                      'subPropertyOf', 'equivalentClass', 'equivalentProperty',
                      'inverseOf', 'disjointWith']
WITH a, b, r, ${SRC_COALESCE} AS src, ${TGT_COALESCE} AS tgt
WHERE src IS NOT NULL AND tgt IS NOT NULL AND src <> tgt
RETURN src AS source, tgt AS target, type(r) AS relType,
       coalesce(r.weight, 1.0) AS weight
`;

// Node detail lookup — tries every known ID property
export const Q_NODE_DETAIL = `
MATCH (n)
WHERE NOT (n:Class OR n:ObjectProperty OR n:DatatypeProperty)
  AND (n.cardId = $id OR n.id = $id OR n.uri = $id
    OR n.indexId = $id OR n.queryId = $id OR n.legId = $id OR n.resultId = $id
    OR n.sessionId = $id OR n.turnId = $id OR n.episodeId = $id
    OR n.slotId = $id OR n.traceId = $id OR n.factId = $id
    OR n.goalId = $id OR n.trackerId = $id OR n.conflictId = $id
    OR n.candidateId = $id OR n.reportId = $id OR n.templateId = $id
    OR n.domain = $id)
WITH n
LIMIT 1
OPTIONAL MATCH (n)-[r]-(neighbor)
WHERE NOT (neighbor:Class OR neighbor:ObjectProperty OR neighbor:DatatypeProperty
        OR neighbor:Ontology OR neighbor:_GraphConfig OR neighbor:_NsPrefDef)
RETURN n,
  collect({
    relType:   type(r),
    direction: CASE WHEN startNode(r) = n THEN 'out' ELSE 'in' END,
    id:        coalesce(neighbor.cardId, neighbor.legId, neighbor.resultId,
                        neighbor.turnId, neighbor.factId, neighbor.goalId,
                        neighbor.trackerId, neighbor.conflictId, neighbor.candidateId,
                        neighbor.reportId, neighbor.id, neighbor.sessionId,
                        neighbor.uri, neighbor.templateId, neighbor.domain),
    name:      coalesce(neighbor.name, neighbor.communicativeFunction,
                        neighbor.content, neighbor.goalDescription, 'Unknown'),
    domain:    coalesce(neighbor.domain, 'Schema'),
    nodeType:  [lbl IN labels(neighbor) WHERE NOT lbl IN ['Resource','NamedIndividual',
                  'Class','ObjectProperty','DatatypeProperty','Ontology',
                  '_GraphConfig','_NsPrefDef']][0]
  }) AS neighbors
`;

// Protocol learning path via PART_OF
export const Q_PROTOCOL_PATH = `
MATCH (d:ProtocolDAG {domain: $domain})
MATCH (step:ProtocolStep)-[:PART_OF]->(d)
OPTIONAL MATCH (step)-[:TRIGGERS]->(tech:Technique)
WHERE tech.name IS NOT NULL
RETURN
  step.id          AS stepId,
  step.name        AS stepName,
  step.stepNumber  AS stepNumber,
  step.description AS description,
  step.protocol    AS protocol,
  step.domain      AS domain,
  collect({
    id:     tech.cardId,
    name:   tech.name,
    domain: tech.domain,
    type:   'Technique',
    degree: 0
  }) AS techniques
ORDER BY step.stepNumber ASC
`;

export const Q_DOMAIN_NODES = `
MATCH (n:Technique)
WHERE n.domain = $domain AND n.name IS NOT NULL AND n.cardId IS NOT NULL
RETURN
  n.cardId  AS id,
  n.name    AS name,
  n.domain  AS domain,
  'Technique' AS type,
  COUNT { (n)-[]-() } AS degree
ORDER BY degree DESC
`;

export const Q_SHORTEST_PATH = `
MATCH (a), (b)
WHERE (a.cardId = $from OR a.id = $from)
  AND (b.cardId = $to   OR b.id = $to)
MATCH path = shortestPath((a)-[*..12]-(b))
RETURN [node IN nodes(path) | {
  id:     coalesce(node.cardId, node.id),
  name:   coalesce(node.name, node.communicativeFunction, 'Unknown'),
  domain: coalesce(node.domain, 'Unknown')
}] AS steps
LIMIT 1
`;

export const Q_SEARCH = `
MATCH (n:Technique)
WHERE n.name IS NOT NULL
  AND (toLower(n.name)                         CONTAINS toLower($q)
    OR toLower(coalesce(n.description, ''))    CONTAINS toLower($q)
    OR toLower(coalesce(n.whenToUse,   ''))    CONTAINS toLower($q)
    OR toLower(coalesce(n.domain,      ''))    CONTAINS toLower($q))
RETURN
  coalesce(n.cardId, n.id) AS id,
  n.name      AS name,
  n.domain    AS domain,
  'Technique' AS type,
  1.0         AS score
ORDER BY n.name
LIMIT 20
`;
