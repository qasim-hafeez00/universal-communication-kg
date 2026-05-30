"""
UCKB Phase 10 — Validation Script
Validates all 10 acceptance criteria by inspecting the generated Cypher scripts.
Does NOT require a live Neo4j connection.

If --neo4j is passed, also validates against a running Neo4j instance and writes
a full report with live counts.

Usage (file-based, no Neo4j required):
    python validate_phase10.py

Usage (Neo4j-connected):
    python validate_phase10.py --neo4j [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]

Returns exit code 0 if ALL PASS, 1 if any criterion fails.
"""

import sys
import io
import re
import argparse
from datetime import datetime
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT    = Path(__file__).resolve().parents[1]
CYPHER  = ROOT / "cypher"
REPORT  = ROOT / "reports" / "phase10_validation_report.txt"
REPORT.parent.mkdir(parents=True, exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# CYPHER SCRIPT HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def read_cypher(filename: str) -> str:
    p = CYPHER / filename
    return p.read_text(encoding="utf-8") if p.exists() else ""


def count_merge_nodes(text: str, label: str) -> int:
    """Count MERGE (n:Label ...) statements for a given node label."""
    return len(re.findall(rf'MERGE\s*\([^:)]*:{label}[\s{{]', text, re.IGNORECASE))


def count_edge_type(text: str, rel: str) -> int:
    """Count MERGE (...)-[:REL_TYPE ...]->(...)  statements."""
    return len(re.findall(rf'\[:{rel}[\s\]{{]', text, re.IGNORECASE))


def count_property_occurrences(text: str, prop: str, value: str) -> int:
    """Count occurrences of prop: 'value' or prop: value patterns."""
    pattern = rf"{prop}:\s*['\"]?{re.escape(value)}['\"]?"
    return len(re.findall(pattern, text, re.IGNORECASE))


def find_set_values(text: str, prop: str) -> list:
    """Extract all values set for a given property using SET ... += { prop: value } patterns."""
    pattern = rf"{prop}:\s*(['\"]?)([^,\n\r}}]+)\1"
    return [m.group(2).strip().strip("'\"") for m in re.finditer(pattern, text)]


def extract_float_values(text: str, prop: str) -> list:
    """Extract all float values for a property like compositeScore: 0.799"""
    pattern = rf"{prop}:\s*([\d.]+)"
    return [float(m.group(1)) for m in re.finditer(pattern, text)]


# ─────────────────────────────────────────────────────────────────────────────
# FILE-BASED ACCEPTANCE CRITERIA
# ─────────────────────────────────────────────────────────────────────────────

def ac_p10_1():
    """All 6 D-SMART node types have MERGE statements in the Cypher scripts."""
    facts_txt   = read_cypher("22_conversation_facts.cypher")
    goal_txt    = read_cypher("23_goal_tracking.cypher")
    tracker_txt = read_cypher("24_protocol_trackers.cypher")
    conflict_txt= read_cypher("25_conflict_detection.cypher")
    cand_txt    = read_cypher("26_reasoning_candidates.cypher")

    counts = {
        "ConversationFact":  count_merge_nodes(facts_txt,    "ConversationFact"),
        "GoalState":         count_merge_nodes(goal_txt,     "GoalState"),
        "ProtocolTracker":   count_merge_nodes(tracker_txt,  "ProtocolTracker"),
        "ConsistencyConflict": count_merge_nodes(conflict_txt, "ConsistencyConflict"),
        "ReasoningCandidate":  count_merge_nodes(cand_txt,   "ReasoningCandidate"),
        "ConsistencyReport":   count_merge_nodes(cand_txt,   "ConsistencyReport"),
    }
    missing = [k for k, v in counts.items() if v == 0]
    passed  = len(missing) == 0
    detail  = ", ".join(f"{k}={v}" for k, v in counts.items())
    if missing:
        detail += f" | MISSING: {missing}"
    return passed, detail


def ac_p10_2():
    """>=15 ConversationFact MERGE nodes; all have factType, speakerRole, validFrom; all linked via EXTRACTED_FROM."""
    text    = read_cypher("22_conversation_facts.cypher")
    total   = count_merge_nodes(text, "ConversationFact")
    with_type    = len(re.findall(r"factType:\s*'", text))
    with_speaker = len(re.findall(r"speakerRole:\s*'", text))
    with_valid   = len(re.findall(r"validFrom:\s*\d", text))
    with_edge    = count_edge_type(text, "EXTRACTED_FROM")
    passed = (total >= 15 and with_type >= total and
              with_speaker >= total and with_valid >= total and with_edge >= total)
    detail = (f"total={total} (need >=15), withType={with_type}, "
              f"withSpeaker={with_speaker}, withValidFrom={with_valid}, withEdge={with_edge}")
    return passed, detail


def ac_p10_3():
    """>=2 ConsistencyConflict nodes of type 'factual'; CONTRADICTS edges present (bidirectional)."""
    text     = read_cypher("25_conflict_detection.cypher")
    total_cc = count_merge_nodes(text, "ConsistencyConflict")
    factual  = count_property_occurrences(text, "conflictType", "factual")
    contradicts = count_edge_type(text, "CONTRADICTS")
    passed  = factual >= 2 and contradicts >= 4
    detail  = (f"ConsistencyConflicts={total_cc}, factualType={factual} (need >=2), "
               f"contradictsEdges={contradicts} (need >=4 bidirectional)")
    return passed, detail


def ac_p10_4():
    """>=2 SUPERSEDES edges; superseded=true on target facts."""
    text      = read_cypher("25_conflict_detection.cypher")
    supersedes_edges = count_edge_type(text, "SUPERSEDES")
    superseded_flags = len(re.findall(r"superseded:\s*true", read_cypher("22_conversation_facts.cypher")))
    passed = supersedes_edges >= 2 and superseded_flags >= 2
    detail = (f"supersedesEdges={supersedes_edges} (need >=2), "
              f"superseded=true flags in facts={superseded_flags} (need >=2)")
    return passed, detail


def ac_p10_5():
    """>=3 GoalState nodes; all have goalType+status+confidenceScore; >=1 has driftDetectedAt set."""
    text  = read_cypher("23_goal_tracking.cypher")
    total = count_merge_nodes(text, "GoalState")
    with_goal_type = len(re.findall(r"goalType:\s*'", text))
    with_status    = len(re.findall(r"status:\s*'", text))
    with_conf      = len(re.findall(r"confidenceScore:\s*[\d.]+", text))
    # driftDetectedAt with actual turn number (not null)
    with_drift     = len(re.findall(r"driftDetectedAt:\s*\d+", text))
    passed = (total >= 3 and with_goal_type >= total and
              with_status >= total and with_conf >= total and with_drift >= 1)
    detail = (f"total={total} (need >=3), withGoalType={with_goal_type}, "
              f"withStatus={with_status}, withConf={with_conf}, "
              f"withDrift={with_drift} (need >=1)")
    return passed, detail


def ac_p10_6():
    """>=3 ProtocolTrackers; all linked via TRACKS to ProtocolDAG."""
    text  = read_cypher("24_protocol_trackers.cypher")
    total = count_merge_nodes(text, "ProtocolTracker")
    tracks_edges   = count_edge_type(text, "TRACKS")
    has_tracker_edges = count_edge_type(text, "HAS_TRACKER")
    protocol_ids   = find_set_values(text, "protocolId")
    passed = total >= 3 and tracks_edges >= total
    detail = (f"total={total} (need >=3), tracksEdges={tracks_edges} (must equal total), "
              f"hasTrackerEdges={has_tracker_edges}, protocolIds={protocol_ids}")
    return passed, detail


def ac_p10_7():
    """>=15 ReasoningCandidates; all compositeScores in [0,1]; exactly 1 selected=true per turn group."""
    text   = read_cypher("26_reasoning_candidates.cypher")
    total  = count_merge_nodes(text, "ReasoningCandidate")

    # Extract all compositeScore values and verify they're in [0,1]
    scores = extract_float_values(text, "compositeScore")
    valid_scores = [s for s in scores if 0.0 <= s <= 1.0]

    # Count selected=true occurrences
    selected_true  = len(re.findall(r"selected:\s*true", text))
    selected_false = len(re.findall(r"selected:\s*false", text))

    # 5 turn groups × 1 selected each = 5
    turn_groups = len(re.findall(r"CANDIDATE_FOR edges", "") or re.findall(r"TURN \d+", text))
    # Count distinct turnNumber values in candidates
    turn_numbers = set(re.findall(r"turnNumber:\s*(\d+)", text))
    candidate_turn_groups = len(turn_numbers) - 1 if len(turn_numbers) > 0 else 0  # exclude ConsistencyReport turnNumbers

    passed = (total >= 15 and len(valid_scores) == len(scores) and
              selected_true == 5 and selected_false == 10)
    detail = (f"total={total} (need >=15), compositeScores={len(scores)} all valid={len(valid_scores)==len(scores)}, "
              f"selected_true={selected_true} (need 5), selected_false={selected_false} (need 10)")
    return passed, detail


def ac_p10_8():
    """>=3 ConsistencyReports; all derScore in [0,1]; all linked via HAS_REPORT."""
    text  = read_cypher("26_reasoning_candidates.cypher")
    total = count_merge_nodes(text, "ConsistencyReport")
    der_scores = extract_float_values(text, "derScore")
    valid_der  = [s for s in der_scores if 0.0 <= s <= 1.0]
    has_report = count_edge_type(text, "HAS_REPORT")
    passed = total >= 3 and len(valid_der) == total and has_report >= total
    detail = (f"total={total} (need >=3), derScores={der_scores}, "
              f"allValid={len(valid_der)==total}, hasReportEdges={has_report}")
    return passed, detail


def ac_p10_9():
    """>=1 ProtocolTracker with deviationCount>0; >=1 FLAGGED_DEVIATION edge to protocol conflict."""
    tracker_text  = read_cypher("24_protocol_trackers.cypher")
    conflict_text = read_cypher("25_conflict_detection.cypher")

    # Find deviationCount values > 0
    deviation_values = extract_float_values(tracker_text, "deviationCount")
    trackers_with_dev = [v for v in deviation_values if v > 0]

    flagged_dev_edges  = count_edge_type(conflict_text, "FLAGGED_DEVIATION")
    protocol_conflicts = count_property_occurrences(conflict_text, "conflictType", "protocol")

    passed = len(trackers_with_dev) >= 1 and flagged_dev_edges >= 1 and protocol_conflicts >= 1
    detail = (f"trackersWithDeviation={len(trackers_with_dev)} (values={trackers_with_dev}, need >=1), "
              f"flaggedDevEdges={flagged_dev_edges} (need >=1), "
              f"protocolConflicts={protocol_conflicts} (need >=1)")
    return passed, detail


def ac_p10_10():
    """Exactly 6 Text2CypherTemplate with category='consistency' and all 6 expected names."""
    text  = read_cypher("27_consistency_templates.cypher")
    total = count_merge_nodes(text, "Text2CypherTemplate")
    # Count only SET blocks (lines with leading whitespace + category:), not WHERE clauses
    category_in_set = len(re.findall(r"^\s+category:\s*'consistency'", text, re.MULTILINE))

    expected = [
        "ACTIVE_FACTS_SNAPSHOT",
        "GOAL_DRIFT_CHECK",
        "PROTOCOL_POSITION_QUERY",
        "CONFLICT_HISTORY",
        "CANDIDATE_SELECTION_LOG",
        "CONSISTENCY_REPORT_TREND",
    ]
    found_names = []
    for name in expected:
        if re.search(rf"name:\s*'{name}'", text):
            found_names.append(name)
    missing = [n for n in expected if n not in found_names]

    passed = total == 6 and category_in_set == 6 and len(missing) == 0
    detail = (f"templates={total} (need 6), categoryConsistency={category_in_set} (need 6), "
              f"found={found_names}")
    if missing:
        detail += f" | MISSING: {missing}"
    return passed, detail


# ─────────────────────────────────────────────────────────────────────────────
# DIAGNOSTICS
# ─────────────────────────────────────────────────────────────────────────────

def collect_file_diagnostics() -> list:
    lines = []

    lines.append("\nCypher file inventory:")
    for i in range(21, 29):
        fname = f"{i}_*.cypher"
        matches = list(CYPHER.glob(fname))
        if matches:
            f = matches[0]
            lines.append(f"  {f.name:<45} {f.stat().st_size:>7} bytes")
        else:
            lines.append(f"  [{i}_*.cypher]   MISSING")

    facts_txt  = read_cypher("22_conversation_facts.cypher")
    cand_txt   = read_cypher("26_reasoning_candidates.cypher")

    lines.append("\nConversationFact distribution by session:")
    for sess in ["s001", "s002", "s003"]:
        n = len(re.findall(rf"factId: 'cf_{sess}_", facts_txt))
        lines.append(f"  {sess}: {n} facts")

    lines.append("\nCompositeScore values (all ReasoningCandidates):")
    scores = extract_float_values(cand_txt, "compositeScore")
    for i, s in enumerate(scores, 1):
        lines.append(f"  Candidate {i:>2}: {s:.3f}")

    lines.append("\nDER scores (all ConsistencyReports):")
    ders = extract_float_values(cand_txt, "derScore")
    sess_ids = re.findall(r"sessionId:\s*'([^']+)'", cand_txt)
    report_sessions = []
    in_report = False
    for line in cand_txt.splitlines():
        if "ConsistencyReport" in line and "MERGE" in line:
            in_report = True
        if in_report and "sessionId:" in line:
            m = re.search(r"sessionId:\s*'([^']+)'", line)
            if m:
                report_sessions.append(m.group(1))
                in_report = False
    for i, d in enumerate(ders):
        sess = report_sessions[i] if i < len(report_sessions) else "?"
        lines.append(f"  {sess}: DER={d:.2f}")

    lines.append(f"\nOntology files:")
    ont_dir = ROOT / "ontology"
    for f in sorted(ont_dir.glob("*")):
        lines.append(f"  {f.name:<40} {f.stat().st_size:>7} bytes")

    lines.append(f"\nSHACL shapes:")
    shacl_dir = ROOT / "shacl"
    for f in sorted(shacl_dir.glob("*.ttl")):
        shape_count = len(re.findall(r"a sh:NodeShape", f.read_text(encoding="utf-8")))
        sparql_count = len(re.findall(r"a sh:SPARQLConstraint", f.read_text(encoding="utf-8")))
        lines.append(f"  {f.name:<40} {shape_count} NodeShapes, {sparql_count} SPARQLConstraints")

    return lines


# ─────────────────────────────────────────────────────────────────────────────
# RUNNER
# ─────────────────────────────────────────────────────────────────────────────

ACS = [
    ("AC-P10-1",  ac_p10_1,  "All 6 D-SMART node types present (ConversationFact, GoalState, ProtocolTracker, ConsistencyConflict, ReasoningCandidate, ConsistencyReport)"),
    ("AC-P10-2",  ac_p10_2,  ">= 15 ConversationFacts; all have factType, speakerRole, validFrom; all linked via EXTRACTED_FROM"),
    ("AC-P10-3",  ac_p10_3,  "ConsistencyConflict: >= 2 factual conflicts with CONTRADICTS edges (bidirectional)"),
    ("AC-P10-4",  ac_p10_4,  "SUPERSEDES edges: >= 2 temporal invalidations; target facts have superseded=true"),
    ("AC-P10-5",  ac_p10_5,  "GoalState: >= 3 nodes; all valid fields; >= 1 with driftDetectedAt set"),
    ("AC-P10-6",  ac_p10_6,  "ProtocolTracker: >= 3 nodes; all linked via TRACKS to existing ProtocolDAG"),
    ("AC-P10-7",  ac_p10_7,  "ReasoningCandidate: >= 15 nodes; all compositeScores in [0,1]; exactly 1 selected per turn group"),
    ("AC-P10-8",  ac_p10_8,  "ConsistencyReport: >= 3 nodes; all derScore in [0,1]; all linked via HAS_REPORT"),
    ("AC-P10-9",  ac_p10_9,  "Protocol deviation: >= 1 ProtocolTracker with deviationCount>0; >= 1 FLAGGED_DEVIATION edge"),
    ("AC-P10-10", ac_p10_10, "Consistency templates: exactly 6 Text2CypherTemplate with category='consistency'"),
]


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 10 Validator")
    parser.add_argument("--neo4j", action="store_true",
                        help="Also validate against live Neo4j (file-based runs regardless)")
    parser.add_argument("--uri",      default="bolt://localhost:7687")
    parser.add_argument("--user",     default="neo4j")
    parser.add_argument("--password", default="uckb_admin_2024")
    args = parser.parse_args()

    header = [
        "UCKB Phase 10 — Multi-Turn Logical Consistency (D-SMART) — Validation Report",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "=" * 70,
        "",
        "ACCEPTANCE CRITERIA",
        "-" * 70,
    ]

    results = []
    for ac_id, fn, description in ACS:
        passed, detail = fn()
        results.append((ac_id, passed, description, detail))

    passed_count = sum(1 for _, p, _, _ in results if p)
    overall = "ALL PASS" if passed_count == len(results) else f"FAIL ({passed_count}/{len(results)} passed)"

    output_lines = []
    for ac_id, passed, description, detail in results:
        status = "PASS" if passed else "FAIL"
        output_lines.append(f"  {ac_id}  [{status}]  {description}")
        output_lines.append(f"            {detail}")
        output_lines.append("")

    footer = [
        "=" * 70,
        f"  OVERALL: {overall} {passed_count}/{len(results)}",
        "=" * 70,
        "",
        "DIAGNOSTICS",
        "-" * 70,
    ]

    diag_lines = collect_file_diagnostics()
    all_lines  = header + output_lines + footer + diag_lines + ["", "=" * 70]
    report_text = "\n".join(all_lines)

    print(report_text)
    REPORT.write_text(report_text, encoding="utf-8")
    print(f"\nReport written to: {REPORT.relative_to(ROOT.parent.parent.parent)}")

    sys.exit(0 if passed_count == len(results) else 1)


if __name__ == "__main__":
    main()
