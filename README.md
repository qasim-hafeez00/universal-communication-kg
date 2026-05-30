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

**The world's first structured, safety-annotated knowledge graph of human communication — built for AI agents that need to know not just *what* to say, but *how*, *when*, *why*, and *to whom*.**

[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python&logoColor=white)](https://www.python.org/)
[![Neo4j 5.11+](https://img.shields.io/badge/Neo4j-5.11%2B-green?logo=neo4j&logoColor=white)](https://neo4j.com/)
[![OWL 2](https://img.shields.io/badge/Ontology-OWL%202-orange)](https://www.w3.org/TR/owl2-overview/)
[![SHACL](https://img.shields.io/badge/Validation-SHACL-purple)](https://www.w3.org/TR/shacl/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Phases](https://img.shields.io/badge/Phases-11%20%2F%2014-brightgreen)](#roadmap)
[![Nodes](https://img.shields.io/badge/Graph-1141%20nodes%20%7C%204900%2B%20edges-informational)](#graph-statistics)
[![All Tests Pass](https://img.shields.io/badge/Validation-ALL%20PASS%20(11%20phases)-success)](#validation)

[**Quick Start**](#quick-start) · [**Architecture**](#architecture) · [**Domains**](#domains-covered) · [**Roadmap**](#roadmap) · [**Contributing**](#contributing) · [**Cite**](#citation)

</div>

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why It Matters](#why-it-matters)
- [What We Have Built](#what-we-have-built)
- [Graph Statistics](#graph-statistics)
- [Architecture](#architecture)
- [Domains Covered](#domains-covered)
- [Phase-by-Phase Breakdown](#phase-by-phase-breakdown)
- [Safety Design](#safety-design)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Running the Graph](#running-the-graph)
- [Usage Examples](#usage-examples)
- [Hybrid Retrieval Engine](#hybrid-retrieval-engine)
- [Querying with Cypher](#querying-with-cypher)
- [Ontology and SHACL](#ontology-and-shacl)
- [Validation](#validation)
- [Use Cases](#use-cases)
- [Project Structure](#project-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Citation](#citation)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## What Is This?

The **Universal Communication Knowledge Graph (UCKB)** is a curated, evidence-graded knowledge base that maps the entire landscape of human communication — from crisis de-escalation to cross-cultural negotiation — as a traversable graph.

It answers questions that no LLM weight alone can reliably answer at inference time:

| Question | UCKB Answer |
|---|---|
| "What technique should I use when someone is panicking?" | Ranked, domain-scoped results filtered by emotional contraindications |
| "Is active listening safe to use when the caller is dissociated?" | `CONTRAINDICATED_WHEN` edge check returns BLOCKED |
| "What comes *before* I can use this influence technique?" | Full prerequisite chain traversal via `REQUIRES` and `PRECEDES` edges |
| "How does this technique adapt for a high-context Japanese caller?" | `CulturalAdaptationRule` + `CulturalProfile` edges |
| "What did this AI agent say three turns ago and does it contradict what it just said?" | D-SMART `ConversationFact` + `ConsistencyConflict` nodes |
| "Find me the most relevant technique using natural language" | 3-leg BM25 + vector + Cypher fusion via weighted RRF |

This is **infrastructure for AI agents**, not a chatbot. It is a knowledge layer that any AI system — RAG pipeline, autonomous agent, real-time assistant — can query to make communication decisions that are **safe, contextually appropriate, evidence-based, and culturally aware**.

---

## Why It Matters

### The Problem

AI language models have absorbed enormous amounts of text about communication. But text absorption is not the same as structured knowledge about *when* a technique is appropriate, *what prerequisites must be met*, *which techniques are absolute contraindications*, and *how a technique must be adapted for a specific cultural or domain context*.

This results in AI agents that:
- Use manipulative sales techniques in a crisis call
- Apply interrogation tactics in a clinical interview
- Recommend culturally inappropriate gestures
- Contradict themselves across a multi-turn conversation
- Have no way to verify that a technique's prerequisites have been satisfied

### The Solution

UCKB gives every AI agent access to:

1. **Hard safety gates** — techniques with `activationBlocked=true` (e.g. the Reid Interrogation Technique) can never be returned regardless of query
2. **Prerequisite chains** — an influence technique cannot be suggested until its emotional-prerequisite chain is satisfied
3. **Domain contamination guards** — a sales technique cannot bleed into a crisis dispatch domain
4. **Cross-cultural adaptation rules** — the same technique is delivered differently across 10 cultural profiles
5. **Protocol DAGs** — 9 clinical/legal/sales protocols are represented as directed acyclic graphs with gate conditions
6. **Temporal memory** — every session is tracked; technique effectiveness decays over time via exponential decay
7. **Multi-turn consistency** — a D-SMART engine detects contradictions, goal drift, and protocol deviations across a conversation
8. **Hybrid retrieval** — BM25 lexical + dense vector semantic + Cypher graph traversal, fused via Reciprocal Rank Fusion

### Who Built It

This project was built as part of an AI communication systems research initiative. Every node and edge is grounded in peer-reviewed communication science, cognitive psychology, and clinical/legal practice literature.

---

## What We Have Built

```
11 phases of structured knowledge, all validated, all ready for Neo4j ingestion.
```

| Layer | What It Contains |
|---|---|
| **Techniques** | 379 communication techniques across 6 domains, evidence-graded |
| **Protocols** | 9 Protocol DAGs (BCSM, SPIKES, SPIN, Harvard, PEACE, SBI, NVC, Radical Candor, CoachIDL) |
| **Signals** | 99 SignalMarkers (vocal, linguistic, nonverbal, behavioural) |
| **Emotions** | 61 EmotionalState nodes with contraindication edges |
| **Dialogue Acts** | 35 ISO 24617-2 compliant DialogueActs across 6 dimensions |
| **Cultural Profiles** | 10 national/regional CulturalProfiles + 10 adaptation rules |
| **Psychological Models** | Transactional Analysis (4 EgoStates), FACS (6 mappings), prosodic features |
| **Temporal Memory** | Session/Turn/EpisodicMemory/MemoryTrace with exponential decay |
| **Consistency Engine** | D-SMART: ConversationFact, GoalState, ProtocolTracker, ConsistencyConflict |
| **Retrieval Engine** | HybridQuery with BM25 + vector + Cypher legs fused via weighted RRF |
| **Ontology** | OWL 2 ontology in Turtle + JSON-LD, validated by SHACL shapes |

**Total: 1,141 nodes · 4,900+ relationships · 35 Text2Cypher templates · 11 OWL ontology modules · 9 SHACL shape files**

---

## Graph Statistics

```
NODE TYPE               COUNT   DESCRIPTION
────────────────────────────────────────────────────────────────────
Technique               379     Communication techniques, evidence-graded
Resource                168     Track A academic/clinical sources
SignalMarker             99     Observable cues triggering techniques
DomainProtocol           64     Structured protocol sequences
EmotionalState           61     Emotional states with safety annotations
ProtocolStep             38     Individual steps within protocol DAGs
DialogueAct              35     ISO 24617-2 communicative function types
CulturalContext          19     Hofstede/Lewis cultural dimension nodes
CommunicationStyle       19     DISC-style communication style profiles
ProtocolGate             18     Gate conditions between protocol steps
RetrievalLeg             18     Hybrid retrieval single-leg results
PsychologicalModel       17     Theoretical models (TA, BKT, NVC...)
Text2CypherTemplate      17     Production Cypher query templates
DomainSlot               15     DST slot definitions per domain
DomainBoundary           15     Cross-domain contamination guards
WorkingMemorySlot        12     Live session context with TTL
MemoryTrace              11     Cross-session technique effectiveness
Turn                     11     Single dialogue exchange with emotion
...and 20+ more node types
────────────────────────────────────────────────────────────────────
TOTAL                  1141
```

```
RELATIONSHIP TYPE         COUNT   DESCRIPTION
────────────────────────────────────────────────────────────────────
TRIGGERS                 1270    Signal/emotion/DA triggers technique
DOMAIN_VARIANT_OF         565    Cross-domain technique variants
ESCALATES_TO              421    Fallback/escalation chains
CONTRAINDICATED_WHEN      358    Safety: technique blocked by state
REQUIRES                  350    Prerequisite chain
PRECEDES                  203    Protocol step ordering
ENHANCES                  182    Synergy relationships
ADAPTS_FOR                 58    Cultural adaptation edges
HAS_DIMENSION              65    Cultural profile dimensions
...and 30+ more relationship types
────────────────────────────────────────────────────────────────────
TOTAL                   4900+
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    UCKB Architecture (Phase 11)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────────────┐   │
│  │  OWL 2      │   │  SHACL      │   │   Domain Ontologies     │   │
│  │  Ontology   │   │  Shapes     │   │   (11 TTL/JSON-LD files)│   │
│  └──────┬──────┘   └──────┬──────┘   └──────────┬──────────────┘   │
│         │                 │                     │                   │
│         └─────────────────┴─────────────────────┘                  │
│                           │                                         │
│                    ┌──────▼──────┐                                  │
│                    │  Neo4j 5.11+│                                  │
│                    │  Graph DB   │                                  │
│                    │  1141 nodes │                                  │
│                    │  4900+ edges│                                  │
│                    └──────┬──────┘                                  │
│                           │                                         │
│         ┌─────────────────┼─────────────────────┐                  │
│         │                 │                     │                   │
│  ┌──────▼──────┐  ┌───────▼──────┐  ┌──────────▼─────────┐         │
│  │  BM25       │  │  Vector      │  │  Cypher            │         │
│  │  Full-text  │  │  Index       │  │  Graph Traversal   │         │
│  │  (Lucene)   │  │  384-dim     │  │  35 Templates      │         │
│  └──────┬──────┘  └───────┬──────┘  └──────────┬─────────┘         │
│         │                 │                     │                   │
│         └─────────────────┴─────────────────────┘                  │
│                           │                                         │
│                  ┌────────▼────────┐                                │
│                  │ Weighted RRF    │                                │
│                  │ Fusion Engine   │                                │
│                  │ k=60, per-domain│                                │
│                  │ leg weights     │                                │
│                  └────────┬────────┘                                │
│                           │                                         │
│                  ┌────────▼────────┐                                │
│                  │ Safety Filter   │                                │
│                  │ SchemaFilter    │                                │
│                  │ Registry        │                                │
│                  └────────┬────────┘                                │
│                           │                                         │
│                  ┌────────▼────────┐                                │
│                  │ HybridResult    │                                │
│                  │ (top-K, safe,   │                                │
│                  │ domain-scoped)  │                                │
│                  └─────────────────┘                                │
└─────────────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Version |
|---|---|---|
| Graph Database | Neo4j | 5.11+ |
| Ontology Language | OWL 2 (Turtle + JSON-LD) | W3C 2012 |
| Shape Validation | SHACL | W3C 2017 |
| Graph Import | n10s (neosemantics) | 5.26.0 |
| Python | CPython | 3.10+ |
| Ontology Library | rdflib | 7.x |
| Embedding Model | sentence-transformers/all-MiniLM-L6-v2 | HuggingFace |
| Full-text Search | Lucene (built-in Neo4j) | BM25 |
| Vector Index | Neo4j Vector Index | cosine, 384-dim |
| Fusion Algorithm | Weighted Reciprocal Rank Fusion | k=60 |
| APOC | Neo4j APOC plugin | 5.x |

---

## Domains Covered

| Domain | Techniques | Protocols | Key Frameworks |
|---|---|---|---|
| **Crisis Dispatch & Emergency** | 72+ | BCSM (6-step) | Behavioural Change Stairway Model, CIT, Verbal Judo |
| **Clinical & Medical** | 66+ | SPIKES (6-step), MI | SPIKES breaking-bad-news, Motivational Interviewing, Teach-Back |
| **Sales & Negotiation** | 60+ | SPIN, ChallengerSale, Harvard | SPIN Selling, Challenger Sale, Harvard Principled Negotiation, Never Split the Difference |
| **Legal & Investigative** | 40+ | PEACE (5-step) | PEACE interviewing, FBI Statement Analysis (8 markers), Cognitive Interview |
| **Corporate & Engineering** | 46+ | SBI, NVC, RadicalCandor | Situation-Behavior-Impact, Nonviolent Communication, Radical Candor, Karpman Drama Triangle |
| **Education** | 40+ | CoachIDL, BKT | Bayesian Knowledge Tracing, Socratic Questioning, Scaffolded Hints (3-tier), CoachIDL acts |

### Safety Annotations Across All Domains

- **379 techniques** with evidence grades (`high` / `medium` / `low`)
- **358 CONTRAINDICATED_WHEN edges** — technique–emotion pairs that are unsafe
- **1 ABSOLUTE contraindication** — Reid Interrogation Technique (`activationBlocked=true`, `contraindication=ABSOLUTE`)
- **46 influence-tagged techniques** — require emotional-prerequisite clearance before activation
- **15 DomainBoundary nodes** — cross-domain contamination guards (e.g. Sales→Crisis = BLOCK_ALL)

---

## Phase-by-Phase Breakdown

<details>
<summary><strong>Phase 1 — Epistemological & Linguistic Foundations</strong></summary>

Established the **communication doctrine** that governs all subsequent phases:
- Influence vs. empathy distinction (all influence techniques require empathy prerequisite)
- Cognitive Load theory (Sweller 1988) — technique complexity tiers
- Relevance Theory (Sperber & Wilson 1986) — cognitive effort scoring
- Communication Accommodation Theory (Giles 1973) — `catDirection` property
- Evidence hierarchy (RCT > systematic review > case study > expert opinion)

All doctrine principles are encoded as constraints that are validated in every phase.
</details>

<details>
<summary><strong>Phase 2 — Master Taxonomy</strong></summary>

Produced the UCKB Master Taxonomy spreadsheet (`outputs/phase2_uckb/`) classifying 400+ communication techniques across:
- 6 primary domains
- 3 communication styles (empathic, directive, neutral)
- Cognitive load profiles (lowest-load through highest-load)
- Evidence level grades
</details>

<details>
<summary><strong>Phase 3 — OWL 2 Ontology</strong></summary>

Full OWL 2 ontology in Turtle format covering:
- `CommunicationAct`, `Technique`, `EmotionalState`, `SignalMarker`, `CulturalContext`, `CommunicationStyle`
- 3 domain-specific ontology modules: Crisis Dispatch, Clinical, Sales & Negotiation
- SHACL shapes for constraint validation
- Mappings between domain concepts and the core ontology

Output: `outputs/phase3_uckb/uckb-ontology/`
</details>

<details>
<summary><strong>Phase 4 — Neo4j Graph Database</strong></summary>

Ingested the full ontology into Neo4j via neosemantics (n10s):
- **504 content nodes** across Crisis, Clinical, Sales domains
- **3,337 relationships** in 11 locked relationship types
- 12 production Text2Cypher templates (Q1–Q12)
- Docker Compose configuration for self-hosted Neo4j
- Safety gate system: prerequisite chain validation, contraindication filter

**ALL PASS 10/10 ACs** · `outputs/phase4_uckb/`
</details>

<details>
<summary><strong>Phase 5 — Dialogue Acts (ISO 24617-2)</strong></summary>

Added the ISO 24617-2 Dialogue Act taxonomy:
- **35 DialogueAct** communicative function types
- **6 DialogueDimension** categories (Task, SocialObligations, Feedback, TurnTaking, OwnComm, PartnerComm)
- **100% linkage** — every DialogueAct triggers at least one Technique
- Dialogue State Tracking (DST) schema with **15 DomainSlot** nodes
- BDI (Belief-Desire-Intention) query templates

**ALL PASS 8/8 ACs** · `outputs/phase5_uckb/`
</details>

<details>
<summary><strong>Phase 6 — Psychological & Multimodal Layer</strong></summary>

Added nonverbal and psychological signal processing:
- **4 EgoState nodes** (Transactional Analysis: Adult, Nurturing Parent, Critical Parent, Adapted Child)
- **6 FACS (Facial Action Coding System)** macro-expression mappings
- **6 ProsodicFeature** nodes (speech rate, pitch, energy, pause duration, filler frequency, voice quality)
- **4 BehavioralAdaptor** types (self, object, illustrator, emblem)
- Mehrabian 7-38-55 modality weight chain
- **26 SignalMarker→EgoState** mappings

**ALL PASS 8/8 ACs** · `outputs/phase6_uckb/`
</details>

<details>
<summary><strong>Phase 7 — Cross-Cultural Adaptation</strong></summary>

Added the cultural adaptation layer based on Hofstede, Lewis, and Hall:
- **10 CulturalProfiles** (USA, UK, Germany, Japan, China, India, Arab World, Latin America, Nordic, East Africa)
- **10 CulturalAdaptationRules** (Silence-as-Respect, Emblem-Gesture-Disambiguation, Gaze-Aversion-Recalibration, etc.)
- **7 BehavioralStyleProfiles** (Aggressive, Passive, Assertive, Analytical, Diplomatic, Charismatic, Passive-Aggressive)
- **58 ADAPTS_FOR** technique–culture edges
- **80 STYLE_SUGGESTS** behavioral style→technique edges

**ALL PASS 8/8 ACs** · `outputs/phase7_uckb/`
</details>

<details>
<summary><strong>Phase 8 — Domain Sub-Graphs & Protocol DAGs</strong></summary>

Added the 3 missing professional domains and formalised all 9 protocol DAGs:
- **Legal & Investigative** (40 nodes): PEACE framework, FBI Statement Analysis 8-marker system, Reid Technique (ABSOLUTE block)
- **Corporate & Engineering** (46 nodes): SBI, NVC, Radical Candor, Karpman Drama→Winner's Triangle
- **Education** (40 nodes): BKT (Corbett & Anderson 1994 parameters), CoachIDL, Socratic sequence, Scaffolded hints 3-tier
- **9 Protocol DAGs** as JSON + Cypher: BCSM, SPIKES, SPIN, ChallengerSale, HarvardNegotiation, PEACE, SBI, NVC, CoachIDL
- **6 SchemaFilterRegistry** domain filters
- **15 DomainBoundary** contamination guard nodes

**ALL PASS 16/16 ACs** · `outputs/phase8_uckb/`
</details>

<details>
<summary><strong>Phase 9 — Temporal Memory (Graphiti-inspired)</strong></summary>

Added dynamic session memory to the static knowledge graph:
- **Session** nodes — each AI agent conversation tracked as a graph episode
- **Turn** nodes — individual dialogue exchanges with detected emotion + recommended technique
- **TemporalFact** nodes — time-stamped atomic observations with validity windows
- **WorkingMemorySlot** nodes — live key-value context with TTL expiry
- **EpisodicMemory** nodes — compressed emotional arc + protocol state for completed sessions
- **MemoryTrace** nodes — cross-session technique effectiveness with domain-tuned **exponential decay**

Decay formula: `weight = initialWeight × exp(−λ × ageHours)`
- Crisis: λ = 0.08/hr (fast decay — urgency-driven)
- Clinical/Sales: λ = 0.04/hr
- Corporate: λ = 0.02/hr (slow — stable interpersonal skills)

**ALL PASS 10/10 ACs** · Graph: 1,091 nodes · `outputs/phase9_uckb/`
</details>

<details>
<summary><strong>Phase 10 — D-SMART Multi-Turn Logical Consistency</strong></summary>

Added the Dynamic Structured Memory (DSM) consistency engine:
- **ConversationFact** nodes — atomic speaker-attributed facts extracted per turn
- **GoalState** nodes — inferred user goal with drift detection
- **ProtocolTracker** nodes — live protocol position + deviation counter
- **ConsistencyConflict** nodes — detected contradictions (factual / goal / protocol) with severity
- **ReasoningCandidate** nodes — RT candidate responses with NLI score, goal alignment, protocol deviation
- **ConsistencyReport** nodes — per-session DER (Dialogue Consistency Evaluation Rate) snapshot

Composite score formula: `compositeScore = 0.5×nliScore + 0.3×goalAlignment + 0.2×(1 − protocolDeviation)`

**ALL PASS 10/10 ACs** · Graph: ~1,143 nodes · `outputs/phase10_uckb/`
</details>

<details>
<summary><strong>Phase 11 — Real-Time Hybrid Retrieval Engine</strong></summary>

Added 3-leg retrieval with Reciprocal Rank Fusion:
- **FullTextIndex** — BM25 Lucene full-text index over Technique/SignalMarker/ProtocolStep fields
- **VectorIndex** — 384-dim cosine vector index on `Technique.embedding` (all-MiniLM-L6-v2)
- **FusionConfig** — per-domain RRF config (k=60, domain-tuned leg weights)
- **HybridQuery** — 6 registered 3-leg query templates
- **RetrievalLeg** — single-leg result before fusion
- **HybridResult** — fused result with safety validation

Weighted RRF: `rrfScore(d) = Σᵢ wᵢ / (60 + rankᵢ)` · Safety filter applied before and after fusion

**ALL PASS 10/10 ACs** · Graph: ~1,187 nodes · 148 Technique embeddings · `outputs/phase11_uckb/`
</details>

---

## Safety Design

The UCKB is built with a **safety-first doctrine** that was established in Phase 1 and enforced in every subsequent phase.

### Hard Blocks
```
legal_contraindicated_reid:
  activationBlocked: true
  contraindication: ABSOLUTE
  note: Reid Interrogation Technique — scientifically discredited,
        produces false confessions. NEVER returned by any query.
```

### Prerequisite Gates
Influence techniques carry `requiresEmotionalClearance: true`. The Safety Gate query (Q11) must return `CLEARED` before any influence technique can be activated:

```cypher
MATCH (t:Technique {id: $techniqueId})
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
WITH t, collect(prereq.id) AS requiredPrereqs
// Only CLEARED if all prerequisites in $completedTechniqueIds
```

### Domain Contamination Guards
```
Sales → Crisis:     BLOCK_ALL
Corporate → Crisis: BLOCK_ALL
Legal → Clinical:   SELECTIVE (only PEACE engage allowed)
...
```

### Cross-Domain RRF Safety
The Cypher leg of the HybridRetriever builds a `blockedSet` *before* BM25 and vector results are fused. Any technique in `blockedSet` is excluded from RRF regardless of how high its BM25/vector score is.

---

## Quick Start

### Prerequisites

- Python 3.10+
- Neo4j 5.11+ (Desktop, Docker, or AuraDB)
- 4 GB RAM for Neo4j (8 GB recommended)

### 1 — Clone the Repository

```bash
git clone https://github.com/qasim-hafeez00/universal-communication-kg.git
cd universal-communication-kg
```

### 2 — Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 3 — Start Neo4j

**Docker (recommended):**
```bash
cd outputs/phase4_uckb/docker
docker-compose up -d
# Neo4j available at http://localhost:7474
# Bolt at bolt://localhost:7687
# Default credentials: neo4j / uckb_admin_2024
```

**Neo4j Desktop:** Create a new project, start a 5.11+ database, install APOC and n10s plugins.

### 4 — Ingest All Phases

```bash
python scripts/ingest_all_phases.py
# Or phase by phase:
python outputs/phase4_uckb/scripts/ingest_phase2_cypher.py
python outputs/phase5_uckb/scripts/import_phase5_neo4j.py
python outputs/phase6_uckb/scripts/import_phase6_neo4j.py
python outputs/phase7_uckb/scripts/import_phase7_neo4j.py
python outputs/phase8_uckb/run_phase8.py
python outputs/phase9_uckb/scripts/import_phase9_neo4j.py
python outputs/phase10_uckb/scripts/import_phase10_neo4j.py
python outputs/phase11_uckb/scripts/import_phase11_neo4j.py
```

### 5 — Generate Embeddings

```bash
# Mock (no GPU required, fully reproducible):
python outputs/phase11_uckb/scripts/generate_embeddings.py --neo4j

# Real (sentence-transformers, ~400MB download):
python outputs/phase11_uckb/scripts/generate_embeddings.py --real --neo4j
```

### 6 — Try the Hybrid Retriever

```python
from outputs.phase11_uckb.scripts.hybrid_retriever import HybridRetriever

retriever = HybridRetriever(domain='dispatch')
results = retriever.retrieve("caller panicking, mentions weapon, refuses to cooperate")

for r in results:
    print(r)
# [1] Minimal Encouragers (BCSM Step 2)  (rrf=0.016327, bm25_r=1, vec_r=2, cyp_r=1)
# [2] Active Listening (BCSM)            (rrf=0.015990, ...)
# [3] Emotional Labeling                 (rrf=0.015873, ...)
```

### 7 — Run Validation

```bash
# Validate a specific phase:
python outputs/phase11_uckb/scripts/validate_phase11.py --neo4j
# ALL PASS 10/10

# Demo simulation (no Neo4j required):
python outputs/phase11_uckb/scripts/simulate_hybrid_query.py
```

---

## Installation

### As a Python Package (coming in Phase 12)

```bash
pip install uckb
```

### From Source

```bash
git clone https://github.com/qasim-hafeez00/universal-communication-kg.git
cd universal-communication-kg
pip install -e .
```

### Requirements File

Create `requirements.txt`:

```
neo4j>=5.0.0
rdflib>=7.0.0
sentence-transformers>=2.2.0   # optional: for real embeddings
numpy>=1.24.0
```

Or install individually:

```bash
# Core (Neo4j driver + ontology)
pip install neo4j rdflib

# Optional: real semantic embeddings
pip install sentence-transformers

# Optional: SHACL validation
pip install pyshacl
```

---

## Running the Graph

### Docker Compose (Recommended)

The full Neo4j environment is pre-configured at `outputs/phase4_uckb/docker/`:

```bash
cd outputs/phase4_uckb/docker
docker-compose up -d
```

This starts:
- **Neo4j 5.x** with APOC and n10s plugins pre-installed
- Port **7474** — Neo4j Browser (HTTP)
- Port **7687** — Bolt driver
- Credentials: `neo4j` / `uckb_admin_2024`

### Environment Variables

```bash
export NEO4J_URI=bolt://localhost:7687
export NEO4J_USER=neo4j
export NEO4J_PASSWORD=uckb_admin_2024
```

### Neo4j AuraDB (Cloud)

All import scripts accept `--uri`, `--user`, `--password` flags:

```bash
python outputs/phase11_uckb/scripts/import_phase11_neo4j.py \
  --uri neo4j+s://your-instance.databases.neo4j.io \
  --user neo4j \
  --password your-aura-password
```

---

## Usage Examples

### Query 1 — Technique Lookup by Emotional State

```python
from neo4j import GraphDatabase

driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "uckb_admin_2024"))

with driver.session() as db:
    results = db.run("""
        MATCH (e:EmotionalState)
        WHERE toLower(e.name) = 'panic'
        MATCH (t:Technique)
        WHERE t.domain CONTAINS 'Crisis'
          AND NOT (t)-[:CONTRAINDICATED_WHEN]->(e)
          AND NOT t.activationBlocked = true
        RETURN t.name AS technique,
               t.evidenceLevel AS evidence,
               t.cognitiveLoadProfile AS load
        ORDER BY t.evidenceLevel DESC, t.avgLatency_ms ASC
        LIMIT 5
    """)
    for r in results:
        print(f"{r['technique']}  [{r['evidence']}]  load={r['load']}")
```

### Query 2 — Hybrid Retrieval (Python)

```python
from outputs.phase11_uckb.scripts.hybrid_retriever import HybridRetriever
from neo4j import GraphDatabase

driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "uckb_admin_2024"))
retriever = HybridRetriever(domain='clinical', driver=driver)

results = retriever.retrieve(
    query_text="patient is resisting hearing the diagnosis",
    cypher_params={"current_step": 4},  # SPIKES Step E
    top_k=5
)
for r in results:
    print(r)
```

### Query 3 — Protocol Step Navigation

```cypher
// Get ordered BCSM steps for a panic call
MATCH (proto:ProtocolDAG {id: 'bcsm_dag'})
MATCH path = (proto)-[:PRECEDES*1..6]->(step:ProtocolStep)
RETURN step.stepNumber AS step,
       step.name AS name,
       step.gateCondition AS gate
ORDER BY step.stepNumber ASC
```

### Query 4 — Cultural Adaptation

```cypher
// Adapt active listening for Japan
MATCH (core:Technique)
WHERE toLower(core.name) = 'active listening'
MATCH (core)-[:ADAPTS_FOR]->(ctx:CulturalContext)
MATCH (profile:CulturalProfile)-[:HAS_DIMENSION]->(ctx)
WHERE profile.name = 'Japan'
MATCH (rule:CulturalAdaptationRule)
WHERE (profile)-[:APPLIES_RULE]->(rule)
RETURN core.name AS technique,
       collect(DISTINCT ctx.label) AS applicable_contexts,
       collect(DISTINCT rule.name) AS adaptation_rules
```

### Query 5 — Cross-Session Consistency Check

```cypher
// Find active (non-superseded) facts for the current session
MATCH (sess:Session {sessionId: $sessionId})
MATCH (sess)<-[:EXTRACTED_FROM]-(fact:ConversationFact)
WHERE fact.superseded = false
RETURN fact.content AS fact,
       fact.factType AS type,
       fact.speakerRole AS speaker,
       fact.validFrom AS turn
ORDER BY fact.validFrom ASC
```

### Query 6 — Full Safety Gate Check

```cypher
MATCH (t:Technique {cardId: $techniqueCardId})
OPTIONAL MATCH (t)-[:REQUIRES]->(prereq:Technique)
WITH t, collect(prereq.cardId) AS required
WITH t, required,
     [p IN required WHERE p IN $completed] AS satisfied,
     [p IN required WHERE NOT p IN $completed] AS missing
RETURN t.name AS technique,
       CASE WHEN size(missing) > 0 OR t.requiresEmotionalClearance = true
            THEN 'BLOCKED'
            ELSE 'CLEARED'
       END AS gate_status,
       missing AS missing_prerequisites
```

---

## Hybrid Retrieval Engine

Phase 11 introduced a 3-leg retrieval engine with **Weighted Reciprocal Rank Fusion (RRF)**:

```
Query Text + Embedding + Domain + CypherParams
        │
        ├──► BM25 Leg       CALL db.index.fulltext.queryNodes(...)   → ranked list
        ├──► Vector Leg     CALL db.index.vector.queryNodes(...)     → ranked list
        └──► Cypher Leg     Graph traversal (protocol/emotion/domain) → ranked list
                                         │
                              Weighted RRF (k=60)
                              score = Σ wᵢ / (60 + rankᵢ)
                                         │
                              Safety Filter (blocked set + domain guard)
                                         │
                              HybridResult (top-K, safetyValidated=true)
```

### Per-Domain Leg Weights

| Domain | BM25 | Vector | Cypher | Rationale |
|---|---|---|---|---|
| crisis dispatch | 0.15 | 0.25 | **0.60** | Safety graph structure must dominate |
| clinical | 0.20 | 0.30 | **0.50** | Protocol gates critical |
| negotiation | 0.30 | **0.40** | 0.30 | Semantic intent most important |
| legal | **0.40** | 0.25 | 0.35 | Lexical precision for SA markers |
| corporate | 0.25 | 0.35 | 0.40 | Balanced |
| education | 0.20 | **0.40** | 0.40 | Semantic pedagogical intent |

---

## Querying with Cypher

The UCKB ships with **35 production Text2Cypher templates** across 5 categories:

| Category | Templates | Phase |
|---|---|---|
| `core` | Q1–Q12 (technique lookup, protocol navigation, safety gates) | 4 |
| `domain` | 5 domain-specific templates | 8 |
| `temporal` | 6 session memory templates | 9 |
| `consistency` | 6 D-SMART consistency templates | 10 |
| `hybrid` | 6 3-leg RRF retrieval templates | 11 |

Retrieve all templates:
```cypher
MATCH (t:Text2CypherTemplate)
RETURN t.id, t.category, t.description
ORDER BY t.category, t.id
```

---

## Ontology and SHACL

The UCKB is fully described in OWL 2 across 11 ontology modules:

| Module | File | Classes |
|---|---|---|
| Core communication acts | `phase3_uckb/core/communication-acts.ttl` | 8 |
| Psychological models | `phase3_uckb/core/psychological-models.ttl` | 6 |
| Cultural contexts | `phase3_uckb/core/cultural-contexts.ttl` | 5 |
| Emotional states | `phase3_uckb/core/emotional-states.ttl` | 4 |
| Temporal memory | `phase9_uckb/ontology/temporal-memory.ttl` | 6 |
| D-SMART consistency | `phase10_uckb/ontology/dsmart-memory.ttl` | 6 |
| Hybrid retrieval | `phase11_uckb/ontology/hybrid-retrieval.ttl` | 6 |
| ...and 4 more modules | | |

SHACL validation:
```bash
pip install pyshacl
pyshacl -s outputs/phase11_uckb/shacl/hybrid-shapes.ttl \
        -d outputs/phase11_uckb/ontology/hybrid-retrieval.ttl \
        --output result.ttl
```

---

## Validation

Every phase ships with a file-based validation script that requires **no live Neo4j** to run:

```bash
# Run all phase validators
for phase in 4 5 6 7 8 9 10 11; do
  echo "=== Phase $phase ==="
  python outputs/phase${phase}_uckb/scripts/validate_phase${phase}.py
done
```

| Phase | ACs | Status |
|---|---|---|
| Phase 4 (Core Graph) | 10/10 | ALL PASS |
| Phase 5 (Dialogue Acts) | 8/8 | ALL PASS |
| Phase 6 (Psychological) | 8/8 | ALL PASS |
| Phase 7 (Cultural) | 8/8 | ALL PASS |
| Phase 8 (Domain Sub-Graphs) | 16/16 | ALL PASS |
| Phase 9 (Temporal Memory) | 10/10 | ALL PASS |
| Phase 10 (D-SMART) | 10/10 | ALL PASS |
| Phase 11 (Hybrid Retrieval) | 10/10 | ALL PASS |
| **Total** | **80/80** | **ALL PASS** |

---

## Use Cases

### 1 — AI Call Centre Agent (Crisis Dispatch)
A real-time AI co-pilot that monitors a call, detects panic signals from speech, queries UCKB for the safest low-cognitive-load technique, and surfaces it to the dispatcher within 200ms — while continuously checking that no influence technique fires before rapport prerequisites are met.

### 2 — Clinical Decision Support
A palliative care AI assistant that tracks which SPIKES step the clinician is on, detects when the patient's emotion shifts, queries the appropriate empathy response for Step E, and flags if the conversation is deviating from the protocol.

### 3 — Sales Coaching
An AI sales coach that monitors a live discovery call, detects when a prospect is stalling on price, runs a 3-leg hybrid retrieval (BM25 on "price objection" + semantic on "resistance" + graph traversal on SPIN position), and surfaces the highest-RRF-scored technique that is safe for the current emotional state.

### 4 — Legal Interview Training
A simulation environment for police and legal interviewers that enforces the PEACE protocol, detects Statement Analysis markers (pronoun shifts, verb tense changes) in real time, and *never* surfaces the Reid Technique regardless of how close the query is semantically.

### 5 — Cross-Cultural Communication Training
An AI tutor that teaches professionals how to adapt their communication style for specific cultural contexts — surfacing not just the technique but the full adaptation rules for Japan vs. Germany vs. Arab World.

### 6 — Multi-Turn Consistency Monitoring
An AI agent health monitor that tracks every ConversationFact extracted from a session, detects contradictions and goal drift, computes a Dialogue Consistency Evaluation Rate (DER), and surfaces alerts when the agent is becoming inconsistent.

### 7 — RAG Knowledge Layer
Any RAG (Retrieval-Augmented Generation) pipeline can use UCKB as a structured knowledge source — querying the graph instead of (or in addition to) a vector store to get domain-safe, prerequisite-aware, culturally-adapted context for LLM generation.

### 8 — Communication Research
Researchers can use UCKB as a structured representation of the communication science literature — querying technique clusters, evidence distributions, cross-cultural patterns, and inter-domain mappings.

---

## Project Structure

```
universal-communication-kg/
│
├── README.md
├── requirements.txt
├── LICENSE
│
├── outputs/
│   ├── phase2_uckb/            # Master taxonomy (Excel)
│   ├── phase3_uckb/            # OWL ontology (Turtle + JSON-LD)
│   │   └── uckb-ontology/
│   │       ├── core/           # Core ontology modules
│   │       ├── domains/        # Domain TTL files
│   │       ├── validation/     # SHACL shapes
│   │       └── jsonld/         # JSON-LD serialisations
│   │
│   ├── phase4_uckb/            # Neo4j graph + 12 Text2Cypher templates
│   │   ├── cypher/             # Cypher scripts 01-07
│   │   ├── docker/             # Docker Compose + neo4j.conf + APOC
│   │   └── scripts/            # Ingest + validate
│   │
│   ├── phase5_uckb/            # Dialogue Acts (ISO 24617-2)
│   ├── phase6_uckb/            # Psychological + multimodal layer
│   ├── phase7_uckb/            # Cross-cultural adaptation
│   │
│   ├── phase8_uckb/            # Domain sub-graphs + 9 Protocol DAGs
│   │   ├── cypher/             # Scripts 08-14
│   │   ├── domains/            # Legal/Corporate/Education TTL
│   │   ├── protocol_dags/      # 9 DAG JSON files
│   │   └── shacl/
│   │
│   ├── phase9_uckb/            # Temporal memory (Graphiti-inspired)
│   │   ├── cypher/             # Scripts 15-20
│   │   ├── ontology/           # temporal-memory.ttl/.jsonld
│   │   └── shacl/
│   │
│   ├── phase10_uckb/           # D-SMART multi-turn consistency
│   │   ├── cypher/             # Scripts 21-28
│   │   ├── ontology/           # dsmart-memory.ttl/.jsonld
│   │   └── shacl/
│   │
│   └── phase11_uckb/           # Hybrid retrieval engine (BM25+Vector+Cypher)
│       ├── cypher/             # Scripts 29-35
│       ├── scripts/            # hybrid_retriever.py, generate_embeddings.py...
│       ├── data/               # phase11_data.json, embeddings.json
│       ├── ontology/           # hybrid-retrieval.ttl/.jsonld
│       ├── shacl/
│       └── reports/
│
├── scripts/
│   └── build_phase*.py         # Phase-level ontology builders
│
└── protocol_dags/              # Consolidated DAG JSON files
```

---

## Roadmap

### Currently Implemented (Phases 1–11) ✅

All phases listed in [Phase-by-Phase Breakdown](#phase-by-phase-breakdown) are complete and validated.

### Planned (Phases 12–14)

| Phase | Title | Key Deliverables |
|---|---|---|
| **Phase 12** | Python Package + REST API | `pip install uckb` · FastAPI endpoints · OpenAPI spec · Swagger UI |
| **Phase 13** | Agent SDK Integration | LangChain tool · LlamaIndex retriever · OpenAI function-calling adapter · Claude tool use integration |
| **Phase 14** | Real-Time Signal Processing | Live audio feature extraction (pitch, speech rate, FACS) → SignalMarker → UCKB query pipeline · WebSocket API |

### Longer Term

- **Phase 15** — Technique effectiveness feedback loop (online learning from real session outcomes)
- **Phase 16** — Multilingual support (Arabic, Mandarin, Spanish technique variants)
- **Phase 17** — FHIR integration for clinical deployment
- **Phase 18** — Fine-tuned embedding model trained on UCKB technique descriptions
- **Phase 19** — GraphQL interface
- **Phase 20** — Hosted AuraDB instance + public API with rate limiting

---

## Contributing

Contributions are welcome. UCKB is built on published communication science — new nodes and edges must be evidence-grounded.

### How to Contribute

1. **Fork** the repository
2. **Create a feature branch** (`git checkout -b feature/phase12-api`)
3. **Follow the phase structure** — each new addition should be a phase with its own Cypher scripts, Python scripts, OWL module, SHACL shapes, and validation suite
4. **All ACs must pass** — `python validate_phaseN.py` must return `ALL PASS`
5. **Add evidence citation** — every new Technique node requires an `evidenceLevel` and source reference
6. **Submit a pull request** with the validation report attached

### Contribution Guidelines

- Every `Technique` node must have: `name`, `domain`, `evidenceLevel`, `cognitiveLoadProfile`, `whenToUse`, `steps`
- Every `CONTRAINDICATED_WHEN` edge must reference an existing `EmotionalState` node
- No new technique may be added without checking the Phase 1 doctrine (influence → empathy prerequisite)
- New domain ontologies must extend the core OWL namespace `https://uckb.io/ontology#`

### Adding a New Domain

1. Create `outputs/phaseN_uckb/domains/your_domain.ttl`
2. Run `n10s.rdf.import.fetch` to load into Neo4j
3. Add a `SchemaFilterRegistry` node for the domain
4. Add `DomainBoundary` nodes for cross-domain guards
5. Create at least one `ProtocolDAG` for the domain
6. Write `phaseN_validation.py` with ≥8 ACs

---

## Citation

If you use UCKB in research, please cite:

```bibtex
@software{uckb2026,
  title        = {Universal Communication Knowledge Graph (UCKB)},
  author       = {Hafeez, Qasim},
  year         = {2026},
  url          = {https://github.com/qasim-hafeez00/universal-communication-kg},
  note         = {A structured, safety-annotated knowledge graph of human communication
                  techniques for AI agents — 1,141 nodes, 4,900+ edges, 11 phases,
                  6 domains, BM25+Vector+Cypher hybrid retrieval with weighted RRF},
  version      = {0.11.0}
}
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.

This project is open-source and free to use for research, education, and commercial applications. Attribution appreciated.

---

## Acknowledgements

UCKB is grounded in decades of peer-reviewed research across communication science, psychology, and AI. Key theoretical foundations include:

| Framework | Authors | Year |
|---|---|---|
| Behavioural Change Stairway Model (BCSM) | Vecchi, FBI | 1988 |
| SPIKES Breaking-Bad-News Protocol | Baile et al. | 2000 |
| SPIN Selling | Neil Rackham | 1988 |
| Challenger Sale | Dixon & Adamson | 2011 |
| Harvard Principled Negotiation | Fisher, Ury & Patton | 1981 |
| PEACE Investigative Interviewing | Clarke & Milne (ACPO) | 1999 |
| FBI Statement Analysis (8 markers) | Adams | 1996 |
| Nonviolent Communication (NVC) | Marshall B. Rosenberg | 2003 |
| Situation-Behavior-Impact (SBI) | Center for Creative Leadership | 1984 |
| Radical Candor | Kim Scott | 2017 |
| Karpman Drama Triangle | Stephen Karpman | 1968 |
| CoachIDL Dialogue Acts | Shaffer & Suthers | 2006 |
| Bayesian Knowledge Tracing (BKT) | Corbett & Anderson | 1994 |
| ISO 24617-2 Dialogue Acts | ISO | 2012 |
| Hofstede Cultural Dimensions | Geert Hofstede | 1980 |
| Lewis Cultural Model | Richard Lewis | 1996 |
| Transactional Analysis (TA) | Eric Berne | 1964 |
| FACS (Facial Action Coding System) | Ekman & Friesen | 1978 |
| Mehrabian 7-38-55 Rule | Albert Mehrabian | 1971 |
| Relevance Theory | Sperber & Wilson | 1986 |
| Communication Accommodation Theory | Howard Giles | 1973 |
| Reciprocal Rank Fusion | Cormack, Clarke & Buettcher | 2009 |
| Graphiti (temporal memory architecture) | Zep AI | 2024 |

---

<div align="center">

**Built with ❤️ for the AI agents that need to communicate with humans — safely, appropriately, and effectively.**

[⭐ Star this repo](https://github.com/qasim-hafeez00/universal-communication-kg) · [🐛 Report a bug](https://github.com/qasim-hafeez00/universal-communication-kg/issues) · [💡 Request a feature](https://github.com/qasim-hafeez00/universal-communication-kg/discussions)

</div>
