"use client";
import { colorForDomain } from "@/lib/domain-colors";
import { cn } from "@/lib/utils";

const DOMAINS = [
  { key: "dispatch",    label: "Crisis Dispatch",  icon: "🚨" },
  { key: "clinical",   label: "Clinical",          icon: "🏥" },
  { key: "negotiation",label: "Negotiation",       icon: "💼" },
  { key: "legal",      label: "Legal",             icon: "⚖️" },
  { key: "corporate",  label: "Corporate",         icon: "🏢" },
  { key: "education",  label: "Education",         icon: "📚" },
] as const;

interface Preset {
  domain: string;
  label: string;
  query: string;
}

interface Props {
  domain: string;
  query: string;
  onDomainChange: (d: string) => void;
  onQueryChange: (q: string) => void;
  presets: readonly Preset[];
}

export default function ScenarioBuilder({ domain, query, onDomainChange, onQueryChange, presets }: Props) {
  const color = colorForDomain(
    { dispatch: "Crisis Dispatch / Emergency", clinical: "Clinical / Medical",
      negotiation: "Sales & Negotiation", legal: "Legal & Investigative",
      corporate: "Corporate & Engineering", education: "Education" }[domain] ?? ""
  );

  return (
    <div className="space-y-5">
      {/* Domain */}
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-widest text-[#6b7280] mb-2">Domain</p>
        <div className="grid grid-cols-2 gap-1.5">
          {DOMAINS.map((d) => (
            <button
              key={d.key}
              type="button"
              onClick={() => onDomainChange(d.key)}
              className={cn(
                "flex items-center gap-1.5 px-2.5 py-2 rounded-lg text-[11px] transition-all text-left border",
                domain === d.key
                  ? "border-transparent text-[#e2e4f0]"
                  : "border-transparent text-[#6b7280] hover:text-[#9ca3af] bg-transparent"
              )}
              style={
                domain === d.key
                  ? { background: colorForDomain(
                      { dispatch: "Crisis Dispatch / Emergency", clinical: "Clinical / Medical",
                        negotiation: "Sales & Negotiation", legal: "Legal & Investigative",
                        corporate: "Corporate & Engineering", education: "Education" }[d.key] ?? ""
                    ) + "20",
                      borderColor: colorForDomain(
                        { dispatch: "Crisis Dispatch / Emergency", clinical: "Clinical / Medical",
                          negotiation: "Sales & Negotiation", legal: "Legal & Investigative",
                          corporate: "Corporate & Engineering", education: "Education" }[d.key] ?? ""
                      ) + "50" }
                  : { background: "var(--surface-2, #1a1a2e)" }
              }
            >
              <span>{d.icon}</span>
              <span>{d.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Query */}
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-widest text-[#6b7280] mb-2">Scenario Query</p>
        <textarea
          value={query}
          onChange={(e) => onQueryChange(e.target.value)}
          placeholder="Describe the scenario…"
          rows={4}
          className="w-full rounded-lg border border-[var(--border)] bg-[#1a1a2e] text-xs text-[#e2e4f0] placeholder-[#4b5563] p-3 outline-none resize-none focus:border-[#22d3ee40] transition-colors"
        />
      </div>

      {/* Presets */}
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-widest text-[#6b7280] mb-2">Presets</p>
        <div className="space-y-1">
          {presets.map((p) => (
            <button
              key={p.domain + p.label}
              type="button"
              onClick={() => { onDomainChange(p.domain); onQueryChange(p.query); }}
              className="w-full text-left px-2.5 py-2 rounded-lg text-[10px] text-[#6b7280] hover:text-[#e2e4f0] hover:bg-white/5 transition-colors leading-relaxed"
            >
              {p.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
