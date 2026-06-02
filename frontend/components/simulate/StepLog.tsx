"use client";
import { motion, AnimatePresence } from "framer-motion";
import { type SimStep } from "@/app/simulate/page";
import { CheckCircle2, XCircle, Zap, GitBranch, Search, Shield, Trophy } from "lucide-react";
import { colorForDomain } from "@/lib/domain-colors";
import { cn } from "@/lib/utils";

interface Props {
  steps: SimStep[];
  currentStep: number;
}

const STEP_ICONS: Record<SimStep["kind"], React.ReactNode> = {
  input:     <Zap size={12} />,
  classify:  <GitBranch size={12} />,
  protocol:  <GitBranch size={12} />,
  retrieval: <Search size={12} />,
  safety:    <Shield size={12} />,
  result:    <Trophy size={12} />,
};

const STEP_LABELS: Record<SimStep["kind"], string> = {
  input:     "Input",
  classify:  "Classify",
  protocol:  "Protocol",
  retrieval: "Retrieval",
  safety:    "Safety",
  result:    "Result",
};

export default function StepLog({ steps, currentStep }: Props) {
  if (!steps.length) {
    return (
      <div className="h-full flex items-center justify-center">
        <p className="text-[10px] text-[#4b5563] text-center">Steps will appear here</p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <AnimatePresence>
        {steps.map((step, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, x: 12 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.05 }}
            className={cn(
              "rounded-lg border p-3 transition-all",
              i === currentStep
                ? "border-[#22d3ee40] bg-[#22d3ee08]"
                : "border-[var(--border)] bg-transparent"
            )}
          >
            <div className="flex items-center gap-2 mb-1.5">
              <span
                className={cn(
                  "text-[10px]",
                  i === currentStep ? "text-[#22d3ee]" : "text-[#4b5563]"
                )}
              >
                {STEP_ICONS[step.kind]}
              </span>
              <span
                className={cn(
                  "text-[10px] font-semibold uppercase tracking-wider",
                  i === currentStep ? "text-[#22d3ee]" : "text-[#6b7280]"
                )}
              >
                Step {i + 1} · {STEP_LABELS[step.kind]}
              </span>
            </div>

            <StepContent step={step} />
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}

function StepContent({ step }: { step: SimStep }) {
  switch (step.kind) {
    case "input":
      return <p className="text-[11px] text-[#9ca3af] leading-relaxed">&ldquo;{step.text}&rdquo;</p>;

    case "classify":
      return (
        <div className="flex items-center gap-1.5">
          <span className="text-[10px] text-[#6b7280]">DialogueAct:</span>
          <code className="text-[10px] text-[#22d3ee] font-mono">{step.act}</code>
        </div>
      );

    case "protocol":
      return (
        <div className="flex items-center gap-1.5">
          <span className="text-[10px] text-[#6b7280]">Protocol:</span>
          <span className="text-[10px] text-[#e2e4f0] font-medium">{step.protocol}</span>
          <span className="text-[9px] text-[#10b981]">activated</span>
        </div>
      );

    case "retrieval":
      return (
        <div className="space-y-1">
          {(["bm25Leg", "vectorLeg", "cypherLeg"] as const).map((leg) => {
            const top = step.response[leg][0];
            const label = { bm25Leg: "BM25", vectorLeg: "Vector", cypherLeg: "Cypher" }[leg];
            return top ? (
              <div key={leg} className="flex items-center gap-1.5">
                <span className="text-[9px] text-[#6b7280] w-14">{label} #1:</span>
                <span className="text-[10px] text-[#9ca3af] truncate">{top.techniqueName}</span>
              </div>
            ) : null;
          })}
          {step.response.fused[0] && (
            <div className="flex items-center gap-1.5 mt-1 pt-1 border-t border-[var(--border)]">
              <span className="text-[9px] text-[#22d3ee] w-14">RRF #1:</span>
              <span className="text-[10px] text-[#e2e4f0] font-medium truncate">
                {step.response.fused[0].techniqueName}
              </span>
              <span className="text-[9px] text-[#6b7280] font-mono ml-auto flex-shrink-0">
                {step.response.fused[0].rrfScore.toFixed(5)}
              </span>
            </div>
          )}
        </div>
      );

    case "safety":
      return (
        <div className="flex items-center gap-2">
          {step.passed ? (
            <>
              <CheckCircle2 size={12} className="text-[#10b981]" />
              <span className="text-[10px] text-[#10b981]">Safety check passed</span>
            </>
          ) : (
            <>
              <XCircle size={12} className="text-[#ef4444]" />
              <span className="text-[10px] text-[#ef4444]">Blocked: {step.blocked}</span>
            </>
          )}
        </div>
      );

    case "result":
      return (
        <div className="space-y-1">
          <p className="text-xs font-semibold text-[#e2e4f0]">{step.name}</p>
          <div className="flex items-center gap-2">
            <span
              className="w-1.5 h-1.5 rounded-full"
              style={{ background: colorForDomain(step.domain) }}
            />
            <span className="text-[10px] text-[#6b7280]">{step.domain}</span>
            <span className="text-[9px] text-[#4b5563] font-mono ml-auto">
              rrf={step.rrfScore.toFixed(5)}
            </span>
          </div>
        </div>
      );
  }
}
