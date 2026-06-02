export const DOMAINS = [
  "Crisis Dispatch / Emergency",
  "Sales & Negotiation",
  "Clinical / Medical",
  "Legal & Investigative",
  "Corporate & Engineering",
  "Education",
  "Dialogue Acts",
  "Psychological",
  "Cultural",
  "Multimodal",
  "Memory",
  "Retrieval",
  "Schema",
  "Protocol",
  "Consistency",
] as const;

export type Domain = (typeof DOMAINS)[number];

export const DOMAIN_KEY: Record<string, string> = {
  "Crisis Dispatch / Emergency": "dispatch",
  "Sales & Negotiation":        "negotiation",
  "Clinical / Medical":         "clinical",
  "Legal & Investigative":      "legal",
  "Corporate & Engineering":    "corporate",
  Education:                    "education",
  "Dialogue Acts":              "dialogue",
  Psychological:                "psychological",
  Cultural:                     "cultural",
  Multimodal:                   "multimodal",
  Memory:                       "memory",
  Retrieval:                    "retrieval",
  Schema:                       "schema",
  Protocol:                     "protocol",
  Consistency:                  "consistency",
};

const DOMAIN_COLOR_MAP: Record<string, string> = {
  "Crisis Dispatch / Emergency": "#f59e0b",
  "Sales & Negotiation":         "#6366f1",
  "Clinical / Medical":          "#10b981",
  "Legal & Investigative":       "#ef4444",
  "Corporate & Engineering":     "#3b82f6",
  Education:                     "#8b5cf6",
  "Dialogue Acts":               "#60a5fa",
  Psychological:                 "#ec4899",
  Cultural:                      "#f97316",
  Multimodal:                    "#22d3ee",
  Memory:                        "#a78bfa",
  Retrieval:                     "#34d399",
  Schema:                        "#94a3b8",
  Protocol:                      "#fbbf24",
  Consistency:                   "#e11d48",
};

const DOMAIN_ICON_MAP: Record<string, string> = {
  "Crisis Dispatch / Emergency": "🚨",
  "Sales & Negotiation":         "💼",
  "Clinical / Medical":          "🏥",
  "Legal & Investigative":       "⚖️",
  "Corporate & Engineering":     "🏢",
  Education:                     "📚",
  "Dialogue Acts":               "💬",
  Psychological:                 "🧠",
  Cultural:                      "🌍",
  Multimodal:                    "🎙️",
  Memory:                        "🗂️",
  Retrieval:                     "🔍",
  Schema:                        "📐",
  Protocol:                      "🔗",
  Consistency:                   "⚖",
};

// Legacy typed accessors (keep for DomainFilter compatibility)
export const DOMAIN_COLOR = DOMAIN_COLOR_MAP as Record<Domain, string>;
export const DOMAIN_BG    = Object.fromEntries(
  Object.entries(DOMAIN_COLOR_MAP).map(([k, v]) => [k, v + "1a"])
) as Record<Domain, string>;
export const DOMAIN_ICON  = DOMAIN_ICON_MAP as Record<Domain, string>;

export function colorForDomain(domain: string): string {
  return DOMAIN_COLOR_MAP[domain] ?? "#6b7280";
}

export function bgForDomain(domain: string): string {
  return (DOMAIN_COLOR_MAP[domain] ?? "#6b7280") + "1a";
}

export function iconForDomain(domain: string): string {
  return DOMAIN_ICON_MAP[domain] ?? "○";
}
