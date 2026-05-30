"""
UCKB Phase 10 — D-SMART Session Simulator
Demonstrates a full D-SMART processing loop on demo_session_001 using only
in-memory Python data structures (no Neo4j required).

The script shows:
  1. Fact extraction pass — ConversationFacts derived from each Turn
  2. Conflict detection — DSM checks new facts against existing graph
  3. SUPERSEDES invalidation — newer fact overwrites older
  4. Reasoning Tree expansion — 3 candidates generated for the conflict turn
  5. NLI selection — composite score computed, best candidate selected
  6. ConsistencyReport — DER snapshot computed for the session

Output is printed to stdout and mirrors the data in scripts 22-26.
Run this before import_phase10_neo4j.py to verify the logic is sound.

Usage:
    python simulate_dsmart_session.py
"""

import sys
import io
from dataclasses import dataclass, field
from typing import Optional

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")


# ─────────────────────────────────────────────────────────────────────────────
# DATA CLASSES
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Turn:
    turn_id:     str
    session_id:  str
    turn_number: int
    speaker:     str
    utterance:   str
    emotion:     str
    protocol_step: str


@dataclass
class ConversationFact:
    fact_id:     str
    session_id:  str
    content:     str
    fact_type:   str   # commitment | position | information | denial
    speaker:     str
    turn_number: int
    valid_from:  int
    valid_until: int = 9999
    weight:      float = 0.8
    superseded:  bool = False


@dataclass
class ConsistencyConflict:
    conflict_id:         str
    session_id:          str
    conflict_type:       str   # factual | goal | protocol
    severity:            str   # critical | moderate | minor
    description:         str
    detected_at_turn:    int
    resolution_strategy: str
    resolved_at_turn:    Optional[int] = None


@dataclass
class ReasoningCandidate:
    candidate_id:       str
    session_id:         str
    turn_number:        int
    response_sketch:    str
    nli_score:          float
    protocol_deviation: float
    goal_alignment:     float
    composite_score:    float = 0.0
    selected:           bool = False

    def compute_composite(self):
        self.composite_score = round(
            0.5 * self.nli_score +
            0.3 * self.goal_alignment +
            0.2 * (1.0 - self.protocol_deviation),
            3
        )


@dataclass
class DSMState:
    session_id: str
    facts:      list = field(default_factory=list)
    conflicts:  list = field(default_factory=list)

    def active_facts(self):
        return [f for f in self.facts if not f.superseded]

    def add_fact(self, fact: ConversationFact):
        self.facts.append(fact)

    def check_conflicts(self, new_fact: ConversationFact) -> list:
        """Simple contradiction heuristic: denial vs information on same entity."""
        conflicts = []
        for existing in self.active_facts():
            if existing.fact_id == new_fact.fact_id:
                continue
            # Denial contradicts a prior information fact about the same topic
            if (new_fact.fact_type == "denial" and existing.fact_type == "information"):
                if _topic_overlap(new_fact.content, existing.content):
                    conflicts.append((existing, new_fact))
            # Information that explicitly negates a prior claim
            if (new_fact.fact_type == "information" and existing.fact_type == "information"):
                if _negation_detected(new_fact.content, existing.content):
                    conflicts.append((existing, new_fact))
        return conflicts

    def supersede(self, newer: ConversationFact, older: ConversationFact, turn: int):
        older.superseded  = True
        older.valid_until = turn
        older.weight      = 0.0
        print(f"    SUPERSEDES: [{newer.fact_id}] invalidates [{older.fact_id}]")


def _topic_overlap(a: str, b: str) -> bool:
    a_words = set(a.lower().split())
    b_words = set(b.lower().split())
    shared  = a_words & b_words - {"the", "a", "is", "to", "and", "or", "in", "of"}
    return len(shared) >= 2


def _negation_detected(newer: str, older: str) -> bool:
    negation_keywords = ["admits", "confesses", "reveals", "corrects", "acknowledges"]
    return any(kw in newer.lower() for kw in negation_keywords) and _topic_overlap(newer, older)


# ─────────────────────────────────────────────────────────────────────────────
# DEMO TURNS — Session 001 (BCSM crisis)
# ─────────────────────────────────────────────────────────────────────────────

DEMO_TURNS = [
    Turn("turn_s001_01", "demo_session_001", 1, "caller",
         "My sister is inside. We had a fight about custody. I need to talk to her.",
         "panic_acute", "bcsm_step_1"),
    Turn("turn_s001_02", "demo_session_001", 2, "caller",
         "I am unarmed. I just want to talk. Please don't send anyone in.",
         "panic_acute", "bcsm_step_1"),
    Turn("turn_s001_03", "demo_session_001", 3, "caller",
         "I will speak calmly. But I never even entered the apartment. I was outside.",
         "distress_verbal", "bcsm_step_2"),
    Turn("turn_s001_04", "demo_session_001", 4, "caller",
         "Okay. I admit I am holding a knife. I just wanted to feel safe.",
         "guarded", "bcsm_step_3"),
]

# Facts to extract per turn (mirrors 22_conversation_facts.cypher)
DEMO_FACTS = [
    ConversationFact("cf_s001_t01_001","demo_session_001","Subject states sister is inside the apartment","information","caller",1,1,weight=0.82),
    ConversationFact("cf_s001_t01_002","demo_session_001","Subject states motive is domestic dispute over custody","position","caller",1,1,weight=0.79),
    ConversationFact("cf_s001_t02_001","demo_session_001","Subject claims to be unarmed","information","caller",2,2,weight=0.75),
    ConversationFact("cf_s001_t03_001","demo_session_001","Subject agrees to speak calmly and not escalate","commitment","caller",3,3,weight=0.74),
    ConversationFact("cf_s001_t03_002","demo_session_001","Subject denies having entered the apartment","denial","caller",3,3,weight=0.71),
    ConversationFact("cf_s001_t04_001","demo_session_001","Subject admits to holding a knife","information","caller",4,4,weight=0.88),
]

# Reasoning Tree candidates at the conflict turn (turn 4)
CANDIDATES_TURN_4 = [
    ReasoningCandidate("rc_s001_t04_001","demo_session_001",4,
        "Acknowledge subject emotional state, validate concern for sister, redirect to weapon safety",
        nli_score=0.71, protocol_deviation=0.10, goal_alignment=0.88),
    ReasoningCandidate("rc_s001_t04_002","demo_session_001",4,
        "Directly address weapon admission, issue safety instruction, demand compliance",
        nli_score=0.31, protocol_deviation=0.40, goal_alignment=0.45),
    ReasoningCandidate("rc_s001_t04_003","demo_session_001",4,
        "Ask clarifying question to resolve presence/weapon contradiction before advancing protocol",
        nli_score=0.62, protocol_deviation=0.15, goal_alignment=0.72),
]


# ─────────────────────────────────────────────────────────────────────────────
# D-SMART LOOP
# ─────────────────────────────────────────────────────────────────────────────

def compute_der(dsm: DSMState) -> float:
    """
    Simplified DER formula:
      base = 1.0
      penalise 0.1 per unresolved critical conflict
      penalise 0.05 per unresolved moderate conflict
      penalise 0.02 per superseded fact (shows DSM had to correct itself)
    """
    score = 1.0
    for conflict in dsm.conflicts:
        if conflict.resolved_at_turn is None:
            if conflict.severity == "critical":
                score -= 0.15
            elif conflict.severity == "moderate":
                score -= 0.10
            else:
                score -= 0.05
    superseded_count = sum(1 for f in dsm.facts if f.superseded)
    score -= superseded_count * 0.02
    return max(round(score, 3), 0.0)


def run_dsmart_loop():
    print("=" * 66)
    print("  UCKB Phase 10 — D-SMART Simulation: demo_session_001")
    print("  BCSM Crisis Session — Turns 1-4")
    print("=" * 66)

    dsm = DSMState(session_id="demo_session_001")

    # Facts indexed by turn
    facts_by_turn = {}
    for f in DEMO_FACTS:
        facts_by_turn.setdefault(f.turn_number, []).append(f)

    # ── Process turns 1-4 ────────────────────────────────────────────────────
    for turn in DEMO_TURNS:
        print(f"\n── Turn {turn.turn_number} [{turn.speaker}] — emotion: {turn.emotion}")
        print(f"   '{turn.utterance[:80]}'")

        new_facts = facts_by_turn.get(turn.turn_number, [])
        for fact in new_facts:
            print(f"\n  DSM EXTRACT:  [{fact.fact_id}]")
            print(f"    type={fact.fact_type}  speaker={fact.speaker}")
            print(f"    content: \"{fact.content}\"")

            # Check consistency against existing DSM state
            conflicts = dsm.check_conflicts(fact)
            for existing, new in conflicts:
                print(f"\n  CONFLICT DETECTED:")
                print(f"    [{existing.fact_id}] vs [{new.fact_id}]")

                if new.fact_type == "denial":
                    cc = ConsistencyConflict(
                        "cc_s001_001", "demo_session_001", "factual", "critical",
                        f"'{existing.content}' contradicted by '{new.content}'",
                        detected_at_turn=turn.turn_number,
                        resolution_strategy="clarify",
                        resolved_at_turn=turn.turn_number + 1
                    )
                else:
                    cc = ConsistencyConflict(
                        "cc_s001_002", "demo_session_001", "factual", "moderate",
                        f"'{existing.content}' contradicted by '{new.content}'",
                        detected_at_turn=turn.turn_number,
                        resolution_strategy="supersede",
                        resolved_at_turn=turn.turn_number
                    )
                    dsm.supersede(fact, existing, turn.turn_number)
                    cc.resolved_at_turn = turn.turn_number

                dsm.conflicts.append(cc)
                print(f"    → Conflict [{cc.conflict_id}] type={cc.conflict_type} severity={cc.severity}")
                print(f"    → Resolution: {cc.resolution_strategy}")

            dsm.add_fact(fact)

        # ── Reasoning Tree at conflict turn ──────────────────────────────────
        if turn.turn_number == 4 and dsm.conflicts:
            print(f"\n  REASONING TREE — expanding 3 candidates for turn {turn.turn_number}")
            print(f"  DSM state: {len(dsm.active_facts())} active facts, "
                  f"{len(dsm.conflicts)} conflicts")

            for c in CANDIDATES_TURN_4:
                c.compute_composite()
                print(f"\n    Candidate [{c.candidate_id}]")
                print(f"      strategy:    {c.response_sketch[:70]}")
                print(f"      nliScore:    {c.nli_score:.2f}")
                print(f"      goalAlign:   {c.goal_alignment:.2f}")
                print(f"      protoDev:    {c.protocol_deviation:.2f}")
                print(f"      composite:   {c.composite_score:.3f}")

            best = max(CANDIDATES_TURN_4, key=lambda c: c.composite_score)
            best.selected = True

            print(f"\n  RT SELECTION: [{best.candidate_id}]  composite={best.composite_score:.3f}")
            print(f"    → {best.response_sketch}")

    # ── Consistency Report ────────────────────────────────────────────────────
    der = compute_der(dsm)
    active = dsm.active_facts()
    unresolved = [c for c in dsm.conflicts if c.resolved_at_turn is None]

    print(f"\n{'=' * 66}")
    print(f"  CONSISTENCY REPORT — demo_session_001  turn=4")
    print(f"{'=' * 66}")
    print(f"  DER score:          {der:.3f}")
    print(f"  Active facts:       {len(active)}")
    print(f"  Total facts:        {len(dsm.facts)}")
    print(f"  Superseded:         {sum(1 for f in dsm.facts if f.superseded)}")
    print(f"  Total conflicts:    {len(dsm.conflicts)}")
    print(f"  Unresolved:         {len(unresolved)}")
    print(f"\n  Active DSM facts (top by weight):")
    for f in sorted(active, key=lambda x: -x.weight):
        print(f"    [{f.fact_id}]  w={f.weight:.2f}  {f.fact_type}")
        print(f"      \"{f.content[:70]}\"")
    print(f"\n  Conflicts:")
    for cc in dsm.conflicts:
        status = f"resolved at t{cc.resolved_at_turn}" if cc.resolved_at_turn else "UNRESOLVED"
        print(f"    [{cc.conflict_id}]  {cc.conflict_type}/{cc.severity}  {status}")
    print(f"\n  RT selection log:")
    for c in sorted(CANDIDATES_TURN_4, key=lambda x: -x.composite_score):
        marker = " ← SELECTED" if c.selected else ""
        print(f"    [{c.candidate_id}]  composite={c.composite_score:.3f}{marker}")

    print(f"\n{'=' * 66}")
    print("  Simulation complete. Neo4j data in scripts 22-26.")
    print(f"{'=' * 66}")


if __name__ == "__main__":
    run_dsmart_loop()
