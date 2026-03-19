# Build luxJob stack in correct order
# 1. Base image (required by api and agent)
# 2. Compose up --build

$ErrorActionPreference = "Stop"

Write-Host "Building base image (luxjob_base)..." -ForegroundColor Cyan
docker build -f dockerfile.base -t luxjob_base .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nBuilding and starting services..." -ForegroundColor Cyan
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`nDone. API: http://localhost:8080  Agent: http://localhost:3838" -ForegroundColor Green
