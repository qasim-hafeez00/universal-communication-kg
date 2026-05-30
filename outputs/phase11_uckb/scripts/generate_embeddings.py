"""
UCKB Phase 11 — Embedding Generator
Generates 384-dim embeddings for all Technique nodes in the UCKB.

Two modes:
  --mock   (default) Reproducible pseudo-random vectors seeded by node ID hash.
           No GPU or internet required. Used for validation.
  --real   Uses sentence-transformers/all-MiniLM-L6-v2 for genuine semantic
           embeddings. Requires: pip install sentence-transformers

Saves to: outputs/phase11_uckb/data/embeddings.json
Format:   { "technique_id": [384 floats], ... }

Usage:
    python generate_embeddings.py          # mock mode
    python generate_embeddings.py --real   # real sentence-transformer embeddings
    python generate_embeddings.py --neo4j  # also write embeddings to live Neo4j
"""

import argparse
import json
import sys
import io
import hashlib
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT     = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)

DIMS = 384

# ─────────────────────────────────────────────────────────────────────────────
# Technique inventory
# Drawn from core UCKB domains across Phases 3-8.
# In a live graph these would be queried via:
#   MATCH (t:Technique) RETURN t.id, t.name, t.domain, t.steps
# ─────────────────────────────────────────────────────────────────────────────

TECHNIQUES = [
    # ── Crisis Dispatch (BCSM) ───────────────────────────────────────────────
    ("t_bcsm_minimal_enc",       "Minimal Encouragers",                           "Crisis Dispatch"),
    ("t_bcsm_active_listening",  "Active Listening",                               "Crisis Dispatch"),
    ("t_bcsm_emotional_labeling","Emotional Labeling",                             "Crisis Dispatch"),
    ("t_bcsm_mirroring",         "Mirroring",                                      "Crisis Dispatch"),
    ("t_bcsm_paraphrasing",      "Paraphrasing",                                   "Crisis Dispatch"),
    ("t_bcsm_open_questions",    "Open-Ended Questions (BCSM)",                   "Crisis Dispatch"),
    ("t_bcsm_rapport",           "Rapport Building (BCSM)",                       "Crisis Dispatch"),
    ("t_bcsm_ied",               "Identify-Empathise-Defuse",                      "Crisis Dispatch"),
    ("t_bcsm_reality_testing",   "Reality Testing",                                "Crisis Dispatch"),
    ("t_bcsm_problem_solving",   "Collaborative Problem Solving (BCSM)",          "Crisis Dispatch"),
    ("t_bcsm_containment",       "Emotional Containment",                          "Crisis Dispatch"),
    ("t_bcsm_de_escalation",     "De-Escalation Ladder",                          "Crisis Dispatch"),
    ("t_bcsm_temporal_anchoring","Temporal Anchoring",                             "Crisis Dispatch"),
    ("t_bcsm_verbal_judo",       "Verbal Judo",                                    "Crisis Dispatch"),
    ("t_bcsm_silence",           "Strategic Silence",                              "Crisis Dispatch"),
    # ── Clinical (SPIKES) ────────────────────────────────────────────────────
    ("t_spikes_setting",         "SPIKES Setting — Create Safe Space",            "Clinical"),
    ("t_spikes_perception",      "SPIKES Perception — Elicit Patient Understanding","Clinical"),
    ("t_spikes_invitation",      "SPIKES Invitation — Ask Permission",            "Clinical"),
    ("t_spikes_knowledge",       "SPIKES Knowledge — Deliver News Chunk",         "Clinical"),
    ("t_spikes_empathy_response","SPIKES Empathy Response (Step E)",               "Clinical"),
    ("t_spikes_strategy",        "SPIKES Strategy — Summarise and Plan",          "Clinical"),
    ("t_motivational_interview", "Motivational Interviewing",                      "Clinical"),
    ("t_teach_back",             "Teach-Back Technique",                           "Clinical"),
    ("t_shared_decision",        "Shared Decision-Making",                         "Clinical"),
    ("t_reflective_practice",    "Reflective Listening (Clinical)",                "Clinical"),
    ("t_narrative_medicine",     "Narrative Medicine Elicitation",                 "Clinical"),
    ("t_trauma_informed",        "Trauma-Informed Communication",                  "Clinical"),
    ("t_cals_signposting",       "Signposting (Clinical)",                         "Clinical"),
    ("t_chunking_checking",      "Chunk-and-Check Information Delivery",          "Clinical"),
    ("t_normalization",          "Normalisation Response",                         "Clinical"),
    # ── Sales & Negotiation (SPIN / Harvard / Challenger) ────────────────────
    ("t_spin_situation_q",       "SPIN Situation Question",                        "Sales & Negotiation"),
    ("t_spin_problem_q",         "SPIN Problem Question",                          "Sales & Negotiation"),
    ("t_spin_implication_q",     "SPIN Implication Question",                      "Sales & Negotiation"),
    ("t_spin_need_payoff_q",     "SPIN Need-Payoff Question",                      "Sales & Negotiation"),
    ("t_harvard_batna",          "BATNA Preparation (Harvard)",                    "Sales & Negotiation"),
    ("t_harvard_interests",      "Interest-Based Bargaining (Harvard)",            "Sales & Negotiation"),
    ("t_harvard_criteria",       "Objective Criteria Appeal (Harvard)",            "Sales & Negotiation"),
    ("t_challenger_teach",       "Challenger Teach",                               "Sales & Negotiation"),
    ("t_challenger_tailor",      "Challenger Tailor",                              "Sales & Negotiation"),
    ("t_challenger_take_control","Challenger Take Control",                        "Sales & Negotiation"),
    ("t_anchoring",              "Anchoring (Negotiation)",                        "Sales & Negotiation"),
    ("t_mirroring_neg",          "Mirroring (Negotiation)",                        "Sales & Negotiation"),
    ("t_calibrated_questions",   "Calibrated Questions (Never Split the Difference)","Sales & Negotiation"),
    ("t_tactical_empathy",       "Tactical Empathy",                               "Sales & Negotiation"),
    ("t_labeling_neg",           "Labeling (Negotiation)",                         "Sales & Negotiation"),
    # ── Legal & Investigative (PEACE) ────────────────────────────────────────
    ("t_peace_planning",         "PEACE Planning & Preparation",                  "Legal & Investigative"),
    ("t_peace_engage",           "PEACE Engage & Explain",                        "Legal & Investigative"),
    ("t_peace_account",          "PEACE Account — Free Recall",                   "Legal & Investigative"),
    ("t_peace_probing",          "PEACE Probing Questions (Step A — Account)",    "Legal & Investigative"),
    ("t_peace_closure",          "PEACE Closure",                                 "Legal & Investigative"),
    ("t_peace_evaluation",       "PEACE Evaluation",                              "Legal & Investigative"),
    ("t_cognitive_interview",    "Cognitive Interview Protocol",                  "Legal & Investigative"),
    ("t_sa_probe",               "Statement Analysis Probe (SA markers 1-8)",     "Legal & Investigative"),
    ("t_timeline_clarification", "Timeline Clarification Technique",              "Legal & Investigative"),
    ("t_free_recall_prompt",     "Free Recall Prompt",                            "Legal & Investigative"),
    # ── Corporate & Engineering (SBI / NVC / Radical Candor) ─────────────────
    ("t_sbi_feedback",           "SBI Feedback (Situation-Behavior-Impact)",      "Corporate & Engineering"),
    ("t_nvc_observation",        "NVC Observation",                               "Corporate & Engineering"),
    ("t_nvc_feeling",            "NVC Feeling",                                   "Corporate & Engineering"),
    ("t_nvc_need",               "NVC Need",                                      "Corporate & Engineering"),
    ("t_nvc_request",            "NVC Request",                                   "Corporate & Engineering"),
    ("t_radical_candor",         "Radical Candor (Care Personally + Challenge Directly)","Corporate & Engineering"),
    ("t_karpman_rescue",         "Karpman Winner's Triangle — Resource",          "Corporate & Engineering"),
    ("t_accountability_convo",   "Accountability Conversation (SBI+Follow-up)",  "Corporate & Engineering"),
    ("t_psychological_safety",   "Psychological Safety Priming",                  "Corporate & Engineering"),
    ("t_active_listening_corp",  "Active Listening (Corporate)",                  "Corporate & Engineering"),
    # ── Education (CoachIDL / BKT / Scaffolding) ─────────────────────────────
    ("t_scaffold_tier1",         "Scaffolded Hint Tier 1 (Minimal Support)",      "Education"),
    ("t_scaffold_tier2",         "Scaffolded Hint Tier 2 (Moderate Support)",     "Education"),
    ("t_scaffold_tier3",         "Scaffolded Hint Tier 3 (Near-Complete Guide)",  "Education"),
    ("t_socratic_q",             "Socratic Questioning",                          "Education"),
    ("t_praise_effort",          "Praise for Effort (Growth Mindset)",            "Education"),
    ("t_teach_back_edu",         "Teach-Back (Education)",                        "Education"),
    ("t_coachydl_demo",          "CoachIDL Demonstrate Act",                      "Education"),
    ("t_coachydl_elicit",        "CoachIDL Elicit Act",                           "Education"),
    ("t_coachydl_evaluate",      "CoachIDL Evaluate Act",                         "Education"),
    ("t_coachydl_recast",        "CoachIDL Recast Act",                           "Education"),
    ("t_retrieval_practice",     "Retrieval Practice (Spaced Repetition)",        "Education"),
    ("t_elaborative_interrog",   "Elaborative Interrogation",                     "Education"),
    ("t_analogy_bridge",         "Analogy Bridge (Prior Knowledge Link)",         "Education"),
    ("t_think_aloud",            "Think-Aloud Modeling",                          "Education"),
    ("t_error_analysis",         "Error Analysis Prompt",                         "Education"),
    # ── Cross-domain core techniques (from Phase 3/4 core ontology) ──────────
    ("t_active_listening_core",  "Active Listening (Core)",                        "Core"),
    ("t_rapport_building",       "Rapport Building (Core)",                        "Core"),
    ("t_open_questions_core",    "Open-Ended Questions (Core)",                    "Core"),
    ("t_closed_questions_core",  "Closed Questions (Core)",                        "Core"),
    ("t_paraphrasing_core",      "Paraphrasing (Core)",                            "Core"),
    ("t_summarising",            "Summarising",                                    "Core"),
    ("t_reframing",              "Cognitive Reframing",                            "Core"),
    ("t_validation",             "Emotional Validation",                           "Core"),
    ("t_normalization_core",     "Normalisation (Core)",                           "Core"),
    ("t_empathic_accuracy",      "Empathic Accuracy",                              "Core"),
    ("t_nonverbal_mirroring",    "Nonverbal Mirroring",                            "Core"),
    ("t_pacing",                 "Pacing (Communication Rhythm)",                  "Core"),
    ("t_chunking_core",          "Information Chunking (Core)",                    "Core"),
    ("t_signposting_core",       "Signposting (Core)",                             "Core"),
    ("t_perspective_taking",     "Perspective Taking",                             "Core"),
    ("t_active_waiting",         "Active Waiting (Silence)",                       "Core"),
    ("t_door_opener",            "Door Opener",                                    "Core"),
    ("t_minimal_encouragers_core","Minimal Encouragers (Core)",                    "Core"),
    ("t_istatement",             "I-Statement",                                    "Core"),
    ("t_meta_communication",     "Meta-Communication",                             "Core"),
    ("t_grounding",              "Grounding Technique",                            "Core"),
]


# ─────────────────────────────────────────────────────────────────────────────
# MOCK EMBEDDING (reproducible, no ML required)
# ─────────────────────────────────────────────────────────────────────────────

def mock_embedding(technique_id: str, dims: int = DIMS) -> list:
    """
    Reproducible pseudo-random vector seeded by the SHA-256 hash of the
    technique ID, then L2-normalised to unit length (matches cosine index).
    """
    import struct
    h = hashlib.sha256(technique_id.encode()).digest()
    # Expand hash to `dims` floats via XOR rotation
    rng_seed = int.from_bytes(h[:4], 'big')
    vec = []
    for i in range(dims):
        rng_seed = (rng_seed * 1664525 + 1013904223) & 0xFFFFFFFF
        rotated  = (rng_seed ^ int.from_bytes(h[(i % 28):(i % 28) + 4], 'big')) & 0xFFFFFFFF
        val = struct.unpack('f', struct.pack('I', rotated))[0]
        if not (-1e10 < val < 1e10):
            val = float(rotated % 1000) / 1000.0 - 0.5
        vec.append(val)
    # L2 normalise
    mag = sum(v * v for v in vec) ** 0.5
    if mag < 1e-9:
        mag = 1.0
    return [round(v / mag, 8) for v in vec]


# ─────────────────────────────────────────────────────────────────────────────
# REAL EMBEDDING (sentence-transformers)
# ─────────────────────────────────────────────────────────────────────────────

def real_embeddings(technique_texts: list) -> list:
    try:
        from sentence_transformers import SentenceTransformer
    except ImportError:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install",
                               "sentence-transformers", "-q"])
        from sentence_transformers import SentenceTransformer

    model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
    vecs  = model.encode(technique_texts, normalize_embeddings=True, show_progress_bar=True)
    return [v.tolist() for v in vecs]


# ─────────────────────────────────────────────────────────────────────────────
# WRITE TO NEO4J
# ─────────────────────────────────────────────────────────────────────────────

def fetch_live_techniques(uri: str, user: str, password: str) -> list:
    """Query live Neo4j for all (cardId, name) pairs — used as embedding keys."""
    try:
        from neo4j import GraphDatabase
    except ImportError:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "neo4j", "-q"])
        from neo4j import GraphDatabase

    driver = GraphDatabase.driver(uri, auth=(user, password))
    rows = []
    with driver.session() as db:
        results = db.run(
            "MATCH (t:Technique) WHERE t.cardId IS NOT NULL "
            "RETURN t.cardId AS cid, coalesce(t.name, t.cardId) AS name"
        )
        for r in results:
            rows.append((r["cid"], r["name"]))
    driver.close()
    return rows


def write_to_neo4j(embeddings: dict, uri: str, user: str, password: str) -> int:
    """Write embeddings to Technique nodes matched by cardId."""
    try:
        from neo4j import GraphDatabase
    except ImportError:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "neo4j", "-q"])
        from neo4j import GraphDatabase

    driver = GraphDatabase.driver(uri, auth=(user, password))
    updated = 0
    with driver.session() as db:
        for cid, vec in embeddings.items():
            r = db.run(
                "MATCH (t:Technique {cardId: $cid}) SET t.embedding = $vec RETURN t.cardId",
                cid=cid, vec=vec,
            )
            if r.single():
                updated += 1
    driver.close()
    return updated


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 11 Embedding Generator")
    parser.add_argument("--real",     action="store_true",
                        help="Use sentence-transformers (requires install + download)")
    parser.add_argument("--neo4j",    action="store_true",
                        help="Also write embeddings to live Neo4j instance")
    parser.add_argument("--uri",      default="bolt://localhost:7687")
    parser.add_argument("--user",     default="neo4j")
    parser.add_argument("--password", default="uckb_admin_2024")
    args = parser.parse_args()

    mode = "real" if args.real else "mock"
    print(f"\nGenerating {DIMS}-dim embeddings for {len(TECHNIQUES)} Technique nodes ({mode} mode)...")

    # If connected to Neo4j, use live technique cardIds (overrides static list)
    technique_source = TECHNIQUES  # default: static list
    if args.neo4j:
        print(f"  Fetching live Technique cardIds from {args.uri}...")
        live = fetch_live_techniques(args.uri, args.user, args.password)
        if live:
            technique_source = [(cid, name, "") for cid, name in live]
            print(f"  Found {len(live)} Technique nodes with cardId in live graph.")

    if args.real:
        texts = [f"{name}." for _, name, _ in technique_source]
        vecs  = real_embeddings(texts)
        embeddings = {tid: vec for (tid, _, _), vec in zip(technique_source, vecs)}
    else:
        embeddings = {tid: mock_embedding(tid) for tid, _, _ in technique_source}

    out = DATA_DIR / "embeddings.json"
    out.write_text(json.dumps(embeddings, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"\n  Written: {out.relative_to(ROOT.parent.parent)}")
    print(f"  Technique nodes with embeddings: {len(embeddings)}")
    print(f"  Vector dimensions:               {DIMS}")
    print(f"  Mode:                            {mode}")

    # Spot-check: verify unit norm for first 3
    import math
    print("\n  L2-norm spot-check (should be ~1.0):")
    for tid in list(embeddings)[:3]:
        v   = embeddings[tid]
        mag = math.sqrt(sum(x * x for x in v))
        print(f"    {tid:<35} ‖v‖={mag:.6f}")

    if args.neo4j:
        print(f"\nWriting embeddings to Neo4j at {args.uri}...")
        n = write_to_neo4j(embeddings, args.uri, args.user, args.password)
        print(f"  Updated {n} Technique nodes with .embedding property.")

    print("\nEmbedding generation complete.")


if __name__ == "__main__":
    main()
