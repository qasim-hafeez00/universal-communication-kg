import Graph from "graphology";
import { NodeStub, GraphEdge } from "./types";
import { colorForDomain } from "./domain-colors";

export function buildGraphology(
  nodes: NodeStub[],
  edges: GraphEdge[]
): Graph {
  const g = new Graph({ type: "directed", multi: false, allowSelfLoops: false });

  for (const n of nodes) {
    if (!n.id || g.hasNode(n.id)) continue;
    const size = 6 + Math.sqrt(Math.max(n.degree, 1)) * 2.5;
    g.addNode(n.id, {
      label: n.name,
      domain: n.domain,
      nodeType: n.type,
      degree: n.degree,
      size,
      color: colorForDomain(n.domain),
      x: Math.random() * 1000,
      y: Math.random() * 1000,
    });
  }

  for (const e of edges) {
    if (!e.source || !e.target || e.source === e.target) continue;
    if (!g.hasNode(e.source) || !g.hasNode(e.target)) continue;
    if (g.hasEdge(e.source, e.target)) continue;
    g.addEdge(e.source, e.target, {
      relType: e.type,
      weight: e.weight ?? 1,
      color: colorForDomain(g.getNodeAttribute(e.source, "domain")),
      size: 1,
    });
  }

  return g;
}

export function filterGraph(
  g: Graph,
  activeDomains: Set<string>,
  activeTypes: Set<string>
): Graph {
  const filtered = new Graph({ type: "directed", multi: false, allowSelfLoops: false });

  g.forEachNode((id, attrs) => {
    if (activeDomains.size && !activeDomains.has(attrs.domain)) return;
    if (activeTypes.size && !activeTypes.has(attrs.nodeType)) return;
    filtered.addNode(id, attrs);
  });

  g.forEachEdge((edge, attrs, source, target) => {
    if (filtered.hasNode(source) && filtered.hasNode(target)) {
      filtered.addEdge(source, target, attrs);
    }
  });

  return filtered;
}
