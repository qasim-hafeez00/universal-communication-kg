import { NextRequest, NextResponse } from "next/server";
import { runQuery, toNumber } from "@/lib/neo4j";
import { Q_DOMAIN_NODES } from "@/lib/queries";

export const dynamic = "force-dynamic";

const DOMAIN_MAP: Record<string, string> = {
  dispatch: "Crisis Dispatch / Emergency",
  negotiation: "Sales & Negotiation",
  clinical: "Clinical / Medical",
  legal: "Legal & Investigative",
  corporate: "Corporate & Engineering",
  education: "Education",
};

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ domain: string }> }
) {
  const { domain } = await params;
  const fullDomain = DOMAIN_MAP[domain] ?? domain;

  try {
    const records = await runQuery(Q_DOMAIN_NODES, { domain: fullDomain });
    const nodes = records.map((r) => ({
      id: String(r.id ?? ""),
      name: String(r.name ?? ""),
      domain: String(r.domain ?? fullDomain),
      type: String(r.type ?? "Technique"),
      degree: toNumber(r.degree),
    }));
    return NextResponse.json(nodes);
  } catch (err) {
    console.error(`GET /api/domain/${domain} error:`, err);
    return NextResponse.json([]);
  }
}
