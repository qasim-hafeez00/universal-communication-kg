"""
UCKB Phase 10 — Ontology Builder
Generates outputs/phase10_uckb/ontology/dsmart-memory.ttl and dsmart-memory.jsonld
using rdflib. Run this to regenerate both files from the canonical Python definition.

Usage:
    python build_phase10_ontology.py

Prerequisites:
    pip install rdflib
"""

import sys
import json
from pathlib import Path

try:
    from rdflib import Graph, Namespace, Literal, URIRef
    from rdflib.namespace import OWL, RDF, RDFS, XSD, SKOS, DCTERMS
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "rdflib", "-q"])
    from rdflib import Graph, Namespace, Literal, URIRef
    from rdflib.namespace import OWL, RDF, RDFS, XSD, SKOS, DCTERMS

ROOT    = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "ontology"
OUT_DIR.mkdir(parents=True, exist_ok=True)

UCKB   = Namespace("https://uckb.io/ontology#")
DS     = Namespace("https://uckb.io/ontology/dsmart#")
ONTO   = URIRef("https://uckb.io/ontology/dsmart")

# ─────────────────────────────────────────────────────────────────────────────

def build_graph() -> Graph:
    g = Graph()
    g.bind("owl",     OWL)
    g.bind("rdfs",    RDFS)
    g.bind("xsd",     XSD)
    g.bind("skos",    SKOS)
    g.bind("dcterms", DCTERMS)
    g.bind("uckb",    UCKB)
    g.bind("dsmart",  DS)

    # ── Ontology header ───────────────────────────────────────────────────────
    g.add((ONTO, RDF.type,            OWL.Ontology))
    g.add((ONTO, DCTERMS.title,       Literal("UCKB D-SMART Memory Ontology")))
    g.add((ONTO, DCTERMS.description, Literal(
        "OWL ontology for Phase 10 Multi-Turn Logical Consistency (D-SMART). "
        "Models ConversationFact extraction, GoalState tracking, ProtocolTracker "
        "position, ConsistencyConflict detection, ReasoningCandidate generation, "
        "and ConsistencyReport DER snapshots."
    )))
    g.add((ONTO, DCTERMS.created,     Literal("2026-05-31", datatype=XSD.date)))
    g.add((ONTO, OWL.versionInfo,     Literal("1.0")))
    g.add((ONTO, OWL.imports,         URIRef("https://uckb.io/ontology/temporal-memory")))

    # ── Classes ───────────────────────────────────────────────────────────────
    classes = [
        (DS.ConversationFact,
         "Conversation Fact",
         "Atomic speaker-attributed fact extracted from a Turn by the DSM. "
         "Constitutes the live OWL-compliant conversation knowledge graph.",
         "Subject states sister is inside the apartment (turn 1, information, caller)"),

        (DS.GoalState,
         "Goal State",
         "Inferred underlying user goal tracked across turns to detect goal drift — "
         "when the agent responds to surface utterances rather than the core objective.",
         "Goal: safety; status: active; detectedAt: 1; confidence: 0.83"),

        (DS.ProtocolTracker,
         "Protocol Tracker",
         "Live protocol position and deviation counter. Bridges Phase 8 ProtocolDAG "
         "to the dynamic session. Increments deviationCount on skipped/repeated steps.",
         "BCSM tracker; currentStep=3; deviationCount=0; status=on_track"),

        (DS.ConsistencyConflict,
         "Consistency Conflict",
         "Detected contradiction logged into the DSM. Types: factual, goal, protocol. "
         "Triggers NLI re-evaluation of pending ReasoningCandidates.",
         "Factual critical: presence vs denial contradiction (turns 1 and 3)"),

        (DS.ReasoningCandidate,
         "Reasoning Candidate",
         "One RT candidate response path before NLI selection. Carries nliScore, "
         "goalAlignment, protocolDeviation, compositeScore. Exactly one per turn "
         "group has selected=true.",
         "Empathic reframe; nliScore=0.71; compositeScore=0.799; selected=true"),

        (DS.ConsistencyReport,
         "Consistency Report",
         "Per-session DER snapshot at a milestone turn. Records derScore, factCount, "
         "conflictCount, activeGoals, and protocolStep.",
         "Session 001, turn 4: derScore=0.67, factCount=5, conflictCount=2"),
    ]

    for cls, label, comment, example in classes:
        g.add((cls, RDF.type,          OWL.Class))
        g.add((cls, RDFS.label,        Literal(label)))
        g.add((cls, RDFS.comment,      Literal(comment)))
        g.add((cls, RDFS.subClassOf,   UCKB.KnowledgeNode))
        g.add((cls, SKOS.example,      Literal(example)))

    # ── Object Properties ─────────────────────────────────────────────────────
    obj_props = [
        (DS.extractedFrom, "extracted from",
         DS.ConversationFact, UCKB.Turn,
         [OWL.ObjectProperty],
         "Links a ConversationFact to the Turn it was extracted from."),

        (DS.contradicts, "contradicts",
         DS.ConversationFact, DS.ConversationFact,
         [OWL.ObjectProperty, OWL.SymmetricProperty],
         "Symmetric: two ConversationFacts that are logically incompatible."),

        (DS.supersedes, "supersedes",
         DS.ConversationFact, DS.ConversationFact,
         [OWL.ObjectProperty, OWL.IrreflexiveProperty],
         "Newer ConversationFact temporally invalidates an older one."),

        (DS.hasGoal, "has goal",
         UCKB.Session, DS.GoalState,
         [OWL.ObjectProperty],
         "Links a Session to its inferred GoalState."),

        (DS.hasTracker, "has tracker",
         UCKB.Session, DS.ProtocolTracker,
         [OWL.ObjectProperty],
         "Links a Session to its live ProtocolTracker."),

        (DS.tracks, "tracks",
         DS.ProtocolTracker, UCKB.ProtocolDAG,
         [OWL.ObjectProperty],
         "Links ProtocolTracker to the ProtocolDAG it monitors."),

        (DS.candidateFor, "candidate for",
         DS.ReasoningCandidate, UCKB.Turn,
         [OWL.ObjectProperty],
         "Links a ReasoningCandidate to its source Turn."),

        (DS.hasReport, "has report",
         UCKB.Session, DS.ConsistencyReport,
         [OWL.ObjectProperty],
         "Links a Session to a ConsistencyReport DER snapshot."),

        (DS.flaggedDeviation, "flagged deviation",
         DS.ProtocolTracker, DS.ConsistencyConflict,
         [OWL.ObjectProperty],
         "Links ProtocolTracker to ConsistencyConflict raised on deviation."),
    ]

    for prop, label, domain, range_, types, comment in obj_props:
        for t in types:
            g.add((prop, RDF.type, t))
        g.add((prop, RDFS.label,   Literal(label)))
        g.add((prop, RDFS.comment, Literal(comment)))
        g.add((prop, RDFS.domain,  domain))
        g.add((prop, RDFS.range,   range_))

    # ── Datatype Properties ───────────────────────────────────────────────────
    dt_props = [
        (DS.factType,       "fact type",        DS.ConversationFact,  XSD.string,
         "Semantic type: commitment, position, information, denial."),
        (DS.superseded,     "superseded",       DS.ConversationFact,  XSD.boolean,
         "True when this fact has been invalidated by a newer fact."),
        (DS.goalStatus,     "goal status",      DS.GoalState,         XSD.string,
         "Lifecycle state: active, drifted, resolved, blocked."),
        (DS.confidenceScore,"confidence score", DS.GoalState,         XSD.decimal,
         "RT confidence in current goal inference, in [0.0, 1.0]."),
        (DS.deviationCount, "deviation count",  DS.ProtocolTracker,   XSD.integer,
         "Number of protocol step deviations counted by the tracker."),
        (DS.nliScore,       "NLI score",        DS.ReasoningCandidate, XSD.decimal,
         "NLI consistency score against current DSM state, in [0.0, 1.0]."),
        (DS.compositeScore, "composite score",  DS.ReasoningCandidate, XSD.decimal,
         "0.5*nliScore + 0.3*goalAlignment + 0.2*(1-protocolDeviation)."),
        (DS.derScore,       "DER score",        DS.ConsistencyReport,  XSD.decimal,
         "Dialogue Consistency Evaluation Rate for this snapshot, in [0.0, 1.0]."),
    ]

    for prop, label, domain, dtype, comment in dt_props:
        g.add((prop, RDF.type,      OWL.DatatypeProperty))
        g.add((prop, RDFS.label,    Literal(label)))
        g.add((prop, RDFS.comment,  Literal(comment)))
        g.add((prop, RDFS.domain,   domain))
        g.add((prop, RDFS.range,    dtype))

    return g


def build_jsonld(g: Graph) -> dict:
    context = {
        "owl":     "http://www.w3.org/2002/07/owl#",
        "rdf":     "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        "rdfs":    "http://www.w3.org/2000/01/rdf-schema#",
        "xsd":     "http://www.w3.org/2001/XMLSchema#",
        "skos":    "http://www.w3.org/2004/02/skos/core#",
        "dcterms": "http://purl.org/dc/terms/",
        "uckb":    "https://uckb.io/ontology#",
        "dsmart":  "https://uckb.io/ontology/dsmart#",
    }
    nodes = []
    for subj in set(g.subjects()):
        entry = {"@id": str(subj)}
        types = list(g.objects(subj, RDF.type))
        if types:
            entry["@type"] = [str(t) for t in types] if len(types) > 1 else str(types[0])
        for pred, obj in g.predicate_objects(subj):
            if pred == RDF.type:
                continue
            key = str(pred)
            for prefix, ns in context.items():
                if key.startswith(ns):
                    key = f"{prefix}:{key[len(ns):]}"
                    break
            val = {"@id": str(obj)} if isinstance(obj, URIRef) else str(obj)
            if key in entry:
                if not isinstance(entry[key], list):
                    entry[key] = [entry[key]]
                entry[key].append(val)
            else:
                entry[key] = val
        nodes.append(entry)
    return {"@context": context, "@graph": nodes}


def main():
    print("Building D-SMART ontology graph...")
    g = build_graph()

    ttl_path = OUT_DIR / "dsmart-memory.ttl"
    g.serialize(destination=str(ttl_path), format="turtle")
    print(f"  Written: {ttl_path.relative_to(ROOT.parent.parent.parent)}")

    jsonld_path = OUT_DIR / "dsmart-memory.jsonld"
    doc = build_jsonld(g)
    jsonld_path.write_text(json.dumps(doc, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"  Written: {jsonld_path.relative_to(ROOT.parent.parent.parent)}")

    triples = len(g)
    classes  = sum(1 for _ in g.subjects(RDF.type, OWL.Class))
    obj_p    = sum(1 for _ in g.subjects(RDF.type, OWL.ObjectProperty))
    sym_p    = sum(1 for _ in g.subjects(RDF.type, OWL.SymmetricProperty))
    dt_p     = sum(1 for _ in g.subjects(RDF.type, OWL.DatatypeProperty))

    print(f"\n  Triples:             {triples}")
    print(f"  Classes:             {classes}")
    print(f"  Object properties:   {obj_p} ({sym_p} symmetric)")
    print(f"  Datatype properties: {dt_p}")
    print("\nD-SMART ontology build complete.")


if __name__ == "__main__":
    main()
