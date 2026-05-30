"""
UCKB Phase 9 — Session Simulator
Creates a third demo session (Sales domain, SPIN protocol) via the parameterized
Neo4j HTTP API. This proves the temporal layer works across domains, not just Crisis.

Also verifies all Phase 9 nodes are in the graph and prints a summary.

Usage:
    python simulate_session.py

Requires: requests  (auto-installed)
Neo4j running at localhost:7474 with neo4j / uckb_admin_2024.
"""

import sys
import base64
import math
import time

try:
    import requests
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "-q"])
    import requests

sys.stdout.reconfigure(encoding="utf-8")

NEO4J_HTTP = "http://localhost:7474/db/neo4j/tx/commit"
NEO4J_USER = "neo4j"
NEO4J_PASS = "uckb_admin_2024"

AUTH    = base64.b64encode(f"{NEO4J_USER}:{NEO4J_PASS}".encode()).decode()
HEADERS = {"Content-Type": "application/json", "Authorization": f"Basic {AUTH}"}

NOW_MS = int(time.time() * 1000)


def run_one(stmt: dict) -> tuple[bool, str]:
    body = {"statements": [stmt]}
    r = requests.post(NEO4J_HTTP, json=body, headers=HEADERS, timeout=30)
    r.raise_for_status()
    data = r.json()
    errs = data.get("errors", [])
    if errs:
        for e in errs:
            code = e.get("code", "")
            if "ConstraintValidationFailed" in code or "AlreadyExists" in code:
                return True, "idempotent"
        return False, str(errs[0].get("message", ""))[:120]
    return True, "ok"


def run_query(cypher: str, params: dict = None) -> list:
    stmt = {"statement": cypher}
    if params:
        stmt["parameters"] = params
    body = {"statements": [stmt]}
    r = requests.post(NEO4J_HTTP, json=body, headers=HEADERS, timeout=30)
    r.raise_for_status()
    data = r.json()
    if data.get("errors"):
        raise RuntimeError(data["errors"])
    rows = data["results"][0]["data"]
    cols = data["results"][0]["columns"]
    return [{c: row["row"][i] for i, c in enumerate(cols)} for row in rows]


def load(statements: list[dict]) -> tuple[int, int]:
    ok = err = 0
    for stmt in statements:
        success, msg = run_one(stmt)
        if success:
            ok += 1
        else:
            err += 1
            print(f"    ERROR: {msg}")
    return ok, err


# ── Session 003: Sales domain — SPIN protocol ────────────────────────────────

def create_sales_session():
    print("\n  Creating Sales SPIN demo session (demo_session_003)...")

    s3_start = NOW_MS - 7200000  # 2h ago
    s3_end   = NOW_MS - 5400000  # 1.5h ago

    stmts = [
        {
            "statement": "MERGE (s:Session {sessionId: $id}) SET s += $props",
            "parameters": {
                "id": "demo_session_003",
                "props": {
                    "userId":        "demo_user_002",
                    "domainContext": "Sales & Negotiation",
                    "startedAt":     s3_start,
                    "endedAt":       s3_end,
                    "turnCount":     4,
                    "outcomeScore":  0.85,
                    "status":        "completed"
                }
            }
        },
    ]

    # 4 Turns: prospect moves defensive → curious → interested → committed
    emotions   = ["defensive", "curious", "interested", "committed"]
    tech_ids   = ["sales_001", "sales_002", "sales_003", "sales_004"]
    step_ids   = ["spin_step_1", "spin_step_2", "spin_step_3", "spin_step_4"]
    speakers   = ["prospect", "agent", "prospect", "prospect"]

    for i, (emo, tech, step, spk) in enumerate(zip(emotions, tech_ids, step_ids, speakers), 1):
        ts = s3_start + i * 600000
        stmts.append({
            "statement": "MERGE (t:Turn {turnId: $id}) SET t += $props",
            "parameters": {
                "id": f"turn_s003_0{i}",
                "props": {
                    "sessionId":              "demo_session_003",
                    "turnNumber":             i,
                    "timestamp":              ts,
                    "speakerRole":            spk,
                    "detectedEmotionName":    emo,
                    "recommendedTechniqueId": tech,
                    "protocolStepId":         step
                }
            }
        })

    # Turn sequence
    for i in range(1, 4):
        stmts.append({
            "statement": """
                MATCH (a:Turn {turnId: $aid}), (b:Turn {turnId: $bid})
                MERGE (a)-[:PRECEDES]->(b)
            """,
            "parameters": {"aid": f"turn_s003_0{i}", "bid": f"turn_s003_0{i+1}"}
        })

    # Session → Turn
    for i in range(1, 5):
        stmts.append({
            "statement": """
                MATCH (s:Session {sessionId: $sid}), (t:Turn {turnId: $tid})
                MERGE (s)-[:HAS_TURN]->(t)
            """,
            "parameters": {"sid": "demo_session_003", "tid": f"turn_s003_0{i}"}
        })

    # EpisodicMemory
    stmts.append({
        "statement": "MERGE (ep:EpisodicMemory {episodeId: $id}) SET ep += $props",
        "parameters": {
            "id": "episode_s003",
            "props": {
                "sessionId":        "demo_session_003",
                "userId":           "demo_user_002",
                "startTurnNumber":  1,
                "endTurnNumber":    4,
                "emotionalArc":     "defensive -> curious -> interested -> committed",
                "protocolId":       "SPIN",
                "lastCompletedStep": 4,
                "protocolCompleted": True,
                "summary":          "Prospect moved from defensive to committed across 4 SPIN turns; full protocol completed with positive close outcome",
                "domainFilter":     "Sales & Negotiation",
                "createdAt":        s3_end
            }
        }
    })

    stmts.append({
        "statement": """
            MATCH (s:Session {sessionId: $sid}), (ep:EpisodicMemory {episodeId: $eid})
            MERGE (s)-[:HAS_EPISODE]->(ep)
        """,
        "parameters": {"sid": "demo_session_003", "eid": "episode_s003"}
    })

    # Protocol linkage
    stmts.append({
        "statement": """
            MATCH (s:Session {sessionId: $sid}), (dag:ProtocolDAG {id: 'spin_dag'})
            MERGE (s)-[:ACTIVE_PROTOCOL {activatedAt: $ts}]->(dag)
        """,
        "parameters": {"sid": "demo_session_003", "ts": s3_start}
    })

    stmts.append({
        "statement": """
            MATCH (s:Session {sessionId: $sid}), (step:ProtocolStep {id: 'spin_step_4'})
            MERGE (s)-[:AT_STEP {reachedAt: $ts, completed: true}]->(step)
        """,
        "parameters": {"sid": "demo_session_003", "ts": s3_end}
    })

    # WorkingMemorySlots for session 003
    wm_ttl = s3_end + 86400000  # active for 24h after session end
    for key, value in [
        ("active_domain",   "Sales & Negotiation"),
        ("active_protocol", "SPIN"),
        ("current_step",    "4"),
        ("prospect_state",  "committed"),
        ("session_outcome", "successful_close"),
    ]:
        stmts.append({
            "statement": "MERGE (wm:WorkingMemorySlot {slotId: $id}) SET wm += $props",
            "parameters": {
                "id": f"wm_s003_{key}",
                "props": {
                    "sessionId": "demo_session_003",
                    "key":       key,
                    "value":     value,
                    "updatedAt": s3_end,
                    "ttl":       wm_ttl,
                    "domain":    "Sales & Negotiation"
                }
            }
        })

    # MemoryTraces for sales session
    for i, tech_id in enumerate(tech_ids, 1):
        age_h = (NOW_MS - (s3_start + i * 600000)) / 3600000
        decay = 0.04  # sales = moderate decay
        iw    = 0.88 + i * 0.02
        w     = iw * math.exp(-decay * age_h)
        stmts.append({
            "statement": "MERGE (mt:MemoryTrace {traceId: $id}) SET mt += $props",
            "parameters": {
                "id": f"trace_u002_{tech_id}",
                "props": {
                    "userId":          "demo_user_002",
                    "techniqueCardId": tech_id,
                    "domain":          "Sales & Negotiation",
                    "successCount":    2,
                    "failCount":       0,
                    "lastUsed":        s3_start + i * 600000,
                    "initialWeight":   round(iw, 3),
                    "weight":          round(w, 4),
                    "decayRate":       decay,
                    "ageHours":        round(age_h, 2)
                }
            }
        })
        # REINFORCES via DAG step as fallback
        stmts.append({
            "statement": """
                MATCH (mt:MemoryTrace {traceId: $tid}),
                      (step:ProtocolStep {id: $step})
                WHERE NOT (mt)-[:REINFORCES]->()
                MERGE (mt)-[:REINFORCES {successCount: 2, lastReinforced: $ts, viaDagStep: true}]->(step)
            """,
            "parameters": {
                "tid":  f"trace_u002_{tech_id}",
                "step": f"spin_step_{i}",
                "ts":   s3_start + i * 600000
            }
        })

    ok, err = load(stmts)
    print(f"    {ok} OK, {err} errors")


# ── Verification queries ─────────────────────────────────────────────────────

def print_verification():
    print("\n" + "=" * 60)
    print("  PHASE 9 GRAPH VERIFICATION")
    print("=" * 60)

    checks = [
        ("Sessions",          "MATCH (n:Session) RETURN count(n) AS n"),
        ("Turns",             "MATCH (n:Turn) RETURN count(n) AS n"),
        ("TemporalFacts",     "MATCH (n:TemporalFact) RETURN count(n) AS n"),
        ("WorkingMemorySlots","MATCH (n:WorkingMemorySlot) RETURN count(n) AS n"),
        ("EpisodicMemories",  "MATCH (n:EpisodicMemory) RETURN count(n) AS n"),
        ("MemoryTraces",      "MATCH (n:MemoryTrace) RETURN count(n) AS n"),
    ]

    for label, query in checks:
        rows = run_query(query)
        n = rows[0]["n"]
        print(f"  {label:<24} {n:>4}")

    print()
    edges = [
        ("HAS_TURN",         "MATCH ()-[r:HAS_TURN]->() RETURN count(r) AS n"),
        ("HAS_EPISODE",      "MATCH ()-[r:HAS_EPISODE]->() RETURN count(r) AS n"),
        ("HAS_SLOT",         "MATCH ()-[r:HAS_SLOT]->() RETURN count(r) AS n"),
        ("FOLLOWS",          "MATCH ()-[r:FOLLOWS]->() RETURN count(r) AS n"),
        ("ACTIVE_PROTOCOL",  "MATCH ()-[r:ACTIVE_PROTOCOL]->() RETURN count(r) AS n"),
        ("AT_STEP",          "MATCH ()-[r:AT_STEP]->() RETURN count(r) AS n"),
        ("REINFORCES",       "MATCH ()-[r:REINFORCES]->() RETURN count(r) AS n"),
        ("DETECTED",         "MATCH ()-[r:DETECTED]->() RETURN count(r) AS n"),
    ]
    for label, query in edges:
        rows = run_query(query)
        n = rows[0]["n"]
        print(f"  {label:<24} {n:>4}")

    print()
    stale_rows = run_query(
        "MATCH (wm:WorkingMemorySlot) WHERE wm.ttl < timestamp() RETURN count(wm) AS n"
    )
    print(f"  Stale slots (TTL expired): {stale_rows[0]['n']}")

    follows_rows = run_query(
        "MATCH (s2:Session)-[:FOLLOWS]->(s1:Session) RETURN s2.sessionId AS from, s1.sessionId AS to"
    )
    print(f"  FOLLOWS edges:")
    for r in follows_rows:
        print(f"    {r['from']} -> {r['to']}")

    templates = run_query(
        "MATCH (t:Text2CypherTemplate {category:'temporal'}) RETURN t.name AS name ORDER BY name"
    )
    print(f"\n  Temporal templates: {len(templates)}")
    for t in templates:
        print(f"    {t['name']}")

    total = run_query("MATCH (n) RETURN count(n) AS n")[0]["n"]
    rels  = run_query("MATCH ()-[r]->() RETURN count(r) AS n")[0]["n"]
    print(f"\n  Total graph: {total} nodes, {rels} relationships")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("  UCKB Phase 9 — Session Simulator")
    print("=" * 60)

    try:
        rows = run_query("MATCH (n) RETURN count(n) AS n")
        print(f"\nConnected. Graph has {rows[0]['n']} nodes.")
    except Exception as e:
        print(f"\nCannot connect to Neo4j: {e}")
        sys.exit(1)

    create_sales_session()
    print_verification()

    print("\n" + "=" * 60)
    print("  Simulation complete.")
    print("  Run validate_phase9.py for the full AC report.")
    print("=" * 60)


if __name__ == "__main__":
    main()
