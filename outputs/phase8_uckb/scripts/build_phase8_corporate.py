"""
UCKB Phase 8 — build_phase8_corporate.py
Generates:
  - outputs/phase8_uckb/domains/corporate.ttl  (already created; this regenerates from data)
  - outputs/phase8_uckb/jsonld/corporate.jsonld
"""
import sys
import pathlib
from rdflib import Graph, Namespace, Literal, URIRef
from rdflib.namespace import OWL, RDF, RDFS, XSD

sys.stdout.reconfigure(encoding='utf-8')

UCKB = Namespace("https://uckb.io/ontology#")
BASE_DIR = pathlib.Path(__file__).resolve().parents[2]
OUT_TTL    = BASE_DIR / "domains" / "corporate.ttl"
OUT_JSONLD = BASE_DIR / "jsonld" / "corporate.jsonld"

COMM_STYLES = [
    {"id": "corp_style_radical_candor",         "label": "Radical Candor",
     "dim1": "care_personally:HIGH",  "dim2": "challenge_directly:HIGH",  "target": True},
    {"id": "corp_style_obnoxious_aggression",    "label": "Obnoxious Aggression",
     "dim1": "care_personally:LOW",   "dim2": "challenge_directly:HIGH",  "target": False,
     "detectionSignals": "contempt_marker; blaming_language"},
    {"id": "corp_style_ruinous_empathy",         "label": "Ruinous Empathy",
     "dim1": "care_personally:HIGH",  "dim2": "challenge_directly:LOW",   "target": False,
     "detectionSignals": "avoidance_substantive_critique; excessive_hedging"},
    {"id": "corp_style_manipulative_insincerity","label": "Manipulative Insincerity",
     "dim1": "care_personally:LOW",   "dim2": "challenge_directly:LOW",   "target": False,
     "detectionSignals": "passive_aggressive_markers; indirect_critique"},
]

TECHNIQUES = [
    {"id": "corp_001_sbi_situation",    "label": "SBI Situation",    "tier": "Tier 1", "cognitiveLoad": "low-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "First step of SBI: state specific observable situation without evaluation.",
     "steps": "State: In [specific situation]...",
     "sourceIds": "CCL_SBI; ScottRadicalCandor",
     "peaceStep": "none",
     "precedes": ["corp_002_sbi_behavior"]},
    {"id": "corp_002_sbi_behavior",     "label": "SBI Behavior",     "tier": "Tier 1", "cognitiveLoad": "low-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Second step of SBI: describe specific observable behavior without interpretation.",
     "steps": "State: ...you [specific observable action]...",
     "sourceIds": "CCL_SBI; ScottRadicalCandor",
     "peaceStep": "none",
     "follows": ["corp_001_sbi_situation"],
     "precedes": ["corp_003_sbi_impact"],
     "contraindications_when": ["corp_emo_personality_attack_risk"]},
    {"id": "corp_003_sbi_impact",       "label": "SBI Impact",       "tier": "Tier 1", "cognitiveLoad": "low-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Third step of SBI: describe specific impact on self, team, or work.",
     "steps": "State: ...and the impact was [effect].",
     "sourceIds": "CCL_SBI; ScottRadicalCandor",
     "peaceStep": "none",
     "follows": ["corp_002_sbi_behavior"]},
    {"id": "corp_004_radical_candor_delivery", "label": "Radical Candor Delivery", "tier": "Tier 1", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Full RC feedback: personal care plus direct SBI challenge in private channel.",
     "steps": "1) Private channel; 2) Check safety; 3) SBI; 4) Listen; 5) Next step.",
     "sourceIds": "ScottRadicalCandor2017",
     "peaceStep": "none",
     "requires": ["corp_019_psychological_safety_check", "corp_001_sbi_situation"]},
    {"id": "corp_005_private_channel_enforcement", "label": "Private Channel Enforcement", "tier": "Tier 1", "cognitiveLoad": "lowest-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Ensures critique is delivered in private channel only.",
     "steps": "Confirm channel is private before delivering critique. If not, defer.",
     "sourceIds": "ScottRadicalCandor2017",
     "peaceStep": "none",
     "reviewNotes": "Only corporate technique with environmental constraint, not emotional-state constraint.",
     "contraindications_when": ["corp_emo_public_setting"]},
    {"id": "corp_006_immediate_feedback", "label": "Immediate Feedback", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Feedback within 48-hour window while specific detail remains fresh.",
     "steps": "After observing behavior: wait for calm; find private channel; deliver within 48h.",
     "sourceIds": "ScottRadicalCandor2017; CCL_SBI",
     "peaceStep": "none",
     "contraindications_when": ["corp_emo_high_arousal"]},
    {"id": "corp_009_nvc_observation", "label": "NVC Observation", "tier": "Tier 1", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "First step of NVC: state specific observable fact, free from evaluation.",
     "steps": "State: When [I see/hear] [specific observable fact]...",
     "sourceIds": "Rosenberg2003NVC",
     "peaceStep": "none",
     "precedes": ["corp_010_nvc_feeling"],
     "contradicts": ["corp_emo_interpretation_as_fact"]},
    {"id": "corp_010_nvc_feeling", "label": "NVC Feeling", "tier": "Tier 1", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Second step of NVC: name the feeling using emotion vocabulary.",
     "steps": "State: ...I feel [emotion word]...",
     "sourceIds": "Rosenberg2003NVC",
     "peaceStep": "none",
     "follows": ["corp_009_nvc_observation"],
     "precedes": ["corp_011_nvc_need"]},
    {"id": "corp_011_nvc_need", "label": "NVC Need", "tier": "Tier 1", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Third step of NVC: articulate underlying universal need, not strategy.",
     "steps": "State: ...because I need [universal need]...",
     "sourceIds": "Rosenberg2003NVC",
     "peaceStep": "none",
     "follows": ["corp_010_nvc_feeling"],
     "precedes": ["corp_012_nvc_request"]},
    {"id": "corp_012_nvc_request", "label": "NVC Request", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Fourth step of NVC: specific positive genuinely-refusable request.",
     "steps": "State: ...would you be willing to [specific positive action]?",
     "sourceIds": "Rosenberg2003NVC",
     "peaceStep": "none",
     "follows": ["corp_011_nvc_need"],
     "contradicts": ["corp_emo_demand"]},
    {"id": "corp_016_winners_triangle_vulnerable", "label": "Winner's Triangle: Vulnerable", "tier": "Tier 2", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Moves Karpman Victim role to adaptive Vulnerable: owns feelings without helplessness.",
     "steps": "Acknowledge real difficulty; separate feelings from helplessness; ask: What is one thing within your control?",
     "sourceIds": "Choy1990WinnersTriangle; Karpman1968",
     "peaceStep": "none"},
    {"id": "corp_017_winners_triangle_assertive", "label": "Winner's Triangle: Assertive", "tier": "Tier 2", "cognitiveLoad": "high-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Moves Karpman Persecutor to adaptive Assertive: direct and clear without contempt.",
     "steps": "Name behavior; state impact; make specific request — without blame or contempt.",
     "sourceIds": "Choy1990WinnersTriangle; Karpman1968",
     "peaceStep": "none"},
    {"id": "corp_018_winners_triangle_caring", "label": "Winner's Triangle: Caring", "tier": "Tier 2", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Moves Karpman Rescuer to adaptive Caring: empowers agency rather than creates dependency.",
     "steps": "Ask: What would be most helpful? Coach rather than rescue.",
     "sourceIds": "Choy1990WinnersTriangle; Karpman1968",
     "peaceStep": "none",
     "contradicts": ["corp_emo_rescuer_enabling"]},
    {"id": "corp_019_psychological_safety_check", "label": "Psychological Safety Check", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Pre-feedback gate assessing whether context has sufficient psychological safety.",
     "steps": "Assess: Can people disagree openly? Do errors get punished? Build safety before feedback if unsure.",
     "sourceIds": "Edmondson1999PsychSafety; ScottRadicalCandor2017",
     "peaceStep": "none"},
    {"id": "corp_020_context_setting_feedback", "label": "Context Setting for Feedback", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Brief framing before SBI establishing developmental intent and care-personally.",
     "steps": "Say: I want to share something because I think it will help. Is now a good time?",
     "sourceIds": "ScottRadicalCandor2017",
     "peaceStep": "none",
     "precedes": ["corp_001_sbi_situation"]},
    {"id": "corp_024_criticism_vs_complaint", "label": "Criticism vs Complaint Distinction", "tier": "Tier 1", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Meta-technique: check whether feedback is criticism (character) or complaint (behavior).",
     "steps": "Test: Remove the behavior — does feedback still claim who person IS? If yes, rewrite as observable behavior.",
     "sourceIds": "Gottman1994WhyMarriages; ScottRadicalCandor2017",
     "peaceStep": "none",
     "contradicts": ["corp_emo_personality_attack_risk"]},
    {"id": "corp_025_360_feedback_framing", "label": "360-Degree Feedback Framing", "tier": "Tier 2", "cognitiveLoad": "medium-load",
     "domain": "Corporate & Engineering", "reviewStatus": "source_checked",
     "description": "Frames feedback as collected from multiple perspectives to reduce single-source attribution.",
     "steps": "Say: I gathered input from several people. The pattern is...",
     "sourceIds": "Bracken1997_360",
     "peaceStep": "none",
     "domain_variant_of": ["Objective_Criteria"]},
]


def build_graph() -> Graph:
    g = Graph()
    g.bind("uckb", UCKB)
    g.bind("owl", OWL)
    g.bind("rdfs", RDFS)
    g.bind("xsd", XSD)

    def prop(node, name, value):
        if value is not None:
            g.add((node, UCKB[name], Literal(str(value))))

    # CommunicationStyle nodes
    for cs in COMM_STYLES:
        node = UCKB[cs["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, UCKB.CommunicationStyle))
        g.add((node, RDFS.label, Literal(cs["label"])))
        prop(node, "cardId", cs["id"])
        prop(node, "classLabel", "CommunicationStyle")
        prop(node, "domain", "Corporate & Engineering")
        prop(node, "dimension1", cs["dim1"])
        prop(node, "dimension2", cs["dim2"])
        g.add((node, UCKB.targetState, Literal(cs["target"], datatype=XSD.boolean)))
        if cs.get("detectionSignals"):
            prop(node, "detectionSignals", cs["detectionSignals"])
        prop(node, "reviewStatus", "source_checked")

    # CommunicationTechnique nodes
    str_fields = [
        "domain", "tier", "reviewStatus", "sourceIds", "description",
        "steps", "reviewNotes", "peaceStep",
    ]
    rel_map = {
        "precedes": "PRECEDES", "follows": "FOLLOWS", "requires": "REQUIRES",
        "enhances": "ENHANCES", "contradicts": "CONTRADICTS",
        "domain_variant_of": "DOMAIN_VARIANT_OF",
    }
    contraindicated_reason = "Corporate technique contraindicated in this state"

    for card in TECHNIQUES:
        node = UCKB[card["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, UCKB.CommunicationTechnique))
        g.add((node, RDFS.label, Literal(card["label"])))
        prop(node, "cardId", card["id"])
        prop(node, "classLabel", "CommunicationTechnique")
        prop(node, "cognitiveLoadProfile", card.get("cognitiveLoad"))
        prop(node, "name", card["label"])
        for f in str_fields:
            if f in card:
                prop(node, f, card[f])
        for rel_key, rel_uri in rel_map.items():
            for tgt in card.get(rel_key, []):
                g.add((node, UCKB[rel_uri], UCKB[tgt]))
        for cw in card.get("contraindications_when", []):
            g.add((node, UCKB.CONTRAINDICATED_WHEN, UCKB[cw]))

    return g


def main():
    print("Building corporate domain graph...")
    g = build_graph()
    OUT_TTL.parent.mkdir(parents=True, exist_ok=True)
    g.serialize(destination=str(OUT_TTL), format="turtle")
    print(f"  Written: {OUT_TTL}")
    OUT_JSONLD.parent.mkdir(parents=True, exist_ok=True)
    g.serialize(destination=str(OUT_JSONLD), format="json-ld")
    print(f"  Written: {OUT_JSONLD}")
    print(f"  Techniques: {len(TECHNIQUES)}, CommunicationStyles: {len(COMM_STYLES)}")
    print("Corporate build complete.")


if __name__ == "__main__":
    main()
