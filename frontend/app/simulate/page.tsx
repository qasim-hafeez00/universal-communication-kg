"use client";

import { useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Play, SkipForward, RotateCcw } from "lucide-react";
import ScenarioBuilder from "@/components/simulate/ScenarioBuilder";
import StepLog from "@/components/simulate/StepLog";
import RetrievalBars from "@/components/simulate/RetrievalBars";
import { RetrievalResponse } from "@/lib/types";
import { colorForDomain } from "@/lib/domain-colors";

const PRESETS = [
  { domain: "dispatch",    label: "Caller panicking, weapon mentioned, non-compliant",        query: "caller panicking, weapon mentioned, refuses to comply" },
  { domain: "clinical",   label: "Patient resistant to bad news — oncologist delivering diagnosis", query: "patient resistant to bad news, oncologist delivering diagnosis" },
  { domain: "negotiation",label: "Prospect stalling on price objection, late-stage deal",      query: "prospect stalling on price objection, late-stage deal" },
  { domain: "legal",      label: "Subject using pronoun changes, interview step 3",            query: "subject using pronoun changes and verb tense shifts, interview step 3" },
  { domain: "corporate",  label: "Team member defensive during code review",                   query: "team member displaying defensiveness during code review feedback" },
  { domain: "education",  label: "Student making systematic errors, low confidence",          query: "student making systematic errors on fractions, low confidence" },
] as const;

export type SimStep =
  | { kind: "input";     text: string }
  | { kind: "classify";  act: string }
  | { kind: "protocol";  protocol: string }
  | { kind: "retrieval"; response: RetrievalResponse }
  | { kind: "safety";    passed: boolean; blocked?: string }
  | { kind: "result";    name: string; id: string; domain: string; rrfScore: number };

export default function SimulatePage() {
  const [domain, setDomain] = useState("dispatch");
  const [query, setQuery] = useState("");
  const [steps, setSteps] = useState<SimStep[]>([]);
  const [running, setRunning] = useState(false);
  const [currentStep, setCurrentStep] = useState(-1);

  const runSimulation = useCallback(async (d: string, q: string) => {
    if (!q.trim()) return;
    setSteps([]);
    setCurrentStep(-1);
    setRunning(true);

    const allSteps: SimStep[] = [];

    // Step 1: Input
    allSteps.push({ kind: "input", text: q });
    setSteps([...allSteps]);
    setCurrentStep(0);
    await delay(600);

    // Step 2: DialogueAct classification (mock)
    const actMap: Record<string, string> = {
      dispatch: "da_distress_expression",
      clinical: "da_resistance",
      negotiation: "da_objection",
      legal: "da_deception_marker",
      corporate: "da_defensiveness",
      education: "da_confusion",
    };
    allSteps.push({ kind: "classify", act: actMap[d] ?? "da_unknown" });
    setSteps([...allSteps]);
    setCurrentStep(1);
    await delay(700);

    // Step 3: Protocol activation (mock)
    const protocolMap: Record<string, string> = {
      dispatch: "BCSM", clinical: "SPIKES", negotiation: "SPIN",
      legal: "PEACE", corporate: "SBI", education: "CoachIDL Socratic",
    };
    allSteps.push({ kind: "protocol", protocol: protocolMap[d] ?? "BCSM" });
    setSteps([...allSteps]);
    setCurrentStep(2);
    await delay(700);

    // Step 4: Hybrid retrieval
    const resp = await fetch("/api/retrieve", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ domain: d, query: q }),
    });
    const retrievalData: RetrievalResponse = await resp.json();
    allSteps.push({ kind: "retrieval", response: retrievalData });
    setSteps([...allSteps]);
    setCurrentStep(3);
    await delay(900);

    // Step 5: Safety check
    const winner = retrievalData.fused[0];
    const blocked = !winner?.safetyValidated ? winner?.techniqueId : undefined;
    allSteps.push({ kind: "safety", passed: !blocked, blocked });
    setSteps([...allSteps]);
    setCurrentStep(4);
    await delay(600);

    // Step 6: Result
    if (winner) {
      allSteps.push({
        kind: "result",
        name: winner.techniqueName,
        id: winner.techniqueId,
        domain: winner.domain,
        rrfScore: winner.rrfScore,
      });
      setSteps([...allSteps]);
      setCurrentStep(5);
    }

    setRunning(false);
  }, []);

  const reset = () => {
    setSteps([]);
    setCurrentStep(-1);
    setRunning(false);
  };

  const retrieval = steps.find((s): s is Extract<SimStep, { kind: "retrieval" }> => s.kind === "retrieval");

  return (
    <div className="flex-1 flex overflow-hidden">
      {/* Left: Builder */}
      <aside className="w-[300px] flex-shrink-0 border-r border-[var(--border)] bg-[var(--surface)] flex flex-col">
        <div className="p-4 border-b border-[var(--border)]">
          <h2 className="text-xs font-semibold text-[#e2e4f0] mb-0.5">Scenario Builder</h2>
          <p className="text-[10px] text-[#6b7280]">Configure a scenario and watch the graph route it</p>
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          <ScenarioBuilder
            domain={domain}
            query={query}
            onDomainChange={setDomain}
            onQueryChange={setQuery}
            presets={PRESETS}
          />
        </div>

        <div className="p-4 border-t border-[var(--border)] space-y-2">
          <button
            type="button"
            disabled={running || !query.trim()}
            onClick={() => runSimulation(domain, query)}
            className="w-full flex items-center justify-center gap-2 py-2.5 rounded-lg text-xs font-semibold transition-all disabled:opacity-40 disabled:cursor-not-allowed bg-[#22d3ee18] text-[#22d3ee] hover:bg-[#22d3ee28] border border-[#22d3ee30]"
          >
            <Play size={12} />
            {running ? "Running…" : "Run Scenario"}
          </button>
          {steps.length > 0 && (
            <button
              type="button"
              onClick={reset}
              className="w-full flex items-center justify-center gap-2 py-2 rounded-lg text-xs text-[#6b7280] hover:text-[#e2e4f0] bg-white/5 hover:bg-white/10 transition-all"
            >
              <RotateCcw size={11} />
              Reset
            </button>
          )}
        </div>
      </aside>

      {/* Centre: retrieval bars animation */}
      <div className="flex-1 flex flex-col border-r border-[var(--border)] overflow-hidden">
        <div className="p-4 border-b border-[var(--border)]">
          <h2 className="text-xs font-semibold text-[#e2e4f0]">Retrieval Engine</h2>
          <p className="text-[10px] text-[#6b7280]">BM25 + Vector + Cypher → RRF Fusion</p>
        </div>
        <div className="flex-1 overflow-y-auto p-6">
          <AnimatePresence>
            {retrieval ? (
              <RetrievalBars response={retrieval.response} />
            ) : (
              <motion.div
                key="idle"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="h-full flex items-center justify-center"
              >
                <div className="text-center space-y-2">
                  <SkipForward size={28} className="mx-auto text-[#374151]" />
                  <p className="text-xs text-[#4b5563]">Run a scenario to see retrieval</p>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Right: step log */}
      <aside className="w-[280px] flex-shrink-0 bg-[var(--surface)] flex flex-col">
        <div className="p-4 border-b border-[var(--border)]">
          <h2 className="text-xs font-semibold text-[#e2e4f0]">Traversal Log</h2>
          <p className="text-[10px] text-[#6b7280]">Step-by-step routing decisions</p>
        </div>
        <div className="flex-1 overflow-y-auto p-3">
          <StepLog steps={steps} currentStep={currentStep} />
        </div>
      </aside>
    </div>
  );
}

function delay(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}
