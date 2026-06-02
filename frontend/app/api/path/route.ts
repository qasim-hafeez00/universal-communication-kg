import { NextRequest, NextResponse } from "next/server";
import { runQuery } from "@/lib/neo4j";
import { Q_SHORTEST_PATH } from "@/lib/queries";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const from = req.nextUrl.searchParams.get("from") ?? "";
  const to = req.nextUrl.searchParams.get("to") ?? "";
  if (!from || !to) {
    return NextResponse.json({ error: "from and to required" }, { status: 400 });
  }

  try {
    const records = await runQuery(Q_SHORTEST_PATH, { from, to });
    if (!records.length) {
      return NextResponse.json({ steps: [] });
    }
    const steps = (records[0] as Record<string, unknown>).steps ?? [];
    return NextResponse.json({ steps });
  } catch (err) {
    console.error("GET /api/path error:", err);
    return NextResponse.json({ steps: [] });
  }
}
