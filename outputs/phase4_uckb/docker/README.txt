UCKB Phase 4 — Neo4j Setup Instructions
========================================

STEP 0 — Prerequisites
-----------------------
1. Install Docker Desktop (https://www.docker.com/products/docker-desktop/)
2. Download the Neosemantics (n10s) plugin JAR:
     URL:  https://github.com/neo4j-labs/neosemantics/releases
     File: neo4j-rdfsync-5.X.X.jar  (choose the version matching Neo4j 5.20)
     Place the JAR in:  outputs/phase4_uckb/docker/plugins/

STEP 1 — Start the database
----------------------------
From this directory:

    docker compose up -d

Wait ~30 seconds for Neo4j to start. Check health:

    docker compose ps
    docker compose logs neo4j | tail -20

Neo4j Browser: http://localhost:7474
Credentials:   neo4j / uckb_admin_2024

STEP 2 — Run Cypher scripts IN ORDER
--------------------------------------
Open Neo4j Browser (http://localhost:7474) and paste each file in sequence,
OR use cypher-shell from the command line:

    docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 < ../cypher/01_init_constraints.cypher
    docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 < ../cypher/02_n10s_graphconfig.cypher
    docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 < ../cypher/03_import_core_ontology.cypher
    docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 < ../cypher/04_import_domain_ontology.cypher
    docker exec -i uckb_neo4j cypher-shell -u neo4j -p uckb_admin_2024 < ../cypher/05_safety_sequences.cypher

STEP 3 — Run Python ingestion (Track B)
-----------------------------------------
From the project root:

    pip install neo4j openpyxl
    python outputs/phase4_uckb/scripts/ingest_phase2_cypher.py

STEP 4 — Validate
------------------
    python outputs/phase4_uckb/scripts/validate_phase4.py

Report is written to:  outputs/phase4_uckb/reports/phase4_validation_report.txt

STEP 5 — Explore
-----------------
Open Neo4j Browser and run queries from:
    outputs/phase4_uckb/cypher/06_text2cypher_library.cypher
