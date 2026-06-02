import { NextRequest, NextResponse } from "next/server";
import { runQuery, toNumber } from "@/lib/neo4j";
import { Q_PROTOCOL_PATH } from "@/lib/queries";

export const dynamic = "force-dynamic";

const DOMAIN_MAP: Record<string, string> = {
  dispatch:    "Crisis Dispatch / Emergency",
  negotiation: "Sales & Negotiation",
  clinical:    "Clinical / Medical",
  legal:       "Legal & Investigative",
  corporate:   "Corporate & Engineering",
  education:   "Education",
};

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ domain: string }> }
) {
  const { domain } = await params;
  const fullDomain = DOMAIN_MAP[domain] ?? domain;

  try {
    const records = await runQuery(Q_PROTOCOL_PATH, { domain: fullDomain });
    if (!records.length) {
      return NextResponse.json(null);
    }

    const steps = records.map((r) => ({
      id: String(r.stepId ?? ""),
      name: String(r.stepName ?? ""),
      stepNumber: toNumber(r.stepNumber),
      description: String(r.description ?? ""),
      protocol: String(r.protocol ?? ""),
      domain: String(r.domain ?? fullDomain),
      gateCondition: undefined as string | undefined,
      techniques: ((r.techniques as unknown[]) ?? [])
        .filter((t) => {
          const to = t as Record<string, unknown>;
          return to.id && to.name;
        })
        .map((t) => {
          const to = t as Record<string, unknown>;
          return {
            id: String(to.id ?? ""),
            name: String(to.name ?? ""),
            domain: String(to.domain ?? fullDomain),
            type: "Technique" as const,
            degree: 0,
          };
        }),
    }));

    // Determine protocol name from first step
    const protocol = steps[0]?.protocol ?? "Protocol";
    return NextResponse.json({ domain: fullDomain, protocol, steps });
  } catch (err) {
    console.error(`GET /api/protocol/${domain} error:`, err);
    return NextResponse.json(null);
  }
}
