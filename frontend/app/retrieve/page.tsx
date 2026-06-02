"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Search, CheckCircle2, XCircle } from "lucide-react";
import { RetrievalResponse, RetrievalLeg, FusedResult } from "@/lib/types";
import { colorForDomain } from "@/lib/domain-colors";
import { cn } from "@/lib/utils";

const DOMAINS = [
  { key: "dispatch",    label: "Dispatch",    color: "#f59e0b" },
  { key: "clinical",   label: "Clinical",    color: "#10b981" },
  { key: "negotiation",label: "Negotiation", color: "#6366f1" },
  { key: "legal",      label: "Legal",       color: "#ef4444" },
  { key: "corporate",  label: "Corporate",   color: "#3b82f6" },
  { key: "education",  label: "Education",   color: "#8b5cf6" },
];

const DOMAIN_FULL: Record<string, string> = {
  dispatch: "Crisis Dispatch / Emergency", clinical: "Clinical / Medical",
  negotiation: "Sales & Negotiation", legal: "Legal & Investigative",
  corporate: "Corporate & Engineering", education: "Education",
};

export default function RetrievePage() {
  const [domain, setDomain] = useState("dispatch");
  const [query, setQuery] = useState("");
  const [result, setResult] = useState<RetrievalResponse | null>(null);
  const [loading, setLoading] = useState(false);

  const run = async () => {
    if (!query.trim()) return;
    setLoading(true);
    try {
      const resp = await fetch("/api/retrieve", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ domain, query }),
      });
      const data = await resp.json();
      setResult(data);
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const domainColor = colorForDomain(DOMAIN_FULL[domain] ?? "");

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {/* Header */}
      <div className="p-5 border-b border-[var(--border)] bg-[var(--surface)] space-y-4">
        <div>
          <h1 className="text-sm font-semibold text-[#e2e4f0]">Retrieval Debugger</h1>
          <p className="text-xs text-[#6b7280] mt-0.5">
            Inspect BM25 + Vector + Cypher legs and their RRF fusion
          </p>
        </div>

        {/* Domain pills */}
        <div className="flex gap-2 flex-wrap">
          {DOMAINS.map((d) => (
            <button
              key={d.key}
              type="button"
              onClick={() => setDomain(d.key)}
              className={cn(
                "px-3 py-1.5 rounded-full text-xs font-medium transition-all border",
                domain === d.key
                  ? "text-[#e2e4f0]"
                  : "border-transparent text-[#6b7280] hover:text-[#9ca3af] bg-transparent"
              )}
              style={
                domain === d.key
                  ? { background: d.color + "18", borderColor: d.color + "50", color: d.color }
                  : { background: "var(--surface)" }
              }
            >
              {d.label}
            </button>
          ))}
        </div>

        {/* Query input */}
        <div className="flex gap-2">
          <div className="flex-1 flex items-center gap-2 px-3 py-2.5 rounded-lg border border-[var(--border)] bg-[#1a1a2e]">
            <Search size={13} className="text-[#6b7280] flex-shrink-0" />
            <input
              className="flex-1 bg-transparent text-xs text-[#e2e4f0] placeholder-[#4b5563] outline-none"
              placeholder="Enter a natural language query…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && run()}
            />
          </div>
          <button
            type="button"
            disabled={loading || !query.trim()}
            onClick={run}
            className="px-4 py-2 rounded-lg text-xs font-semibold transition-all disabled:opacity-40 bg-[#22d3ee18] text-[#22d3ee] border border-[#22d3ee30] hover:bg-[#22d3ee28]"
          >
            {loading ? "Running…" : "Run →"}
          </button>
        </div>
      </div>

      {/* Results */}
      <div className="flex-1 overflow-auto p-5">
        <AnimatePresence>
          {result && (
            <motion.div
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              className="space-y-6"
            >
              {/* Three legs */}
              <div className="grid grid-cols-3 gap-4">
                {(["bm25Leg", "vectorLeg", "cypherLeg"] as const).map((legKey) => {
                  const label = { bm25Leg: "BM25", vectorLeg: "Vector", cypherLeg: "Cypher" }[legKey];
                  const cfg = { dispatch: { bm25: 0.15, vector: 0.25, cypher: 0.60 }, clinical: { bm25: 0.20, vector: 0.30, cypher: 0.50 }, negotiation: { bm25: 0.30, vector: 0.40, cypher: 0.30 }, legal: { bm25: 0.40, vector: 0.25, cypher: 0.35 }, corporate: { bm25: 0.25, vector: 0.35, cypher: 0.40 }, education: { bm25: 0.20, vector: 0.40, cypher: 0.40 } }[domain];
                  const weight = cfg ? { bm25Leg: cfg.bm25, vectorLeg: cfg.vector, cypherLeg: cfg.cypher }[legKey] : 0;

                  return (
                    <div
                      key={legKey}
                      className="rounded-xl border border-[var(--border)] overflow-hidden"
                      style={{ background: "var(--surface)" }}
                    >
                      <div
                        className="px-3 py-2.5 border-b border-[var(--border)] flex items-center justify-between"
                        style={{ background: domainColor + "08" }}
                      >
                        <span className="text-xs font-semibold text-[#e2e4f0]">{label} Leg</span>
                        <span
                          className="text-[10px] font-mono px-2 py-0.5 rounded"
                          style={{ background: domainColor + "20", color: domainColor }}
                        >
                          w={weight}
                        </span>
                      </div>
                      <LegTable rows={result[legKey]} color={domainColor} />
                    </div>
                  );
                })}
              </div>

              {/* Fused results */}
              <div
                className="rounded-xl border border-[var(--border)] overflow-hidden"
                style={{ background: "var(--surface)" }}
              >
                <div
                  className="px-4 py-3 border-b border-[var(--border)] flex items-center justify-between"
                  style={{ background: domainColor + "08" }}
                >
                  <span className="text-xs font-semibold text-[#e2e4f0]">
                    Fused Results (weighted RRF, k=60)
                  </span>
                  <span className="text-[10px] text-[#6b7280] font-mono">
                    domain={result.domain}
                  </span>
                </div>
                <FusedTable rows={result.fused} color={domainColor} />
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {!result && !loading && (
          <div className="h-full flex items-center justify-center">
            <div className="text-center space-y-2">
              <Search size={28} className="mx-auto text-[#374151]" />
              <p className="text-xs text-[#4b5563]">Enter a query and click Run to see results</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function LegTable({ rows, color }: { rows: RetrievalLeg[]; color: string }) {
  return (
    <table className="w-full text-[10px]">
      <thead>
        <tr className="border-b border-[var(--border)]">
          <th className="text-left px-3 py-2 text-[#6b7280] font-medium w-8">#</th>
          <th className="text-left px-3 py-2 text-[#6b7280] font-medium">Technique</th>
          <th className="text-right px-3 py-2 text-[#6b7280] font-medium">Score</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.techniqueId} className="border-b border-[var(--border)] hover:bg-white/3 transition-colors">
            <td className="px-3 py-2 text-[#6b7280] font-mono">{r.rank}</td>
            <td className="px-3 py-2">
              <p className="text-[#e2e4f0] truncate">{r.techniqueName}</p>
            </td>
            <td className="px-3 py-2 text-right font-mono" style={{ color }}>
              {r.score.toFixed(3)}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function FusedTable({ rows, color }: { rows: FusedResult[]; color: string }) {
  return (
    <table className="w-full text-[10px]">
      <thead>
        <tr className="border-b border-[var(--border)]">
          <th className="text-left px-3 py-2 text-[#6b7280] font-medium w-8">#</th>
          <th className="text-left px-3 py-2 text-[#6b7280] font-medium">Technique</th>
          <th className="text-center px-2 py-2 text-[#6b7280] font-medium">bm25</th>
          <th className="text-center px-2 py-2 text-[#6b7280] font-medium">vec</th>
          <th className="text-center px-2 py-2 text-[#6b7280] font-medium">cyp</th>
          <th className="text-right px-3 py-2 text-[#6b7280] font-medium">RRF Score</th>
          <th className="px-3 py-2 text-[#6b7280] font-medium">Safe</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r, i) => (
          <tr
            key={r.techniqueId}
            className="border-b border-[var(--border)] transition-colors hover:bg-white/3"
            style={i === 0 ? { background: color + "08" } : {}}
          >
            <td className="px-3 py-2 font-mono" style={{ color: i === 0 ? color : "#6b7280" }}>
              {r.fusedRank}
            </td>
            <td className="px-3 py-2">
              <div className="flex items-center gap-2">
                <span
                  className="w-1.5 h-1.5 rounded-full flex-shrink-0"
                  style={{ background: colorForDomain(r.domain) }}
                />
                <span className={cn("truncate", i === 0 ? "text-[#e2e4f0] font-medium" : "text-[#9ca3af]")}>
                  {r.techniqueName}
                </span>
              </div>
            </td>
            <td className="px-2 py-2 text-center text-[#6b7280] font-mono">{r.bm25Rank}</td>
            <td className="px-2 py-2 text-center text-[#6b7280] font-mono">{r.vectorRank}</td>
            <td className="px-2 py-2 text-center text-[#6b7280] font-mono">{r.cypherRank}</td>
            <td className="px-3 py-2 text-right font-mono" style={{ color }}>
              {r.rrfScore.toFixed(6)}
            </td>
            <td className="px-3 py-2">
              {r.safetyValidated ? (
                <CheckCircle2 size={11} className="text-[#10b981] mx-auto" />
              ) : (
                <XCircle size={11} className="text-[#ef4444] mx-auto" />
              )}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
