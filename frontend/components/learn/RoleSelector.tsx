"use client";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

const ROLES = [
  {
    key: "dispatcher",
    label: "Crisis Dispatcher",
    icon: "🚨",
    description: "Emergency de-escalation, BCSM protocol",
    color: "#f59e0b",
    domain: "dispatch",
  },
  {
    key: "clinician",
    label: "Clinician",
    icon: "🏥",
    description: "Patient communication, SPIKES protocol",
    color: "#10b981",
    domain: "clinical",
  },
  {
    key: "negotiator",
    label: "Negotiator",
    icon: "💼",
    description: "Sales & persuasion, SPIN & Harvard methods",
    color: "#6366f1",
    domain: "negotiation",
  },
  {
    key: "legal",
    label: "Legal Interviewer",
    icon: "⚖️",
    description: "Investigative interviewing, PEACE model",
    color: "#ef4444",
    domain: "legal",
  },
  {
    key: "manager",
    label: "Manager",
    icon: "🏢",
    description: "Feedback & coaching, SBI & NVC models",
    color: "#3b82f6",
    domain: "corporate",
  },
  {
    key: "educator",
    label: "Educator",
    icon: "📚",
    description: "Scaffolded instruction, Socratic method",
    color: "#8b5cf6",
    domain: "education",
  },
] as const;

type RoleKey = (typeof ROLES)[number]["key"];

interface RoleSelectorProps {
  onSelect: (role: RoleKey) => void;
}

export default function RoleSelector({ onSelect }: RoleSelectorProps) {
  return (
    <div className="max-w-2xl w-full space-y-8">
      <div className="text-center">
        <h1 className="text-xl font-semibold text-[#e2e4f0] mb-2">
          Who are you?
        </h1>
        <p className="text-sm text-[#6b7280]">
          Select your role to get a personalised learning path through the
          communication knowledge graph.
        </p>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
        {ROLES.map((role, i) => (
          <motion.button
            key={role.key}
            type="button"
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.06 }}
            onClick={() => onSelect(role.key)}
            className={cn(
              "group flex flex-col items-center gap-3 p-5 rounded-xl border text-center",
              "transition-all duration-200 hover:scale-[1.02] active:scale-[0.98]"
            )}
            style={{
              borderColor: "var(--border)",
              background: "var(--surface)",
            }}
          >
            <span
              className="text-2xl w-12 h-12 rounded-xl flex items-center justify-center transition-colors"
              style={{ background: role.color + "18" }}
            >
              {role.icon}
            </span>
            <div>
              <p
                className="text-xs font-semibold transition-colors"
                style={{ color: role.color }}
              >
                {role.label}
              </p>
              <p className="text-[10px] text-[#6b7280] mt-0.5 leading-relaxed">
                {role.description}
              </p>
            </div>
          </motion.button>
        ))}
      </div>
    </div>
  );
}
