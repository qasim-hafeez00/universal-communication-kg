"use client";
import { useGraphStore } from "@/stores/graph-store";
import { cn } from "@/lib/utils";

const NODE_TYPES = [
  { key: "Technique",           label: "Technique",          icon: "○" },
  { key: "SignalMarker",        label: "Signal Marker",       icon: "◈" },
  { key: "DomainProtocol",      label: "Domain Protocol",     icon: "⬟" },
  { key: "StatementMarker",     label: "Statement Marker",    icon: "◇" },
  { key: "DialogueAct",         label: "Dialogue Act",        icon: "💬" },
  { key: "ProtocolStep",        label: "Protocol Step",       icon: "⬡" },
  { key: "ProtocolDAG",         label: "Protocol DAG",        icon: "⬢" },
  { key: "ProtocolGate",        label: "Protocol Gate",       icon: "⬩" },
  { key: "EmotionalState",      label: "Emotional State",     icon: "♡" },
  { key: "EgoState",            label: "Ego State",           icon: "△" },
  { key: "CulturalProfile",     label: "Cultural Profile",    icon: "🌍" },
  { key: "Session",             label: "Session / Memory",    icon: "🗂️" },
  { key: "RetrievalLeg",        label: "Retrieval",           icon: "🔍" },
  { key: "Text2CypherTemplate", label: "Query Template",      icon: "📐" },
] as const;

export default function NodeTypeFilter() {
  const { activeTypes, toggleType, clearFilters } = useGraphStore();

  const allActive = activeTypes.size === 0;

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between mb-2">
        <p className="text-[10px] font-semibold uppercase tracking-widest text-[#6b7280]">
          Node Types
        </p>
        {!allActive && (
          <button
            type="button"
            onClick={clearFilters}
            className="text-[10px] text-[#22d3ee] hover:underline"
          >
            Reset
          </button>
        )}
      </div>

      {NODE_TYPES.map(({ key, label, icon }) => {
        const active = activeTypes.has(key);
        return (
          <button
            key={key}
            type="button"
            onClick={() => toggleType(key)}
            className={cn(
              "w-full flex items-center gap-2 px-2.5 py-1.5 rounded-md text-xs transition-all text-left",
              active
                ? "text-[#e2e4f0] bg-white/5"
                : "text-[#6b7280] hover:text-[#9ca3af]"
            )}
          >
            <span className="text-sm font-mono leading-none w-4">{icon}</span>
            <span className="flex-1">{label}</span>
            <span className={cn("w-1.5 h-1.5 rounded-full flex-shrink-0",
              active ? "bg-[#22d3ee]" : "bg-[#374151]")} />
          </button>
        );
      })}
    </div>
  );
}
