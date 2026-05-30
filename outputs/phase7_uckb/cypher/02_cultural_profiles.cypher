// ─────────────────────────────────────────────────────────────────────────────
// UCKB Phase 7 — Step 02: CulturalProfile nodes + HAS_DIMENSION + BELONGS_TO_MODEL
//
// 10 CulturalProfile nodes with full Hofstede scores.
// New PsychologicalModel nodes for Hall, Hofstede, Lewis, Meyer (MERGE idempotent).
// HAS_DIMENSION links to existing 19 CulturalContext dimensional descriptors.
// Safe to re-run — all statements use MERGE.
// ─────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// NEW PsychologicalModel nodes (4 cultural theory frameworks)
// ════════════════════════════════════════════════════════════════════════════

MERGE (m:PsychologicalModel {name: "Hall's Context Communication Model"})
SET m += {theorist: "Edward T. Hall", domain: "cross-cultural", createdInPhase: 7};

MERGE (m:PsychologicalModel {name: "Hofstede Cultural Dimensions"})
SET m += {theorist: "Geert Hofstede", domain: "cross-cultural", createdInPhase: 7};

MERGE (m:PsychologicalModel {name: "Lewis Model of Communication"})
SET m += {theorist: "Richard D. Lewis", domain: "cross-cultural", createdInPhase: 7};

MERGE (m:PsychologicalModel {name: "Erin Meyer Culture Map"})
SET m += {theorist: "Erin Meyer", domain: "cross-cultural", createdInPhase: 7};

// ════════════════════════════════════════════════════════════════════════════
// CulturalProfile nodes (10 regional/national clusters)
// ════════════════════════════════════════════════════════════════════════════

MERGE (cp:CulturalProfile {id: "culture_japan"})
SET cp += {
  name:                  "Japan",
  lewisModel:            "reactive",
  hallContextLevel:      "high",
  hofstedePDI:           54,
  hofstedeIDV:           46,
  hofstedeMAS:           95,
  hofstedeUAI:           92,
  hofstedeLTO:           88,
  hofstedeIVR:           42,
  timeOrientation:       "polychronic",
  faceSaving:            true,
  indirectCommunication: true,
  geographicRegions:     ["East Asia", "Japan"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_usa"})
SET cp += {
  name:                  "USA Mainstream",
  lewisModel:            "linear-active",
  hallContextLevel:      "low",
  hofstedePDI:           40,
  hofstedeIDV:           91,
  hofstedeMAS:           62,
  hofstedeUAI:           46,
  hofstedeLTO:           26,
  hofstedeIVR:           68,
  timeOrientation:       "monochronic",
  faceSaving:            false,
  indirectCommunication: false,
  geographicRegions:     ["North America", "United States"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_germany"})
SET cp += {
  name:                  "Germany",
  lewisModel:            "linear-active",
  hallContextLevel:      "low",
  hofstedePDI:           35,
  hofstedeIDV:           67,
  hofstedeMAS:           66,
  hofstedeUAI:           65,
  hofstedeLTO:           83,
  hofstedeIVR:           40,
  timeOrientation:       "monochronic",
  faceSaving:            false,
  indirectCommunication: false,
  geographicRegions:     ["Western Europe", "Germany", "Austria", "Switzerland"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_arab_world"})
SET cp += {
  name:                  "Arab World",
  lewisModel:            "multi-active",
  hallContextLevel:      "high",
  hofstedePDI:           80,
  hofstedeIDV:           38,
  hofstedeMAS:           53,
  hofstedeUAI:           68,
  hofstedeLTO:           23,
  hofstedeIVR:           34,
  timeOrientation:       "polychronic",
  faceSaving:            true,
  indirectCommunication: true,
  geographicRegions:     ["Middle East", "North Africa", "Gulf States"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_nordic"})
SET cp += {
  name:                  "Nordic Countries",
  lewisModel:            "linear-active",
  hallContextLevel:      "low",
  hofstedePDI:           31,
  hofstedeIDV:           74,
  hofstedeMAS:           16,
  hofstedeUAI:           29,
  hofstedeLTO:           35,
  hofstedeIVR:           55,
  timeOrientation:       "monochronic",
  faceSaving:            false,
  indirectCommunication: false,
  geographicRegions:     ["Scandinavia", "Sweden", "Norway", "Denmark", "Finland"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_latin_america"})
SET cp += {
  name:                  "Latin America",
  lewisModel:            "multi-active",
  hallContextLevel:      "high",
  hofstedePDI:           70,
  hofstedeIDV:           21,
  hofstedeMAS:           49,
  hofstedeUAI:           76,
  hofstedeLTO:           30,
  hofstedeIVR:           76,
  timeOrientation:       "polychronic",
  faceSaving:            true,
  indirectCommunication: true,
  geographicRegions:     ["South America", "Central America", "Mexico", "Caribbean"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_india"})
SET cp += {
  name:                  "India",
  lewisModel:            "multi-active",
  hallContextLevel:      "high",
  hofstedePDI:           77,
  hofstedeIDV:           48,
  hofstedeMAS:           56,
  hofstedeUAI:           40,
  hofstedeLTO:           51,
  hofstedeIVR:           26,
  timeOrientation:       "polychronic",
  faceSaving:            true,
  indirectCommunication: true,
  geographicRegions:     ["South Asia", "India", "Pakistan", "Bangladesh", "Sri Lanka"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_china"})
SET cp += {
  name:                  "China",
  lewisModel:            "reactive",
  hallContextLevel:      "high",
  hofstedePDI:           80,
  hofstedeIDV:           20,
  hofstedeMAS:           66,
  hofstedeUAI:           30,
  hofstedeLTO:           87,
  hofstedeIVR:           24,
  timeOrientation:       "polychronic",
  faceSaving:            true,
  indirectCommunication: true,
  geographicRegions:     ["East Asia", "China", "Taiwan", "Singapore"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_uk"})
SET cp += {
  name:                  "UK Mainstream",
  lewisModel:            "linear-active",
  hallContextLevel:      "low",
  hofstedePDI:           35,
  hofstedeIDV:           89,
  hofstedeMAS:           66,
  hofstedeUAI:           35,
  hofstedeLTO:           51,
  hofstedeIVR:           69,
  timeOrientation:       "monochronic",
  faceSaving:            false,
  indirectCommunication: false,
  geographicRegions:     ["Western Europe", "United Kingdom", "Ireland"],
  createdInPhase:        7
};

MERGE (cp:CulturalProfile {id: "culture_east_africa"})
SET cp += {
  name:                  "East Africa",
  lewisModel:            "multi-active",
  hallContextLevel:      "high",
  hofstedePDI:           64,
  hofstedeIDV:           27,
  hofstedeMAS:           41,
  hofstedeUAI:           52,
  hofstedeLTO:           32,
  hofstedeIVR:           40,
  timeOrientation:       "polychronic",
  faceSaving:            true,
  indirectCommunication: true,
  geographicRegions:     ["Sub-Saharan Africa", "Kenya", "Tanzania", "Uganda", "Ethiopia"],
  createdInPhase:        7
};

// ════════════════════════════════════════════════════════════════════════════
// BELONGS_TO_MODEL — CulturalProfile -> PsychologicalModel
// ════════════════════════════════════════════════════════════════════════════

MATCH (hofstede:PsychologicalModel {name: "Hofstede Cultural Dimensions"})
MATCH (hall:PsychologicalModel {name: "Hall's Context Communication Model"})
MATCH (lewis:PsychologicalModel {name: "Lewis Model of Communication"})
MATCH (meyer:PsychologicalModel {name: "Erin Meyer Culture Map"})
MATCH (cp:CulturalProfile)
MERGE (cp)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(hofstede)
MERGE (cp)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(hall)
MERGE (cp)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(lewis)
MERGE (cp)-[:BELONGS_TO_MODEL {addedInPhase: 7}]->(meyer);

// ════════════════════════════════════════════════════════════════════════════
// HAS_DIMENSION — CulturalProfile -> CulturalContext (existing descriptors)
// ════════════════════════════════════════════════════════════════════════════

// Japan
MATCH (cp:CulturalProfile {id: "culture_japan"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["High Context","Reactive","High Power Distance","High Collectivism","High Uncertainty Avoidance","Long-Term Orientation","Polychronic Time","High Masculinity"]
   OR c1.name IN ["HighContext","Reactive","PowerDistanceHigh","CollectivismHigh","UncertaintyAvoidanceHigh","LongTermOrientation","PolychronicTime","MasculinityHigh"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// USA
MATCH (cp:CulturalProfile {id: "culture_usa"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["Low Context","Linear-Active","Low Power Distance","High Individualism","Low Uncertainty Avoidance","Monochronic Time"]
   OR c1.name IN ["LowContext","LinearActive","PowerDistanceLow","IndividualismHigh","UncertaintyAvoidanceLow","MonochronicTime"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// Germany
MATCH (cp:CulturalProfile {id: "culture_germany"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["Low Context","Linear-Active","Low Power Distance","High Individualism","High Uncertainty Avoidance","Long-Term Orientation","Monochronic Time","High Masculinity"]
   OR c1.name IN ["LowContext","LinearActive","PowerDistanceLow","IndividualismHigh","UncertaintyAvoidanceHigh","LongTermOrientation","MonochronicTime","MasculinityHigh"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// Arab World
MATCH (cp:CulturalProfile {id: "culture_arab_world"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["High Context","Multi-Active","High Power Distance","High Collectivism","High Uncertainty Avoidance","Polychronic Time"]
   OR c1.name IN ["HighContext","MultiActive","PowerDistanceHigh","CollectivismHigh","UncertaintyAvoidanceHigh","PolychronicTime"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// Nordic
MATCH (cp:CulturalProfile {id: "culture_nordic"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["Low Context","Linear-Active","Low Power Distance","High Individualism","Low Uncertainty Avoidance","High Femininity","Monochronic Time","Long-Term Orientation"]
   OR c1.name IN ["LowContext","LinearActive","PowerDistanceLow","IndividualismHigh","UncertaintyAvoidanceLow","FemininityHigh","MonochronicTime","LongTermOrientation"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// Latin America
MATCH (cp:CulturalProfile {id: "culture_latin_america"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["High Context","Multi-Active","High Power Distance","High Collectivism","Polychronic Time","Short-Term Orientation"]
   OR c1.name IN ["HighContext","MultiActive","PowerDistanceHigh","CollectivismHigh","PolychronicTime","ShortTermOrientation"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// India
MATCH (cp:CulturalProfile {id: "culture_india"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["High Context","Multi-Active","High Power Distance","High Collectivism","Polychronic Time","Long-Term Orientation"]
   OR c1.name IN ["HighContext","MultiActive","PowerDistanceHigh","CollectivismHigh","PolychronicTime","LongTermOrientation"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// China
MATCH (cp:CulturalProfile {id: "culture_china"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["High Context","Reactive","High Power Distance","High Collectivism","Long-Term Orientation","Polychronic Time"]
   OR c1.name IN ["HighContext","Reactive","PowerDistanceHigh","CollectivismHigh","LongTermOrientation","PolychronicTime"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// UK
MATCH (cp:CulturalProfile {id: "culture_uk"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["Low Context","Linear-Active","Low Power Distance","High Individualism","Monochronic Time","Long-Term Orientation"]
   OR c1.name IN ["LowContext","LinearActive","PowerDistanceLow","IndividualismHigh","MonochronicTime","LongTermOrientation"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);

// East Africa
MATCH (cp:CulturalProfile {id: "culture_east_africa"})
MATCH (c1:CulturalContext) WHERE c1.name IN ["High Context","Multi-Active","High Power Distance","High Collectivism","Polychronic Time"]
   OR c1.name IN ["HighContext","MultiActive","PowerDistanceHigh","CollectivismHigh","PolychronicTime"]
MERGE (cp)-[:HAS_DIMENSION {addedInPhase: 7}]->(c1);
