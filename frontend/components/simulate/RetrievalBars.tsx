"use client";
import { motion } from "framer-motion";
import { RetrievalResponse } from "@/lib/types";
import { colorForDomain } from "@/lib/domain-colors";
import { CheckCircle2, XCircle } from "lucide-react";

const DOMAIN_FULL: Record<string, string> = {
  dispatch: "Crisis Dispatch / Emergency", clinical: "Clinical / Medical",
  negotiation: "Sales & Negotiation", legal: "Legal & Investigative",
  corporate: "Corporate & Engineering", education: "Education",
};

export default function RetrievalBars({ response }: { response: RetrievalResponse }) {
  const color = colorForDomain(DOMAIN_FULL[response.domain] ?? "");

  return (
    <div className="space-y-8">
      {/* Three legs */}
      <div className="grid grid-cols-3 gap-4">
        {(["bm25Leg", "vectorLeg", "cypherLeg"] as const).map((legKey) => {
          const leg = response[legKey];
          const label = { bm25Leg: "BM25", vectorLeg: "Vector", cypherLeg: "Cypher" }[legKey];
          const maxScore = Math.max(...leg.map((r) => r.score), 0.001);

          return (
            <div key={legKey} className="space-y-2">
              <p className="text-[10px] font-semibold uppercase tracking-widest text-[#6b7280]">
                {label} Leg
              </p>
              <div className="space-y-1.5">
                {leg.map((r, i) => (
                  <div key={r.techniqueId} className="space-y-0.5">
                    <div className="flex items-center justify-between text-[9px] text-[#6b7280]">
                      <span className="truncate mr-2 text-[#9ca3af]">{r.techniqueName}</span>
                      <span className="font-mono flex-shrink-0">#{r.rank}</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-[var(--border)] overflow-hidden">
                      <motion.div
                        className="h-full rounded-full"
                        style={{ background: i === 0 ? color : color + "60" }}
                        initial={{ width: 0 }}
                        animate={{ width: `${(r.score / maxScore) * 100}%` }}
                        transition={{ delay: i * 0.08, duration: 0.5 }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* Divider */}
      <div className="h-px bg-[var(--border)]" />

      {/* Fused results */}
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-widest text-[#6b7280] mb-3">
          Fused Results (weighted RRF, k=60)
        </p>
        <div className="space-y-2">
          {response.fused.map((r, i) => (
            <motion.div
              key={r.techniqueId}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.08 }}
              className="flex items-center gap-3 py-2 px-3 rounded-lg border border-[var(--border)] text-[11px]"
              style={i === 0 ? { borderColor: color + "40", background: color + "08" } : {}}
            >
              <span
                className="w-5 h-5 rounded-full flex items-center justify-center text-[9px] font-bold flex-shrink-0"
                style={{
                  background: i === 0 ? color + "20" : "#1e1e30",
                  color: i === 0 ? color : "#6b7280",
                }}
              >
                {r.fusedRank}
              </span>

              <span
                className="w-2 h-2 rounded-full flex-shrink-0"
                style={{ background: colorForDomain(r.domain) }}
              />

              <span className="flex-1 truncate text-[#e2e4f0]">{r.techniqueName}</span>

              <span className="text-[#4b5563] font-mono text-[9px] flex-shrink-0">
                b:{r.bm25Rank} v:{r.vectorRank} c:{r.cypherRank}
              </span>

              <span className="font-mono text-[9px] text-[#6b7280] flex-shrink-0">
                {r.rrfScore.toFixed(5)}
              </span>

              {r.safetyValidated ? (
                <CheckCircle2 size={10} className="text-[#10b981] flex-shrink-0" />
              ) : (
                <XCircle size={10} className="text-[#ef4444] flex-shrink-0" />
              )}
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  );
}
