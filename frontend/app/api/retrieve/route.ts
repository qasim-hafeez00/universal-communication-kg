import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

// Domain config mirrors the Python HybridRetriever DOMAIN_CONFIGS
const DOMAIN_CONFIGS: Record<string, { bm25: number; vector: number; cypher: number; k: number }> = {
  dispatch:    { bm25: 0.15, vector: 0.25, cypher: 0.60, k: 60 },
  clinical:    { bm25: 0.20, vector: 0.30, cypher: 0.50, k: 60 },
  negotiation: { bm25: 0.30, vector: 0.40, cypher: 0.30, k: 60 },
  legal:       { bm25: 0.40, vector: 0.25, cypher: 0.35, k: 60 },
  corporate:   { bm25: 0.25, vector: 0.35, cypher: 0.40, k: 60 },
  education:   { bm25: 0.20, vector: 0.40, cypher: 0.40, k: 60 },
};

// Mock technique data per domain (mirrors Python MOCK_TECHNIQUES)
const MOCK_TECHNIQUES: Record<string, [string, string, string][]> = {
  dispatch: [
    ["t_bcsm_minimal_enc", "Minimal Encouragers (BCSM Step 2)", "Crisis Dispatch / Emergency"],
    ["t_bcsm_active_listening", "Active Listening (BCSM)", "Crisis Dispatch / Emergency"],
    ["t_bcsm_emotional_labeling", "Emotional Labeling", "Crisis Dispatch / Emergency"],
    ["t_bcsm_mirroring", "Mirroring (BCSM)", "Crisis Dispatch / Emergency"],
    ["t_bcsm_open_ended_q", "Open-Ended Questions (BCSM)", "Crisis Dispatch / Emergency"],
  ],
  clinical: [
    ["t_spikes_empathy_response", "SPIKES Empathy Response (Step E)", "Clinical / Medical"],
    ["t_spikes_setting", "SPIKES Setting (Step S)", "Clinical / Medical"],
    ["t_spikes_perception", "SPIKES Perception Check (Step P)", "Clinical / Medical"],
    ["t_spikes_invitation", "SPIKES Invitation (Step I)", "Clinical / Medical"],
    ["t_spikes_knowledge", "SPIKES Knowledge Delivery (Step K)", "Clinical / Medical"],
  ],
  negotiation: [
    ["t_spin_implication_q", "SPIN Implication Question", "Sales & Negotiation"],
    ["t_spin_situation_q", "SPIN Situation Question", "Sales & Negotiation"],
    ["t_spin_problem_q", "SPIN Problem Question", "Sales & Negotiation"],
    ["t_spin_need_payoff", "SPIN Need-Payoff Question", "Sales & Negotiation"],
    ["t_harvard_batna", "Harvard BATNA Analysis", "Sales & Negotiation"],
  ],
  legal: [
    ["t_peace_probing", "PEACE Probing (Account Phase)", "Legal & Investigative"],
    ["t_peace_free_narrative", "Free Narrative Invitation", "Legal & Investigative"],
    ["t_peace_cognitive_interview", "Cognitive Interview", "Legal & Investigative"],
    ["t_peace_mental_reinstate", "Mental Reinstatement of Context", "Legal & Investigative"],
    ["t_peace_clarification", "PEACE Clarification", "Legal & Investigative"],
  ],
  corporate: [
    ["t_sbi_feedback", "SBI Feedback Model", "Corporate & Engineering"],
    ["t_nvc_observation", "NVC Observation Statement", "Corporate & Engineering"],
    ["t_nvc_feeling", "NVC Feeling Expression", "Corporate & Engineering"],
    ["t_nvc_need", "NVC Need Identification", "Corporate & Engineering"],
    ["t_nvc_request", "NVC Request Formulation", "Corporate & Engineering"],
  ],
  education: [
    ["t_scaffold_tier1", "Tier 1 Scaffold (BKT < 0.4)", "Education"],
    ["t_scaffold_tier2", "Tier 2 Scaffold (BKT 0.4-0.7)", "Education"],
    ["t_socratic_q", "Socratic Questioning", "Education"],
    ["t_coachidl_hint", "CoachIDL Hint Sequence", "Education"],
    ["t_bkt_mastery_check", "BKT Mastery Check", "Education"],
  ],
};

function rrfScore(rank: number, k: number, weight: number): number {
  return weight / (k + rank);
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { domain = "dispatch", query = "" } = body as { domain: string; query: string };

    const cfg = DOMAIN_CONFIGS[domain] ?? DOMAIN_CONFIGS.dispatch;
    const techniques = MOCK_TECHNIQUES[domain] ?? MOCK_TECHNIQUES.dispatch;

    // Simulate BM25: rank by query word overlap
    const words = query.toLowerCase().split(/\s+/);
    const bm25Leg = [...techniques]
      .map(([id, name, dom]) => ({
        techniqueId: id,
        techniqueName: name,
        domain: dom,
        rawScore: words.filter((w) => name.toLowerCase().includes(w)).length / words.length + Math.random() * 0.3,
      }))
      .sort((a, b) => b.rawScore - a.rawScore)
      .map((t, i) => ({ ...t, rank: i + 1, score: t.rawScore }));

    // Simulate vector: shuffled (semantic similarity mock)
    const vectorLeg = [...techniques]
      .map(([id, name, dom]) => ({ techniqueId: id, techniqueName: name, domain: dom, score: Math.random() }))
      .sort((a, b) => b.score - a.score)
      .map((t, i) => ({ ...t, rank: i + 1 }));

    // Simulate cypher: domain-first ordering (graph traversal mock)
    const cypherLeg = [...techniques]
      .map(([id, name, dom], idx) => ({
        techniqueId: id, techniqueName: name, domain: dom,
        score: (techniques.length - idx) / techniques.length + Math.random() * 0.1,
      }))
      .sort((a, b) => b.score - a.score)
      .map((t, i) => ({ ...t, rank: i + 1 }));

    // RRF fusion
    const allIds = techniques.map(([id]) => id);
    const fused = allIds.map((id) => {
      const b = bm25Leg.find((r) => r.techniqueId === id)!;
      const v = vectorLeg.find((r) => r.techniqueId === id)!;
      const c = cypherLeg.find((r) => r.techniqueId === id)!;
      const score =
        rrfScore(b.rank, cfg.k, cfg.bm25) +
        rrfScore(v.rank, cfg.k, cfg.vector) +
        rrfScore(c.rank, cfg.k, cfg.cypher);
      return {
        techniqueId: id,
        techniqueName: b.techniqueName,
        domain: b.domain,
        rrfScore: score,
        bm25Rank: b.rank,
        vectorRank: v.rank,
        cypherRank: c.rank,
        safetyValidated: id !== "legal_contraindicated_reid",
      };
    });

    fused.sort((a, b) => b.rrfScore - a.rrfScore);
    const fusedRanked = fused.map((r, i) => ({ ...r, fusedRank: i + 1 }));

    return NextResponse.json({
      query,
      domain,
      bm25Leg: bm25Leg.map((r) => ({
        rank: r.rank,
        score: r.score,
        techniqueId: r.techniqueId,
        techniqueName: r.techniqueName,
        domain: r.domain,
      })),
      vectorLeg: vectorLeg.map((r) => ({
        rank: r.rank,
        score: r.score,
        techniqueId: r.techniqueId,
        techniqueName: r.techniqueName,
        domain: r.domain,
      })),
      cypherLeg: cypherLeg.map((r) => ({
        rank: r.rank,
        score: r.score,
        techniqueId: r.techniqueId,
        techniqueName: r.techniqueName,
        domain: r.domain,
      })),
      fused: fusedRanked,
    });
  } catch (err) {
    console.error("POST /api/retrieve error:", err);
    return NextResponse.json({ error: "Retrieval failed" }, { status: 500 });
  }
}
