export type NodeType =
  | "Technique"
  | "CommunicationTechnique"
  | "DialogueAct"
  | "ProtocolStep"
  | "ProtocolDAG"
  | "ProtocolGate"
  | "EgoState"
  | "StatementMarker"
  | "ConversationFact"
  | "GoalState"
  | "Unknown";

export interface NodeStub {
  id: string;
  name: string;
  domain: string;
  type: NodeType;
  degree: number;
}

export interface TechniqueDetail {
  id: string;
  name: string;
  domain: string;
  type: NodeType;
  description?: string;
  whenToUse?: string;
  whenNotToUse?: string;
  steps?: string;
  successSignals?: string;
  failureSignals?: string;
  triggerSignals?: string;
  cognitiveLoadProfile?: string;
  contraindications?: string;
  tier?: string;
  culturalNotes?: string;
  sourceIds?: string;
  reviewStatus?: string;
  protocol?: string;
  peaceStep?: string;
  neighbors: NeighborRef[];
}

export interface NeighborRef {
  id: string;
  name: string;
  domain: string;
  type: NodeType;
  relType: string;
  direction: "in" | "out";
}

export interface GraphEdge {
  source: string;
  target: string;
  type: string;
  weight?: number;
}

export interface SearchResult {
  id: string;
  name: string;
  domain: string;
  type: NodeType;
  score: number;
}

export interface RetrievalLeg {
  rank: number;
  score: number;
  techniqueId: string;
  techniqueName: string;
  domain: string;
}

export interface FusedResult {
  fusedRank: number;
  rrfScore: number;
  techniqueId: string;
  techniqueName: string;
  domain: string;
  bm25Rank: number;
  vectorRank: number;
  cypherRank: number;
  safetyValidated: boolean;
}

export interface RetrievalResponse {
  query: string;
  domain: string;
  bm25Leg: RetrievalLeg[];
  vectorLeg: RetrievalLeg[];
  cypherLeg: RetrievalLeg[];
  fused: FusedResult[];
}

export interface ProtocolStep {
  id: string;
  name: string;
  stepNumber: number;
  description: string;
  domain: string;
  protocol: string;
  techniques: NodeStub[];
  gateCondition?: string;
}

export interface LearningPath {
  domain: string;
  protocol: string;
  steps: ProtocolStep[];
}
