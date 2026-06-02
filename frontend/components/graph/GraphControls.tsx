"use client";
import { ZoomIn, ZoomOut, Maximize2 } from "lucide-react";
import { useGraphStore } from "@/stores/graph-store";
import { cn } from "@/lib/utils";

export default function GraphControls() {
  const { layout, setLayout, triggerZoom } = useGraphStore();

  const layouts = [
    { key: "force", label: "Force" },
    { key: "radial", label: "Radial" },
    { key: "hierarchical", label: "Hierarchical" },
  ] as const;

  return (
    <div className="absolute bottom-4 right-4 flex flex-col gap-2 z-10">
      {/* Layout selector */}
      <div className="flex flex-col rounded-lg overflow-hidden border border-[var(--border)] bg-[var(--surface)]">
        {layouts.map((l) => (
          <button
            key={l.key}
            type="button"
            onClick={() => setLayout(l.key)}
            className={cn(
              "px-3 py-1.5 text-xs font-medium transition-colors text-left",
              layout === l.key
                ? "text-[#22d3ee] bg-[#22d3ee15]"
                : "text-[#6b7280] hover:text-[#e2e4f0] hover:bg-white/5"
            )}
          >
            {l.label}
          </button>
        ))}
      </div>

      {/* Zoom controls */}
      <div className="flex flex-col rounded-lg overflow-hidden border border-[var(--border)] bg-[var(--surface)]">
        <button
          type="button"
          onClick={() => triggerZoom("in")}
          className="p-2 text-[#6b7280] hover:text-[#e2e4f0] hover:bg-white/5 transition-colors"
          title="Zoom in"
        >
          <ZoomIn size={14} />
        </button>
        <div className="h-px bg-[var(--border)]" />
        <button
          type="button"
          onClick={() => triggerZoom("out")}
          className="p-2 text-[#6b7280] hover:text-[#e2e4f0] hover:bg-white/5 transition-colors"
          title="Zoom out"
        >
          <ZoomOut size={14} />
        </button>
        <div className="h-px bg-[var(--border)]" />
        <button
          type="button"
          onClick={() => triggerZoom("fit")}
          className="p-2 text-[#6b7280] hover:text-[#e2e4f0] hover:bg-white/5 transition-colors"
          title="Fit to screen"
        >
          <Maximize2 size={14} />
        </button>
      </div>
    </div>
  );
}
