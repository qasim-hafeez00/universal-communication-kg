"""
UCKB Phase 9 — Validation Script
Runs all 10 acceptance criteria against a running Neo4j instance and writes
outputs/phase9_uckb/reports/phase9_validation_report.txt.

Usage:
    python validate_phase9.py [--uri bolt://localhost:7687] [--user neo4j] [--password uckb_admin_2024]

Prerequisites:
    pip install neo4j
    Phase 9 data loaded via import_phase9_neo4j.py + simulate_session.py.
"""

import sys
import io
import argparse
from datetime import datetime
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

try:
    from neo4j import GraphDatabase, exceptions as neo4j_exc
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "neo4j", "-q"])
    from neo4j import GraphDatabase, exceptions as neo4j_exc

ROOT   = Path(__file__).resolve().parents[1]
REPORT = ROOT / "reports" / "phase9_validation_report.txt"
REPORT.parent.mkdir(parents=True, exist_ok=True)

DEFAULT_URI      = "bolt://localhost:7687"
DEFAULT_USER     = "neo4j"
DEFAULT_PASSWORD = "uckb_admin_2024"


def rq(session, cypher: str, params: dict = None):
    try:
        result = session.run(cypher, params or {})
        return list(result), None
    except neo4j_exc.Neo4jError as e:
        return [], str(e)


# ── AC-P9-1: Temporal node types all present ──────────────────────────────────

def ac_p9_1(session):
    """All 6 temporal node types present with >= 1 instance each."""
    types = ["Session", "Turn", "TemporalFact", "WorkingMemorySlot", "EpisodicMemory", "MemoryTrace"]
    found = {}
    for t in types:
        rows, err = rq(session, f"MATCH (n:{t}) RETURN count(n) AS n")
        found[t] = rows[0]["n"] if (rows and not err) else 0
    missing = [t for t, n in found.items() if n == 0]
    passed = len(missing) == 0
    detail = ", ".join(f"{t}={n}" for t, n in found.items())
    if missing:
        detail += f" | MISSING: {missing}"
    return passed, detail


# ── AC-P9-2: Core temporal indices present ────────────────────────────────────

def ac_p9_2(session):
    """4 core temporal indices exist: turn_timestamp_idx, trace_weight_idx, fact_expiry_idx, wm_slot_ttl_idx."""
    required = ["turn_timestamp_idx", "trace_weight_idx", "fact_expiry_idx", "wm_slot_ttl_idx"]
    # SHOW INDEXES uses YIELD syntax in Neo4j 5.x, not WHERE...RETURN
    rows, err = rq(session, """
        SHOW INDEXES YIELD name, state
        WHERE name IN $names
    """, {"names": required})
    if err:
        return False, f"QUERY ERROR: {err}"
    found = {r["name"]: r["state"] for r in rows}
    missing = [n for n in required if n not in found]
    online  = [n for n, s in found.items() if s == "ONLINE"]
    passed  = len(missing) == 0 and len(online) == len(required)
    detail  = f"found={len(found)}/4, online={len(online)}/4"
    if missing:
        detail += f" | missing: {missing}"
    return passed, detail


# ── AC-P9-3: STALE_MEMORY — stale WorkingMemorySlots identifiable ─────────────

def ac_p9_3(session):
    """At least 2 WorkingMemorySlots with ttl < timestamp() exist."""
    rows, err = rq(session, """
        MATCH (wm:WorkingMemorySlot)
        WHERE wm.ttl < timestamp()
        RETURN count(wm) AS n, collect(wm.slotId) AS ids
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n = rows[0]["n"]
    ids = rows[0]["ids"]
    passed = n >= 2
    detail = f"stale slots={n} (need >=2): {ids}"
    return passed, detail


# ── AC-P9-4: EpisodicMemory nodes with emotionalArc ───────────────────────────

def ac_p9_4(session):
    """At least 2 EpisodicMemory nodes with emotionalArc and domainFilter."""
    rows, err = rq(session, """
        MATCH (ep:EpisodicMemory)
        RETURN count(ep) AS total,
               count(ep.emotionalArc) AS withArc,
               count(ep.domainFilter) AS withFilter,
               count(ep.protocolCompleted) AS withCompleted
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = r["total"] >= 2 and r["withArc"] == r["total"] and r["withFilter"] == r["total"]
    detail = (f"total={r['total']}, withArc={r['withArc']}, "
              f"withFilter={r['withFilter']}, withCompleted={r['withCompleted']} (need >=2 each)")
    return passed, detail


# ── AC-P9-5: MemoryTrace decay parameters valid ────────────────────────────────

def ac_p9_5(session):
    """All MemoryTrace nodes: weight in [0.0, 1.0], decayRate in [0.01, 1.0], total >= 7."""
    rows, err = rq(session, """
        MATCH (mt:MemoryTrace)
        WITH count(mt) AS total,
             count(CASE WHEN mt.weight >= 0.0 AND mt.weight <= 1.0 THEN 1 END) AS weightOK,
             count(CASE WHEN mt.decayRate >= 0.01 AND mt.decayRate <= 1.0 THEN 1 END) AS rateOK
        RETURN total, weightOK, rateOK
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = r["total"] >= 7 and r["weightOK"] == r["total"] and r["rateOK"] == r["total"]
    detail = f"total={r['total']} (need >=7), weightOK={r['weightOK']}, decayRateOK={r['rateOK']}"
    return passed, detail


# ── AC-P9-6: Cross-session FOLLOWS edge exists ────────────────────────────────

def ac_p9_6(session):
    """At least 1 FOLLOWS edge links two Session nodes."""
    rows, err = rq(session, """
        MATCH (s2:Session)-[f:FOLLOWS]->(s1:Session)
        RETURN count(f) AS n,
               collect({from: s2.sessionId, to: s1.sessionId}) AS links
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n    = rows[0]["n"]
    links = rows[0]["links"]
    passed = n >= 1
    detail = f"FOLLOWS edges={n} (need >=1): {links}"
    return passed, detail


# ── AC-P9-7: REINFORCES edges — MemoryTrace → Technique or ProtocolStep ──────

def ac_p9_7(session):
    """At least 3 REINFORCES edges from MemoryTrace nodes."""
    rows, err = rq(session, """
        MATCH (mt:MemoryTrace)-[r:REINFORCES]->(n)
        RETURN count(r) AS edges,
               count(DISTINCT mt) AS tracesLinked
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = r["edges"] >= 3
    detail = f"REINFORCES edges={r['edges']} (need >=3), traces with edges={r['tracesLinked']}"
    return passed, detail


# ── AC-P9-8: 6 temporal Text2CypherTemplate nodes ────────────────────────────

def ac_p9_8(session):
    """Exactly 6 Text2CypherTemplate nodes with category='temporal'."""
    rows, err = rq(session, """
        MATCH (t:Text2CypherTemplate {category: 'temporal'})
        RETURN count(t) AS n, collect(t.name) AS names
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    n     = rows[0]["n"]
    names = sorted(rows[0]["names"])
    passed = n == 6
    detail = f"temporal templates={n} (need 6): {names}"
    return passed, detail


# ── AC-P9-9: EpisodicMemory domainFilter matches SchemaFilterRegistry ─────────

def ac_p9_9(session):
    """All EpisodicMemory domainFilter values match a SchemaFilterRegistry domain (CONTAINS match)."""
    # EpisodicMemory uses full names ('Crisis Dispatch', 'Sales & Negotiation')
    # SchemaFilterRegistry uses short keys ('dispatch', 'negotiation')
    # CONTAINS match: 'crisis dispatch' CONTAINS 'dispatch' → TRUE
    rows, err = rq(session, """
        MATCH (ep:EpisodicMemory)
        OPTIONAL MATCH (reg:SchemaFilterRegistry)
        WHERE toLower(ep.domainFilter) CONTAINS reg.domain
        WITH count(DISTINCT ep) AS total,
             count(DISTINCT CASE WHEN reg IS NOT NULL THEN ep END) AS matched
        RETURN total, matched
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = r["total"] > 0 and r["matched"] == r["total"]
    detail = f"total EpisodicMemory={r['total']}, matching registry={r['matched']} (need equal)"
    return passed, detail


# ── AC-P9-10: ACTIVE_PROTOCOL + AT_STEP edges exist ──────────────────────────

def ac_p9_10(session):
    """At least 2 ACTIVE_PROTOCOL and 2 AT_STEP edges (one per demo session)."""
    rows, err = rq(session, """
        MATCH (s:Session)-[ap:ACTIVE_PROTOCOL]->(dag:ProtocolDAG)
        WITH count(ap) AS apCount
        MATCH (s2:Session)-[ast:AT_STEP]->(step:ProtocolStep)
        RETURN apCount, count(ast) AS astCount
    """)
    if err or not rows:
        return False, f"QUERY ERROR: {err}"
    r = rows[0]
    passed = r["apCount"] >= 2 and r["astCount"] >= 2
    detail = f"ACTIVE_PROTOCOL={r['apCount']} (need >=2), AT_STEP={r['astCount']} (need >=2)"
    return passed, detail


CHECKS = [
    ("AC-P9-1",  "All 6 temporal node types present (Session, Turn, TemporalFact, WorkingMemorySlot, EpisodicMemory, MemoryTrace)", ac_p9_1),
    ("AC-P9-2",  "4 core temporal indices online (turn_timestamp, trace_weight, fact_expiry, wm_slot_ttl)",                          ac_p9_2),
    ("AC-P9-3",  "STALE_MEMORY: >= 2 WorkingMemorySlots with expired TTL identifiable",                                              ac_p9_3),
    ("AC-P9-4",  "EpisodicMemory: >= 2 nodes, all have emotionalArc + domainFilter",                                                 ac_p9_4),
    ("AC-P9-5",  "MemoryTrace: >= 7 nodes, all weight in [0.0,1.0], decayRate in [0.01,1.0]",                                        ac_p9_5),
    ("AC-P9-6",  "Cross-session FOLLOWS edge: >= 1 link between Session nodes",                                                      ac_p9_6),
    ("AC-P9-7",  "REINFORCES edges: >= 3 MemoryTrace → Technique/ProtocolStep",                                                      ac_p9_7),
    ("AC-P9-8",  "Temporal retrieval library: exactly 6 Text2CypherTemplate with category='temporal'",                               ac_p9_8),
    ("AC-P9-9",  "EpisodicMemory domainFilter matches a SchemaFilterRegistry domain",                                                 ac_p9_9),
    ("AC-P9-10", "Protocol DAG continuity: >= 2 ACTIVE_PROTOCOL edges + >= 2 AT_STEP edges",                                         ac_p9_10),
]


def main():
    parser = argparse.ArgumentParser(description="UCKB Phase 9 Validator")
    parser.add_argument("--uri",      default=DEFAULT_URI)
    parser.add_argument("--user",     default=DEFAULT_USER)
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    args = parser.parse_args()

    try:
        driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        driver.verify_connectivity()
    except Exception as e:
        print(f"FATAL: Cannot connect to Neo4j at {args.uri}: {e}")
        sys.exit(1)

    lines = []
    lines.append("UCKB Phase 9 — Temporal Memory Architecture — Validation Report")
    lines.append(f"Generated: {datetime.now():%Y-%m-%d %H:%M:%S}")
    lines.append("=" * 70)
    lines.append("")
    lines.append("ACCEPTANCE CRITERIA")
    lines.append("-" * 70)

    results = []
    with driver.session() as session:
        for ac_id, description, check_fn in CHECKS:
            passed, detail = check_fn(session)
            results.append(passed)
            status = "PASS" if passed else "FAIL"
            lines.append(f"  {ac_id}  [{status}]  {description}")
            lines.append(f"            {detail}")
            lines.append("")

    # Diagnostics
    lines.append("=" * 70)
    all_pass = all(results)
    pass_count = sum(results)
    lines.append(f"  OVERALL: {'ALL PASS' if all_pass else f'FAILURES DETECTED'} {pass_count}/{len(results)}")
    lines.append("=" * 70)

    lines.append("")
    lines.append("DIAGNOSTICS")
    lines.append("-" * 70)

    try:
        with driver.session() as session:
            # Node counts
            rows, _ = rq(session, """
                MATCH (n)
                WHERE n:Session OR n:Turn OR n:TemporalFact OR
                      n:WorkingMemorySlot OR n:EpisodicMemory OR n:MemoryTrace
                WITH labels(n)[0] AS lbl, count(n) AS cnt
                RETURN lbl, cnt ORDER BY lbl
            """)
            lines.append("\nPhase 9 node counts:")
            for r in rows:
                lines.append(f"  {r['lbl']:<28} {r['cnt']}")

            # Relationship counts
            rows, _ = rq(session, """
                MATCH ()-[r]->()
                WHERE type(r) IN ['HAS_TURN','HAS_EPISODE','HAS_SLOT','HAS_FACT',
                                  'DETECTED','FOLLOWS','ACTIVE_PROTOCOL','AT_STEP',
                                  'REINFORCES','TRIGGERED','PRECEDES']
                RETURN type(r) AS rel, count(r) AS cnt ORDER BY cnt DESC
            """)
            lines.append("\nPhase 9 relationship counts:")
            for r in rows:
                lines.append(f"  {r['rel']:<28} {r['cnt']}")

            # Protocol continuity
            rows, _ = rq(session, """
                MATCH (s:Session)
                OPTIONAL MATCH (s)-[:ACTIVE_PROTOCOL]->(dag:ProtocolDAG)
                OPTIONAL MATCH (s)-[:AT_STEP]->(step:ProtocolStep)
                RETURN s.sessionId AS session, dag.protocol AS protocol,
                       step.stepNumber AS step, s.status AS status
                ORDER BY s.startedAt
            """)
            lines.append("\nSession protocol state:")
            for r in rows:
                lines.append(f"  {r['session']:<25} protocol={r['protocol']} step={r['step']} status={r['status']}")

            # Emotional arcs
            rows, _ = rq(session, """
                MATCH (ep:EpisodicMemory)
                RETURN ep.episodeId AS id, ep.emotionalArc AS arc, ep.protocolCompleted AS done
                ORDER BY ep.createdAt
            """)
            lines.append("\nEmotional arcs:")
            for r in rows:
                lines.append(f"  [{r['id']}]  arc: {r['arc']}  completed={r['done']}")

            # Memory trace decay
            rows, _ = rq(session, """
                MATCH (mt:MemoryTrace)
                RETURN mt.traceId AS id, mt.domain AS domain, mt.weight AS w,
                       mt.decayRate AS lambda, mt.ageHours AS age
                ORDER BY mt.weight DESC LIMIT 10
            """)
            lines.append("\nTop MemoryTraces by weight (post-decay):")
            for r in rows:
                lines.append(f"  {r['id']:<35} w={r['w']:.4f}  λ={r['lambda']}  age={r['age']}h")

            # Total graph state
            rows, _ = rq(session, "MATCH (n) RETURN count(n) AS n")
            total_n = rows[0]["n"] if rows else "?"
            rows, _ = rq(session, "MATCH ()-[r]->() RETURN count(r) AS n")
            total_r = rows[0]["n"] if rows else "?"
            lines.append(f"\nTotal graph: {total_n} nodes, {total_r} relationships")

    except Exception as e:
        lines.append(f"\n[Diagnostics skipped: {e}]")

    lines.append("\n" + "=" * 70)

    report_text = "\n".join(lines)
    REPORT.write_text(report_text, encoding="utf-8")
    print(report_text)
    print(f"\nReport written to: {REPORT}")
    driver.close()

    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
