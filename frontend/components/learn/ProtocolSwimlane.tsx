"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { CheckCircle2, Lock, ChevronDown, ChevronUp } from "lucide-react";
import { useGraphStore } from "@/stores/graph-store";
import { LearningPath, ProtocolStep } from "@/lib/types";
import { colorForDomain, DOMAIN_KEY } from "@/lib/domain-colors";
import { cn } from "@/lib/utils";

const ROLE_DOMAIN: Record<string, string> = {
  dispatcher: "dispatch",
  clinician: "clinical",
  negotiator: "negotiation",
  legal: "legal",
  manager: "corporate",
  educator: "education",
};

// Fallback data for when Neo4j isn't connected
const FALLBACK_PATHS: Record<string, LearningPath> = {
  dispatch: {
    domain: "Crisis Dispatch / Emergency",
    protocol: "BCSM",
    steps: [
      { id: "bcsm_step_1", name: "Active Listening", stepNumber: 1, description: "Full attentional processing; reflective feedback; no interruption.", domain: "Crisis Dispatch / Emergency", protocol: "BCSM", techniques: [] },
      { id: "bcsm_step_2", name: "Empathy", stepNumber: 2, description: "Acknowledge emotional reality; validate without endorsing unsupported facts.", domain: "Crisis Dispatch / Emergency", protocol: "BCSM", gateCondition: "caller_acknowledged_signal OR speech_rate_normalizes", techniques: [] },
      { id: "bcsm_step_3", name: "Rapport", stepNumber: 3, description: "Build trust and connection; establish common ground.", domain: "Crisis Dispatch / Emergency", protocol: "BCSM", gateCondition: "affect_intensity_drops AND caller_accepts_next_question", techniques: [] },
      { id: "bcsm_step_4", name: "Influence", stepNumber: 4, description: "Guide behavior through established rapport; propose alternatives.", domain: "Crisis Dispatch / Emergency", protocol: "BCSM", gateCondition: "rapport_confirmed AND caller_elaborates", techniques: [] },
      { id: "bcsm_step_5", name: "Behavioral Change", stepNumber: 5, description: "Observable change in caller behavior; safety instruction accepted.", domain: "Crisis Dispatch / Emergency", protocol: "BCSM", gateCondition: "influence_accepted AND behavioral_shift", techniques: [] },
    ],
  },
  clinical: {
    domain: "Clinical / Medical",
    protocol: "SPIKES",
    steps: [
      { id: "spikes_s", name: "Setting", stepNumber: 1, description: "Arrange a private, comfortable setting; invite key people.", domain: "Clinical / Medical", protocol: "SPIKES", techniques: [] },
      { id: "spikes_p", name: "Perception", stepNumber: 2, description: "Assess what the patient already knows.", domain: "Clinical / Medical", protocol: "SPIKES", techniques: [] },
      { id: "spikes_i", name: "Invitation", stepNumber: 3, description: "Ask permission to share information.", domain: "Clinical / Medical", protocol: "SPIKES", techniques: [] },
      { id: "spikes_k", name: "Knowledge", stepNumber: 4, description: "Deliver information in clear, jargon-free language.", domain: "Clinical / Medical", protocol: "SPIKES", techniques: [] },
      { id: "spikes_e", name: "Empathy", stepNumber: 5, description: "Respond to emotions; acknowledge and validate.", domain: "Clinical / Medical", protocol: "SPIKES", techniques: [] },
      { id: "spikes_s2", name: "Summary", stepNumber: 6, description: "Summarise and plan next steps collaboratively.", domain: "Clinical / Medical", protocol: "SPIKES", techniques: [] },
    ],
  },
  negotiation: {
    domain: "Sales & Negotiation",
    protocol: "SPIN",
    steps: [
      { id: "spin_s", name: "Situation Questions", stepNumber: 1, description: "Gather background facts about the prospect's current situation.", domain: "Sales & Negotiation", protocol: "SPIN", techniques: [] },
      { id: "spin_p", name: "Problem Questions", stepNumber: 2, description: "Uncover problems, difficulties, or dissatisfactions.", domain: "Sales & Negotiation", protocol: "SPIN", techniques: [] },
      { id: "spin_i", name: "Implication Questions", stepNumber: 3, description: "Develop the problem into a felt need.", domain: "Sales & Negotiation", protocol: "SPIN", techniques: [] },
      { id: "spin_n", name: "Need-Payoff Questions", stepNumber: 4, description: "Focus on the value and benefits of the solution.", domain: "Sales & Negotiation", protocol: "SPIN", techniques: [] },
    ],
  },
  legal: {
    domain: "Legal & Investigative",
    protocol: "PEACE",
    steps: [
      { id: "peace_p", name: "Preparation & Planning", stepNumber: 1, description: "Research the subject; plan interview objectives and structure.", domain: "Legal & Investigative", protocol: "PEACE", techniques: [] },
      { id: "peace_e", name: "Engage & Explain", stepNumber: 2, description: "Build rapport; explain the process and ground rules.", domain: "Legal & Investigative", protocol: "PEACE", techniques: [] },
      { id: "peace_a", name: "Account", stepNumber: 3, description: "Free narrative invitation; cognitive interview techniques.", domain: "Legal & Investigative", protocol: "PEACE", gateCondition: "rapport_established", techniques: [] },
      { id: "peace_c", name: "Closure", stepNumber: 4, description: "Summarise; allow the subject to correct or add information.", domain: "Legal & Investigative", protocol: "PEACE", techniques: [] },
      { id: "peace_e2", name: "Evaluation", stepNumber: 5, description: "Assess interview against objectives; document findings.", domain: "Legal & Investigative", protocol: "PEACE", techniques: [] },
    ],
  },
  corporate: {
    domain: "Corporate & Engineering",
    protocol: "SBI",
    steps: [
      { id: "sbi_s", name: "Situation", stepNumber: 1, description: "Describe the specific situation where the behaviour occurred.", domain: "Corporate & Engineering", protocol: "SBI", techniques: [] },
      { id: "sbi_b", name: "Behaviour", stepNumber: 2, description: "Describe the observable, specific behaviour without judgement.", domain: "Corporate & Engineering", protocol: "SBI", techniques: [] },
      { id: "sbi_i", name: "Impact", stepNumber: 3, description: "Describe the impact that the behaviour had on you and the team.", domain: "Corporate & Engineering", protocol: "SBI", techniques: [] },
    ],
  },
  education: {
    domain: "Education",
    protocol: "CoachIDL Socratic",
    steps: [
      { id: "edu_s1", name: "Diagnose", stepNumber: 1, description: "BKT mastery check; identify specific misconceptions.", domain: "Education", protocol: "CoachIDL Socratic", techniques: [] },
      { id: "edu_s2", name: "Scaffold", stepNumber: 2, description: "Apply Tier 1 / Tier 2 scaffolding based on mastery level.", domain: "Education", protocol: "CoachIDL Socratic", gateCondition: "bkt_mastery < 0.4 → Tier 1; 0.4–0.7 → Tier 2", techniques: [] },
      { id: "edu_s3", name: "Socratic Dialogue", stepNumber: 3, description: "Guide student to correct answer through targeted questions.", domain: "Education", protocol: "CoachIDL Socratic", gateCondition: "scaffold_accepted AND student_attempts_answer", techniques: [] },
    ],
  },
};

export default function ProtocolSwimlane() {
  const { role, masteredIds, toggleMastered } = useGraphStore();
  const [path, setPath] = useState<LearningPath | null>(null);
  const [expandedStep, setExpandedStep] = useState<string | null>(null);

  const domainKey = role ? ROLE_DOMAIN[role] ?? "dispatch" : "dispatch";

  useEffect(() => {
    // Try fetching from API; fall back to static data
    // Try live Neo4j protocol path first, fall back to static data
    fetch(`/api/protocol/${domainKey}`)
      .then((r) => r.json())
      .then((data: LearningPath | null) => {
        if (data && data.steps && data.steps.length > 0) {
          setPath(data);
        } else {
          setPath(FALLBACK_PATHS[domainKey] ?? null);
        }
      })
      .catch(() => {
        setPath(FALLBACK_PATHS[domainKey] ?? null);
      });
  }, [domainKey]);

  if (!path) {
    return (
      <div className="flex items-center justify-center h-32">
        <div className="w-5 h-5 border-2 border-[#22d3ee] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const color = colorForDomain(path.domain);

  // Step is unlocked if it's the first, or if the previous step's id is mastered
  const isUnlocked = (i: number) => {
    if (i === 0) return true;
    return masteredIds.has(path.steps[i - 1].id);
  };

  const isMastered = (step: ProtocolStep) => masteredIds.has(step.id);

  return (
    <div className="space-y-6">
      {/* Protocol header */}
      <div className="flex items-center gap-3">
        <span
          className="text-xs font-bold px-3 py-1 rounded-full"
          style={{ background: color + "20", color }}
        >
          {path.protocol}
        </span>
        <h2 className="text-sm font-semibold text-[#e2e4f0]">{path.domain}</h2>
        <span className="text-xs text-[#6b7280]">
          {path.steps.filter((s) => masteredIds.has(s.id)).length}/{path.steps.length} steps mastered
        </span>
      </div>

      {/* Progress bar */}
      <div className="h-1 rounded-full bg-[var(--border)] overflow-hidden">
        <motion.div
          className="h-full rounded-full"
          style={{ background: color }}
          initial={{ width: 0 }}
          animate={{
            width: `${(path.steps.filter((s) => masteredIds.has(s.id)).length / path.steps.length) * 100}%`,
          }}
          transition={{ duration: 0.5 }}
        />
      </div>

      {/* Steps */}
      <div className="flex flex-col gap-3">
        {path.steps.map((step, i) => {
          const unlocked = isUnlocked(i);
          const mastered = isMastered(step);
          const expanded = expandedStep === step.id;

          return (
            <motion.div
              key={step.id}
              initial={{ opacity: 0, x: -16 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.07 }}
              className={cn(
                "rounded-xl border overflow-hidden transition-all",
                mastered
                  ? "border-[#10b98140]"
                  : unlocked
                  ? "border-[var(--border)]"
                  : "border-[var(--border)] opacity-50"
              )}
              style={{ background: "var(--surface)" }}
            >
              {/* Step header */}
              <button
                type="button"
                disabled={!unlocked}
                onClick={() => setExpandedStep(expanded ? null : step.id)}
                className="w-full flex items-center gap-4 p-4 text-left"
              >
                {/* Step number / status icon */}
                <div
                  className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 text-xs font-bold"
                  style={{
                    background: mastered
                      ? "#10b98120"
                      : unlocked
                      ? color + "20"
                      : "#1e1e30",
                    color: mastered ? "#10b981" : unlocked ? color : "#4b5563",
                  }}
                >
                  {mastered ? (
                    <CheckCircle2 size={16} />
                  ) : !unlocked ? (
                    <Lock size={12} />
                  ) : (
                    step.stepNumber
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <p
                    className={cn(
                      "text-sm font-medium",
                      mastered
                        ? "text-[#10b981]"
                        : unlocked
                        ? "text-[#e2e4f0]"
                        : "text-[#6b7280]"
                    )}
                  >
                    {step.name}
                  </p>
                  <p className="text-[11px] text-[#6b7280] mt-0.5 truncate">
                    {step.description}
                  </p>
                </div>

                {unlocked && (
                  <span className="text-[#6b7280] flex-shrink-0">
                    {expanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                  </span>
                )}
              </button>

              {/* Expanded content */}
              {expanded && unlocked && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="border-t border-[var(--border)] px-4 pb-4 pt-3 space-y-3"
                >
                  <p className="text-xs text-[#9ca3af] leading-relaxed">
                    {step.description}
                  </p>

                  {step.gateCondition && (
                    <div className="rounded-lg px-3 py-2 bg-[#22d3ee08] border border-[#22d3ee20]">
                      <p className="text-[10px] font-semibold text-[#22d3ee] mb-1">
                        Gate Condition
                      </p>
                      <p className="text-[10px] text-[#9ca3af] font-mono">
                        {step.gateCondition}
                      </p>
                    </div>
                  )}

                  <button
                    type="button"
                    onClick={() => toggleMastered(step.id)}
                    className={cn(
                      "w-full py-2 rounded-lg text-xs font-medium transition-all flex items-center justify-center gap-2",
                      mastered
                        ? "bg-[#10b98118] text-[#10b981] hover:bg-[#10b98128]"
                        : "bg-white/5 text-[#9ca3af] hover:bg-white/10 hover:text-[#e2e4f0]"
                    )}
                  >
                    <CheckCircle2 size={12} />
                    {mastered ? "Marked as Mastered" : "Mark as Mastered"}
                  </button>
                </motion.div>
              )}
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
