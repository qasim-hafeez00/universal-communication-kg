"use client";

import { useEffect, useRef, useCallback, useMemo, useState } from "react";
import ForceGraph2D from "react-force-graph-2d";
import { NodeStub, GraphEdge } from "@/lib/types";
import { colorForDomain } from "@/lib/domain-colors";
import { useGraphStore } from "@/stores/graph-store";

// ── Types ─────────────────────────────────────────────────────────────────────

type FGNode = {
  id: string;
  name: string;
  domain: string;
  nodeType: string;
  degree: number;
  color: string;
  x?: number;
  y?: number;
  vx?: number;
  vy?: number;
  fx?: number;
  fy?: number;
  __r?: number; // cached world radius for hit detection
};

type FGLink = {
  source: string | FGNode;
  target: string | FGNode;
  relType: string;
  weight: number;
};

interface GraphCanvasProps {
  nodes: NodeStub[];
  edges: GraphEdge[];
  onNodeClick: (id: string) => void;
}

// ── Relationship colours ─────────────────────────────────────────────────────

const REL_COLORS: Record<string, string> = {
  REQUIRES:             "#6366f1",
  ESCALATES_TO:         "#ef4444",
  ENHANCES:             "#10b981",
  REINFORCES:           "#10b981",
  SAFE_FOR:             "#10b981",
  TRIGGERS:             "#06b6d4",
  TRIGGERED:            "#06b6d4",
  TRIGGERED_BY:         "#06b6d4",
  PRECEDES:             "#f59e0b",
  PART_OF:              "#94a3b8",
  ACTIVE_PROTOCOL:      "#94a3b8",
  AT_STEP:              "#94a3b8",
  FOLLOWS:              "#94a3b8",
  CONTRAINDICATED_WHEN: "#ef4444",
  CONTRADICTS:          "#ef4444",
  DOMAIN_VARIANT_OF:    "#8b5cf6",
  CULTURAL_VARIANT_OF:  "#f97316",
  ADAPTS_FOR:           "#f97316",
  APPLIES_RULE:         "#f97316",
  STYLE_SUGGESTS:       "#f97316",
  PREFERS_STYLE:        "#f97316",
  INDICATES_EMOTION:    "#ec4899",
  MAPS_TO_EGO_STATE:    "#a78bfa",
  RESOLVES_EGO_STATE:   "#a78bfa",
  HAS_TURN:             "#10b981",
  HAS_SLOT:             "#10b981",
  HAS_EPISODE:          "#10b981",
  HAS_FACT:             "#10b981",
  HAS_LEG:              "#10b981",
  PRODUCED_BY:          "#3b82f6",
  QUERIES_INDEX:        "#3b82f6",
  FUSED_INTO:           "#3b82f6",
  USES_FUSION:          "#3b82f6",
  REQUIRES_ACT:         "#3b82f6",
  GATES:                "#f59e0b",
  EXTRACTED_FROM:       "#94a3b8",
  HAS_GOAL:             "#10b981",
  HAS_TRACKER:          "#10b981",
  HAS_REPORT:           "#10b981",
  TRACKS:               "#3b82f6",
  FLAGGED_DEVIATION:    "#ef4444",
  CANDIDATE_FOR:        "#8b5cf6",
  SUPERSEDES:           "#94a3b8",
  FILTERS_BY:           "#f59e0b",
  CO_INDEX_WITH:        "#3b82f6",
};

const DEFAULT_LINK_COLOR = "#94a3b8";

// ── Node ID extractor ────────────────────────────────────────────────────────

function nodeId(n: FGNode | string | number): string {
  return typeof n === "object" ? n.id : String(n);
}

// ── Smart label: tries to fit the best readable label in a given char budget ──

function smartLabel(name: string, maxChars: number): string {
  if (name.length <= maxChars) return name;
  const words = name.split(/[\s\-_/()]+/).filter(Boolean);
  // Try first word
  if (words[0].length <= maxChars) return words[0];
  // Hard truncate
  return name.slice(0, Math.max(2, maxChars - 1)) + "…";
}

// ── Node screen radius (degree-proportional, always visible on screen) ────────

function screenRadius(degree: number, selected: boolean, highlighted: boolean): number {
  // Logarithmic growth: low-degree nodes stay small, hubs grow larger
  const base = Math.max(15, Math.min(38, 13 + Math.log(degree + 1) * 4.5));
  if (selected) return base + 5;
  if (highlighted) return base + 3;
  return base;
}

// ── Component ────────────────────────────────────────────────────────────────

export default function GraphCanvas({ nodes, edges, onNodeClick }: GraphCanvasProps) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const fgRef = useRef<any>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const hasInitialZoom = useRef(false);
  const physicsApplied = useRef(false);

  const { activeDomains, activeTypes, selectedNodeId, highlightedIds, layout, zoomAction } =
    useGraphStore();

  const [dims, setDims] = useState({ w: 800, h: 600 });

  // Track container size
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const ro = new ResizeObserver((entries) => {
      const r = entries[0].contentRect;
      setDims({ w: Math.floor(r.width), h: Math.floor(r.height) });
    });
    ro.observe(el);
    setDims({ w: el.clientWidth || 800, h: el.clientHeight || 600 });
    return () => ro.disconnect();
  }, []);

  // Build graph data from raw props
  const { fgNodes, fgLinks } = useMemo(() => {
    const fgNodes: FGNode[] = nodes.map((n) => ({
      id: n.id,
      name: n.name,
      domain: n.domain,
      nodeType: n.type,
      degree: n.degree,
      color: colorForDomain(n.domain),
    }));

    const nodeSet = new Set(fgNodes.map((n) => n.id));
    const seen = new Set<string>();
    const fgLinks: FGLink[] = [];
    for (const e of edges) {
      const key = `${e.source}→${e.target}`;
      if (!nodeSet.has(e.source) || !nodeSet.has(e.target)) continue;
      if (e.source === e.target || seen.has(key)) continue;
      seen.add(key);
      fgLinks.push({ source: e.source, target: e.target, relType: e.type, weight: e.weight ?? 1 });
    }
    return { fgNodes, fgLinks };
  }, [nodes, edges]);

  // O(1) node lookup
  const nodeMap = useMemo(() => {
    const m = new Map<string, FGNode>();
    fgNodes.forEach((n) => m.set(n.id, n));
    return m;
  }, [fgNodes]);

  // Neighbour set for dimming / highlighting
  const neighborIds = useMemo(() => {
    if (!selectedNodeId) return new Set<string>();
    const s = new Set<string>();
    for (const l of fgLinks) {
      const src = nodeId(l.source);
      const tgt = nodeId(l.target);
      if (src === selectedNodeId) s.add(tgt);
      if (tgt === selectedNodeId) s.add(src);
    }
    return s;
  }, [selectedNodeId, fgLinks]);

  // Apply d3 force settings after the graph initialises (deferred to ensure fgRef is ready)
  useEffect(() => {
    physicsApplied.current = false;
    const t = setTimeout(() => {
      const fg = fgRef.current;
      if (!fg || physicsApplied.current) return;
      physicsApplied.current = true;
      // Strong repulsion so 700 nodes spread out properly
      fg.d3Force("charge")?.strength(-600);
      fg.d3Force("link")?.distance(90);
      fg.d3ReheatSimulation();
    }, 100);
    return () => clearTimeout(t);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fgNodes.length]);

  // Respond to zoom actions from GraphControls
  useEffect(() => {
    if (!zoomAction || !fgRef.current) return;
    const fg = fgRef.current;
    if (zoomAction.type === "fit") fg.zoomToFit(500, 60);
    else if (zoomAction.type === "in") fg.zoom(fg.zoom() * 1.5, 200);
    else if (zoomAction.type === "out") fg.zoom(fg.zoom() / 1.5, 200);
  }, [zoomAction]);

  // Apply layout positions
  useEffect(() => {
    const t = setTimeout(() => {
      const fg = fgRef.current;
      if (!fg) return;

      if (layout === "force") {
        fgNodes.forEach((n) => { n.fx = undefined; n.fy = undefined; });
        fg.d3Force("charge")?.strength(-600);
        fg.d3Force("link")?.distance(90);
        fg.d3ReheatSimulation();
      } else if (layout === "radial") {
        const domains = [...new Set(fgNodes.map((n) => n.domain))];
        fgNodes.forEach((node) => {
          const di = domains.indexOf(node.domain);
          const angle = (di / domains.length) * 2 * Math.PI;
          const r = 600;
          node.fx = Math.cos(angle) * r + Math.sin(node.degree * 0.6) * 90;
          node.fy = Math.sin(angle) * r + Math.cos(node.degree * 0.6) * 90;
        });
        fg.d3ReheatSimulation();
      } else if (layout === "hierarchical") {
        const domains = [...new Set(fgNodes.map((n) => n.domain))];
        const byDomain: Record<string, FGNode[]> = {};
        fgNodes.forEach((n) => { (byDomain[n.domain] ??= []).push(n); });
        domains.forEach((domain, di) => {
          const group = byDomain[domain] ?? [];
          group.forEach((node, ni) => {
            node.fx = di * 360 - (domains.length * 180);
            node.fy = ni * 60 - (group.length * 30);
          });
        });
        fg.d3ReheatSimulation();
      }
    }, 100);
    return () => clearTimeout(t);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [layout]);

  // ── Filter predicates ────────────────────────────────────────────────────

  const nodeVisible = useCallback(
    (node: object) => {
      const n = node as FGNode;
      if (activeDomains.size > 0 && !activeDomains.has(n.domain)) return false;
      if (activeTypes.size > 0 && !activeTypes.has(n.nodeType)) return false;
      return true;
    },
    [activeDomains, activeTypes]
  );

  const linkVisible = useCallback(
    (link: object) => {
      const l = link as FGLink;
      const srcNode = nodeMap.get(nodeId(l.source));
      const tgtNode = nodeMap.get(nodeId(l.target));
      if (!srcNode || !tgtNode) return false;
      if (activeDomains.size > 0 && (!activeDomains.has(srcNode.domain) || !activeDomains.has(tgtNode.domain))) return false;
      if (activeTypes.size > 0 && (!activeTypes.has(srcNode.nodeType) || !activeTypes.has(tgtNode.nodeType))) return false;
      return true;
    },
    [activeDomains, activeTypes, nodeMap]
  );

  // ── Circle node renderer ──────────────────────────────────────────────────
  //
  // Nodes are drawn as circles whose radius is FIXED in screen-space pixels
  // (i.e. worldRadius = screenRadius / globalScale). This ensures every node
  // is always readable regardless of zoom level, exactly like physicsgraph.com.

  const nodeCanvasObject = useCallback(
    (nodeObj: object, ctx: CanvasRenderingContext2D, globalScale: number) => {
      const node = nodeObj as FGNode;
      const nx = node.x ?? 0;
      const ny = node.y ?? 0;
      const col = node.color;

      const isSelected    = node.id === selectedNodeId;
      const isNeighbor    = !!selectedNodeId && neighborIds.has(node.id);
      const isDimmed      = !!selectedNodeId && !isSelected && !isNeighbor;
      const isHighlighted = highlightedIds.has(node.id);

      ctx.globalAlpha = isDimmed ? 0.12 : 1;

      // Fixed screen radius (world = screen / zoom)
      const sR = screenRadius(node.degree, isSelected, isHighlighted);
      const wR = sR / globalScale;
      node.__r = wR;

      // ── Circle fill ──────────────────────────────────────────────────────
      ctx.beginPath();
      ctx.arc(nx, ny, wR, 0, 2 * Math.PI);

      if (isSelected) {
        ctx.fillStyle = col;                  // solid domain colour
      } else if (isHighlighted) {
        ctx.fillStyle = col + "dd";
      } else if (isNeighbor) {
        ctx.fillStyle = col + "30";
      } else {
        ctx.fillStyle = col + "20";           // very light tint
      }
      ctx.fill();

      // ── Circle border ────────────────────────────────────────────────────
      const borderPx = isSelected ? 3 : isNeighbor || isHighlighted ? 2.5 : 1.5;
      ctx.strokeStyle = isSelected
        ? "#2563eb"
        : isHighlighted
        ? col
        : isNeighbor
        ? col + "ee"
        : col + "bb";
      ctx.lineWidth = borderPx / globalScale;
      ctx.stroke();

      // ── Label inside circle ──────────────────────────────────────────────
      // Font size is also fixed in screen space so text is always readable
      const fontPx = Math.max(7, Math.min(11, sR * 0.62));
      const worldFont = fontPx / globalScale;
      ctx.font = `600 ${worldFont}px Inter, system-ui, sans-serif`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";

      // How many chars fit inside the circle at this screen size?
      const availableScreenPx = sR * 2 * 0.80;          // 80% of diameter
      const avgCharPx = fontPx * 0.58;                   // ~0.58× font size per char
      const maxChars = Math.max(2, Math.floor(availableScreenPx / avgCharPx));
      const label = smartLabel(node.name, maxChars);

      ctx.fillStyle = isSelected || isHighlighted ? "#ffffff" : "#1e293b";
      ctx.fillText(label, nx, ny);

      ctx.globalAlpha = 1;
    },
    [selectedNodeId, neighborIds, highlightedIds]
  );

  const nodePointerAreaPaint = useCallback(
    (nodeObj: object, color: string, ctx: CanvasRenderingContext2D, globalScale: number) => {
      const node = nodeObj as FGNode;
      const r = node.__r ?? (15 / globalScale);
      ctx.beginPath();
      ctx.arc(node.x ?? 0, node.y ?? 0, r, 0, 2 * Math.PI);
      ctx.fillStyle = color;
      ctx.fill();
    },
    []
  );

  // ── Link styling ─────────────────────────────────────────────────────────

  const getLinkColor = useCallback(
    (link: object) => {
      const l = link as FGLink;
      const base = REL_COLORS[l.relType] ?? DEFAULT_LINK_COLOR;
      if (!selectedNodeId) return base + "88";
      const src = nodeId(l.source);
      const tgt = nodeId(l.target);
      const isActive = src === selectedNodeId || tgt === selectedNodeId;
      return isActive ? base + "ee" : base + "18";
    },
    [selectedNodeId]
  );

  const getLinkWidth = useCallback(
    (link: object) => {
      const l = link as FGLink;
      if (!selectedNodeId) return 1.5;
      const src = nodeId(l.source);
      const tgt = nodeId(l.target);
      return src === selectedNodeId || tgt === selectedNodeId ? 3 : 0.4;
    },
    [selectedNodeId]
  );

  const getLinkParticles = useCallback(
    (link: object) => {
      const l = link as FGLink;
      if (!selectedNodeId) return 0;
      const src = nodeId(l.source);
      const tgt = nodeId(l.target);
      return src === selectedNodeId || tgt === selectedNodeId ? 3 : 0;
    },
    [selectedNodeId]
  );

  // ── Tooltip: full name + domain on hover ─────────────────────────────────

  const getNodeLabel = useCallback((nodeObj: object) => {
    const n = nodeObj as FGNode;
    return `<div style="background:rgba(255,255,255,0.96);color:#1e293b;padding:5px 10px;border-radius:6px;font-size:12px;font-family:Inter,system-ui,sans-serif;border:1px solid #e2e8f0;max-width:220px;pointer-events:none"><strong>${n.name}</strong><br><span style="color:#64748b;font-size:10px">${n.domain} · ${n.nodeType}</span></div>`;
  }, []);

  // ── Handlers ─────────────────────────────────────────────────────────────

  const handleNodeClick = useCallback(
    (nodeObj: object) => onNodeClick((nodeObj as FGNode).id),
    [onNodeClick]
  );

  const handleBgClick = useCallback(() => {
    useGraphStore.getState().setSelectedNode(null);
  }, []);

  const handleEngineStop = useCallback(() => {
    if (!hasInitialZoom.current && fgRef.current) {
      fgRef.current.zoomToFit(800, 60);
      hasInitialZoom.current = true;
    }
  }, []);

  return (
    <div ref={containerRef} className="w-full h-full">
      <ForceGraph2D
        ref={fgRef}
        graphData={{ nodes: fgNodes, links: fgLinks }}
        width={dims.w}
        height={dims.h}
        backgroundColor="#f8fafc"
        // ── Nodes ────────────────────────────────────────────────────────
        nodeCanvasObject={nodeCanvasObject}
        nodeCanvasObjectMode="replace"
        nodePointerAreaPaint={nodePointerAreaPaint}
        nodeVisibility={nodeVisible}
        nodeLabel={getNodeLabel}
        // ── Links ────────────────────────────────────────────────────────
        linkVisibility={linkVisible}
        onNodeClick={handleNodeClick}
        onBackgroundClick={handleBgClick}
        linkColor={getLinkColor}
        linkWidth={getLinkWidth}
        linkDirectionalArrowLength={6}
        linkDirectionalArrowRelPos={1}
        linkDirectionalArrowColor={getLinkColor}
        linkDirectionalParticles={getLinkParticles}
        linkDirectionalParticleWidth={2.5}
        linkDirectionalParticleColor={getLinkColor}
        // ── Physics ──────────────────────────────────────────────────────
        warmupTicks={200}
        cooldownTime={18000}
        d3AlphaDecay={0.012}
        d3VelocityDecay={0.3}
        onEngineStop={handleEngineStop}
      />
    </div>
  );
}
