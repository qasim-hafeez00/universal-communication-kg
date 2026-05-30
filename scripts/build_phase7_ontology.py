"""
UCKB Phase 7 — Ontology Builder
Generates 4 OWL/Turtle + JSON-LD files for cross-cultural and behavioral style layers.
No Neo4j dependency — pure rdflib.

Output (outputs/phase7_uckb/ontology/):
  cultural-profiles.ttl / .jsonld
  behavioral-styles-p7.ttl / .jsonld
"""

import json
from pathlib import Path
from rdflib import Graph, Namespace, URIRef, Literal, RDF, RDFS, OWL, XSD

ROOT   = Path(__file__).resolve().parent.parent
OUTDIR = ROOT / "outputs" / "phase7_uckb" / "ontology"
OUTDIR.mkdir(parents=True, exist_ok=True)

UCKB = Namespace("https://uckb.io/ontology#")
CC   = Namespace("https://uckb.io/ontology/crosscultural#")

# ─────────────────────────────────────────────────────────────────────────────
# Helper
# ─────────────────────────────────────────────────────────────────────────────

def new_graph() -> Graph:
    g = Graph()
    g.bind("uckb", UCKB)
    g.bind("cc",   CC)
    g.bind("owl",  OWL)
    g.bind("rdfs", RDFS)
    g.bind("xsd",  XSD)
    return g


def add_class(g: Graph, cls_uri: URIRef, label: str, parent: URIRef = None, comment: str = ""):
    g.add((cls_uri, RDF.type, OWL.Class))
    g.add((cls_uri, RDFS.label, Literal(label)))
    if parent:
        g.add((cls_uri, RDFS.subClassOf, parent))
    if comment:
        g.add((cls_uri, RDFS.comment, Literal(comment)))


def add_individual(g: Graph, ind_uri: URIRef, cls_uri: URIRef, label: str, props: dict):
    g.add((ind_uri, RDF.type, OWL.NamedIndividual))
    g.add((ind_uri, RDF.type, cls_uri))
    g.add((ind_uri, RDFS.label, Literal(label)))
    for pred_local, val in props.items():
        pred = CC[pred_local] if not pred_local.startswith("http") else URIRef(pred_local)
        if isinstance(val, bool):
            g.add((ind_uri, pred, Literal(val, datatype=XSD.boolean)))
        elif isinstance(val, int):
            g.add((ind_uri, pred, Literal(val, datatype=XSD.integer)))
        elif isinstance(val, float):
            g.add((ind_uri, pred, Literal(val, datatype=XSD.decimal)))
        elif isinstance(val, list):
            g.add((ind_uri, pred, Literal(", ".join(str(v) for v in val))))
        else:
            g.add((ind_uri, pred, Literal(str(val))))


def save(g: Graph, stem: str):
    ttl_path  = OUTDIR / f"{stem}.ttl"
    jsonld_path = OUTDIR / f"{stem}.jsonld"
    g.serialize(destination=str(ttl_path),    format="turtle")
    g.serialize(destination=str(jsonld_path), format="json-ld", indent=2)
    print(f"  Wrote {ttl_path.name} ({ttl_path.stat().st_size:,} bytes)")
    print(f"  Wrote {jsonld_path.name} ({jsonld_path.stat().st_size:,} bytes)")


# ─────────────────────────────────────────────────────────────────────────────
# Object / Datatype properties
# ─────────────────────────────────────────────────────────────────────────────

OBJECT_PROPS = [
    ("hasDimension",   "Links CulturalProfile to a CulturalContext dimensional descriptor"),
    ("appliesRule",    "Links CulturalProfile/CulturalContext to a CulturalAdaptationRule"),
    ("styleSuggests",  "Links BehavioralStyleProfile to a recommended Technique"),
    ("adaptsFor",      "Links a Technique to the CulturalContext it is preferred in"),
    ("recalibrateIn",  "Nonverbal signal meaning must be reinterpreted in this CulturalContext"),
    ("prefersStyle",   "CulturalContext dimensional node predicts this CommunicationStyle"),
]

DATATYPE_PROPS = [
    ("hofstedePDI",          XSD.integer, "Hofstede Power Distance Index (0-100)"),
    ("hofstedeIDV",          XSD.integer, "Hofstede Individualism score (0-100)"),
    ("hofstedeMAS",          XSD.integer, "Hofstede Masculinity score (0-100)"),
    ("hofstedeUAI",          XSD.integer, "Hofstede Uncertainty Avoidance Index (0-100)"),
    ("hofstedeLTO",          XSD.integer, "Hofstede Long-Term Orientation (0-100)"),
    ("hofstedeIVR",          XSD.integer, "Hofstede Indulgence score (0-100)"),
    ("hallContextLevel",     XSD.string,  "Hall's context level: 'high' or 'low'"),
    ("lewisModel",           XSD.string,  "Lewis model type: linear-active|multi-active|reactive"),
    ("timeOrientation",      XSD.string,  "monochronic or polychronic"),
    ("faceSaving",           XSD.boolean, "Whether face-saving is a primary cultural driver"),
    ("indirectCommunication",XSD.boolean, "Whether indirect communication is the norm"),
    ("agentBehavior",        XSD.string,  "Prescribed agent behavior when rule activates"),
    ("trigger",              XSD.string,  "Cultural dimension(s) or event that activates this rule"),
    ("primaryStyle",         XSD.string,  "CommunicationStyle name this profile represents"),
    ("agentAdaptation",      XSD.string,  "Agent response strategy when this style is detected"),
    ("preferredEvidence",    XSD.string,  "emotional | factual | mixed"),
]


def build_property_declarations(g: Graph):
    for local, comment in OBJECT_PROPS:
        uri = CC[local]
        g.add((uri, RDF.type, OWL.ObjectProperty))
        g.add((uri, RDFS.comment, Literal(comment)))

    for local, dtype, comment in DATATYPE_PROPS:
        uri = CC[local]
        g.add((uri, RDF.type, OWL.DatatypeProperty))
        g.add((uri, RDFS.range, dtype))
        g.add((uri, RDFS.comment, Literal(comment)))


# ─────────────────────────────────────────────────────────────────────────────
# cultural-profiles.ttl
# ─────────────────────────────────────────────────────────────────────────────

CULTURAL_PROFILES = [
    {
        "id": "CultureJapan", "name": "Japan",
        "regions": ["East Asia", "Japan"],
        "lewisModel": "reactive", "hallContextLevel": "high",
        "PDI": 54, "IDV": 46, "MAS": 95, "UAI": 92, "LTO": 88, "IVR": 42,
        "timeOrientation": "polychronic", "faceSaving": True, "indirectCommunication": True,
    },
    {
        "id": "CultureUSA", "name": "USA Mainstream",
        "regions": ["North America", "United States"],
        "lewisModel": "linear-active", "hallContextLevel": "low",
        "PDI": 40, "IDV": 91, "MAS": 62, "UAI": 46, "LTO": 26, "IVR": 68,
        "timeOrientation": "monochronic", "faceSaving": False, "indirectCommunication": False,
    },
    {
        "id": "CultureGermany", "name": "Germany",
        "regions": ["Western Europe", "Germany", "Austria", "Switzerland"],
        "lewisModel": "linear-active", "hallContextLevel": "low",
        "PDI": 35, "IDV": 67, "MAS": 66, "UAI": 65, "LTO": 83, "IVR": 40,
        "timeOrientation": "monochronic", "faceSaving": False, "indirectCommunication": False,
    },
    {
        "id": "CultureArabWorld", "name": "Arab World",
        "regions": ["Middle East", "North Africa", "Gulf States"],
        "lewisModel": "multi-active", "hallContextLevel": "high",
        "PDI": 80, "IDV": 38, "MAS": 53, "UAI": 68, "LTO": 23, "IVR": 34,
        "timeOrientation": "polychronic", "faceSaving": True, "indirectCommunication": True,
    },
    {
        "id": "CultureNordic", "name": "Nordic Countries",
        "regions": ["Scandinavia", "Sweden", "Norway", "Denmark", "Finland"],
        "lewisModel": "linear-active", "hallContextLevel": "low",
        "PDI": 31, "IDV": 74, "MAS": 16, "UAI": 29, "LTO": 35, "IVR": 55,
        "timeOrientation": "monochronic", "faceSaving": False, "indirectCommunication": False,
    },
    {
        "id": "CultureLatinAmerica", "name": "Latin America",
        "regions": ["South America", "Central America", "Mexico", "Caribbean"],
        "lewisModel": "multi-active", "hallContextLevel": "high",
        "PDI": 70, "IDV": 21, "MAS": 49, "UAI": 76, "LTO": 30, "IVR": 76,
        "timeOrientation": "polychronic", "faceSaving": True, "indirectCommunication": True,
    },
    {
        "id": "CultureIndia", "name": "India",
        "regions": ["South Asia", "India", "Pakistan", "Bangladesh", "Sri Lanka"],
        "lewisModel": "multi-active", "hallContextLevel": "high",
        "PDI": 77, "IDV": 48, "MAS": 56, "UAI": 40, "LTO": 51, "IVR": 26,
        "timeOrientation": "polychronic", "faceSaving": True, "indirectCommunication": True,
    },
    {
        "id": "CultureChina", "name": "China",
        "regions": ["East Asia", "China", "Taiwan", "Singapore"],
        "lewisModel": "reactive", "hallContextLevel": "high",
        "PDI": 80, "IDV": 20, "MAS": 66, "UAI": 30, "LTO": 87, "IVR": 24,
        "timeOrientation": "polychronic", "faceSaving": True, "indirectCommunication": True,
    },
    {
        "id": "CultureUK", "name": "UK Mainstream",
        "regions": ["Western Europe", "United Kingdom", "Ireland"],
        "lewisModel": "linear-active", "hallContextLevel": "low",
        "PDI": 35, "IDV": 89, "MAS": 66, "UAI": 35, "LTO": 51, "IVR": 69,
        "timeOrientation": "monochronic", "faceSaving": False, "indirectCommunication": False,
    },
    {
        "id": "CultureEastAfrica", "name": "East Africa",
        "regions": ["Sub-Saharan Africa", "Kenya", "Tanzania", "Uganda", "Ethiopia"],
        "lewisModel": "multi-active", "hallContextLevel": "high",
        "PDI": 64, "IDV": 27, "MAS": 41, "UAI": 52, "LTO": 32, "IVR": 40,
        "timeOrientation": "polychronic", "faceSaving": True, "indirectCommunication": True,
    },
]


def build_cultural_profiles_graph() -> Graph:
    g = new_graph()
    build_property_declarations(g)

    add_class(g, CC.CulturalProfile, "Cultural Profile",
              parent=UCKB.PsychologicalConstruct,
              comment="A named regional or national cultural cluster aggregating Hofstede dimensional scores and communication style descriptors.")
    add_class(g, CC.CulturalAdaptationRule, "Cultural Adaptation Rule",
              parent=UCKB.PsychologicalConstruct,
              comment="A specific behavioral change the agent applies when interacting within a given cultural context.")

    for p in CULTURAL_PROFILES:
        uri = CC[p["id"]]
        add_individual(g, uri, CC.CulturalProfile, p["name"], {
            "lewisModel":            p["lewisModel"],
            "hallContextLevel":      p["hallContextLevel"],
            "hofstedePDI":           p["PDI"],
            "hofstedeIDV":           p["IDV"],
            "hofstedeMAS":           p["MAS"],
            "hofstedeUAI":           p["UAI"],
            "hofstedeLTO":           p["LTO"],
            "hofstedeIVR":           p["IVR"],
            "timeOrientation":       p["timeOrientation"],
            "faceSaving":            p["faceSaving"],
            "indirectCommunication": p["indirectCommunication"],
            "geographicRegions":     p["regions"],
            "createdInPhase":        7,
        })

    print(f"\ncultural-profiles.ttl: {len(CULTURAL_PROFILES)} CulturalProfile individuals")
    return g


# ─────────────────────────────────────────────────────────────────────────────
# behavioral-styles-p7.ttl
# ─────────────────────────────────────────────────────────────────────────────

BEHAVIORAL_STYLE_PROFILES = [
    {
        "id": "BspAssertive", "name": "Assertive Profile",
        "primaryStyle": "Assertive",
        "agentAdaptation": "Match directness with mutual respect; collaborative problem-solving; affirm interests before positions",
        "preferredEvidence": "mixed",
        "contraindicated": ["emotional_manipulation", "avoidance"],
        "detectionSignals": ["direct statements", "I-statements", "clear boundary language"],
    },
    {
        "id": "BspPassive", "name": "Passive Profile",
        "primaryStyle": "Passive",
        "agentAdaptation": "Proactively elicit opinions; create psychological safety; use open questions not closed; do not press for immediate decisions",
        "preferredEvidence": "emotional",
        "contraindicated": ["pressure_tactics", "confrontation", "direct_challenge"],
        "detectionSignals": ["self-minimising language", "hedging", "apology markers", "Adapted Child Marker"],
    },
    {
        "id": "BspAggressive", "name": "Aggressive Profile",
        "primaryStyle": "Aggressive",
        "agentAdaptation": "Deploy firm Adult boundaries; refuse to match aggression; redirect to objective data; mirror Critical Parent with calm Adult state",
        "preferredEvidence": "factual",
        "contraindicated": ["emotional_appeals", "capitulation", "counter_aggression"],
        "detectionSignals": ["accusatory you-statements", "interruption pattern", "volume spike", "Critical Parent Marker"],
    },
    {
        "id": "BspPassiveAggressive", "name": "Passive-Aggressive Profile",
        "primaryStyle": "PassiveAggressive",
        "agentAdaptation": "Ignore sarcasm surface; address literal meaning; force explicit clarity; do not mirror covert hostility",
        "preferredEvidence": "factual",
        "contraindicated": ["emotional_framing", "indirect_implication"],
        "detectionSignals": ["sarcasm markers", "backhanded compliments", "blame_language", "ambivalence"],
    },
    {
        "id": "BspAnalytical", "name": "Analytical Profile",
        "primaryStyle": "Analytical",
        "agentAdaptation": "Disable emotional framing; lead with data, metrics, verifiable evidence; step-by-step logical sequencing",
        "preferredEvidence": "factual",
        "contraindicated": ["emotional_appeals", "ambiguous_framing", "anecdotal_evidence"],
        "detectionSignals": ["data requests", "precision language", "challenge to evidence", "absolutist_language"],
    },
    {
        "id": "BspDiplomatic", "name": "Diplomatic Profile",
        "primaryStyle": "Diplomatic",
        "agentAdaptation": "Synthesize multiple stakeholder positions; integrative summaries; consensus framing; never take sides publicly",
        "preferredEvidence": "mixed",
        "contraindicated": ["blunt_confrontation", "winner_loser_framing"],
        "detectionSignals": ["measured tone", "both-sides language", "consensus seeking"],
    },
    {
        "id": "BspCharismatic", "name": "Charismatic Profile",
        "primaryStyle": "Charismatic",
        "agentAdaptation": "Align with high-level vision; aspirational framing; acknowledge authority with substantive content; leverage social proof",
        "preferredEvidence": "mixed",
        "contraindicated": ["dry_technical_detail", "legalistic_framing"],
        "detectionSignals": ["vision language", "authority claims", "social proof references", "high energy prosodic"],
    },
]


def build_behavioral_styles_graph() -> Graph:
    g = new_graph()
    build_property_declarations(g)

    add_class(g, CC.BehavioralStyleProfile, "Behavioral Style Profile",
              parent=UCKB.PsychologicalConstruct,
              comment="An agent response archetype that maps a detected communication style to prescribed interaction strategies and technique sets.")

    for bsp in BEHAVIORAL_STYLE_PROFILES:
        uri = CC[bsp["id"]]
        add_individual(g, uri, CC.BehavioralStyleProfile, bsp["name"], {
            "primaryStyle":       bsp["primaryStyle"],
            "agentAdaptation":    bsp["agentAdaptation"],
            "preferredEvidence":  bsp["preferredEvidence"],
            "contraindicated":    bsp["contraindicated"],
            "detectionSignals":   bsp["detectionSignals"],
            "createdInPhase":     7,
        })

    print(f"behavioral-styles-p7.ttl: {len(BEHAVIORAL_STYLE_PROFILES)} BehavioralStyleProfile individuals")
    return g


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("UCKB Phase 7 — Ontology Builder")
    print("=" * 50)

    g1 = build_cultural_profiles_graph()
    save(g1, "cultural-profiles")

    g2 = build_behavioral_styles_graph()
    save(g2, "behavioral-styles-p7")

    print("\nDone. 4 ontology files written to outputs/phase7_uckb/ontology/")
