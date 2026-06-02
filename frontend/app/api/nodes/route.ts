import { NextResponse } from "next/server";
import { runQuery, toNumber } from "@/lib/neo4j";
import { Q_ALL_NODES, Q_ALL_EDGES } from "@/lib/queries";

export const dynamic = "force-dynamic";

// Normalize every domain variant found in the DB to canonical display names
const DOMAIN_ALIASES: Record<string, string> = {
  // Crisis Dispatch variants
  "dispatch":                           "Crisis Dispatch / Emergency",
  "crisis dispatch":                    "Crisis Dispatch / Emergency",
  "crisis dispatch / emergency":        "Crisis Dispatch / Emergency",
  // Clinical variants
  "clinical":                           "Clinical / Medical",
  "clinical / medical":                 "Clinical / Medical",
  // Negotiation / Sales variants
  "negotiation":                        "Sales & Negotiation",
  "sales":                              "Sales & Negotiation",
  "sales & negotiation":                "Sales & Negotiation",
  // Legal variants
  "legal":                              "Legal & Investigative",
  "legal & investigative":              "Legal & Investigative",
  // Corporate variants
  "corporate":                          "Corporate & Engineering",
  "corporate & engineering":            "Corporate & Engineering",
  // Education
  "education":                          "Education",
  // Cultural variants
  "cross-cultural":                     "Cultural",
  "cultural":                           "Cultural",
  // Multimodal variants
  "communication-style":                "Multimodal",
  "multimodal":                         "Multimodal",
  // Misc schema variants
  "all":                                "Schema",
  "general":                            "Schema",
  "schema":                             "Schema",
  // Pass-through canonicals (already correct in DB)
  "dialogue acts":                      "Dialogue Acts",
  "psychological":                      "Psychological",
  "memory":                             "Memory",
  "retrieval":                          "Retrieval",
  "protocol":                           "Protocol",
  "consistency":                        "Consistency",
};

function normalizeDomain(d: string): string {
  const key = d.trim().toLowerCase();
  return DOMAIN_ALIASES[key] ?? d.trim();
}

export async function GET() {
  try {
    const [nodeRecords, edgeRecords] = await Promise.all([
      runQuery(Q_ALL_NODES),
      runQuery(Q_ALL_EDGES),
    ]);

    const nodes = nodeRecords
      .map((r) => ({
        id:     String(r.id   ?? ""),
        name:   String(r.name ?? ""),
        domain: normalizeDomain(String(r.domain ?? "Schema")),
        type:   String(r.type ?? "Unknown"),
        degree: toNumber(r.degree),
      }))
      .filter((n) => n.id && n.name && n.id !== "null" && n.name !== "null");

    // Deduplicate by id (catch-all query shouldn't produce duplicates, but be safe)
    const seen = new Set<string>();
    const uniqueNodes = nodes.filter((n) => {
      if (seen.has(n.id)) return false;
      seen.add(n.id);
      return true;
    });

    const edges = edgeRecords
      .map((r) => ({
        source: String(r.source ?? ""),
        target: String(r.target ?? ""),
        type:   String(r.relType ?? ""),
        weight: toNumber(r.weight ?? 1),
      }))
      .filter((e) => e.source && e.target && e.source !== e.target);

    return NextResponse.json({ nodes: uniqueNodes, edges });
  } catch (err) {
    console.error("GET /api/nodes error:", err);
    return NextResponse.json(
      { error: "Failed to fetch graph data", nodes: [], edges: [] },
      { status: 500 }
    );
  }
}
