import { NextRequest, NextResponse } from "next/server";
import { runQuery } from "@/lib/neo4j";
import { Q_NODE_DETAIL } from "@/lib/queries";

export const dynamic = "force-dynamic";

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  try {
    const records = await runQuery(Q_NODE_DETAIL, { id });
    if (!records.length) {
      return NextResponse.json({ error: "Node not found" }, { status: 404 });
    }

    const rec = records[0] as Record<string, unknown>;
    const nodeObj = rec.n as Record<string, unknown>;
    // Neo4j driver wraps node data; access .properties for the actual props
    const props = (
      nodeObj && typeof nodeObj === "object" && "properties" in nodeObj
        ? (nodeObj as { properties: Record<string, unknown> }).properties
        : nodeObj
    ) as Record<string, unknown>;

    const rawNeighbors = (rec.neighbors as unknown[]) ?? [];
    const neighbors = rawNeighbors
      .filter((nb): nb is Record<string, unknown> => {
        const o = nb as Record<string, unknown>;
        return !!o.id && o.id !== id;
      })
      .map((nb) => ({
        id: String(nb.id ?? ""),
        name: String(nb.name ?? ""),
        domain: String(nb.domain ?? "Unknown"),
        type: String(nb.nodeType ?? "Unknown"),
        relType: String(nb.relType ?? ""),
        direction: String(nb.direction ?? "out"),
      }));

    const str = (v: unknown) => (v == null ? "" : String(v));

    const detail = {
      id: str(props.cardId ?? props.id ?? id),
      name: str(props.name ?? props.communicativeFunction ?? ""),
      domain: str(props.domain ?? ""),
      type: "Technique",
      description: str(props.description),
      whenToUse: str(props.whenToUse),
      whenNotToUse: str(props.whenNotToUse),
      steps: str(props.steps),
      successSignals: str(props.successSignals),
      failureSignals: str(props.failureSignals),
      triggerSignals: str(props.triggerSignals),
      cognitiveLoadProfile: str(props.cognitiveLoadProfile),
      contraindications: str(props.contraindications),
      tier: str(props.tier),
      culturalNotes: str(props.culturalNotes),
      sourceIds: str(props.sourceIds),
      reviewStatus: str(props.reviewStatus),
      protocol: str(props.protocol),
      peaceStep: str(props.peaceStep),
      neighbors,
    };

    return NextResponse.json(detail);
  } catch (err) {
    console.error(`GET /api/nodes/${id} error:`, err);
    return NextResponse.json({ error: "Query failed" }, { status: 500 });
  }
}
