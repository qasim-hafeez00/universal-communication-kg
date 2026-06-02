"use client";

import { useEffect, useState, useCallback } from "react";
import dynamic from "next/dynamic";
import { NodeStub, GraphEdge } from "@/lib/types";
import { useGraphStore } from "@/stores/graph-store";
import DomainFilter from "@/components/graph/DomainFilter";
import NodeTypeFilter from "@/components/graph/NodeTypeFilter";
import SearchBox from "@/components/graph/SearchBox";
import GraphControls from "@/components/graph/GraphControls";
import TechniqueCard from "@/components/panels/TechniqueCard";
import { Network } from "lucide-react";

const GraphCanvas = dynamic(() => import("@/components/graph/GraphCanvas"), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full graph-canvas flex items-center justify-center">
      <div className="text-center space-y-3">
        <div className="w-8 h-8 border-2 border-[var(--accent)] border-t-transparent rounded-full animate-spin mx-auto" />
        <p className="text-xs text-[var(--muted)]">Loading knowledge graph…</p>
      </div>
    </div>
  ),
});

export default function ExplorerPage() {
  const [edges, setEdges] = useState<GraphEdge[]>([]);
  const [loadingGraph, setLoadingGraph] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const {
    nodes,
    setNodes,
    selectedNodeId,
    setSelectedNode,
    setHighlightedIds,
  } = useGraphStore();

  useEffect(() => {
    fetch("/api/nodes")
      .then((r) => r.json())
      .then((data: { nodes: NodeStub[]; edges: GraphEdge[] }) => {
        setNodes(data.nodes ?? []);
        setEdges(data.edges ?? []);
      })
      .catch(() =>
        setError("Could not connect to Neo4j. Make sure the database is running.")
      )
      .finally(() => setLoadingGraph(false));
  }, [setNodes]);

  const handleNodeClick = useCallback(
    (id: string) => setSelectedNode(id),
    [setSelectedNode]
  );

  const handleNavigate = useCallback(
    (id: string) => {
      setSelectedNode(id);
      setHighlightedIds(new Set([id]));
    },
    [setSelectedNode, setHighlightedIds]
  );

  const handleClose = useCallback(() => {
    setSelectedNode(null);
    setHighlightedIds(new Set());
  }, [setSelectedNode, setHighlightedIds]);

  return (
    <div className="flex-1 flex overflow-hidden relative">
      {/* Left sidebar */}
      <aside
        className={`flex-shrink-0 flex flex-col overflow-hidden transition-all duration-300 border-r`}
        style={{ borderColor: "var(--border)", background: "var(--surface)", width: sidebarOpen ? 264 : 0 }}
      >
        <div className="w-[264px] p-4 space-y-5 overflow-y-auto h-full">
          <SearchBox onSelect={handleNavigate} />
          <DomainFilter />
          <NodeTypeFilter />

          <div className="rounded-lg p-3 text-xs space-y-1.5" style={{ background: "var(--surface-2)", border: "1px solid var(--border)" }}>
            <p className="text-[10px] font-semibold uppercase tracking-widest mb-2" style={{ color: "var(--muted)" }}>
              Stats
            </p>
            {[
              ["Nodes", nodes.length.toLocaleString()],
              ["Edges", edges.length.toLocaleString()],
              ["Domains", "14"],
              ["Templates", "35"],
            ].map(([label, val]) => (
              <div key={label} className="flex justify-between" style={{ color: "var(--muted)" }}>
                <span>{label}</span>
                <span className="font-mono" style={{ color: "var(--foreground)" }}>{val}</span>
              </div>
            ))}
          </div>
        </div>
      </aside>

      {/* Sidebar toggle */}
      <button
        type="button"
        onClick={() => setSidebarOpen(!sidebarOpen)}
        className="absolute z-10 top-1/2 -translate-y-1/2 px-0.5 py-3 rounded-r text-xs transition-all"
        style={{
          left: sidebarOpen ? 264 : 0,
          background: "var(--surface)",
          borderTop: "1px solid var(--border)",
          borderRight: "1px solid var(--border)",
          borderBottom: "1px solid var(--border)",
          color: "var(--muted)",
        }}
      >
        {sidebarOpen ? "‹" : "›"}
      </button>

      {/* Canvas area */}
      <div className="flex-1 relative overflow-hidden">
        {error ? (
          <div className="w-full h-full graph-canvas flex items-center justify-center">
            <div className="text-center space-y-3 max-w-sm px-6">
              <Network size={32} className="mx-auto" style={{ color: "var(--muted)" }} />
              <p className="text-sm font-semibold" style={{ color: "var(--foreground)" }}>Graph Unavailable</p>
              <p className="text-xs" style={{ color: "var(--muted)" }}>{error}</p>
              <p className="text-[10px] font-mono mt-2" style={{ color: "var(--muted)", opacity: 0.6 }}>
                Set NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD in .env.local
              </p>
            </div>
          </div>
        ) : loadingGraph ? (
          <div className="w-full h-full graph-canvas flex items-center justify-center">
            <div className="text-center space-y-3">
              <div className="w-8 h-8 border-2 border-t-transparent rounded-full animate-spin mx-auto" style={{ borderColor: "var(--accent)", borderTopColor: "transparent" }} />
              <p className="text-xs" style={{ color: "var(--muted)" }}>Loading knowledge graph…</p>
            </div>
          </div>
        ) : (
          <GraphCanvas nodes={nodes} edges={edges} onNodeClick={handleNodeClick} />
        )}

        <GraphControls />

        <TechniqueCard
          id={selectedNodeId}
          onClose={handleClose}
          onNavigate={handleNavigate}
        />
      </div>
    </div>
  );
}
