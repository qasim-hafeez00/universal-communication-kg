"""
Phase 5 Build Script — Dialogue Acts & ISO 24617-2 Standard
Generates OWL/Turtle + JSON-LD for:
  - dialogue-acts-iso.ttl  (ISO 24617-2 full taxonomy)
  - dst-schema.ttl          (Dialogue State Tracking schema)
No Neo4j dependency — pure ontology file generation.
"""

import sys
import json
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

from rdflib import Graph, Namespace, URIRef, Literal, RDF, RDFS, OWL, XSD
from rdflib.namespace import SKOS

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT     = Path(__file__).resolve().parent.parent
OUT      = ROOT / "outputs" / "phase5_uckb" / "ontology"
OUT.mkdir(parents=True, exist_ok=True)

# ── Namespaces ────────────────────────────────────────────────────────────────
UCKB = Namespace("https://uckb.io/ontology#")
SAC  = Namespace("https://www.w3.org/community/s-agent-comm/ontology#")
ISO  = Namespace("https://uckb.io/ontology/iso24617#")
DC   = Namespace("http://purl.org/dc/elements/1.1/")

def base_graph() -> Graph:
    g = Graph()
    g.bind("uckb", UCKB)
    g.bind("iso",  ISO)
    g.bind("owl",  OWL)
    g.bind("rdfs", RDFS)
    g.bind("rdf",  RDF)
    g.bind("xsd",  XSD)
    g.bind("skos", SKOS)
    g.bind("sac",  SAC)
    g.bind("dc",   DC)
    return g

# ── ISO 24617-2 Taxonomy Data ─────────────────────────────────────────────────

DIMENSIONS = [
    {
        "id": "dim_task",
        "name": "Task",
        "description": "Acts that directly advance the task or information exchange. The primary functional dimension."
    },
    {
        "id": "dim_turn_taking",
        "name": "TurnTaking",
        "description": "Acts that manage the allocation and transfer of speaking turns."
    },
    {
        "id": "dim_feedback",
        "name": "Feedback",
        "description": "Acts signalling whether a preceding act has been understood and accepted."
    },
    {
        "id": "dim_own_comm",
        "name": "OwnComm",
        "description": "Acts by which a speaker manages their own ongoing contribution (self-repair, stalling)."
    },
    {
        "id": "dim_partner_comm",
        "name": "PartnerComm",
        "description": "Acts addressing the partner's contribution or communication difficulties."
    },
    {
        "id": "dim_social",
        "name": "SocialObligations",
        "description": "Conventional social acts governed by social norms and politeness obligations."
    },
]

# Full ISO 24617-2 communicativeFunction taxonomy
# Fields: id, name, dimension_id, description, sentiment, certainty, conditionality,
#         typicalSender, requiresGrounding, requiresInfluencePrereq
DIALOGUE_ACTS = [
    # ── Task dimension ────────────────────────────────────────────────────────
    {
        "id": "da_request",
        "name": "Request",
        "dimension_id": "dim_task",
        "description": "Speaker asks addressee to perform an action or provide information.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": True,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_inform",
        "name": "Inform",
        "dimension_id": "dim_task",
        "description": "Speaker asserts a proposition as true for the addressee's benefit.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_confirm",
        "name": "Confirm",
        "dimension_id": "dim_task",
        "description": "Speaker verifies or reaffirms a proposition previously asserted.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_disconfirm",
        "name": "Disconfirm",
        "dimension_id": "dim_task",
        "description": "Speaker denies or corrects a proposition previously asserted.",
        "sentiment": "negative",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_answer",
        "name": "Answer",
        "dimension_id": "dim_task",
        "description": "Speaker provides information in direct response to a prior Request.",
        "sentiment": "neutral",
        "certainty": "uncertain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_agreement",
        "name": "Agreement",
        "dimension_id": "dim_task",
        "description": "Speaker commits to or aligns with a proposition or proposal.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": True,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_disagreement",
        "name": "Disagreement",
        "dimension_id": "dim_task",
        "description": "Speaker opposes or rejects a proposition or proposal.",
        "sentiment": "negative",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": True,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_correction",
        "name": "Correction",
        "dimension_id": "dim_task",
        "description": "Speaker replaces an erroneous proposition with a correct one.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_proposal",
        "name": "Proposal",
        "dimension_id": "dim_task",
        "description": "Speaker proposes a course of action for addressee to accept or reject. Requires rapport/empathy prerequisite in high-stakes domains.",
        "sentiment": "neutral",
        "certainty": "uncertain",
        "conditionality": "if-then",
        "typicalSender": "Agent",
        "requiresGrounding": True,
        "requiresInfluencePrereq": True,
    },
    {
        "id": "da_accept_proposal",
        "name": "AcceptProposal",
        "dimension_id": "dim_task",
        "description": "Speaker accepts a previously proposed course of action.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_decline_proposal",
        "name": "DeclineProposal",
        "dimension_id": "dim_task",
        "description": "Speaker declines a previously proposed course of action.",
        "sentiment": "negative",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": True,
        "requiresInfluencePrereq": False,
    },
    # ── TurnTaking dimension ──────────────────────────────────────────────────
    {
        "id": "da_offer_turn",
        "name": "OfferTurn",
        "dimension_id": "dim_turn_taking",
        "description": "Speaker explicitly offers the speaking turn to the addressee.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Agent",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_take_turn",
        "name": "TakeTurn",
        "dimension_id": "dim_turn_taking",
        "description": "Speaker claims the speaking turn.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_hold_turn",
        "name": "HoldTurn",
        "dimension_id": "dim_turn_taking",
        "description": "Speaker signals intent to continue their turn (backchannels, fillers).",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_give_turn",
        "name": "GiveTurn",
        "dimension_id": "dim_turn_taking",
        "description": "Speaker relinquishes the floor to the addressee.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_interrupt",
        "name": "Interrupt",
        "dimension_id": "dim_turn_taking",
        "description": "Speaker takes the floor while the addressee is still speaking.",
        "sentiment": "negative",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    # ── Feedback dimension ────────────────────────────────────────────────────
    {
        "id": "da_auto_positive",
        "name": "AutoPositive",
        "dimension_id": "dim_feedback",
        "description": "Speaker signals they have understood the preceding utterance (e.g., 'uh-huh', 'okay').",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_auto_negative",
        "name": "AutoNegative",
        "dimension_id": "dim_feedback",
        "description": "Speaker signals they have not understood or need clarification.",
        "sentiment": "negative",
        "certainty": "uncertain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_allo_positive",
        "name": "AlloPositive",
        "dimension_id": "dim_feedback",
        "description": "Speaker evaluates the preceding act as adequate or correct.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_allo_negative",
        "name": "AlloNegative",
        "dimension_id": "dim_feedback",
        "description": "Speaker evaluates the preceding act as inadequate or incorrect.",
        "sentiment": "negative",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_contact_check",
        "name": "ContactCheck",
        "dimension_id": "dim_feedback",
        "description": "Speaker verifies that the communication channel is open (e.g., 'Are you still there?').",
        "sentiment": "neutral",
        "certainty": "uncertain",
        "conditionality": "unconditional",
        "typicalSender": "Agent",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    # ── OwnComm dimension ─────────────────────────────────────────────────────
    {
        "id": "da_self_correction",
        "name": "SelfCorrection",
        "dimension_id": "dim_own_comm",
        "description": "Speaker repairs their own preceding utterance.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_retraction",
        "name": "Retraction",
        "dimension_id": "dim_own_comm",
        "description": "Speaker withdraws a previously made commitment or assertion.",
        "sentiment": "neutral",
        "certainty": "uncertain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_stalling",
        "name": "Stalling",
        "dimension_id": "dim_own_comm",
        "description": "Speaker uses fillers or delays to hold the floor while processing (e.g., 'um', 'well...').",
        "sentiment": "neutral",
        "certainty": "uncertain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_reformulation",
        "name": "Reformulation",
        "dimension_id": "dim_own_comm",
        "description": "Speaker restates their own prior utterance with different wording for clarity.",
        "sentiment": "neutral",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    # ── PartnerComm dimension ─────────────────────────────────────────────────
    {
        "id": "da_request_repair",
        "name": "RequestRepair",
        "dimension_id": "dim_partner_comm",
        "description": "Speaker asks the addressee to repair or clarify a problematic utterance.",
        "sentiment": "neutral",
        "certainty": "uncertain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_indicate_understanding",
        "name": "IndicateUnderstanding",
        "dimension_id": "dim_partner_comm",
        "description": "Speaker signals that they have understood the addressee's utterance.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Agent",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_clarification_request",
        "name": "ClarificationRequest",
        "dimension_id": "dim_partner_comm",
        "description": "Speaker asks the addressee to elaborate or clarify a specific aspect of their utterance.",
        "sentiment": "neutral",
        "certainty": "uncertain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    # ── SocialObligations dimension ───────────────────────────────────────────
    {
        "id": "da_greeting",
        "name": "Greeting",
        "dimension_id": "dim_social",
        "description": "Conventional opening act establishing social contact.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_goodbye",
        "name": "Goodbye",
        "dimension_id": "dim_social",
        "description": "Conventional closing act terminating social contact.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_thanking",
        "name": "Thanking",
        "dimension_id": "dim_social",
        "description": "Speaker expresses gratitude for a prior act by the addressee.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_apology",
        "name": "Apology",
        "dimension_id": "dim_social",
        "description": "Speaker expresses regret for a prior act that affected the addressee negatively.",
        "sentiment": "negative",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_approval",
        "name": "Approval",
        "dimension_id": "dim_social",
        "description": "Speaker expresses positive evaluation of the addressee's action or statement.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Agent",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_welcome",
        "name": "Welcome",
        "dimension_id": "dim_social",
        "description": "Speaker accepts the addressee's thanks, indicating the prior act was not burdensome.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Agent",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
    {
        "id": "da_farewell",
        "name": "Farewell",
        "dimension_id": "dim_social",
        "description": "Speaker signals the end of an interaction with a culturally appropriate closing ritual.",
        "sentiment": "positive",
        "certainty": "certain",
        "conditionality": "unconditional",
        "typicalSender": "Either",
        "requiresGrounding": False,
        "requiresInfluencePrereq": False,
    },
]

# Functional dependency links: (from_id, to_id, dep_type)
# dep_type: "responds-to" | "initiates"
FUNCTIONAL_DEPS = [
    ("da_answer",           "da_request",            "responds-to"),
    ("da_confirm",          "da_inform",             "responds-to"),
    ("da_disconfirm",       "da_inform",             "responds-to"),
    ("da_correction",       "da_inform",             "responds-to"),
    ("da_agreement",        "da_proposal",           "responds-to"),
    ("da_accept_proposal",  "da_proposal",           "responds-to"),
    ("da_decline_proposal", "da_proposal",           "responds-to"),
    ("da_disagreement",     "da_proposal",           "responds-to"),
    ("da_auto_positive",    "da_inform",             "responds-to"),
    ("da_auto_negative",    "da_inform",             "responds-to"),
    ("da_allo_positive",    "da_request",            "responds-to"),
    ("da_allo_negative",    "da_request",            "responds-to"),
    ("da_welcome",          "da_thanking",           "responds-to"),
    ("da_goodbye",          "da_greeting",           "initiates"),
    ("da_farewell",         "da_goodbye",            "responds-to"),
    ("da_request_repair",   "da_inform",             "responds-to"),
    ("da_clarification_request", "da_inform",        "responds-to"),
    ("da_indicate_understanding", "da_inform",       "responds-to"),
    ("da_stalling",         "da_request",            "responds-to"),
    ("da_take_turn",        "da_offer_turn",         "responds-to"),
]


# ── Build Dialogue Acts OWL ontology ──────────────────────────────────────────

def build_dialogue_acts_ttl():
    g = base_graph()

    onto = UCKB["DialogueActsOntology"]
    g.add((onto, RDF.type, OWL.Ontology))
    g.add((onto, RDFS.label,   Literal("UCKB Dialogue Acts — ISO 24617-2", lang="en")))
    g.add((onto, DC["title"],  Literal("UCKB Phase 5: Dialogue Acts & ISO 24617-2", lang="en")))
    g.add((onto, DC["description"], Literal(
        "OWL ontology defining the ISO 24617-2 dialogue act taxonomy for the Universal "
        "Communication Knowledge Base. Extends Phase 3 communication-acts.ttl.", lang="en")))

    # ── Classes ───────────────────────────────────────────────────────────────
    DialogueDimension = UCKB["DialogueDimension"]
    DialogueAct       = UCKB["DialogueAct"]
    FunctionalDep     = UCKB["FunctionalDependency"]

    for cls, label in [
        (DialogueDimension, "Dialogue Dimension"),
        (DialogueAct,       "Dialogue Act"),
    ]:
        g.add((cls, RDF.type,    OWL.Class))
        g.add((cls, RDFS.label,  Literal(label, lang="en")))
        g.add((cls, RDFS.isDefinedBy, onto))

    # ── Object Properties ─────────────────────────────────────────────────────
    belongsToDimension  = UCKB["belongsToDimension"]
    functionalDependency = UCKB["functionalDependency"]

    for prop, domain, range_, label in [
        (belongsToDimension,   DialogueAct, DialogueDimension, "belongs to dimension"),
        (functionalDependency, DialogueAct, DialogueAct,       "functional dependency"),
    ]:
        g.add((prop, RDF.type,    OWL.ObjectProperty))
        g.add((prop, RDFS.domain, domain))
        g.add((prop, RDFS.range,  range_))
        g.add((prop, RDFS.label,  Literal(label, lang="en")))

    # ── Datatype Properties ───────────────────────────────────────────────────
    dt_props = [
        ("communicativeFunction",  XSD.string,  "communicative function"),
        ("dimension",              XSD.string,  "ISO 24617-2 dimension name"),
        ("sentiment",              XSD.string,  "sentiment qualifier"),
        ("certainty",              XSD.string,  "certainty qualifier"),
        ("conditionality",         XSD.string,  "conditionality qualifier"),
        ("typicalSender",          XSD.string,  "typical sender role"),
        ("requiresGrounding",      XSD.boolean, "requires grounding act first"),
        ("requiresInfluencePrereq",XSD.boolean, "requires empathy/rapport prerequisite"),
        ("dependencyType",         XSD.string,  "functional dependency type (responds-to|initiates)"),
    ]
    for name, dtype, label in dt_props:
        prop = UCKB[name]
        g.add((prop, RDF.type,   OWL.DatatypeProperty))
        g.add((prop, RDFS.range, dtype))
        g.add((prop, RDFS.label, Literal(label, lang="en")))

    # ── Dimension individuals ─────────────────────────────────────────────────
    for dim in DIMENSIONS:
        node = ISO[dim["id"]]
        g.add((node, RDF.type,       DialogueDimension))
        g.add((node, RDF.type,       OWL.NamedIndividual))
        g.add((node, RDFS.label,     Literal(dim["name"], lang="en")))
        g.add((node, RDFS.comment,   Literal(dim["description"], lang="en")))
        g.add((node, UCKB["id"],     Literal(dim["id"])))

    # ── DialogueAct individuals ───────────────────────────────────────────────
    for da in DIALOGUE_ACTS:
        node = ISO[da["id"]]
        g.add((node, RDF.type,        DialogueAct))
        g.add((node, RDF.type,        OWL.NamedIndividual))
        g.add((node, RDFS.label,      Literal(da["name"], lang="en")))
        g.add((node, RDFS.comment,    Literal(da["description"], lang="en")))
        g.add((node, UCKB["id"],                  Literal(da["id"])))
        g.add((node, UCKB["communicativeFunction"],Literal(da["name"])))
        g.add((node, UCKB["dimension"],            Literal(da["dimension_id"].replace("dim_", "").replace("_", ""))))
        g.add((node, UCKB["sentiment"],            Literal(da["sentiment"])))
        g.add((node, UCKB["certainty"],            Literal(da["certainty"])))
        g.add((node, UCKB["conditionality"],       Literal(da["conditionality"])))
        g.add((node, UCKB["typicalSender"],        Literal(da["typicalSender"])))
        g.add((node, UCKB["requiresGrounding"],    Literal(da["requiresGrounding"])))
        g.add((node, UCKB["requiresInfluencePrereq"], Literal(da["requiresInfluencePrereq"])))
        # Link to dimension
        dim_node = ISO[da["dimension_id"]]
        g.add((node, belongsToDimension, dim_node))

    # ── FunctionalDependency triples ──────────────────────────────────────────
    for from_id, to_id, dep_type in FUNCTIONAL_DEPS:
        from_node = ISO[from_id]
        to_node   = ISO[to_id]
        dep_node  = ISO[f"dep_{from_id}_{to_id}"]
        g.add((dep_node, RDF.type,        FunctionalDep))
        g.add((dep_node, RDF.type,        OWL.NamedIndividual))
        g.add((dep_node, UCKB["dependencyType"], Literal(dep_type)))
        g.add((from_node, functionalDependency, dep_node))
        g.add((dep_node,  functionalDependency, to_node))

    return g


# ── Build DST Schema OWL ontology ─────────────────────────────────────────────

DST_SLOTS = [
    # Crisis Dispatch slots
    {"id": "slot_dispatch_location",         "slotName": "location",              "domain": "Crisis Dispatch", "valueType": "string",  "validValues": "street_address|gps_coords|landmark|unknown"},
    {"id": "slot_dispatch_emergency_type",   "slotName": "emergency_type",        "domain": "Crisis Dispatch", "valueType": "string",  "validValues": "medical|fire|violent_crime|mental_health|traffic|other"},
    {"id": "slot_dispatch_emotional_state",  "slotName": "caller_emotional_state","domain": "Crisis Dispatch", "valueType": "string",  "validValues": "calm|anxious|panic|dissociated|hostile|grief"},
    {"id": "slot_dispatch_compliance",       "slotName": "compliance_level",      "domain": "Crisis Dispatch", "valueType": "string",  "validValues": "cooperative|resistant|dissociated"},
    {"id": "slot_dispatch_protocol_step",    "slotName": "current_protocol_step", "domain": "Crisis Dispatch", "valueType": "string",  "validValues": "BCSM_1_Contact|BCSM_2_Empathy|BCSM_3_Rapport|BCSM_4_Influence|BCSM_5_Change"},
    # Clinical slots
    {"id": "slot_clinical_patient_concern",  "slotName": "patient_concern",       "domain": "Clinical",        "valueType": "string",  "validValues": "diagnosis_news|treatment_decision|prognosis|pain_management|end_of_life|other"},
    {"id": "slot_clinical_emotional_state",  "slotName": "caller_emotional_state","domain": "Clinical",        "valueType": "string",  "validValues": "calm|anxious|denial|grief|anger|acceptance"},
    {"id": "slot_clinical_compliance",       "slotName": "compliance_level",      "domain": "Clinical",        "valueType": "string",  "validValues": "cooperative|resistant|ambivalent|dissociated"},
    {"id": "slot_clinical_consent",          "slotName": "informed_consent",      "domain": "Clinical",        "valueType": "boolean", "validValues": "true|false|pending"},
    {"id": "slot_clinical_protocol_step",    "slotName": "current_protocol_step", "domain": "Clinical",        "valueType": "string",  "validValues": "SPIKES_S|SPIKES_P|SPIKES_I|SPIKES_K|SPIKES_E|SPIKES_S2"},
    # Sales & Negotiation slots
    {"id": "slot_sales_buyer_stage",         "slotName": "buyer_stage",           "domain": "Sales",           "valueType": "string",  "validValues": "awareness|interest|evaluation|decision|purchase"},
    {"id": "slot_sales_objection",           "slotName": "active_objection",      "domain": "Sales",           "valueType": "string",  "validValues": "price|timing|authority|need|trust|none"},
    {"id": "slot_sales_emotional_state",     "slotName": "caller_emotional_state","domain": "Sales",           "valueType": "string",  "validValues": "curious|skeptical|interested|resistant|convinced"},
    {"id": "slot_sales_compliance",          "slotName": "compliance_level",      "domain": "Sales",           "valueType": "string",  "validValues": "cooperative|resistant|ambivalent"},
    {"id": "slot_sales_protocol_step",       "slotName": "current_protocol_step", "domain": "Sales",           "valueType": "string",  "validValues": "SPIN_Situation|SPIN_Problem|SPIN_Implication|SPIN_NeedPayoff"},
]

BDI_TEMPLATES = [
    {
        "id": "bdi_crisis",
        "domain": "Crisis Dispatch",
        "belief_template": "caller_emotional_state, location_slot_status, compliance_level, current_protocol_step",
        "desire_template": "caller_reaches_calm_cooperative_state_with_location_confirmed",
        "intention_template": "execute_next_BCSM_step_given_current_belief_state",
    },
    {
        "id": "bdi_clinical",
        "domain": "Clinical",
        "belief_template": "patient_concern, informed_consent_status, emotional_state, current_SPIKES_step",
        "desire_template": "patient_understands_news_and_consents_to_next_step",
        "intention_template": "execute_next_SPIKES_step_with_empathy_prerequisite_satisfied",
    },
    {
        "id": "bdi_sales",
        "domain": "Sales",
        "belief_template": "buyer_stage, active_objection, emotional_state, compliance_level",
        "desire_template": "buyer_reaches_conviction_with_objections_resolved",
        "intention_template": "execute_next_SPIN_step_matching_buyer_stage",
    },
]


def build_dst_schema_ttl():
    g = base_graph()

    onto = UCKB["DSTSchemaOntology"]
    g.add((onto, RDF.type, OWL.Ontology))
    g.add((onto, RDFS.label,  Literal("UCKB Dialogue State Tracking Schema", lang="en")))
    g.add((onto, DC["title"], Literal("UCKB Phase 5: DST & BDI Schema", lang="en")))
    g.add((onto, DC["description"], Literal(
        "OWL schema for Dialogue State Tracking (DST) slot definitions and "
        "Belief-Desire-Intention (BDI) agent reasoning templates.", lang="en")))

    # ── Classes ───────────────────────────────────────────────────────────────
    DialogueState = UCKB["DialogueState"]
    DomainSlot    = UCKB["DomainSlot"]
    BDIState      = UCKB["BDIState"]

    for cls, label in [
        (DialogueState, "Dialogue State"),
        (DomainSlot,    "Domain Slot"),
        (BDIState,      "BDI State Template"),
    ]:
        g.add((cls, RDF.type,   OWL.Class))
        g.add((cls, RDFS.label, Literal(label, lang="en")))
        g.add((cls, RDFS.isDefinedBy, onto))

    # ── Object Properties ─────────────────────────────────────────────────────
    hasSlot = UCKB["hasSlot"]
    g.add((hasSlot, RDF.type,    OWL.ObjectProperty))
    g.add((hasSlot, RDFS.domain, DialogueState))
    g.add((hasSlot, RDFS.range,  DomainSlot))
    g.add((hasSlot, RDFS.label,  Literal("has slot", lang="en")))

    hasBDITemplate = UCKB["hasBDITemplate"]
    g.add((hasBDITemplate, RDF.type,    OWL.ObjectProperty))
    g.add((hasBDITemplate, RDFS.domain, DialogueState))
    g.add((hasBDITemplate, RDFS.range,  BDIState))
    g.add((hasBDITemplate, RDFS.label,  Literal("has BDI template", lang="en")))

    # ── Datatype Properties ───────────────────────────────────────────────────
    dt_props = [
        ("slotName",         XSD.string,  "slot name"),
        ("slotDomain",       XSD.string,  "domain this slot belongs to"),
        ("valueType",        XSD.string,  "value data type"),
        ("validValues",      XSD.string,  "pipe-separated valid values"),
        ("filled",           XSD.boolean, "whether slot is currently filled"),
        ("beliefTemplate",   XSD.string,  "BDI belief template"),
        ("desireTemplate",   XSD.string,  "BDI desire template"),
        ("intentionTemplate",XSD.string,  "BDI intention template"),
    ]
    for name, dtype, label in dt_props:
        prop = UCKB[name]
        g.add((prop, RDF.type,   OWL.DatatypeProperty))
        g.add((prop, RDFS.range, dtype))
        g.add((prop, RDFS.label, Literal(label, lang="en")))

    # ── DomainSlot individuals ────────────────────────────────────────────────
    for slot in DST_SLOTS:
        node = ISO[slot["id"]]
        g.add((node, RDF.type,            DomainSlot))
        g.add((node, RDF.type,            OWL.NamedIndividual))
        g.add((node, UCKB["id"],          Literal(slot["id"])))
        g.add((node, UCKB["slotName"],    Literal(slot["slotName"])))
        g.add((node, UCKB["slotDomain"],  Literal(slot["domain"])))
        g.add((node, UCKB["valueType"],   Literal(slot["valueType"])))
        g.add((node, UCKB["validValues"], Literal(slot["validValues"])))
        g.add((node, UCKB["filled"],      Literal(False)))
        g.add((node, RDFS.label,          Literal(f"{slot['domain']} / {slot['slotName']}", lang="en")))

    # ── BDIState template individuals ─────────────────────────────────────────
    for bdi in BDI_TEMPLATES:
        node = ISO[bdi["id"]]
        g.add((node, RDF.type,                  BDIState))
        g.add((node, RDF.type,                  OWL.NamedIndividual))
        g.add((node, UCKB["id"],                Literal(bdi["id"])))
        g.add((node, UCKB["slotDomain"],        Literal(bdi["domain"])))
        g.add((node, UCKB["beliefTemplate"],    Literal(bdi["belief_template"])))
        g.add((node, UCKB["desireTemplate"],    Literal(bdi["desire_template"])))
        g.add((node, UCKB["intentionTemplate"], Literal(bdi["intention_template"])))
        g.add((node, RDFS.label, Literal(f"BDI Template — {bdi['domain']}", lang="en")))

    return g


# ── JSON-LD helper ────────────────────────────────────────────────────────────

def graph_to_jsonld(g: Graph) -> str:
    raw = g.serialize(format="json-ld", indent=2)
    # rdflib returns str in recent versions
    if isinstance(raw, bytes):
        raw = raw.decode("utf-8")
    return raw


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("Phase 5 — Building Dialogue Acts Ontology (ISO 24617-2)...")

    g_da = build_dialogue_acts_ttl()
    ttl_da  = OUT / "dialogue-acts-iso.ttl"
    jld_da  = OUT / "dialogue-acts-iso.jsonld"
    ttl_da.write_text(g_da.serialize(format="turtle"), encoding="utf-8")
    jld_da.write_text(graph_to_jsonld(g_da), encoding="utf-8")
    da_count  = sum(1 for _ in g_da.triples((None, RDF.type, UCKB["DialogueAct"])))
    dim_count = sum(1 for _ in g_da.triples((None, RDF.type, UCKB["DialogueDimension"])))
    dep_count = sum(1 for _ in g_da.triples((None, RDF.type, UCKB["FunctionalDependency"])))
    print(f"  dialogue-acts-iso.ttl  — {dim_count} dimensions, {da_count} acts, {dep_count} functional-deps")

    print("Phase 5 — Building DST & BDI Schema...")
    g_dst = build_dst_schema_ttl()
    ttl_dst = OUT / "dst-schema.ttl"
    jld_dst = OUT / "dst-schema.jsonld"
    ttl_dst.write_text(g_dst.serialize(format="turtle"), encoding="utf-8")
    jld_dst.write_text(graph_to_jsonld(g_dst), encoding="utf-8")
    slot_count = sum(1 for _ in g_dst.triples((None, RDF.type, UCKB["DomainSlot"])))
    bdi_count  = sum(1 for _ in g_dst.triples((None, RDF.type, UCKB["BDIState"])))
    print(f"  dst-schema.ttl         — {slot_count} domain slots, {bdi_count} BDI templates")

    print(f"\nAll ontology files written to: {OUT}")
    print("Phase 5 ontology build COMPLETE.")


if __name__ == "__main__":
    main()
