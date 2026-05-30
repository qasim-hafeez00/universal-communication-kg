"""
UCKB Phase 8 — build_phase8_education.py
Generates:
  - outputs/phase8_uckb/domains/education.ttl  (already created; regenerates from data)
  - outputs/phase8_uckb/jsonld/education.jsonld
"""
import sys
import pathlib
from rdflib import Graph, Namespace, Literal
from rdflib.namespace import OWL, RDF, RDFS, XSD

sys.stdout.reconfigure(encoding='utf-8')

UCKB = Namespace("https://uckb.io/ontology#")
BASE_DIR   = pathlib.Path(__file__).resolve().parents[2]
OUT_TTL    = BASE_DIR / "domains" / "education.ttl"
OUT_JSONLD = BASE_DIR / "jsonld" / "education.jsonld"

# BKT default parameters (Corbett & Anderson 1994)
BKT_DEFAULTS = {"p_learn": 0.3, "p_guess": 0.25, "p_slip": 0.1, "p_forget": 0.05}

KNOWLEDGE_STATES = [
    {"id": "edu_ks_novice",            "label": "BKT: Novice State",          "p_know_range": "0.0-0.2",  "triggeredAct": "direct_instruction"},
    {"id": "edu_ks_partial",           "label": "BKT: Partial Knowledge",     "p_know_range": "0.2-0.5",  "triggeredAct": "scaffolded_hint"},
    {"id": "edu_ks_near_competent",    "label": "BKT: Near-Competent State",  "p_know_range": "0.3-0.75", "triggeredAct": "socratic_question"},
    {"id": "edu_ks_mastered",          "label": "BKT: Mastered State",        "p_know_range": "> 0.85",   "triggeredAct": "transfer_probe; spaced_rep_schedule",
     "p_learn": 0.3, "p_guess": 0.25, "p_slip": 0.1, "p_forget": 0.05},
    {"id": "edu_ks_transfer_confirmed","label": "BKT: Transfer Confirmed",    "p_know_range": "> 0.90",   "triggeredAct": "spaced_rep_schedule_extended"},
]

TECHNIQUES = [
    {"id": "edu_001_socratic_opening",  "label": "Socratic Opening Question",
     "bktTrigger": "p_know >= 0.3", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "description": "Open question to surface student current understanding before deeper engagement.",
     "whenToUse": "Student has partial knowledge (BKT p_know 0.3-0.75).",
     "whenNotToUse": "p_know < 0.3; no baseline.",
     "steps": "Ask: What do you already know about [concept]?",
     "triggerSignals": "near_competent_state; p_know_0.3_to_0.75",
     "sourceIds": "Collins1989CognitiveTutoring",
     "triggered_by": ["edu_ks_near_competent"],
     "precedes": ["edu_002_socratic_probe"]},
    {"id": "edu_002_socratic_probe",    "label": "Socratic Probe",
     "bktTrigger": "partial_answer_signal", "tier": "Tier 1", "cognitiveLoad": "medium-load",
     "description": "Follow-up question probing assumptions and reasoning chains in a partial answer.",
     "whenToUse": "Student has produced partial answer with retrievable reasoning.",
     "whenNotToUse": "Student in confusion spiral; scaffold first.",
     "steps": "Ask: Why do you think that? What evidence supports that?",
     "triggerSignals": "partial_answer; reasoning_chain_incomplete",
     "sourceIds": "Collins1989CognitiveTutoring; Graesser1995tutordialogue",
     "triggered_by": ["edu_sig_partial_answer"]},
    {"id": "edu_003_socratic_challenge","label": "Socratic Challenge",
     "bktTrigger": "confident_wrong_answer AND p_know > 0.5", "tier": "Tier 2", "cognitiveLoad": "high-load",
     "description": "Counter-example that destabilises a confidently held misconception.",
     "whenToUse": "High-confidence misconception needing productive destabilisation.",
     "whenNotToUse": "Student already low confidence.",
     "steps": "Introduce counter-case: What would you say about [counter-example]? Does your answer still hold?",
     "triggerSignals": "confident_wrong_answer",
     "sourceIds": "VanLehn2011tutoring",
     "triggered_by": ["edu_sig_confident_wrong_answer"],
     "contraindications_when": ["edu_emo_low_confidence"]},
    {"id": "edu_004_scaffolded_hint_t1","label": "Scaffolded Hint Tier 1",
     "bktTrigger": "confusion_signal AND p_know > 0.2", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "description": "Lightest scaffolding: reactivates prerequisite knowledge without revealing solution path.",
     "whenToUse": "Student stuck but has prerequisite knowledge.",
     "whenNotToUse": "p_know < 0.2; use Direct Instruction.",
     "steps": "Ask: What do you know about [prerequisite]?",
     "triggerSignals": "confusion_signal; stuck_after_opening",
     "sourceIds": "Wood1976Scaffolding; VanLehn2011tutoring",
     "triggered_by": ["edu_sig_confusion"],
     "precedes": ["edu_005_scaffolded_hint_t2"]},
    {"id": "edu_005_scaffolded_hint_t2","label": "Scaffolded Hint Tier 2",
     "bktTrigger": "tier1_hint_failed", "tier": "Tier 2", "cognitiveLoad": "low-load",
     "description": "Heavier scaffolding: reveals solution approach without giving the final answer.",
     "whenToUse": "After Tier 1 fails.",
     "steps": "Say: The approach is to [method]. Try applying that.",
     "triggerSignals": "tier1_hint_failed",
     "sourceIds": "Wood1976Scaffolding",
     "precedes": ["edu_006_scaffolded_hint_t3"]},
    {"id": "edu_006_scaffolded_hint_t3","label": "Scaffolded Hint Tier 3",
     "bktTrigger": "tier2_hint_failed", "tier": "Tier 3", "cognitiveLoad": "low-load",
     "description": "Near-complete scaffolding: reveals almost all answer structure, leaves final inference.",
     "whenToUse": "After Tier 2 fails.",
     "steps": "Say: You need [near-complete structure]; what goes in the last part?",
     "triggerSignals": "tier2_hint_failed",
     "sourceIds": "Wood1976Scaffolding",
     "precedes": ["edu_007_direct_instruction"]},
    {"id": "edu_007_direct_instruction","label": "Direct Instruction",
     "bktTrigger": "p_know < 0.3 OR tier3_hint_failed", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "description": "Agent explicitly teaches concept when prerequisite gap prevents self-discovery.",
     "whenToUse": "BKT p_know < 0.3; all scaffold tiers exhausted.",
     "whenNotToUse": "Near-competent state; productive struggle possible.",
     "steps": "State: [Concept] means [definition]. Key things: [1, 2, 3].",
     "triggerSignals": "prerequisite_gap; p_know_below_threshold",
     "sourceIds": "Rosenshine1987DirectInstruction",
     "triggered_by": ["edu_sig_prerequisite_gap"],
     "precedes": ["edu_008_worked_example"]},
    {"id": "edu_008_worked_example",    "label": "Worked Example",
     "bktTrigger": "after_direct_instruction OR example_requested", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "description": "Agent demonstrates technique application step-by-step before student applies independently.",
     "whenToUse": "After direct instruction; student requests show me how.",
     "whenNotToUse": "Near-mastery state; modelling reduces challenge.",
     "steps": "Walk through: Here is how to apply [concept]: [steps]. Now you try.",
     "triggerSignals": "after_direct_instruction; example_requested",
     "sourceIds": "Sweller1988CognitiveLoad"},
    {"id": "edu_010_spaced_rep_prompt", "label": "Spaced Repetition Prompt",
     "bktTrigger": "p_know > 0.85 AND time_since_last > p_forget_threshold", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "description": "Retrieval practice prompt for previously mastered concept at optimum interval.",
     "whenToUse": "BKT mastery confirmed AND time exceeds decay threshold.",
     "whenNotToUse": "Concept not yet mastered.",
     "steps": "Say: Let us revisit something you learned — [concept]. What does it involve?",
     "triggerSignals": "memory_decay_signal; time_threshold_exceeded",
     "sourceIds": "Ebbinghaus1885; Cepeda2006SpacedPractice; Corbett1994BKT",
     "triggered_by": ["edu_sig_memory_decay", "edu_ks_mastered"],
     "requires": ["edu_ks_mastered"]},
    {"id": "edu_011_error_correction",  "label": "Error Correction",
     "bktTrigger": "wrong_answer AND p_slip_high", "tier": "Tier 1", "cognitiveLoad": "low-load",
     "description": "Specific targeted correction identifying exact wrong element.",
     "whenToUse": "Any wrong answer, misconception, or slip detected.",
     "steps": "[Element] is not quite right because [reason]. The correct understanding is [correction].",
     "triggerSignals": "wrong_answer; misconception_detected",
     "sourceIds": "VanLehn2011tutoring",
     "triggered_by": ["edu_sig_wrong_answer"],
     "contradicts": ["edu_emo_shame_response"]},
    {"id": "edu_012_transfer_probe",    "label": "Transfer Probe",
     "bktTrigger": "p_know > 0.85 AND mastery_claim", "tier": "Tier 2", "cognitiveLoad": "medium-load",
     "description": "Tests whether mastered knowledge transfers to a novel context.",
     "whenToUse": "After mastery in original context.",
     "whenNotToUse": "Mastery not established.",
     "steps": "Say: Now, in a different situation — [novel context] — how would you apply [concept]?",
     "triggerSignals": "mastery_confirmed",
     "sourceIds": "Haskell2001Transfer; VanLehn2011tutoring",
     "triggered_by": ["edu_ks_mastered"]},
    {"id": "edu_013_praise_for_effort", "label": "Praise for Effort",
     "bktTrigger": "effort_signal; persistence_after_difficulty", "tier": "Tier 1", "cognitiveLoad": "lowest-load",
     "description": "Specific praise targeting effort, strategy, or persistence — not ability.",
     "whenToUse": "Effort, strategy, or persistence is visible.",
     "whenNotToUse": "Praising ability not effort — rephrase first.",
     "steps": "Say: I can see you worked hard to figure that out.",
     "triggerSignals": "effort_visible; persistence_after_difficulty",
     "sourceIds": "Dweck2006Mindset; Mueller1998PraiseMotivation",
     "triggered_by": ["edu_sig_effort_signal"],
     "domain_variant_of": ["Clinical_Affirmation"]},
]

SIGNAL_MARKERS = [
    {"id": "edu_sig_confusion",               "label": "Confusion Signal",          "detection": "linguistic;behavioral", "modality": "text;voice", "ct": "0.70",
     "description": "Contradictory statements; I don't know; question reversal; fragmented response.",
     "triggers": ["edu_004_scaffolded_hint_t1"]},
    {"id": "edu_sig_partial_answer",          "label": "Partial Answer",             "detection": "linguistic",            "modality": "text;voice", "ct": "0.75",
     "description": "Answer has correct elements but is incomplete or lacks full reasoning.",
     "triggers": ["edu_002_socratic_probe"]},
    {"id": "edu_sig_confident_wrong_answer",  "label": "Confident Wrong Answer",    "detection": "linguistic;prosodic",   "modality": "text;voice", "ct": "0.72",
     "description": "Wrong answer with high apparent confidence; no hedging.",
     "triggers": ["edu_003_socratic_challenge"]},
    {"id": "edu_sig_wrong_answer",            "label": "Wrong Answer",              "detection": "linguistic",            "modality": "text;voice", "ct": "0.85",
     "description": "Factually incorrect answer; neutral or low confidence.",
     "triggers": ["edu_011_error_correction"]},
    {"id": "edu_sig_memory_decay",            "label": "Memory Decay Signal",       "detection": "temporal",              "modality": "system",     "ct": "1.0",
     "description": "Time since last recall exceeds BKT p_forget threshold.",
     "triggers": ["edu_010_spaced_rep_prompt"]},
    {"id": "edu_sig_effort_signal",           "label": "Effort Signal",             "detection": "behavioral;linguistic", "modality": "text;voice", "ct": "0.65",
     "description": "Multiple attempts; self-correction; persisting after failure.",
     "triggers": ["edu_013_praise_for_effort"]},
    {"id": "edu_sig_cognitive_load",          "label": "High Cognitive Load",       "detection": "linguistic;behavioral", "modality": "text;voice", "ct": "0.65",
     "description": "Multiple simultaneous errors; extremely brief responses; explicit overwhelm."},
    {"id": "edu_sig_prerequisite_gap",        "label": "Prerequisite Gap",          "detection": "system;linguistic",     "modality": "system",     "ct": "0.80",
     "description": "Student cannot engage; prerequisite concept p_know < 0.3.",
     "triggers": ["edu_007_direct_instruction"]},
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

    # KnowledgeState nodes
    for ks in KNOWLEDGE_STATES:
        node = UCKB[ks["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, UCKB.KnowledgeState))
        g.add((node, RDFS.label, Literal(ks["label"])))
        prop(node, "cardId", ks["id"])
        prop(node, "classLabel", "KnowledgeState")
        prop(node, "domain", "Education")
        prop(node, "p_know_range", ks["p_know_range"])
        prop(node, "triggeredAct", ks["triggeredAct"])
        for bkt_param in ("p_learn", "p_guess", "p_slip", "p_forget"):
            if bkt_param in ks:
                g.add((node, UCKB[bkt_param], Literal(ks[bkt_param], datatype=XSD.float)))
        prop(node, "reviewStatus", "source_checked")

    # Techniques
    str_fields = ["description", "whenToUse", "whenNotToUse", "steps",
                  "triggerSignals", "sourceIds", "bktTrigger", "tier"]
    rel_map = {"precedes": "PRECEDES", "follows": "FOLLOWS", "requires": "REQUIRES",
               "enhances": "ENHANCES", "contradicts": "CONTRADICTS",
               "triggered_by": "TRIGGERED_BY", "domain_variant_of": "DOMAIN_VARIANT_OF"}

    for card in TECHNIQUES:
        node = UCKB[card["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, UCKB.CommunicationTechnique))
        g.add((node, RDFS.label, Literal(card["label"])))
        prop(node, "cardId", card["id"])
        prop(node, "classLabel", "CommunicationTechnique")
        prop(node, "domain", "Education")
        prop(node, "cognitiveLoadProfile", card.get("cognitiveLoad"))
        prop(node, "name", card["label"])
        prop(node, "reviewStatus", "source_checked")
        for f in str_fields:
            if f in card:
                prop(node, f, card[f])
        for rel_key, rel_uri in rel_map.items():
            for tgt in card.get(rel_key, []):
                g.add((node, UCKB[rel_uri], UCKB[tgt]))
        for cw in card.get("contraindications_when", []):
            g.add((node, UCKB.CONTRAINDICATED_WHEN, UCKB[cw]))

    # Signal markers
    for sm in SIGNAL_MARKERS:
        node = UCKB[sm["id"]]
        g.add((node, RDF.type, OWL.NamedIndividual))
        g.add((node, RDF.type, UCKB.SignalMarker))
        g.add((node, RDFS.label, Literal(sm["label"])))
        prop(node, "cardId", sm["id"])
        prop(node, "classLabel", "SignalMarker")
        prop(node, "domain", "Education")
        prop(node, "description", sm["description"])
        prop(node, "detectionMethod", sm["detection"])
        prop(node, "modality", sm["modality"])
        prop(node, "confidenceThreshold", sm["ct"])
        prop(node, "reviewStatus", "source_checked")
        for tgt in sm.get("triggers", []):
            g.add((node, UCKB.TRIGGERS, UCKB[tgt]))

    return g


def main():
    print("Building education domain graph...")
    g = build_graph()
    OUT_TTL.parent.mkdir(parents=True, exist_ok=True)
    g.serialize(destination=str(OUT_TTL), format="turtle")
    print(f"  Written: {OUT_TTL}")
    OUT_JSONLD.parent.mkdir(parents=True, exist_ok=True)
    g.serialize(destination=str(OUT_JSONLD), format="json-ld")
    print(f"  Written: {OUT_JSONLD}")
    print(f"  Techniques: {len(TECHNIQUES)}, KnowledgeStates: {len(KNOWLEDGE_STATES)}, SignalMarkers: {len(SIGNAL_MARKERS)}")
    print("Education build complete.")


if __name__ == "__main__":
    main()
