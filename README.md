<div align="center">

```
 ██╗   ██╗ ██████╗██╗  ██╗██████╗
 ██║   ██║██╔════╝██║ ██╔╝██╔══██╗
 ██║   ██║██║     █████╔╝ ██████╔╝
 ██║   ██║██║     ██╔═██╗ ██╔══██╗
 ╚██████╔╝╚██████╗██║  ██╗██████╔╝
  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═════╝
```

# Universal Communication Knowledge Graph

**A structured, safety-annotated knowledge graph of human communication — built for AI agents that need to know not just *what* to say, but *how*, *when*, *why*, and *to whom*.**

[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python&logoColor=white)](https://www.python.org/)
[![Neo4j 5.x](https://img.shields.io/badge/Neo4j-5.x-green?logo=neo4j&logoColor=white)](https://neo4j.com/)
[![Next.js](https://img.shields.io/badge/Frontend-Next.js%2016-black?logo=nextdotjs)](https://nextjs.org/)
[![OWL 2](https://img.shields.io/badge/Ontology-OWL%202-orange)](https://www.w3.org/TR/owl2-overview/)
[![SHACL](https://img.shields.io/badge/Validation-SHACL-purple)](https://www.w3.org/TR/shacl/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Phases](https://img.shields.io/badge/Phases-11%20Complete-brightgreen)](#roadmap)
[![Graph](https://img.shields.io/badge/Graph-876%20nodes%20%7C%201858%20edges-informational)](#graph-statistics)
[![Validation](https://img.shields.io/badge/Validation-80%2F80%20PASS-success)](#validation)

[**Quick Start**](#quick-start) · [**Explorer**](#graph-explorer) · [**Architecture**](#architecture) · [**Domains**](#domains-covered) · [**Roadmap**](#roadmap) · [**Cite**](#citation)

</div>

---

## Graph Explorer

A live interactive graph explorer is included. Run it locally to browse all 876 nodes across 15 domains.

<!-- SCREENSHOT: Replace this block with a screenshot of localhost:3000 -->
> **To add a screenshot:** start the frontend (`cd frontend && npm run dev`), open `http://localhost:3000`, take a screenshot, save it as `docs/graph-preview.png`, then replace this block with:
> `![UCKB Graph Explorer](docs/graph-preview.png)`

### Start the Explorer

```bash
cd frontend
npm install
npm run dev
# Open http://localhost:3000
```

The explorer includes four views:

| Page | URL | What It Shows |
|---|---|---|
| **Graph Explorer** | `/` | Full interactive graph — zoom, click nodes, filter by domain |
| **Learn** | `/learn` | Protocol DAGs — step through BCSM, SPIKES, PEACE etc. |
| **Simulate** | `/simulate` | Run a scenario and see which techniques fire |
| **Retrieve** | `/retrieve` | Test the hybrid retrieval engine live |

**Tech stack:** Next.js 16 · react-force-graph-2d · Tailwind CSS · Neo4j Bolt driver

---

## What Is This?

The **Universal Communication Knowledge Graph (UCKB)** is a curated, evidence-graded knowledge base that maps the landscape of human communication — from crisis de-escalation to cross-cultural negotiation — as a traversable graph.

It answers questions that a general-purpose language model cannot reliably answer at inference time:

| Question | UCKB Answer |
|---|---|
| "What technique should I use when someone is panicking?" | Ranked, domain-scoped results filtered by emotional contraindications |
| "Is active listening safe when the caller is dissociated?" | `CONTRAINDICATED_WHEN` edge check returns BLOCKED |
| "What comes *before* I can use this influence technique?" | Full prerequisite chain traversal via `REQUIRES` edges |
| "How does this technique adapt for a high-context Japanese caller?" | `CulturalAdaptationRule` + `CulturalProfile` edges |
| "What did this agent say three turns ago — does it contradict now?" | D-SMART `ConversationFact` + `ConsistencyConflict` nodes |
| "Find me the most relevant technique using natural language" | 3-leg BM25 + vector + Cypher fusion via weighted RRF |

This is **infrastructure for AI agents**, not a chatbot. It is a knowledge layer that any RAG pipeline, autonomous agent, or real-time assistant can query to make communication decisions that are safe, contextually appropriate, evidence-based, and culturally aware.

**Primary use case:** A real-time AI co-pilot for audio calls — an agent that listens to a live conversation, detects signals from speech, and retrieves the right communication technique in under 200ms.

---

## Why It Matters

### The Problem

AI language models have absorbed enormous amounts of text about communication. But text absorption is not the same as structured knowledge about *when* a technique is appropriate, *what prerequisites must be met*, *which techniques are absolute contraindications*, and *how a technique must be adapted for a specific cultural context*.

This leads to AI agents that:
- Use sales techniques in a crisis call
- Apply interrogation tactics in a clinical interview
- Recommend culturally inappropriate approaches
- Contradict themselves across a multi-turn conversation
- Have no way to verify that a technique's prerequisites have been satisfied

### The Solution

UCKB gives every AI agent access to:

1. **Hard safety gates** — techniques with `activationBlocked=true` can never be returned
2. **Prerequisite chains** — influence techniques cannot fire until emotional prerequisites are satisfied
3. **Domain contamination guards** — sales techniques cannot bleed into a crisis domain
4. **Cross-cultural adaptation** — the same technique is delivered differently across 10 cultural profiles
5. **Protocol DAGs** — 9 professional protocols as directed graphs with gate conditions
6. **Temporal memory** — every session tracked; technique effectiveness decays over time
7. **Multi-turn consistency** — contradictions, goal drift, and protocol deviations detected
8. **Hybrid retrieval** — BM25 + dense vector + Cypher graph traversal, fused via RRF

---

## Graph Statistics

```
ACCURATE NODE COUNT (live Neo4j, June 2026)
────────────────────────────────────────────────────────────
Business nodes visible in graph:     876
Business edges between them:        1,858
Domains:                              15
Text2Cypher templates:                35
────────────────────────────────────────────────────────────

NODE TYPES (selected)
Technique               280   Communication techniques, evidence-graded
SignalMarker             83   Observable cues — vocal, linguistic, kinesic, behavioral
EmotionalState           61   Emotional states with contraindication edges
DomainProtocol           41   Structured protocol sequences
DialogueAct              35   ISO 24617-2 communicative function types
ProtocolStep             38   Steps within protocol DAGs
ProtocolGate             18   Gate conditions between protocol steps
ConversationFact         18   D-SMART atomic session facts
CulturalProfile          10   National/regional communication profiles
PsychologicalModel       17   Theoretical grounding (TA, BKT, FACS, NVC…)
EgoState                  4   Transactional Analysis states
...and 20+ more types
────────────────────────────────────────────────────────────

RELATIONSHIP TYPES (top)
TRIGGERS              656   Signal/emotion/DA → technique
DOMAIN_VARIANT_OF     316   Cross-domain technique variants
REQUIRES              229   Prerequisite chains
CONTRAINDICATED_WHEN  218   Safety: technique blocked by emotional state
PRECEDES              125   Protocol step ordering
ENHANCES              100   Technique synergy pairs
BELONGS_TO_MODEL       83   Node → theoretical model
HAS_DIMENSION          65   Cultural profile dimensions
...and 25+ more types
────────────────────────────────────────────────────────────
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                   UCKB System Architecture                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   OWL 2 Ontology (26 TTL files)  +  SHACL Shapes (9 files)      │
│                       │                                          │
│              ┌────────▼────────┐                                 │
│              │   Neo4j 5.x     │  876 nodes · 1858 edges         │
│              │   Graph DB      │  15 domains · 35 templates      │
│              └────────┬────────┘                                 │
│                       │                                          │
│       ┌───────────────┼────────────────┐                         │
│       │               │                │                         │
│  ┌────▼────┐    ┌──────▼──────┐  ┌─────▼──────┐                 │
│  │  BM25   │    │   Vector    │  │   Cypher   │                 │
│  │ Lucene  │    │ 384-dim cos │  │  35 tmpl   │                 │
│  └────┬────┘    └──────┬──────┘  └─────┬──────┘                 │
│       └───────────────┼────────────────┘                         │
│                       │                                          │
│              ┌────────▼────────┐                                 │
│              │  Weighted RRF   │  k=60, per-domain weights       │
│              └────────┬────────┘                                 │
│                       │                                          │
│              ┌────────▼────────┐                                 │
│              │  Safety Filter  │  blocked set + domain guard     │
│              └────────┬────────┘                                 │
│                       │                                          │
│              ┌────────▼────────┐                                 │
│              │  HybridResult   │  top-K, safe, domain-scoped     │
│              └─────────────────┘                                 │
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐   │
│   │              Next.js 16 Frontend (localhost:3000)         │   │
│   │   Explorer · Learn · Simulate · Retrieve                 │   │
│   └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology |
|---|---|
| Graph Database | Neo4j 5.x + APOC + n10s (neosemantics) |
| Ontology | OWL 2 (Turtle format) |
| Shape Validation | SHACL |
| Embedding Model | sentence-transformers/all-MiniLM-L6-v2 (384-dim) |
| Full-text Search | BM25 Lucene (built-in Neo4j) |
| Fusion Algorithm | Weighted Reciprocal Rank Fusion (k=60) |
| Frontend | Next.js 16 · react-force-graph-2d · Tailwind CSS |
| Python | 3.10+ · rdflib · neo4j driver |

---

## Domains Covered

| Domain | Techniques | Protocol | Key Frameworks |
|---|---|---|---|
| **Crisis Dispatch & Emergency** | 72+ | BCSM (6-step) | Behavioural Change Stairway Model, CIT, Verbal Judo |
| **Clinical & Medical** | 66+ | SPIKES (6-step) | SPIKES breaking-bad-news, Motivational Interviewing, Teach-Back |
| **Sales & Negotiation** | 60+ | SPIN, ChallengerSale, Harvard | SPIN Selling, Challenger Sale, Harvard Negotiation, Never Split the Difference |
| **Legal & Investigative** | 40+ | PEACE (5-step) | PEACE interviewing, FBI Statement Analysis (8 markers), Cognitive Interview |
| **Corporate & Engineering** | 46+ | SBI, NVC, Radical Candor | Situation-Behavior-Impact, Nonviolent Communication, Karpman Drama Triangle |
| **Education** | 40+ | CoachIDL, BKT | Bayesian Knowledge Tracing, Socratic Questioning, Scaffolded Hints (3-tier) |

### Safety Annotations

- **218 CONTRAINDICATED_WHEN edges** — technique–emotion pairs that are unsafe
- **1 ABSOLUTE contraindication** — Reid Interrogation Technique (`activationBlocked=true`) — never returned by any query
- **15 DomainBoundary nodes** — cross-domain contamination guards (Sales→Crisis = BLOCK_ALL)
- **Prerequisite chain enforcement** — influence techniques require empathy/rapport prerequisites

---

## Phase-by-Phase Breakdown

<details>
<summary><strong>Phase 1 — Epistemological & Linguistic Foundations (Doctrine)</strong></summary>

Established the communication doctrine governing all subsequent phases:
- Influence vs. empathy distinction — all influence techniques require empathy prerequisite
- Cognitive Load theory (Sweller 1988) — technique complexity tiers
- Relevance Theory (Sperber & Wilson 1986) — cognitive effort scoring
- Communication Accommodation Theory (Giles 1973)
- Evidence hierarchy: RCT → systematic review → case study → expert opinion
</details>

<details>
<summary><strong>Phase 2 — Master Taxonomy</strong></summary>

Classification of 400+ communication techniques across 6 domains, 3 communication styles, cognitive load profiles, and evidence level grades. `outputs/phase2_uckb/`
</details>

<details>
<summary><strong>Phase 3 — OWL 2 Ontology</strong></summary>

Full OWL 2 ontology in Turtle format — 5 core modules + 3 domain modules + SHACL shapes. `outputs/phase3_uckb/uckb-ontology/`
</details>

<details>
<summary><strong>Phase 4 — Neo4j Graph Database</strong></summary>

Ingested ontology into Neo4j via n10s. 504 content nodes, 12 Text2Cypher templates (Q1–Q12), Docker Compose setup, safety gate system. **10/10 ACs PASS** · `outputs/phase4_uckb/`
</details>

<details>
<summary><strong>Phase 5 — Dialogue Acts (ISO 24617-2)</strong></summary>

35 DialogueAct nodes across 6 dimensions, 15 DomainSlot nodes (DST schema), BDI query templates, 100% DialogueAct → Technique linkage. **8/8 ACs PASS** · `outputs/phase5_uckb/`
</details>

<details>
<summary><strong>Phase 6 — Psychological & Multimodal Layer</strong></summary>

4 EgoState nodes (Transactional Analysis), 6 FACS mappings, 6 ProsodicFeature nodes, 4 BehavioralAdaptor types, Mehrabian 7-38-55 modality weights, 26 Signal→EgoState mappings. **8/8 ACs PASS** · `outputs/phase6_uckb/`
</details>

<details>
<summary><strong>Phase 7 — Cross-Cultural Adaptation</strong></summary>

10 CulturalProfiles (USA, UK, Germany, Japan, China, India, Arab World, Latin America, Nordic, East Africa), 10 CulturalAdaptationRules, 7 BehavioralStyleProfiles, 58 ADAPTS_FOR technique–culture edges. **8/8 ACs PASS** · `outputs/phase7_uckb/`
</details>

<details>
<summary><strong>Phase 8 — Domain Sub-Graphs & Protocol DAGs</strong></summary>

Legal & Investigative (40 nodes), Corporate & Engineering (46 nodes), Education (40 nodes). 9 Protocol DAGs as JSON + Cypher: BCSM, SPIKES, SPIN, ChallengerSale, HarvardNegotiation, PEACE, SBI, NVC, CoachIDL. 6 SchemaFilterRegistry nodes, 15 DomainBoundary guards. **16/16 ACs PASS** · `outputs/phase8_uckb/`
</details>

<details>
<summary><strong>Phase 9 — Temporal Memory (Graphiti-inspired)</strong></summary>

Session, Turn, TemporalFact, WorkingMemorySlot, EpisodicMemory, MemoryTrace nodes. Exponential decay per domain (crisis λ=0.08/hr, clinical λ=0.04/hr, corporate λ=0.02/hr). **10/10 ACs PASS** · `outputs/phase9_uckb/`
</details>

<details>
<summary><strong>Phase 10 — D-SMART Multi-Turn Consistency Engine</strong></summary>

ConversationFact, GoalState, ProtocolTracker, ConsistencyConflict, ReasoningCandidate, ConsistencyReport nodes. Composite score: `0.5×nliScore + 0.3×goalAlignment + 0.2×(1 − protocolDeviation)`. **10/10 ACs PASS** · `outputs/phase10_uckb/`
</details>

<details>
<summary><strong>Phase 11 — Real-Time Hybrid Retrieval Engine</strong></summary>

3-leg retrieval with weighted RRF: BM25 (Lucene) + Vector (384-dim cosine) + Cypher (graph traversal). 6 FusionConfig nodes with per-domain leg weights. Safety filter applied before and after fusion. `rrfScore = Σᵢ wᵢ / (60 + rankᵢ)`. **10/10 ACs PASS** · `outputs/phase11_uckb/`
</details>

---

## Hybrid Retrieval Engine

Phase 11 introduced a 3-leg retrieval engine with **Weighted Reciprocal Rank Fusion (RRF)**:

```
Query Text + Domain + CypherParams
        │
        ├──► BM25 Leg       Full-text search (name, steps, whenToUse, signals)
        ├──► Vector Leg     Semantic similarity (384-dim embeddings)
        └──► Cypher Leg     Graph traversal (protocol/emotion/domain/safety)
                                     │
                          Weighted RRF: score = Σ wᵢ / (60 + rankᵢ)
                                     │
                          Safety Filter (blocked set + domain boundary)
                                     │
                          Top-K results, safetyValidated=true
```

### Per-Domain Leg Weights

| Domain | BM25 | Vector | Cypher | Rationale |
|---|---|---|---|---|
| crisis dispatch | 0.15 | 0.25 | **0.60** | Safety graph structure must dominate |
| clinical | 0.20 | 0.30 | **0.50** | Protocol gates critical |
| negotiation | 0.30 | **0.40** | 0.30 | Semantic intent most important |
| legal | **0.40** | 0.25 | 0.35 | Lexical precision for statement analysis markers |
| corporate | 0.25 | 0.35 | 0.40 | Balanced |
| education | 0.20 | **0.40** | 0.40 | Pedagogical semantic intent |

---

## Quick Start

### Prerequisites

- Python 3.10+
- Docker (recommended) or Neo4j 5.x Desktop
- Node.js 18+ (for the frontend)

### 1 — Clone

```bash
git clone https://github.com/qasim-hafeez00/universal-communication-kg.git
cd universal-communication-kg
```

### 2 — Start Neo4j

```bash
cd outputs/phase4_uckb/docker
docker-compose up -d
# Neo4j Browser: http://localhost:7474
# Bolt: bolt://localhost:7687
# Credentials: neo4j / uckb_admin_2024
```

### 3 — Ingest All Phases

```bash
pip install neo4j rdflib
python scripts/ingest_all_phases.py
```

### 4 — Start the Frontend

```bash
cd frontend
npm install
npm run dev
# Open http://localhost:3000
```

### 5 — Try the Hybrid Retriever

```python
from outputs.phase11_uckb.scripts.hybrid_retriever import HybridRetriever

retriever = HybridRetriever(domain='dispatch')
results = retriever.retrieve("caller panicking, mentions weapon, refuses to cooperate")

for r in results:
    print(r)
# [1] Minimal Encouragers     (rrf=0.016, bm25_r=1, vec_r=2, cyp_r=1)
# [2] Active Listening        (rrf=0.015, ...)
# [3] Emotional Labeling      (rrf=0.015, ...)
```

---

## Usage Examples

### Technique Lookup by Emotional State

```cypher
MATCH (e:EmotionalState)
WHERE toLower(e.name) = 'panic'
MATCH (t:Technique)
WHERE t.domain CONTAINS 'Crisis'
  AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
  AND NOT t.activationBlocked = true
RETURN t.name AS technique, t.evidenceLevel AS evidence
ORDER BY t.evidenceLevel DESC
LIMIT 5
```

### Protocol Step Navigation

```cypher
MATCH (proto:ProtocolDAG {id: 'bcsm_dag'})
MATCH (step:ProtocolStep)-[:PART_OF]->(proto)
RETURN step.stepNumber AS step, step.name AS name, step.gateCondition AS gate
ORDER BY step.stepNumber ASC
```

### Safety Gate Check

```cypher
MATCH (t:Technique {cardId: $techniqueId})
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
WITH t, collect(prereq.cardId) AS required
RETURN t.name,
  CASE WHEN size([p IN required WHERE NOT p IN $completed]) > 0
       THEN 'BLOCKED' ELSE 'CLEARED' END AS gate_status
```

### Cultural Adaptation

```cypher
MATCH (t:Technique) WHERE toLower(t.name) = 'active listening'
MATCH (t)-[:ADAPTS_FOR]->(ctx:CulturalContext)
MATCH (p:CulturalProfile {name: 'Japan'})-[:HAS_DIMENSION]->(ctx)
MATCH (p)-[:APPLIES_RULE]->(rule:CulturalAdaptationRule)
RETURN collect(DISTINCT rule.name) AS rules_for_japan
```

---

## Validation

Every phase ships with a validation script. All 80 acceptance criteria pass.

```bash
python outputs/phase11_uckb/scripts/validate_phase11.py --neo4j
# ALL PASS 10/10
```

| Phase | ACs | Status |
|---|---|---|
| Phase 4 — Core Graph | 10/10 | ✅ ALL PASS |
| Phase 5 — Dialogue Acts | 8/8 | ✅ ALL PASS |
| Phase 6 — Psychological | 8/8 | ✅ ALL PASS |
| Phase 7 — Cultural | 8/8 | ✅ ALL PASS |
| Phase 8 — Domain Sub-Graphs | 16/16 | ✅ ALL PASS |
| Phase 9 — Temporal Memory | 10/10 | ✅ ALL PASS |
| Phase 10 — D-SMART | 10/10 | ✅ ALL PASS |
| Phase 11 — Hybrid Retrieval | 10/10 | ✅ ALL PASS |
| **Total** | **80/80** | **✅ ALL PASS** |

---

## Research Direction

The next phase of work focuses on **accuracy validation** toward a publishable research contribution.

**The claim we are building toward:**
> A structured communication knowledge graph with signal-to-technique chains, domain-scoped retrieval, and safety constraints retrieves contextually appropriate communication techniques more precisely than an unstructured LLM prompted with the same knowledge — in real-time communication assistance tasks.

**Planned work:**
- Expert-reviewed `whenToUse` specifications for all 280 techniques (linguist-led)
- Signal marker audit against existing annotated dialogue datasets (AnnoMI, ESConv, IEMOCAP)
- 100-scenario evaluation set with ground-truth technique labels
- Baseline comparison: graph retrieval vs. GPT-4 with no graph vs. GPT-4 with all techniques in context
- Target venue: **SIGDIAL** (Dialogue Systems and Discourse Modelling)

---

## Project Structure

```
universal-communication-kg/
│
├── README.md
├── requirements.txt
│
├── frontend/                   # Next.js 16 interactive graph explorer
│   ├── app/                    # Pages: /, /learn, /simulate, /retrieve
│   ├── app/api/                # API routes → Neo4j
│   └── lib/                    # queries.ts, domain-colors.ts
│
├── outputs/
│   ├── phase3_uckb/            # OWL 2 ontology (26 TTL files)
│   ├── phase4_uckb/            # Core Neo4j graph + Docker + Cypher scripts
│   ├── phase5_uckb/            # Dialogue Acts (ISO 24617-2)
│   ├── phase6_uckb/            # Psychological + multimodal layer
│   ├── phase7_uckb/            # Cross-cultural adaptation
│   ├── phase8_uckb/            # Domain sub-graphs + 9 Protocol DAGs
│   ├── phase9_uckb/            # Temporal memory
│   ├── phase10_uckb/           # D-SMART consistency engine
│   └── phase11_uckb/           # Hybrid retrieval (BM25+Vector+Cypher)
│
├── scripts/                    # Phase builders
└── protocol_dags/              # Consolidated DAG JSON files
```

---

## Roadmap

### Complete ✅ (Phases 1–11)
All phases listed above — ontology, graph, dialogue acts, psychological layer, cultural adaptation, domain sub-graphs, protocol DAGs, temporal memory, consistency engine, hybrid retrieval, Next.js frontend.

### In Progress
| Phase | Title | Deliverables |
|---|---|---|
| **Phase 12** | Accuracy Validation | Signal audit, `whenToUse` rewrite, 100-scenario eval set, baseline benchmarks |
| **Phase 13** | Python Package + REST API | `pip install uckb` · FastAPI · OpenAPI spec |
| **Phase 14** | Agent SDK Integration | LangChain tool · LlamaIndex retriever · OpenAI/Claude tool use |
| **Phase 15** | Real-Time Signal Processing | Live audio → SignalMarker → UCKB pipeline · WebSocket API |

---

## Contributing

Contributions must be evidence-grounded — every new `Technique` node requires `evidenceLevel`, `domain`, `whenToUse`, `steps`, and a source reference.

1. Fork the repository
2. Follow the phase structure — new content = new phase with Cypher scripts, OWL module, SHACL shapes, validation suite
3. All ACs must pass before submitting a PR
4. No technique may be added without checking the Phase 1 doctrine (influence → empathy prerequisite)

---

## Citation

```bibtex
@software{uckb2026,
  title   = {Universal Communication Knowledge Graph (UCKB)},
  author  = {Hafeez, Qasim},
  year    = {2026},
  url     = {https://github.com/qasim-hafeez00/universal-communication-kg},
  note    = {876 nodes · 1858 edges · 11 phases · 6 domains ·
             BM25+Vector+Cypher hybrid retrieval with weighted RRF},
  version = {0.11.0}
}
```

---

## Acknowledgements

| Framework | Authors | Year |
|---|---|---|
| Behavioural Change Stairway Model (BCSM) | Vecchi, FBI | 1988 |
| SPIKES Breaking-Bad-News Protocol | Baile et al. | 2000 |
| SPIN Selling | Neil Rackham | 1988 |
| Harvard Principled Negotiation | Fisher, Ury & Patton | 1981 |
| PEACE Investigative Interviewing | Clarke & Milne (ACPO) | 1999 |
| FBI Statement Analysis (8 markers) | Adams | 1996 |
| Nonviolent Communication (NVC) | Marshall B. Rosenberg | 2003 |
| Karpman Drama Triangle | Stephen Karpman | 1968 |
| Bayesian Knowledge Tracing (BKT) | Corbett & Anderson | 1994 |
| ISO 24617-2 Dialogue Acts | ISO | 2012 |
| Hofstede Cultural Dimensions | Geert Hofstede | 1980 |
| Transactional Analysis (TA) | Eric Berne | 1964 |
| FACS | Ekman & Friesen | 1978 |
| Relevance Theory | Sperber & Wilson | 1986 |
| Reciprocal Rank Fusion | Cormack, Clarke & Buettcher | 2009 |
| Graphiti temporal memory | Zep AI | 2024 |

---

## License

MIT — see [LICENSE](LICENSE). Open-source, free for research, education, and commercial use.

---

<div align="center">

**Built for AI agents that need to communicate with humans — safely, appropriately, and effectively.**

[⭐ Star this repo](https://github.com/qasim-hafeez00/universal-communication-kg) · [🐛 Report an issue](https://github.com/qasim-hafeez00/universal-communication-kg/issues) · [💡 Discussions](https://github.com/qasim-hafeez00/universal-communication-kg/discussions)

</div>
