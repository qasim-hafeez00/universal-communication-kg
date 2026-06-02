"use client";
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, ChevronRight, CheckCircle2, XCircle, AlertTriangle, BookOpen } from "lucide-react";
import { TechniqueDetail } from "@/lib/types";
import { colorForDomain, bgForDomain, iconForDomain, DOMAIN_KEY } from "@/lib/domain-colors";
import { useGraphStore } from "@/stores/graph-store";
import { cn } from "@/lib/utils";

interface TechniqueCardProps {
  id: string | null;
  onClose: () => void;
  onNavigate: (id: string) => void;
}

export default function TechniqueCard({ id, onClose, onNavigate }: TechniqueCardProps) {
  const [detail, setDetail] = useState<TechniqueDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const { masteredIds, toggleMastered } = useGraphStore();

  useEffect(() => {
    if (!id) { setDetail(null); return; }
    setLoading(true);
    fetch(`/api/nodes/${encodeURIComponent(id)}`)
      .then((r) => r.json())
      .then((d) => setDetail(d))
      .catch(() => setDetail(null))
      .finally(() => setLoading(false));
  }, [id]);

  const domainColor = detail ? colorForDomain(detail.domain) : "#6b7280";
  const domainBg    = detail ? bgForDomain(detail.domain) : "#6b72801a";
  // DOMAIN_KEY used for potential future data-domain attribute
  void (detail ? DOMAIN_KEY[detail.domain as keyof typeof DOMAIN_KEY] : "");

  const isMastered = id ? masteredIds.has(id) : false;

  const steps = detail?.steps
    ? detail.steps
        .split(/\n|; |\. (?=[0-9])/)
        .map((s) => s.trim())
        .filter(Boolean)
    : [];

  const sources = detail?.sourceIds
    ? detail.sourceIds.split(/; |,/).map((s) => s.trim()).filter(Boolean)
    : [];

  const triggerTags = detail?.triggerSignals
    ? detail.triggerSignals.split(/; |,/).map((s) => s.trim()).filter(Boolean)
    : [];

  return (
    <AnimatePresence>
      {id && (
        <motion.div
          key="card"
          initial={{ x: "100%" }}
          animate={{ x: 0 }}
          exit={{ x: "100%" }}
          transition={{ type: "spring", stiffness: 280, damping: 28 }}
          className="absolute right-0 top-0 h-full w-[400px] flex flex-col border-l shadow-lg z-20"
          style={{
            background: "var(--surface)",
            borderColor: "var(--border)",
          }}
        >
          {/* Header */}
          <div
            className="flex items-start justify-between p-4 border-b"
            style={{ borderColor: "var(--border)", background: domainBg }}
          >
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1 flex-wrap">
                <span
                  className="text-[10px] font-semibold px-2 py-0.5 rounded-full uppercase tracking-wide"
                  style={{ color: domainColor, background: domainColor + "22" }}
                >
                  {iconForDomain(detail?.domain ?? "")} {detail?.domain?.split(" ")[0] ?? "—"}
                </span>
                {detail?.tier && (
                  <span
                    className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                    style={{ background: "var(--surface-2)", color: "var(--muted)" }}
                  >
                    {detail.tier}
                  </span>
                )}
                {detail?.cognitiveLoadProfile && (
                  <span
                    className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                    style={{ background: "var(--surface-2)", color: "var(--muted)" }}
                  >
                    {detail.cognitiveLoadProfile}
                  </span>
                )}
              </div>
              <h2 className="text-sm font-semibold leading-snug" style={{ color: "var(--foreground)" }}>
                {loading ? "Loading..." : (detail?.name ?? "—")}
              </h2>
              <p className="text-[10px] font-mono mt-0.5" style={{ color: "var(--muted)" }}>{id}</p>
            </div>
            <button
              type="button"
              aria-label="Close"
              onClick={onClose}
              className="ml-2 p-1 rounded-md transition-colors flex-shrink-0 hover:bg-black/5"
              style={{ color: "var(--muted)" }}
            >
              <X size={14} />
            </button>
          </div>

          {/* Body */}
          <div className="flex-1 overflow-y-auto p-4 space-y-5 text-xs">
            {loading && (
              <div className="space-y-3">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="h-4 rounded animate-pulse" style={{ background: "var(--border)" }} />
                ))}
              </div>
            )}

            {!loading && detail && (
              <>
                {/* Description */}
                {detail.description && (
                  <p className="leading-relaxed" style={{ color: "var(--muted)" }}>{detail.description}</p>
                )}

                <Divider />

                {/* When to use */}
                {detail.whenToUse && (
                  <Section title="When to Use">
                    <p className="leading-relaxed" style={{ color: "var(--foreground)" }}>{detail.whenToUse}</p>
                    {triggerTags.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-2">
                        {triggerTags.map((t) => (
                          <Tag key={t} color={domainColor}>{t}</Tag>
                        ))}
                      </div>
                    )}
                  </Section>
                )}

                {/* When NOT to use */}
                {detail.whenNotToUse && (
                  <Section title="When NOT to Use" icon={<AlertTriangle size={11} className="text-red-500" />}>
                    <p className="leading-relaxed text-red-600">{detail.whenNotToUse}</p>
                    {detail.contraindications && (
                      <p className="mt-1 italic" style={{ color: "var(--muted)" }}>{detail.contraindications}</p>
                    )}
                  </Section>
                )}

                <Divider />

                {/* Steps */}
                {steps.length > 0 && (
                  <Section title="Execution">
                    <ol className="space-y-1.5 list-none">
                      {steps.map((step, i) => (
                        <li key={i} className="flex gap-2">
                          <span
                            className="flex-shrink-0 w-4 h-4 rounded-full flex items-center justify-center text-[9px] font-bold mt-0.5"
                            style={{ background: domainColor + "22", color: domainColor }}
                          >
                            {i + 1}
                          </span>
                          <span className="leading-relaxed" style={{ color: "var(--foreground)" }}>{step}</span>
                        </li>
                      ))}
                    </ol>
                  </Section>
                )}

                <Divider />

                {/* Success / Failure */}
                {(detail.successSignals || detail.failureSignals) && (
                  <div className="grid grid-cols-2 gap-3">
                    {detail.successSignals && (
                      <div>
                        <p className="text-[10px] font-semibold uppercase tracking-wider text-emerald-600 mb-1 flex items-center gap-1">
                          <CheckCircle2 size={10} /> Success
                        </p>
                        <p className="leading-relaxed text-emerald-700">{detail.successSignals}</p>
                      </div>
                    )}
                    {detail.failureSignals && (
                      <div>
                        <p className="text-[10px] font-semibold uppercase tracking-wider text-red-500 mb-1 flex items-center gap-1">
                          <XCircle size={10} /> Failure
                        </p>
                        <p className="leading-relaxed text-red-600">{detail.failureSignals}</p>
                      </div>
                    )}
                  </div>
                )}

                {/* Cultural notes */}
                {detail.culturalNotes && (
                  <>
                    <Divider />
                    <Section title="Cultural Notes">
                      <p className="leading-relaxed" style={{ color: "var(--foreground)" }}>{detail.culturalNotes}</p>
                    </Section>
                  </>
                )}

                {/* Sources */}
                {sources.length > 0 && (
                  <>
                    <Divider />
                    <Section title="Sources" icon={<BookOpen size={11} />}>
                      <div className="flex flex-wrap gap-1">
                        {sources.map((s) => (
                          <span
                            key={s}
                            className="text-[10px] px-2 py-0.5 rounded font-mono"
                            style={{ background: "var(--surface-2)", color: "var(--muted)", border: "1px solid var(--border)" }}
                          >
                            {s}
                          </span>
                        ))}
                      </div>
                    </Section>
                  </>
                )}

                {/* Connected techniques */}
                {detail.neighbors.length > 0 && (
                  <>
                    <Divider />
                    <Section title={`Connected (${detail.neighbors.length})`}>
                      <div className="flex flex-col gap-1">
                        {detail.neighbors.slice(0, 8).map((nb) => (
                          <button
                            type="button"
                            key={nb.id + nb.relType}
                            onClick={() => onNavigate(nb.id)}
                            className="flex items-center gap-2 px-2 py-1.5 rounded-md text-left transition-colors hover:bg-black/5 group"
                          >
                            <span
                              className="w-1.5 h-1.5 rounded-full flex-shrink-0"
                              style={{ background: colorForDomain(nb.domain) }}
                            />
                            <span
                              className="flex-1 truncate transition-colors"
                              style={{ color: "var(--muted)" }}
                            >
                              {nb.name}
                            </span>
                            <span className="text-[9px] font-mono flex-shrink-0" style={{ color: "var(--muted)", opacity: 0.6 }}>
                              {nb.relType}
                            </span>
                            <ChevronRight size={10} className="flex-shrink-0" style={{ color: "var(--muted)" }} />
                          </button>
                        ))}
                      </div>
                    </Section>
                  </>
                )}
              </>
            )}
          </div>

          {/* Footer: mastery toggle */}
          <div
            className="p-3 border-t"
            style={{ borderColor: "var(--border)" }}
          >
            <button
              type="button"
              onClick={() => id && toggleMastered(id)}
              className={cn(
                "w-full py-2 rounded-lg text-xs font-medium transition-all flex items-center justify-center gap-2",
                isMastered
                  ? "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200"
                  : "border hover:bg-black/5"
              )}
              style={!isMastered ? { borderColor: "var(--border)", color: "var(--muted)" } : undefined}
            >
              <CheckCircle2 size={12} />
              {isMastered ? "Marked as Studied" : "Mark as Studied"}
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function Divider() {
  return <div className="h-px" style={{ background: "var(--border)" }} />;
}

function Section({
  title,
  icon,
  children,
}: {
  title: string;
  icon?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div>
      <p
        className="text-[10px] font-semibold uppercase tracking-wider mb-1.5 flex items-center gap-1"
        style={{ color: "var(--muted)" }}
      >
        {icon}
        {title}
      </p>
      {children}
    </div>
  );
}

function Tag({ children, color }: { children: React.ReactNode; color: string }) {
  return (
    <span
      className="text-[10px] px-1.5 py-0.5 rounded font-mono"
      style={{ background: color + "18", color }}
    >
      {children}
    </span>
  );
}
