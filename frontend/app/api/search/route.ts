import { NextRequest, NextResponse } from "next/server";
import { runQuery } from "@/lib/neo4j";
import { Q_SEARCH } from "@/lib/queries";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q") ?? "";
  if (!q.trim()) return NextResponse.json([]);

  try {
    const records = await runQuery(Q_SEARCH, { q });
    const results = records.map((r) => ({
      id: String(r.id ?? ""),
      name: String(r.name ?? ""),
      domain: String(r.domain ?? "Unknown"),
      type: String(r.type ?? "Unknown"),
      score: Number(r.score ?? 1),
    }));
    return NextResponse.json(results);
  } catch (err) {
    console.error("GET /api/search error:", err);
    return NextResponse.json([]);
  }
}
