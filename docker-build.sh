#!/bin/bash
# Build luxJob stack in correct order
# 1. Base image (required by api and agent)
# 2. Compose up --build

set -e

echo "Building base image (luxjob_base)..."
docker build -f dockerfile.base -t luxjob_base .

echo ""
echo "Building and starting services..."
docker compose up -d --build

echo ""
echo "Done. API: http://localhost:8080  Agent: http://localhost:3838"
