"""
UCKB Phase 8 — build_phase8_legal.py
Reads legal domain card definitions and generates:
  - outputs/phase8_uckb/domains/legal.ttl  (already created; this regenerates from data)
  - outputs/phase8_uckb/jsonld/legal.jsonld
"""
import sys
import json
import pathlib
from rdflib import Graph, Namespace, Literal, URIRef
from rdflib.namespace import OWL, RDF, RDFS, XSD

sys.stdout.reconfigure(encoding='utf-8')

UCKB = Namespace("https://uckb.io/ontology#")
BASE_DIR = pathlib.Path(__file__).resolve().parents[2]
OUT_TTL   = BASE_DIR / "domains" / "legal.ttl"
OUT_JSONLD = BASE_DIR / "jsonld" / "legal.jsonld"

# ── Card data (mirrors legal.ttl) ────────────────────────────
TECHNIQUES = [
    {
        "id": "legal_001_free_narrative_invitation",
        "label": "Free Narrative Invitation",
        "domain": "Legal & Investigative",
        "peaceStep": "Account",
        "tier": "Tier 1",
        "cognitiveLoad": "low-load",
        "reviewStatus": "source_checked",
        "sourceIds": "Fisher1992; Geiselman1985; PEACE2000",
        "description": "Open-ended invitation to produce a free, uninterrupted first-person account in the interviewee's own words.",
        "whenToUse": "Account phase of PEACE; after rapport established.",
        "whenNotToUse": "Interviewee in acute distress requiring medical attention.",
        "steps": "Say: Tell me everything you remember, from the beginning, in your own words. Remain silent; do not interrupt.",
        "successSignals": "Interviewee produces extended unprompted narrative with sensory detail.",
        "failureSignals": "Interviewee stops prematurely; minimal response.",
        "triggerSignals": "account_phase_active; rapport_established",
        "contraindications": "Do not interrupt account phase with clarifying questions.",
        "dialogueActLinks": "Open-Question; Acknowledge; Feedback-Positive",
        "requiredEdges": "PRECEDES Contradiction Challenge; REQUIRES Rapport Through Transparency",
        "domainVariants": "Dispatch Transparency Statement; Clinical Ask-Tell-Ask",
        "precedes": ["legal_007_contradiction_challenge"],
        "requires": ["legal_013_rapport_through_transparency"],
        "domain_variant_of": ["crisis_dispatch_001_active_listening"],
    },
    {
        "id": "legal_002_cognitive_interview",
        "label": "Cognitive Interview",
        "domain": "Legal & Investigative",
        "peaceStep": "Account",
        "tier": "Tier 1",
        "cognitiveLoad": "medium-load",
        "reviewStatus": "source_checked",
        "sourceIds": "Fisher1992; Geiselman1985; Memon1997",
        "description": "Evidence-based memory retrieval: mental reinstatement, report-everything, temporal-order change, perspective change.",
        "whenToUse": "Witness account is sparse; memory retrieval support needed.",
        "whenNotToUse": "Acute PTSD re-experiencing; false memory risk high.",
        "steps": "1) Mental Reinstatement; 2) Report Everything; 3) Change Temporal Order; 4) Change Perspective.",
        "successSignals": "New details emerge; interviewee becomes more fluent.",
        "failureSignals": "Interviewee confused or contradicts earlier account.",
        "triggerSignals": "account_phase_active; sparse_initial_account",
        "contraindications": "Do not use all components simultaneously; sequence them.",
        "dialogueActLinks": "Instruct; Open-Question; Clarify",
        "requiredEdges": "ENHANCES Free Narrative Invitation",
        "domainVariants": "Clinical Complex Reflection",
        "enhances": ["legal_001_free_narrative_invitation"],
        "domain_variant_of": ["crisis_dispatch_001_active_listening"],
    },
    {
        "id": "legal_013_rapport_through_transparency",
        "label": "Rapport Through Transparency",
        "domain": "Legal & Investigative",
        "peaceStep": "Engage and Explain",
        "tier": "Tier 1",
        "cognitiveLoad": "low-load",
        "reviewStatus": "source_checked",
        "sourceIds": "PEACE2000; Gudjonsson2003",
        "description": "Builds rapport through honest explanation of interview purpose, process, and rights — no deceptive framing.",
        "whenToUse": "Always; first technique in any PEACE interview.",
        "whenNotToUse": "Never — transparency is non-optional in PEACE.",
        "steps": "Explain: who you are; why interview is happening; rights; duration.",
        "successSignals": "Interviewee relaxes; asks process questions; engages voluntarily.",
        "failureSignals": "Interviewee expresses distrust; refuses to engage.",
        "triggerSignals": "interview_start; engage_phase_active",
        "contraindications": "Deception by interviewer destroys all subsequent account quality.",
        "dialogueActLinks": "Inform; Instruct; Rapport",
        "requiredEdges": "CONTRADICTS Reid Technique; PART_OF PEACE Engage Step",
        "domainVariants": "Dispatch Transparency Statement; Clinical Consent Explanation",
        "contradicts": ["legal_contraindicated_reid"],
    },
    {
        "id": "legal_contraindicated_reid",
        "label": "Reid Technique (CONTRAINDICATED)",
        "domain": "Legal & Investigative",
        "peaceStep": "none",
        "tier": "BLOCKED",
        "cognitiveLoad": "N/A",
        "reviewStatus": "source_checked",
        "sourceIds": "Leo2008; Kassin2012; Gudjonsson2003",
        "description": "Confrontational accusation-based interrogation. NEVER to be used.",
        "whenToUse": "NEVER",
        "whenNotToUse": "ALWAYS",
        "steps": "N/A — activation blocked.",
        "successSignals": "N/A",
        "failureSignals": "N/A",
        "triggerSignals": "NONE",
        "contraindications": "ABSOLUTE CONTRAINDICATION",
        "activation_blocked": True,
        "absolute_contraindication": True,
        "rationale": "Leo 2008 (false confessions); Kassin 2012 (DNA exonerations); Gudjonsson 2003.",
    },
]

STATEMENT_MARKERS = [
    {"id": "sa_001_verb_tense_shift", "label": "Verb Tense Shift",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.65",
     "linguisticMarker": "past-tense narrative interrupted by present-tense verb",
     "signalMeaning": "Re-experiencing OR rehearsed account construction."},
    {"id": "sa_002_pronoun_change", "label": "Pronoun Change",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.60",
     "linguisticMarker": "I -> we pronoun shift without referent introduction",
     "signalMeaning": "Distancing from personal ownership."},
    {"id": "sa_003_missing_sequence", "label": "Missing Sequence",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.70",
     "linguisticMarker": "and then later...; the next thing I remember...",
     "signalMeaning": "Omission around legally relevant period."},
    {"id": "sa_004_temporal_equivocation", "label": "Temporal Equivocation",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.55",
     "linguisticMarker": "about that time; around then",
     "signalMeaning": "Avoidance of precise temporal commitment."},
    {"id": "sa_005_lack_of_conviction", "label": "Lack of Conviction",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.60",
     "linguisticMarker": "I think I...; I believe I... applied to own actions",
     "signalMeaning": "Reduced certainty about own acts."},
    {"id": "sa_006_spontaneous_negation", "label": "Spontaneous Negation",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.72",
     "linguisticMarker": "I did not [crime] stated without being asked",
     "signalMeaning": "High-confidence deception marker."},
    {"id": "sa_007_non_answer_answer", "label": "Non-Answer Answer",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.65",
     "linguisticMarker": "What I can tell you is...",
     "signalMeaning": "Topic avoidance behavior."},
    {"id": "sa_008_involuntary_detail", "label": "Involuntary Detail",
     "domain": "Legal & Investigative", "detectionMethod": "linguistic",
     "modality": "text;voice", "confidenceThreshold": "0.50",
     "linguisticMarker": "unprompted specific detail on irrelevant element",
     "signalMeaning": "Displacement behavior."},
]


def build_graph() -> Graph:
    g = Graph()
    g.bind("uckb", UCKB)
    g.bind("owl", OWL)
    g.bind("rdfs", RDFS)
    g.bind("xsd", XSD)

    def prop(node, prop_name, value):
        if value is not None:
            g.add((node, UCKB[prop_name], Literal(str(value))))

    # Techniques
    for card in TECHNIQUES:
        node = UCKB[card["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, UCKB.CommunicationTechnique))
        g.add((node, RDFS.label, Literal(card["label"])))

        str_fields = [
            "domain", "peaceStep", "tier", "reviewStatus", "sourceIds",
            "description", "whenToUse", "whenNotToUse", "steps",
            "successSignals", "failureSignals", "triggerSignals",
            "contraindications", "dialogueActLinks", "requiredEdges", "domainVariants",
        ]
        for f in str_fields:
            if f in card:
                prop(node, f, card[f])

        prop(node, "cardId", card["id"])
        prop(node, "classLabel", "CommunicationTechnique")
        prop(node, "cognitiveLoadProfile", card.get("cognitiveLoad", ""))
        prop(node, "name", card["label"])

        if card.get("activation_blocked"):
            g.add((node, UCKB.activationBlocked, Literal(True, datatype=XSD.boolean)))
        if card.get("rationale"):
            prop(node, "rationale", card["rationale"])

        for rel, rel_type in [
            ("precedes", "PRECEDES"), ("requires", "REQUIRES"),
            ("enhances", "ENHANCES"), ("contradicts", "CONTRADICTS"),
            ("domain_variant_of", "DOMAIN_VARIANT_OF"),
        ]:
            for target_id in card.get(rel, []):
                g.add((node, UCKB[rel_type], UCKB[target_id]))

    # Statement markers
    for sm in STATEMENT_MARKERS:
        node = UCKB[sm["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, UCKB.StatementMarker))
        g.add((node, RDFS.label, Literal(sm["label"])))
        for k, v in sm.items():
            if k not in ("id", "label"):
                prop(node, k, v)
        prop(node, "cardId", sm["id"])
        prop(node, "classLabel", "StatementMarker")
        prop(node, "reviewStatus", "source_checked")

    return g


def main():
    print("Building legal domain graph...")
    g = build_graph()

    OUT_TTL.parent.mkdir(parents=True, exist_ok=True)
    g.serialize(destination=str(OUT_TTL), format="turtle")
    print(f"  Written: {OUT_TTL}")

    OUT_JSONLD.parent.mkdir(parents=True, exist_ok=True)
    g.serialize(destination=str(OUT_JSONLD), format="json-ld")
    print(f"  Written: {OUT_JSONLD}")

    technique_count = sum(1 for t in TECHNIQUES)
    sm_count = len(STATEMENT_MARKERS)
    print(f"  Techniques: {technique_count}, Statement Markers: {sm_count}")
    print("Legal build complete.")


if __name__ == "__main__":
    main()
