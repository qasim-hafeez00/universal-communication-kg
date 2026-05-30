"""
UCKB Phase 6 — Ontology Builder
Generates OWL/Turtle and JSON-LD files for the Psychological, Multimodal & Non-Verbal Layers.

Outputs (no Neo4j dependency):
  outputs/phase6_uckb/ontology/psychological-models-p6.ttl
  outputs/phase6_uckb/ontology/psychological-models-p6.jsonld
  outputs/phase6_uckb/ontology/nonverbal-layer.ttl
  outputs/phase6_uckb/ontology/nonverbal-layer.jsonld

Usage:
  python scripts/build_phase6_ontology.py
"""

import json
from pathlib import Path
from rdflib import Graph, Namespace, URIRef, Literal, RDF, RDFS, OWL, XSD

ROOT    = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "outputs" / "phase6_uckb" / "ontology"
OUT_DIR.mkdir(parents=True, exist_ok=True)

UCKB = Namespace("https://uckb.io/ontology#")
NV   = Namespace("https://uckb.io/ontology/nonverbal#")

# ─────────────────────────────────────────────────────────────────────────────
# Data definitions
# ─────────────────────────────────────────────────────────────────────────────

EGO_STATES = [
    {
        "id": "ego_adapted_child",
        "name": "Adapted Child",
        "berneCategory": "Child",
        "karpmanRole": "Victim",
        "winnerTriangleTarget": "Vulnerable/Survivor",
        "agentAction": "Encourage explicit need-articulation; do NOT rescue",
        "isDysfunctional": True,
        "linguisticMarkers": [
            "nobody listens to me", "helpless tone",
            "pleading requests", "self-deprecation"
        ],
        "belongsToModels": ["Transactional Analysis", "Karpman Drama Triangle", "Winner's Triangle"],
    },
    {
        "id": "ego_critical_parent",
        "name": "Critical Parent",
        "berneCategory": "Parent",
        "karpmanRole": "Persecutor",
        "winnerTriangleTarget": "Assertive",
        "agentAction": "Mirror Adult state; set objective boundaries; never match aggression",
        "isDysfunctional": True,
        "linguisticMarkers": [
            "it is your fault", "absolutist language",
            "blame statements", "contemptuous FACS"
        ],
        "belongsToModels": ["Transactional Analysis", "Karpman Drama Triangle", "Winner's Triangle"],
    },
    {
        "id": "ego_nurturing_parent",
        "name": "Nurturing Parent",
        "berneCategory": "Parent",
        "karpmanRole": "Rescuer",
        "winnerTriangleTarget": "Caring/Coach",
        "agentAction": "Provide scaffolding; empower the other party to solve their own problem",
        "isDysfunctional": True,
        "linguisticMarkers": [
            "over-helping", "solving others problems unsolicited",
            "condescending care"
        ],
        "belongsToModels": ["Transactional Analysis", "Karpman Drama Triangle", "Winner's Triangle"],
    },
    {
        "id": "ego_adult",
        "name": "Adult",
        "berneCategory": "Adult",
        "karpmanRole": "None",
        "winnerTriangleTarget": "Maintain",
        "agentAction": "Reinforce with collaborative dialogue acts and logical sequencing",
        "isDysfunctional": False,
        "linguisticMarkers": [
            "objective language", "I statements",
            "factual framing", "measured tone"
        ],
        "belongsToModels": ["Transactional Analysis", "Winner's Triangle"],
    },
]

FACS_MAPPINGS = [
    {
        "id": "facs_happiness",
        "emotionLabel": "Happiness",
        "auCombination": "AU6+AU12",
        "auCodes": [6, 12],
        "isMicroexpression": False,
        "durationMs": None,
        "isUnilateral": False,
        "routingAction": "Positive reinforcement; increase complexity; advance to next protocol step",
        "conflictsVerbal": False,
        "indicatesEmotion": "Calm",
    },
    {
        "id": "facs_sadness",
        "emotionLabel": "Sadness",
        "auCombination": "AU1+AU4+AU15",
        "auCodes": [1, 4, 15],
        "isMicroexpression": False,
        "durationMs": None,
        "isUnilateral": False,
        "routingAction": "Empathic pacing; reflective listening; switch to SPIKES Emotion step",
        "conflictsVerbal": False,
        "indicatesEmotion": "Grief",
    },
    {
        "id": "facs_fear",
        "emotionLabel": "Fear",
        "auCombination": "AU1+AU2+AU4+AU5+AU7+AU20+AU26",
        "auCodes": [1, 2, 4, 5, 7, 20, 26],
        "isMicroexpression": False,
        "durationMs": None,
        "isUnilateral": False,
        "routingAction": "Activate de-escalation; prevent confrontational assertions; use BCSM Steps 1-2",
        "conflictsVerbal": False,
        "indicatesEmotion": "Fear",
    },
    {
        "id": "facs_anger",
        "emotionLabel": "Anger",
        "auCombination": "AU4+AU5+AU7+AU23",
        "auCodes": [4, 5, 7, 23],
        "isMicroexpression": False,
        "durationMs": None,
        "isUnilateral": False,
        "routingAction": "Defensive negotiation mode; redirect to Objective Criteria; maintain Adult ego state",
        "conflictsVerbal": True,
        "indicatesEmotion": "Hostile",
    },
    {
        "id": "facs_contempt",
        "emotionLabel": "Contempt",
        "auCombination": "AU12+AU14",
        "auCodes": [12, 14],
        "isMicroexpression": False,
        "durationMs": None,
        "isUnilateral": True,
        "routingAction": "CRITICAL — flag communication breakdown risk; shift to mutual respect restoration protocol",
        "conflictsVerbal": True,
        "indicatesEmotion": "Contemptuous",
    },
    {
        "id": "facs_microexpression",
        "emotionLabel": "Microexpression",
        "auCombination": "any AU <1/15s contradicting baseline",
        "auCodes": [],
        "isMicroexpression": True,
        "durationMs": 67,
        "isUnilateral": False,
        "routingAction": "Flag domain for deeper probing; do NOT confront directly; increase clarification questions",
        "conflictsVerbal": True,
        "indicatesEmotion": "Distress",
    },
]

PROSODIC_FEATURES = [
    {
        "id": "prosodic_pitch",
        "name": "Fundamental Frequency (Pitch)",
        "featureType": "frequency",
        "extractionDomain": "voice-only",
        "highValueMeaning": "anxiety or excitement",
        "lowValueMeaning": "depression or potential deception",
        "threshold": "variance >2 standard deviations from baseline",
        "signalsState": "Fear",
        "modality": "paralinguistic",
    },
    {
        "id": "prosodic_speech_rate",
        "name": "Speech Rate",
        "featureType": "rate",
        "extractionDomain": "voice-only",
        "highValueMeaning": "anxiety escalation",
        "lowValueMeaning": "cognitive overload or dissociation",
        "threshold": "drop >30% from baseline or rise >50% from baseline",
        "signalsState": "Dissociated",
        "modality": "paralinguistic",
    },
    {
        "id": "prosodic_energy",
        "name": "Speech Energy (Amplitude)",
        "featureType": "energy",
        "extractionDomain": "multimodal",
        "highValueMeaning": "emotional activation and arousal",
        "lowValueMeaning": "suppression or withdrawal",
        "threshold": "spike >10dB above baseline",
        "signalsState": "Hostile",
        "modality": "paralinguistic",
    },
    {
        "id": "prosodic_voice_quality",
        "name": "Voice Quality",
        "featureType": "quality",
        "extractionDomain": "voice-only",
        "highValueMeaning": "elevated arousal state (breathiness, tremor)",
        "lowValueMeaning": "calm or neutral baseline",
        "threshold": "tremor or creak detected above baseline variability",
        "signalsState": "Distress",
        "modality": "paralinguistic",
    },
    {
        "id": "prosodic_pause_duration",
        "name": "Pause Duration",
        "featureType": "duration",
        "extractionDomain": "voice-only",
        "highValueMeaning": "deception processing or trauma recall",
        "lowValueMeaning": "fluency and cognitive engagement",
        "threshold": ">400ms before answering a direct question",
        "signalsState": "Distress",
        "modality": "paralinguistic",
    },
    {
        "id": "prosodic_filler_frequency",
        "name": "Filler Word Frequency",
        "featureType": "count",
        "extractionDomain": "voice-only",
        "highValueMeaning": "working memory load or potential falsehood or confusion",
        "lowValueMeaning": "cognitive fluency",
        "threshold": ">2x baseline filler rate (um, uh, like)",
        "signalsState": "Cognitive Overload",
        "modality": "paralinguistic",
    },
]

BEHAVIORAL_ADAPTORS = [
    {
        "id": "adaptor_self",
        "name": "Self-Adaptor",
        "adaptorType": "self",
        "description": "Face touching, neck rubbing, hair manipulation — subconscious ANS arousal responses",
        "arousalSignal": "ANS arousal and elevated stress",
        "routingAction": "Activate grounding or de-escalation technique; slow interaction pace",
        "requiresCulturalCalibration": False,
        "modality": "kinesic",
        "indicatesEmotions": ["Distress", "Overwhelmed"],
    },
    {
        "id": "adaptor_object",
        "name": "Object-Adaptor",
        "adaptorType": "object",
        "description": "Pen clicking, phone manipulation, object fidgeting",
        "arousalSignal": "Boredom or anxiety",
        "routingAction": "Check engagement level; increase interactivity or topic relevance",
        "requiresCulturalCalibration": False,
        "modality": "kinesic",
        "indicatesEmotions": ["Ambivalent"],
    },
    {
        "id": "adaptor_emblem",
        "name": "Emblem Gesture",
        "adaptorType": "emblem",
        "description": "Deliberate culturally-specific gestures with precise semantic translations (thumbs up, head shake)",
        "arousalSignal": "Direct communicative intent — requires cultural calibration before interpretation",
        "routingAction": "Route to cultural calibration check before interpreting; flag for Phase 7 cross-cultural layer",
        "requiresCulturalCalibration": True,
        "modality": "kinesic",
        "indicatesEmotions": [],
    },
    {
        "id": "adaptor_illustrator",
        "name": "Illustrator Gesture",
        "adaptorType": "illustrator",
        "description": "Involuntary hand movements tracking verbal rhythm; rate correlates with cognitive fluency",
        "arousalSignal": "High rate = fluency and engagement; low rate = stress or rehearsed deception",
        "routingAction": "Low rate: flag for deception probe or distress check; high rate: advance interaction",
        "requiresCulturalCalibration": False,
        "modality": "kinesic",
        "indicatesEmotions": ["Distress"],
    },
]

MODALITY_WEIGHTS = [
    {
        "id": "modality_semantic",
        "name": "Semantic Content",
        "modalityType": "semantic",
        "weight": 0.07,
        "priority": 3,
        "description": "The words themselves — lowest priority in affective conflicts",
        "applyDomain": "affective",
    },
    {
        "id": "modality_paralinguistic",
        "name": "Paralinguistics",
        "modalityType": "paralinguistic",
        "weight": 0.38,
        "description": "Tone, pitch, speed, volume — overrides semantic content when incongruent",
        "priority": 2,
        "applyDomain": "affective",
    },
    {
        "id": "modality_kinesic",
        "name": "Kinesics / Facial Expressions",
        "modalityType": "kinesic",
        "weight": 0.55,
        "description": "Facial expressions and body language — highest priority in affective conflicts",
        "priority": 1,
        "applyDomain": "affective",
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# Build psychological-models-p6 ontology
# ─────────────────────────────────────────────────────────────────────────────

def build_psych_models_ontology() -> Graph:
    g = Graph()
    g.bind("uckb",  UCKB)
    g.bind("nv",    NV)
    g.bind("owl",   OWL)
    g.bind("rdfs",  RDFS)
    g.bind("xsd",   XSD)

    # Ontology declaration
    onto = URIRef("https://uckb.io/ontology/psychological-models-p6")
    g.add((onto, RDF.type, OWL.Ontology))
    g.add((onto, RDFS.label, Literal("UCKB Phase 6 — Psychological Models Extension", lang="en")))
    g.add((onto, RDFS.comment, Literal(
        "Extends UCKB Phase 3 ontology with TA ego states, Karpman/Winner mapping, "
        "and FACS emotion classification nodes.", lang="en")))

    # Parent class
    PsychConst = UCKB.PsychologicalConstruct
    g.add((PsychConst, RDF.type, OWL.Class))
    g.add((PsychConst, RDFS.label, Literal("PsychologicalConstruct", lang="en")))

    # EgoState class
    EgoStateClass = UCKB.EgoState
    g.add((EgoStateClass, RDF.type, OWL.Class))
    g.add((EgoStateClass, RDFS.subClassOf, PsychConst))
    g.add((EgoStateClass, RDFS.label, Literal("EgoState", lang="en")))
    g.add((EgoStateClass, RDFS.comment, Literal(
        "Transactional Analysis ego state (Berne 1961). One of: Adapted Child, Critical Parent, "
        "Nurturing Parent, Adult.", lang="en")))

    # Datatype properties for EgoState
    for prop, range_type, comment in [
        ("berneCategory",        XSD.string,  "Berne category: Parent, Adult, or Child"),
        ("karpmanRole",          XSD.string,  "Role in Karpman Drama Triangle"),
        ("winnerTriangleTarget", XSD.string,  "Target state in Winner's Triangle"),
        ("agentAction",          XSD.string,  "Prescribed agent action when this ego state is detected"),
        ("isDysfunctional",      XSD.boolean, "True for Child and Parent states; False for Adult"),
    ]:
        p = UCKB[prop]
        g.add((p, RDF.type, OWL.DatatypeProperty))
        g.add((p, RDFS.domain, EgoStateClass))
        g.add((p, RDFS.range, range_type))
        g.add((p, RDFS.label, Literal(prop, lang="en")))
        g.add((p, RDFS.comment, Literal(comment, lang="en")))

    # EgoState individuals
    for ego in EGO_STATES:
        node = UCKB[ego["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, EgoStateClass))
        g.add((node, RDFS.label, Literal(ego["name"], lang="en")))
        g.add((node, UCKB.berneCategory, Literal(ego["berneCategory"])))
        g.add((node, UCKB.karpmanRole, Literal(ego["karpmanRole"])))
        g.add((node, UCKB.winnerTriangleTarget, Literal(ego["winnerTriangleTarget"])))
        g.add((node, UCKB.agentAction, Literal(ego["agentAction"])))
        g.add((node, UCKB.isDysfunctional, Literal(ego["isDysfunctional"])))
        for marker in ego["linguisticMarkers"]:
            g.add((node, UCKB.linguisticMarker, Literal(marker)))

    # Object property: belongsToModel
    bToModel = UCKB.belongsToModel
    g.add((bToModel, RDF.type, OWL.ObjectProperty))
    g.add((bToModel, RDFS.domain, EgoStateClass))
    g.add((bToModel, RDFS.label, Literal("belongsToModel", lang="en")))
    g.add((bToModel, RDFS.comment, Literal(
        "Relates an EgoState to its parent psychological model (TA, Karpman, Winner's Triangle)", lang="en")))

    return g


# ─────────────────────────────────────────────────────────────────────────────
# Build nonverbal-layer ontology
# ─────────────────────────────────────────────────────────────────────────────

def build_nonverbal_ontology() -> Graph:
    g = Graph()
    g.bind("uckb", UCKB)
    g.bind("nv",   NV)
    g.bind("owl",  OWL)
    g.bind("rdfs", RDFS)
    g.bind("xsd",  XSD)

    onto = URIRef("https://uckb.io/ontology/nonverbal-layer")
    g.add((onto, RDF.type, OWL.Ontology))
    g.add((onto, RDFS.label, Literal("UCKB Phase 6 — Non-Verbal & Multimodal Layer", lang="en")))
    g.add((onto, RDFS.comment, Literal(
        "FACS facial action unit mappings, prosodic voice features, behavioral adaptors, "
        "and Mehrabian modality weights.", lang="en")))

    PsychConst = UCKB.PsychologicalConstruct
    g.add((PsychConst, RDF.type, OWL.Class))

    # ── FacsMapping ───────────────────────────────────────────────────────────
    FacsClass = NV.FacsMapping
    g.add((FacsClass, RDF.type, OWL.Class))
    g.add((FacsClass, RDFS.subClassOf, PsychConst))
    g.add((FacsClass, RDFS.label, Literal("FacsMapping", lang="en")))
    g.add((FacsClass, RDFS.comment, Literal(
        "FACS Action Unit combination mapped to an emotion and graph routing action.", lang="en")))

    for prop, range_type, comment in [
        ("emotionLabel",      XSD.string,  "Human-readable emotion name"),
        ("auCombination",     XSD.string,  "AU code string, e.g. AU6+AU12"),
        ("isMicroexpression", XSD.boolean, "True when duration < 1/15 second"),
        ("durationMs",        XSD.integer, "Duration in ms; null for non-micro"),
        ("isUnilateral",      XSD.boolean, "True for contempt (shown on one side of face only)"),
        ("routingAction",     XSD.string,  "Agent routing instruction when this FACS pattern is detected"),
        ("conflictsVerbal",   XSD.boolean, "True when FACS signal typically contradicts verbal content"),
    ]:
        p = NV[prop]
        g.add((p, RDF.type, OWL.DatatypeProperty))
        g.add((p, RDFS.domain, FacsClass))
        g.add((p, RDFS.range, range_type))
        g.add((p, RDFS.label, Literal(prop, lang="en")))
        g.add((p, RDFS.comment, Literal(comment, lang="en")))

    indicatesEmotion = NV.indicatesEmotion
    g.add((indicatesEmotion, RDF.type, OWL.ObjectProperty))
    g.add((indicatesEmotion, RDFS.label, Literal("indicatesEmotion", lang="en")))

    for facs in FACS_MAPPINGS:
        node = NV[facs["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, FacsClass))
        g.add((node, RDFS.label, Literal(f"FACS — {facs['emotionLabel']}", lang="en")))
        g.add((node, NV.emotionLabel, Literal(facs["emotionLabel"])))
        g.add((node, NV.auCombination, Literal(facs["auCombination"])))
        g.add((node, NV.isMicroexpression, Literal(facs["isMicroexpression"])))
        g.add((node, NV.isUnilateral, Literal(facs["isUnilateral"])))
        g.add((node, NV.routingAction, Literal(facs["routingAction"])))
        g.add((node, NV.conflictsVerbal, Literal(facs["conflictsVerbal"])))
        if facs["durationMs"] is not None:
            g.add((node, NV.durationMs, Literal(facs["durationMs"], datatype=XSD.integer)))
        for au in facs["auCodes"]:
            g.add((node, NV.auCode, Literal(au, datatype=XSD.integer)))

    # ── ProsodicFeature ───────────────────────────────────────────────────────
    ProsodicClass = NV.ProsodicFeature
    g.add((ProsodicClass, RDF.type, OWL.Class))
    g.add((ProsodicClass, RDFS.subClassOf, PsychConst))
    g.add((ProsodicClass, RDFS.label, Literal("ProsodicFeature", lang="en")))
    g.add((ProsodicClass, RDFS.comment, Literal(
        "Voice channel signal feature used for emotional state detection in voice-only agents.", lang="en")))

    for prop, range_type, comment in [
        ("featureType",      XSD.string, "Type: frequency, rate, energy, quality, duration, count"),
        ("extractionDomain", XSD.string, "voice-only or multimodal"),
        ("highValueMeaning", XSD.string, "Interpretation when feature value is above threshold"),
        ("lowValueMeaning",  XSD.string, "Interpretation when feature value is below threshold"),
        ("threshold",        XSD.string, "Decision boundary expression"),
        ("signalsState",     XSD.string, "EmotionalState name signalled at threshold"),
    ]:
        p = NV[prop]
        g.add((p, RDF.type, OWL.DatatypeProperty))
        g.add((p, RDFS.domain, ProsodicClass))
        g.add((p, RDFS.range, range_type))
        g.add((p, RDFS.label, Literal(prop, lang="en")))
        g.add((p, RDFS.comment, Literal(comment, lang="en")))

    for feat in PROSODIC_FEATURES:
        node = NV[feat["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, ProsodicClass))
        g.add((node, RDFS.label, Literal(feat["name"], lang="en")))
        g.add((node, NV.featureType, Literal(feat["featureType"])))
        g.add((node, NV.extractionDomain, Literal(feat["extractionDomain"])))
        g.add((node, NV.highValueMeaning, Literal(feat["highValueMeaning"])))
        g.add((node, NV.lowValueMeaning, Literal(feat["lowValueMeaning"])))
        g.add((node, NV.threshold, Literal(feat["threshold"])))
        g.add((node, NV.signalsState, Literal(feat["signalsState"])))
        g.add((node, NV.modality, Literal(feat["modality"])))

    # ── BehavioralAdaptor ─────────────────────────────────────────────────────
    AdaptorClass = NV.BehavioralAdaptor
    g.add((AdaptorClass, RDF.type, OWL.Class))
    g.add((AdaptorClass, RDFS.subClassOf, PsychConst))
    g.add((AdaptorClass, RDFS.label, Literal("BehavioralAdaptor", lang="en")))
    g.add((AdaptorClass, RDFS.comment, Literal(
        "Subconscious kinesic behavior triggered by ANS arousal, used in video-enabled interactions.", lang="en")))

    for prop, range_type, comment in [
        ("adaptorType",                XSD.string,  "self, object, emblem, or illustrator"),
        ("arousalSignal",              XSD.string,  "What ANS state this adaptor signals"),
        ("routingAction",              XSD.string,  "Agent routing instruction when this adaptor is detected"),
        ("requiresCulturalCalibration", XSD.boolean, "True for emblems that vary by culture"),
    ]:
        p = NV[prop]
        g.add((p, RDF.type, OWL.DatatypeProperty))
        g.add((p, RDFS.domain, AdaptorClass))
        g.add((p, RDFS.range, range_type))
        g.add((p, RDFS.label, Literal(prop, lang="en")))
        g.add((p, RDFS.comment, Literal(comment, lang="en")))

    for adaptor in BEHAVIORAL_ADAPTORS:
        node = NV[adaptor["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, AdaptorClass))
        g.add((node, RDFS.label, Literal(adaptor["name"], lang="en")))
        g.add((node, RDFS.comment, Literal(adaptor["description"], lang="en")))
        g.add((node, NV.adaptorType, Literal(adaptor["adaptorType"])))
        g.add((node, NV.arousalSignal, Literal(adaptor["arousalSignal"])))
        g.add((node, NV.routingAction, Literal(adaptor["routingAction"])))
        g.add((node, NV.requiresCulturalCalibration, Literal(adaptor["requiresCulturalCalibration"])))
        g.add((node, NV.modality, Literal(adaptor["modality"])))

    # ── ModalityWeight ────────────────────────────────────────────────────────
    ModalityClass = NV.ModalityWeight
    g.add((ModalityClass, RDF.type, OWL.Class))
    g.add((ModalityClass, RDFS.subClassOf, PsychConst))
    g.add((ModalityClass, RDFS.label, Literal("ModalityWeight", lang="en")))
    g.add((ModalityClass, RDFS.comment, Literal(
        "Mehrabian 7-38-55 weighting for conflict resolution when modalities produce "
        "incongruent signals in affective contexts.", lang="en")))

    for prop, range_type, comment in [
        ("modalityType",  XSD.string,  "semantic, paralinguistic, or kinesic"),
        ("weight",        XSD.decimal, "Mehrabian weight (0.07, 0.38, or 0.55)"),
        ("priority",      XSD.integer, "Override priority; 1 = highest (kinesic)"),
        ("applyDomain",   XSD.string,  "Context restriction: affective (not factual) content only"),
    ]:
        p = NV[prop]
        g.add((p, RDF.type, OWL.DatatypeProperty))
        g.add((p, RDFS.domain, ModalityClass))
        g.add((p, RDFS.range, range_type))
        g.add((p, RDFS.label, Literal(prop, lang="en")))
        g.add((p, RDFS.comment, Literal(comment, lang="en")))

    modalityOverrides = NV.modalityOverrides
    g.add((modalityOverrides, RDF.type, OWL.ObjectProperty))
    g.add((modalityOverrides, RDFS.domain, ModalityClass))
    g.add((modalityOverrides, RDFS.range, ModalityClass))
    g.add((modalityOverrides, RDFS.label, Literal("modalityOverrides", lang="en")))
    g.add((modalityOverrides, RDFS.comment, Literal(
        "When modalities are incongruent in affective contexts, the higher-priority modality overrides the lower.", lang="en")))

    for mw in MODALITY_WEIGHTS:
        node = NV[mw["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, ModalityClass))
        g.add((node, RDFS.label, Literal(mw["name"], lang="en")))
        g.add((node, RDFS.comment, Literal(mw["description"], lang="en")))
        g.add((node, NV.modalityType, Literal(mw["modalityType"])))
        g.add((node, NV.weight, Literal(mw["weight"], datatype=XSD.decimal)))
        g.add((node, NV.priority, Literal(mw["priority"], datatype=XSD.integer)))
        g.add((node, NV.applyDomain, Literal(mw["applyDomain"])))

    # modalityOverrides chain (kinesic > paralinguistic > semantic)
    g.add((NV.modality_kinesic, modalityOverrides, NV.modality_semantic))
    g.add((NV.modality_kinesic, modalityOverrides, NV.modality_paralinguistic))
    g.add((NV.modality_paralinguistic, modalityOverrides, NV.modality_semantic))

    return g


def serialize(g: Graph, stem: str):
    ttl_path  = OUT_DIR / f"{stem}.ttl"
    jld_path  = OUT_DIR / f"{stem}.jsonld"
    g.serialize(destination=str(ttl_path),  format="turtle")
    g.serialize(destination=str(jld_path),  format="json-ld", indent=2)
    print(f"  Written: {ttl_path.name}  ({ttl_path.stat().st_size:,} bytes)")
    print(f"  Written: {jld_path.name}  ({jld_path.stat().st_size:,} bytes)")


def main():
    print("UCKB Phase 6 — Ontology Builder")
    print("=" * 50)

    print("\nBuilding psychological-models-p6 ontology...")
    g1 = build_psych_models_ontology()
    serialize(g1, "psychological-models-p6")
    ego_count = sum(1 for _ in g1.subjects(RDF.type, UCKB.EgoState))
    print(f"  EgoState individuals: {ego_count}")

    print("\nBuilding nonverbal-layer ontology...")
    g2 = build_nonverbal_ontology()
    serialize(g2, "nonverbal-layer")
    facs_count     = sum(1 for _ in g2.subjects(RDF.type, NV.FacsMapping))
    prosodic_count = sum(1 for _ in g2.subjects(RDF.type, NV.ProsodicFeature))
    adaptor_count  = sum(1 for _ in g2.subjects(RDF.type, NV.BehavioralAdaptor))
    modality_count = sum(1 for _ in g2.subjects(RDF.type, NV.ModalityWeight))
    print(f"  FacsMapping: {facs_count}, ProsodicFeature: {prosodic_count}, "
          f"BehavioralAdaptor: {adaptor_count}, ModalityWeight: {modality_count}")

    print("\nDone. 4 files written to outputs/phase6_uckb/ontology/")


if __name__ == "__main__":
    main()
