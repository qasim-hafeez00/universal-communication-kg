"use client";
import { create } from "zustand";
import { NodeStub, TechniqueDetail } from "@/lib/types";

type Role =
  | "dispatcher"
  | "clinician"
  | "negotiator"
  | "legal"
  | "manager"
  | "educator"
  | null;

type ZoomType = "in" | "out" | "fit";

interface GraphStore {
  // graph data
  nodes: NodeStub[];
  setNodes: (nodes: NodeStub[]) => void;

  // selection
  selectedNodeId: string | null;
  selectedDetail: TechniqueDetail | null;
  setSelectedNode: (id: string | null) => void;
  setSelectedDetail: (d: TechniqueDetail | null) => void;

  // filters — empty set means "show all"
  activeDomains: Set<string>;
  activeTypes: Set<string>;
  searchQuery: string;
  toggleDomain: (d: string) => void;
  toggleType: (t: string) => void;
  setSearchQuery: (q: string) => void;
  clearFilters: () => void;

  // highlighted nodes (from search / simulator)
  highlightedIds: Set<string>;
  setHighlightedIds: (ids: Set<string>) => void;

  // layout
  layout: "force" | "radial" | "hierarchical";
  setLayout: (l: "force" | "radial" | "hierarchical") => void;

  // zoom control (triggers effect in GraphCanvas)
  zoomAction: { type: ZoomType; ts: number } | null;
  triggerZoom: (type: ZoomType) => void;

  // practitioner profile (learn page)
  role: Role;
  setRole: (r: Role) => void;
  masteredIds: Set<string>;
  toggleMastered: (id: string) => void;
}

export const useGraphStore = create<GraphStore>((set) => ({
  nodes: [],
  setNodes: (nodes) => set({ nodes }),

  selectedNodeId: null,
  selectedDetail: null,
  setSelectedNode: (id) => set({ selectedNodeId: id, selectedDetail: null }),
  setSelectedDetail: (d) => set({ selectedDetail: d }),

  // Empty = show all; populated = restrict to those items
  activeDomains: new Set<string>(),
  activeTypes: new Set<string>(),
  searchQuery: "",
  toggleDomain: (d) =>
    set((s) => {
      const next = new Set(s.activeDomains);
      next.has(d) ? next.delete(d) : next.add(d);
      return { activeDomains: next };
    }),
  toggleType: (t) =>
    set((s) => {
      const next = new Set(s.activeTypes);
      next.has(t) ? next.delete(t) : next.add(t);
      return { activeTypes: next };
    }),
  setSearchQuery: (q) => set({ searchQuery: q }),
  clearFilters: () =>
    set({ activeDomains: new Set(), activeTypes: new Set() }),

  highlightedIds: new Set(),
  setHighlightedIds: (ids) => set({ highlightedIds: ids }),

  layout: "force",
  setLayout: (l) => set({ layout: l }),

  zoomAction: null,
  triggerZoom: (type) => set({ zoomAction: { type, ts: Date.now() } }),

  role: null,
  setRole: (r) => set({ role: r }),
  masteredIds: new Set(),
  toggleMastered: (id) =>
    set((s) => {
      const next = new Set(s.masteredIds);
      next.has(id) ? next.delete(id) : next.add(id);
      if (typeof window !== "undefined") {
        localStorage.setItem("uckb-mastered", JSON.stringify([...next]));
      }
      return { masteredIds: next };
    }),
}));
