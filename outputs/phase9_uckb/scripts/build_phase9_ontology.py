"""
UCKB Phase 9 — Ontology Builder
Generates outputs/phase9_uckb/ontology/temporal-memory.ttl using rdflib.

Usage:
    python build_phase9_ontology.py

Output:
    outputs/phase9_uckb/ontology/temporal-memory.ttl  (authoritative OWL source)
    outputs/phase9_uckb/ontology/temporal-memory.jsonld
"""

import sys
import pathlib

try:
    from rdflib import Graph, Namespace, Literal, URIRef
    from rdflib.namespace import RDF, RDFS, OWL, XSD, DCTERMS
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "rdflib", "-q"])
    from rdflib import Graph, Namespace, Literal, URIRef
    from rdflib.namespace import RDF, RDFS, OWL, XSD, DCTERMS

BASE_DIR = pathlib.Path(__file__).resolve().parents[1]
OUT_TTL  = BASE_DIR / "ontology" / "temporal-memory.ttl"
OUT_JSON = BASE_DIR / "ontology" / "temporal-memory.jsonld"
OUT_TTL.parent.mkdir(parents=True, exist_ok=True)

UCKB = Namespace("https://uckb.io/ontology#")
ONT  = URIRef("https://uckb.io/ontology/temporal-memory")

g = Graph()
g.bind("uckb",    UCKB)
g.bind("owl",     OWL)
g.bind("rdfs",    RDFS)
g.bind("xsd",     XSD)
g.bind("dcterms", DCTERMS)

# ── Ontology declaration ──────────────────────────────────────────────────────
g.add((ONT, RDF.type,           OWL.Ontology))
g.add((ONT, DCTERMS.title,      Literal("UCKB Temporal Memory Ontology")))
g.add((ONT, DCTERMS.description, Literal("Phase 9: Graphiti-style temporal memory for UCKB AI communication agents")))
g.add((ONT, DCTERMS.version,    Literal("9.0.0")))

# ── Base class ────────────────────────────────────────────────────────────────
g.add((UCKB.TemporalEntity, RDF.type,       OWL.Class))
g.add((UCKB.TemporalEntity, RDFS.label,     Literal("TemporalEntity")))
g.add((UCKB.TemporalEntity, RDFS.comment,   Literal("Abstract base for temporal memory node types. All carry a timestamp.")))

# ── Class definitions ─────────────────────────────────────────────────────────

CLASSES = [
    ("Session",
     "A single conversation episode between an AI communication agent and a human interlocutor. Maps to a Graphiti episode."),
    ("Turn",
     "One dialogue exchange within a Session. Carries detected emotional state and recommended technique."),
    ("TemporalFact",
     "Time-stamped atomic observation within a session, with validity window and confidence decay."),
    ("WorkingMemorySlot",
     "Live key-value context slot for a Session. Expires at ttl (epoch ms). Domain-scoped to SchemaFilterRegistry boundaries."),
    ("EpisodicMemory",
     "Compressed summary of a Session: emotional arc, last protocol step, outcome. Feeds the next session as context."),
    ("MemoryTrace",
     "Cross-session learned effectiveness record per userId x technique. Weight decays using lambda decay."),
]

for name, comment in CLASSES:
    node = UCKB[name]
    g.add((node, RDF.type,          OWL.Class))
    g.add((node, RDFS.label,        Literal(name)))
    g.add((node, RDFS.comment,      Literal(comment)))
    g.add((node, RDFS.subClassOf,   UCKB.TemporalEntity))

# ── Datatype properties ───────────────────────────────────────────────────────

DATATYPE_PROPS = [
    # (name, domain_class, range_type, comment)
    ("sessionId",        "Session",           XSD.string,  "Globally unique session identifier."),
    ("userId",           "Session",           XSD.string,  "Agent user or operator identifier."),
    ("domainContext",    "Session",           XSD.string,  "Domain matching SchemaFilterRegistry."),
    ("startedAt",        "Session",           XSD.long,    "Session start timestamp in epoch ms."),
    ("endedAt",          "Session",           XSD.long,    "Session end timestamp in epoch ms."),
    ("outcomeScore",     "Session",           XSD.float,   "Overall session quality [0.0, 1.0]."),
    ("sessionStatus",   "Session",           XSD.string,  "One of: active, completed, interrupted."),

    ("turnId",           "Turn",              XSD.string,  "Unique turn identifier."),
    ("turnNumber",       "Turn",              XSD.integer, "1-indexed position within parent Session."),
    ("speakerRole",      "Turn",              XSD.string,  "One of: agent, user, caller, dispatcher, patient, clinician."),
    ("detectedEmotionName", "Turn",           XSD.string,  "Name of EmotionalState node detected."),
    ("recommendedTechniqueId", "Turn",        XSD.string,  "cardId of Technique recommended."),
    ("protocolStepId",  "Turn",              XSD.string,  "id of active ProtocolStep."),

    ("factId",           "TemporalFact",      XSD.string,  "Unique fact identifier."),
    ("factType",         "TemporalFact",      XSD.string,  "emotion_detected|technique_applied|protocol_gate_passed|outcome_observed"),
    ("validFrom",        "TemporalFact",      XSD.long,    "Epoch ms from which fact is valid."),
    ("validUntil",       "TemporalFact",      XSD.long,    "Epoch ms after which fact is superseded. Null = still valid."),
    ("factDecayRate",    "TemporalFact",      XSD.float,   "Lambda per hour for confidence decay."),

    ("slotId",           "WorkingMemorySlot", XSD.string,  "Unique slot identifier."),
    ("slotKey",          "WorkingMemorySlot", XSD.string,  "Slot name (e.g., active_domain, current_step)."),
    ("slotValue",        "WorkingMemorySlot", XSD.string,  "Slot value."),
    ("slotTtl",          "WorkingMemorySlot", XSD.long,    "Expiry timestamp in epoch ms."),

    ("episodeId",        "EpisodicMemory",    XSD.string,  "Unique episode identifier."),
    ("emotionalArc",     "EpisodicMemory",    XSD.string,  "Arrow-separated sequence of emotional states."),
    ("lastCompletedStep","EpisodicMemory",    XSD.integer, "ProtocolStep stepNumber reached before end."),
    ("protocolCompleted","EpisodicMemory",    XSD.boolean, "True if protocol reached terminal step."),
    ("episodeSummary",   "EpisodicMemory",    XSD.string,  "Human-readable session outcome summary."),
    ("domainFilter",     "EpisodicMemory",    XSD.string,  "Domain matching SchemaFilterRegistry."),

    ("traceId",          "MemoryTrace",       XSD.string,  "Unique trace identifier."),
    ("traceUserId",      "MemoryTrace",       XSD.string,  "userId this trace belongs to."),
    ("techniqueCardId",  "MemoryTrace",       XSD.string,  "cardId of the measured Technique."),
    ("successCount",     "MemoryTrace",       XSD.integer, "Number of successful applications."),
    ("failCount",        "MemoryTrace",       XSD.integer, "Number of failed applications."),
    ("initialWeight",    "MemoryTrace",       XSD.float,   "Weight at time of last use. [0.0, 1.0]."),
    ("currentWeight",    "MemoryTrace",       XSD.float,   "Decayed weight = initialWeight * exp(-λ * Δh)."),
    ("traceDecayRate",   "MemoryTrace",       XSD.float,   "Lambda per hour. Crisis: 0.08, Clinical: 0.04, Corporate: 0.02."),
    ("ageHours",         "MemoryTrace",       XSD.float,   "Hours since lastUsed (used in decay computation)."),
]

for prop_name, domain_name, range_type, comment in DATATYPE_PROPS:
    prop = UCKB[prop_name]
    g.add((prop, RDF.type,        OWL.DatatypeProperty))
    g.add((prop, RDFS.label,      Literal(prop_name)))
    g.add((prop, RDFS.domain,     UCKB[domain_name]))
    g.add((prop, RDFS.range,      range_type))
    g.add((prop, RDFS.comment,    Literal(comment)))

# ── Object properties (relationships) ────────────────────────────────────────

OBJ_PROPS = [
    ("hasTurn",        "Session",        "Turn",                  "HAS_TURN"),
    ("hasEpisode",     "Session",        "EpisodicMemory",        "HAS_EPISODE"),
    ("hasSlot",        "Session",        "WorkingMemorySlot",     "HAS_SLOT"),
    ("hasFact",        "Session",        "TemporalFact",          "HAS_FACT"),
    ("detected",       "Turn",           "EmotionalState",        "DETECTED"),
    ("precedesTurn",   "Turn",           "Turn",                  "PRECEDES"),
    ("reinforces",     "MemoryTrace",    "CommunicationTechnique","REINFORCES"),
    ("follows",        "Session",        "Session",               "FOLLOWS - continuation across sessions"),
    ("activeProtocol", "Session",        "ProtocolDAG",           "ACTIVE_PROTOCOL"),
    ("atStep",         "Session",        "ProtocolStep",          "AT_STEP"),
    ("triggered",      "EpisodicMemory", "ProtocolDAG",           "TRIGGERED"),
]

for prop_name, domain_name, range_name, label in OBJ_PROPS:
    prop = UCKB[prop_name]
    g.add((prop, RDF.type,      OWL.ObjectProperty))
    g.add((prop, RDFS.label,    Literal(label)))
    g.add((prop, RDFS.domain,   UCKB[domain_name]))
    g.add((prop, RDFS.range,    UCKB[range_name]))

# ── Serialise ─────────────────────────────────────────────────────────────────

g.serialize(str(OUT_TTL),  format="turtle")
g.serialize(str(OUT_JSON), format="json-ld")

print(f"Written: {OUT_TTL}")
print(f"Written: {OUT_JSON}")
print(f"Triples: {len(g)}")

# ── Quick sanity check ────────────────────────────────────────────────────────
classes  = list(g.subjects(RDF.type, OWL.Class))
dt_props = list(g.subjects(RDF.type, OWL.DatatypeProperty))
ob_props = list(g.subjects(RDF.type, OWL.ObjectProperty))
print(f"\nClasses:             {len(classes)}")
print(f"DatatypeProperties:  {len(dt_props)}")
print(f"ObjectProperties:    {len(ob_props)}")

expected_classes = {"Session", "Turn", "TemporalFact", "WorkingMemorySlot", "EpisodicMemory", "MemoryTrace", "TemporalEntity"}
found_names = {str(c).split('#')[-1] for c in classes}
missing = expected_classes - found_names
if missing:
    print(f"\nMISSING classes: {missing}")
    sys.exit(1)
else:
    print("\nAll 7 OWL classes present. Ontology OK.")
