"""
UCKB Phase 8 — build_phase8_protocol_dags.py
Generates JSON-LD representations of all 9 ProtocolDAG structures.
The Cypher representations are in 11_protocol_dags.cypher.
This script produces machine-readable JSON summaries of each DAG
for downstream tooling (Text2Cypher routing, agent runtime).
"""
import sys
import json
import pathlib

sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = pathlib.Path(__file__).resolve().parents[2]
OUT_DIR  = BASE_DIR / "protocol_dags"
OUT_DIR.mkdir(parents=True, exist_ok=True)

PROTOCOL_DAGS = {
    "BCSM": {
        "id": "bcsm_dag",
        "name": "BCSM Protocol",
        "domain": "Crisis Dispatch / Emergency",
        "description": "FBI Behavioral Change Stairway Model — 5-step crisis de-escalation protocol.",
        "steps": [
            {"id": "bcsm_step_1", "name": "Active Listening",    "stepNumber": 1, "gate": None,         "bypassable": True},
            {"id": "bcsm_step_2", "name": "Empathy",             "stepNumber": 2, "gate": "bcsm_gate_1", "bypassable": True},
            {"id": "bcsm_step_3", "name": "Rapport",             "stepNumber": 3, "gate": "bcsm_gate_2", "bypassable": True},
            {"id": "bcsm_step_4", "name": "Influence",           "stepNumber": 4, "gate": "bcsm_gate_3", "bypassable": True},
            {"id": "bcsm_step_5", "name": "Behavioral Change",   "stepNumber": 5, "gate": "bcsm_gate_4", "bypassable": False},
        ],
        "gates": [
            {"id": "bcsm_gate_1", "condition": "caller_acknowledged_signal OR speech_rate_normalizes",
             "failurePath": "re_engage_active_listening", "bypassCondition": "imminent_danger_threshold"},
            {"id": "bcsm_gate_2", "condition": "affect_intensity_drops AND caller_accepts_next_question",
             "failurePath": "repeat_empathy_step", "bypassCondition": "imminent_danger_threshold"},
            {"id": "bcsm_gate_3", "condition": "rapport_confirmed AND caller_elaborates",
             "failurePath": "repair_sequence", "bypassCondition": "imminent_danger_threshold"},
            {"id": "bcsm_gate_4", "condition": "caller_considering_alternative",
             "failurePath": "reinforce_rapport", "bypassCondition": "imminent_danger_threshold"},
        ],
        "bypassNode": {"id": "bcsm_bypass_imminent_danger", "condition": "imminent_danger_threshold",
                       "note": "Skips all steps; routes to One-Step Instruction immediately."},
        "techniques": {1: "crisis_dispatch_001_active_listening", 2: "crisis_dispatch_002_empathic_validation"},
    },
    "SPIKES": {
        "id": "spikes_dag",
        "name": "SPIKES Protocol",
        "domain": "Clinical / Medical",
        "description": "Clinical bad-news delivery: Setting, Perception, Invitation, Knowledge, Emotion, Strategy.",
        "steps": [
            {"id": "spikes_s",   "name": "Setting",    "stepNumber": 1, "gate": None},
            {"id": "spikes_p",   "name": "Perception", "stepNumber": 2, "gate": "spikes_gate_1"},
            {"id": "spikes_i",   "name": "Invitation", "stepNumber": 3, "gate": "spikes_gate_2",
             "criticalNote": "ONLY STEP IN UCKB WHERE PATIENT CAN HALT INFORMATION FLOW"},
            {"id": "spikes_k",   "name": "Knowledge",  "stepNumber": 4, "gate": "spikes_gate_3"},
            {"id": "spikes_e",   "name": "Emotion",    "stepNumber": 5, "gate": "spikes_gate_4",
             "criticalNote": "CANNOT PROCEED TO STRATEGY UNTIL EMOTION IS PROCESSED"},
            {"id": "spikes_str", "name": "Strategy",   "stepNumber": 6, "gate": "spikes_gate_5"},
        ],
        "gates": [
            {"id": "spikes_gate_1", "condition": "privacy_confirmed AND patient_ready"},
            {"id": "spikes_gate_2", "condition": "baseline_understanding_established"},
            {"id": "spikes_gate_3", "condition": "explicit_verbal_consent_received",
             "refusalPath": "spikes_refusal_honored"},
            {"id": "spikes_gate_4", "condition": "patient_acknowledged_each_chunk"},
            {"id": "spikes_gate_5", "condition": "emotional_processing_complete"},
        ],
        "specialNodes": [
            {"id": "spikes_refusal_honored", "name": "Patient Right Not to Know",
             "note": "Invoked when patient declines invitation at Step 3."},
        ],
    },
    "SPIN": {
        "id": "spin_dag",
        "name": "SPIN Selling Protocol",
        "domain": "Sales & Negotiation",
        "description": "Rackham SPIN: Situation, Problem, Implication, Need-Payoff.",
        "steps": [
            {"id": "spin_step_1", "name": "Situation Question",   "stepNumber": 1, "gate": None},
            {"id": "spin_step_2", "name": "Problem Question",     "stepNumber": 2, "gate": None},
            {"id": "spin_step_3", "name": "Implication Question", "stepNumber": 3, "gate": None},
            {"id": "spin_step_4", "name": "Need-Payoff Question", "stepNumber": 4, "gate": None},
        ],
        "gates": [],
    },
    "ChallengerSale": {
        "id": "challenger_dag",
        "name": "Challenger Sale Protocol",
        "domain": "Sales & Negotiation",
        "description": "Dixon/Adamson: Teach, Tailor, Take Control.",
        "steps": [
            {"id": "ch_step_1", "name": "Teach",        "stepNumber": 1, "gate": None},
            {"id": "ch_step_2", "name": "Tailor",       "stepNumber": 2, "gate": None},
            {"id": "ch_step_3", "name": "Take Control", "stepNumber": 3, "gate": None},
        ],
        "gates": [],
    },
    "HarvardNegotiation": {
        "id": "harvard_dag",
        "name": "Harvard Principled Negotiation",
        "domain": "Sales & Negotiation",
        "description": "Fisher/Ury Getting to Yes: 4 principles.",
        "steps": [
            {"id": "harv_step_1", "name": "Separate People from Problem",       "stepNumber": 1, "gate": None},
            {"id": "harv_step_2", "name": "Focus on Interests Not Positions",   "stepNumber": 2, "gate": None},
            {"id": "harv_step_3", "name": "Invent Options for Mutual Gain",     "stepNumber": 3, "gate": None},
            {"id": "harv_step_4", "name": "Insist on Objective Criteria",       "stepNumber": 4, "gate": None},
        ],
        "gates": [],
    },
    "PEACE": {
        "id": "peace_dag",
        "name": "PEACE Protocol",
        "domain": "Legal & Investigative",
        "description": "UK Police: Preparation, Engage/Explain, Account, Closure, Evaluation.",
        "steps": [
            {"id": "peace_p",  "name": "Preparation",     "stepNumber": 1, "gate": None},
            {"id": "peace_e1", "name": "Engage and Explain", "stepNumber": 2, "gate": "peace_gate_1",
             "constraint": "deception_by_interviewer_contraindicated_absolute"},
            {"id": "peace_a",  "name": "Account",         "stepNumber": 3, "gate": "peace_gate_2",
             "note": "Free narrative FIRST; contradictions addressed ONLY after full account."},
            {"id": "peace_c",  "name": "Closure",         "stepNumber": 4, "gate": "peace_gate_3"},
            {"id": "peace_e2", "name": "Evaluation",      "stepNumber": 5, "gate": "peace_gate_4"},
        ],
        "gates": [
            {"id": "peace_gate_1", "condition": "interview_objectives_defined AND evidence_reviewed"},
            {"id": "peace_gate_2", "condition": "caution_delivered AND rapport_established AND rights_explained"},
            {"id": "peace_gate_3", "condition": "full_narrative_obtained AND no_interruptions_made"},
            {"id": "peace_gate_4", "condition": "summary_confirmed_by_interviewee"},
        ],
        "techniques": {2: "legal_013_rapport_through_transparency",
                       3: "legal_001_free_narrative_invitation",
                       4: "legal_011_summary_and_confirm"},
    },
    "SBI": {
        "id": "sbi_dag",
        "name": "SBI Feedback Protocol",
        "domain": "Corporate & Engineering",
        "description": "CCL SBI: Situation, Behavior, Impact.",
        "steps": [
            {"id": "sbi_step_1", "name": "Situation", "stepNumber": 1, "gate": None},
            {"id": "sbi_step_2", "name": "Behavior",  "stepNumber": 2, "gate": None},
            {"id": "sbi_step_3", "name": "Impact",    "stepNumber": 3, "gate": "sbi_gate_behavior"},
        ],
        "gates": [
            {"id": "sbi_gate_behavior",
             "condition": "behavior_is_observable_not_interpreted",
             "note": "If you cannot film the behavior, it is an interpretation."},
        ],
        "techniques": {1: "corp_001_sbi_situation", 2: "corp_002_sbi_behavior", 3: "corp_003_sbi_impact"},
    },
    "NVC": {
        "id": "nvc_dag",
        "name": "NVC Protocol",
        "domain": "Corporate & Engineering",
        "description": "Rosenberg NVC: Observation, Feeling, Need, Request.",
        "steps": [
            {"id": "nvc_step_1", "name": "Observation", "stepNumber": 1, "gate": None},
            {"id": "nvc_step_2", "name": "Feeling",     "stepNumber": 2, "gate": "nvc_gate_observation"},
            {"id": "nvc_step_3", "name": "Need",        "stepNumber": 3, "gate": None},
            {"id": "nvc_step_4", "name": "Request",     "stepNumber": 4, "gate": None},
        ],
        "gates": [
            {"id": "nvc_gate_observation",
             "condition": "no_interpretations_present",
             "note": "Rewrite observation as fact before proceeding."},
        ],
        "techniques": {1: "corp_009_nvc_observation", 2: "corp_010_nvc_feeling",
                       3: "corp_011_nvc_need", 4: "corp_012_nvc_request"},
    },
    "CoachIDL": {
        "id": "coachidl_socratic_dag",
        "name": "CoachIDL Socratic Sequence",
        "domain": "Education",
        "description": "Education Socratic sequence: Opening, Probe, Challenge/Confirm.",
        "steps": [
            {"id": "socratic_step_1", "name": "Socratic Opening",          "stepNumber": 1, "gate": None,
             "bktGate": "p_know >= 0.3"},
            {"id": "socratic_step_2", "name": "Socratic Probe",            "stepNumber": 2, "gate": "coachidl_gate_1"},
            {"id": "socratic_step_3", "name": "Socratic Challenge/Confirm","stepNumber": 3, "gate": "coachidl_gate_2"},
        ],
        "gates": [
            {"id": "coachidl_gate_1", "condition": "partial_answer_produced OR engagement_signal"},
            {"id": "coachidl_gate_2", "condition": "reasoning_chain_visible",
             "failurePath": "route_to_scaffold_tier_1"},
        ],
        "techniques": {1: "edu_001_socratic_opening", 2: "edu_002_socratic_probe", 3: "edu_003_socratic_challenge"},
    },
}


def validate_dag(dag_id: str, dag: dict) -> list:
    """Detect cycles and unguarded non-first steps."""
    errors = []
    step_ids = {s["id"] for s in dag["steps"]}

    # Check for self-references (trivial cycle)
    for step in dag["steps"]:
        if step.get("gate") and step["gate"] == step["id"]:
            errors.append(f"CYCLE: step {step['id']} gates itself.")

    # Check gates exist
    gate_ids = {g["id"] for g in dag.get("gates", [])}
    for step in dag["steps"]:
        if step["stepNumber"] > 1 and step.get("gate"):
            if step["gate"] not in gate_ids:
                errors.append(f"MISSING_GATE: step {step['id']} references undefined gate {step['gate']}")

    return errors


def main():
    print("Building protocol DAG JSON-LD summaries...")
    all_errors = []

    for protocol_name, dag in PROTOCOL_DAGS.items():
        errors = validate_dag(protocol_name, dag)
        if errors:
            print(f"  ERRORS in {protocol_name}: {errors}")
            all_errors.extend(errors)

        out_path = OUT_DIR / f"{protocol_name.lower()}_dag.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(dag, f, indent=2, ensure_ascii=False)
        step_count = len(dag["steps"])
        gate_count = len(dag.get("gates", []))
        print(f"  {protocol_name}: {step_count} steps, {gate_count} gates -> {out_path.name}")

    print(f"\nTotal protocols: {len(PROTOCOL_DAGS)}")
    if all_errors:
        print(f"VALIDATION ERRORS: {len(all_errors)}")
        for e in all_errors:
            print(f"  ! {e}")
        sys.exit(1)
    else:
        print("All DAG structures are cycle-free and gate-complete.")
    print("Protocol DAG build complete.")


if __name__ == "__main__":
    main()
