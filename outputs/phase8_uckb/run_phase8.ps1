# ============================================================
# UCKB Phase 8 — Neo4j Ingestion Runner
# Runs scripts 08-14 in order via cypher-shell inside the
# uckb_neo4j Docker container.
#
# Usage:
#   cd C:\Users\Seraphindra\Documents\communication_kg\outputs\phase8_uckb
#   .\run_phase8.ps1
# ============================================================

$NEO4J_USER     = "neo4j"
$NEO4J_PASSWORD = "uckb_admin_2024"
$CONTAINER      = "uckb_neo4j"
$CYPHER_DIR     = "$PSScriptRoot\cypher"

$SCRIPTS = @(
    "08_legal_domain.cypher",
    "09_corporate_domain.cypher",
    "10_education_domain.cypher",
    "11_protocol_dags.cypher",
    "12_cross_domain_guards.cypher",
    "13_schema_filter_registry.cypher",
    "14_phase8_validation.cypher"
)

function Run-CypherScript {
    param([string]$ScriptPath, [string]$ScriptName)
    Write-Host "`n[$ScriptName]" -ForegroundColor Cyan
    $content = Get-Content $ScriptPath -Raw -Encoding UTF8
    # Feed to cypher-shell; --non-interactive suppresses prompts
    $result = $content | docker exec -i $CONTAINER cypher-shell `
        -u $NEO4J_USER -p $NEO4J_PASSWORD `
        --database neo4j `
        --non-interactive `
        --format plain 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        Write-Host "  OK" -ForegroundColor Green
        # Print last non-empty line (usually the RETURN status)
        $lines = ($result -split "`n") | Where-Object { $_.Trim() -ne "" }
        if ($lines.Count -gt 0) {
            Write-Host "  $($lines[-1])" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ERRORS:" -ForegroundColor Red
        $result | Select-Object -Last 20 | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    }
    return $exitCode
}

Write-Host "======================================================" -ForegroundColor Yellow
Write-Host "  UCKB Phase 8 — Neo4j Ingestion" -ForegroundColor Yellow
Write-Host "  Container: $CONTAINER" -ForegroundColor Yellow
Write-Host "======================================================" -ForegroundColor Yellow

# Verify container is running
$containers = docker ps --format "{{.Names}}" 2>&1
if ($containers -notcontains $CONTAINER) {
    Write-Host "ERROR: $CONTAINER is not running. Start it with: docker compose up -d" -ForegroundColor Red
    exit 1
}
Write-Host "`nContainer $CONTAINER is running." -ForegroundColor Green

# Get baseline node count
$baseQuery = '{"statements":[{"statement":"MATCH (n) RETURN COUNT(n) AS total"}]}'
$h = @{ "Content-Type"="application/json"; "Authorization"="Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${NEO4J_USER}:${NEO4J_PASSWORD}")) }
$baseResult = Invoke-RestMethod -Uri "http://localhost:7474/db/neo4j/tx/commit" -Method POST -Headers $h -Body $baseQuery
$baselineNodes = $baseResult.results[0].data[0].row[0]
Write-Host "Baseline nodes in graph: $baselineNodes" -ForegroundColor Cyan

# Run all scripts
$errors = 0
foreach ($script in $SCRIPTS) {
    $path = Join-Path $CYPHER_DIR $script
    if (-not (Test-Path $path)) {
        Write-Host "`n[$script] FILE NOT FOUND — skipping" -ForegroundColor Yellow
        continue
    }
    $ec = Run-CypherScript -ScriptPath $path -ScriptName $script
    if ($ec -ne 0) { $errors++ }
    Start-Sleep -Milliseconds 500
}

# Final count
$finalResult = Invoke-RestMethod -Uri "http://localhost:7474/db/neo4j/tx/commit" -Method POST -Headers $h -Body $baseQuery
$finalNodes = $finalResult.results[0].data[0].row[0]

Write-Host "`n======================================================" -ForegroundColor Yellow
Write-Host "  Ingestion Complete" -ForegroundColor Yellow
Write-Host "  Baseline: $baselineNodes nodes" -ForegroundColor Cyan
Write-Host "  After:    $finalNodes nodes" -ForegroundColor Green
Write-Host "  Added:    $($finalNodes - $baselineNodes) new nodes" -ForegroundColor Green
Write-Host "  Script errors: $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================" -ForegroundColor Yellow

Write-Host "`nOpen Neo4j Browser: http://localhost:7474" -ForegroundColor Magenta
Write-Host "Credentials: neo4j / uckb_admin_2024" -ForegroundColor Magenta
