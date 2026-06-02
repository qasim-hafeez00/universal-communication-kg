"use client";
import { useGraphStore } from "@/stores/graph-store";
import { DOMAINS, DOMAIN_KEY, iconForDomain } from "@/lib/domain-colors";
import { cn } from "@/lib/utils";

export default function DomainFilter() {
  const { activeDomains, toggleDomain, clearFilters } = useGraphStore();

  const allActive = activeDomains.size === 0;

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between mb-2">
        <p className="text-[10px] font-semibold uppercase tracking-widest" style={{ color: "var(--muted)" }}>
          Domains
        </p>
        {!allActive && (
          <button
            type="button"
            onClick={clearFilters}
            className="text-[10px] hover:underline"
            style={{ color: "var(--accent)" }}
          >
            Reset
          </button>
        )}
      </div>

      {/* "Show all" pill */}
      <button
        type="button"
        onClick={clearFilters}
        className={cn(
          "w-full flex items-center gap-2 px-2.5 py-1.5 rounded-md text-xs transition-all text-left",
          allActive ? "bg-black/5" : "hover:bg-black/4"
        )}
        style={{ color: allActive ? "var(--foreground)" : "var(--muted)" }}
      >
        <span className="text-sm leading-none">◉</span>
        <span className="flex-1 leading-none">All domains</span>
        <span
          className="w-1.5 h-1.5 rounded-full flex-shrink-0"
          style={{ background: allActive ? "var(--accent)" : "#cbd5e1" }}
        />
      </button>

      {DOMAINS.map((domain) => {
        const active  = activeDomains.has(domain);
        const domKey  = DOMAIN_KEY[domain] ?? "dispatch";
        const icon    = iconForDomain(domain);
        return (
          <button
            key={domain}
            type="button"
            data-domain={domKey}
            onClick={() => toggleDomain(domain)}
            className={cn(
              "w-full flex items-center gap-2 px-2.5 py-1.5 rounded-md text-xs transition-all text-left",
              active
                ? "domain-btn-active"
                : "domain-btn-inactive hover:bg-black/4"
            )}
            style={{ color: active ? "var(--foreground)" : "var(--muted)" }}
          >
            <span className="text-sm leading-none">{icon}</span>
            <span className="flex-1 truncate leading-none">{domain}</span>
            <span className={cn("w-1.5 h-1.5 rounded-full flex-shrink-0",
              active ? "domain-dot-active" : "domain-dot-inactive")} />
          </button>
        );
      })}
    </div>
  );
}
