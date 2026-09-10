#!/bin/bash

# Deploy script for Azure VM
# This script builds and starts the Docker container locally (no registry)

set -e

echo "🚀 Starting deployment on Azure VM..."
echo "📅 Timestamp: $(date)"

# Navigate to project directory
cd ~/eleklaszlo.hu || { echo "❌ Failed to navigate to ~/eleklaszlo.hu"; exit 1; }

echo "📦 Building Docker image locally..."
docker compose build || { echo "❌ Failed to build Docker image"; exit 1; }

echo "🛑 Stopping and removing old container..."
docker compose down || true

echo "🚀 Starting new container..."
docker compose up -d || { echo "❌ Failed to start container"; exit 1; }

echo "⏳ Waiting for container to be healthy..."
sleep 5

# Check if container is running
if docker ps | grep -q eleklaszlo-web; then
    echo "✅ Container is running"
else
    echo "❌ Container failed to start"
    docker compose logs
    exit 1
fi

# Check if nginx is responding
if curl -f http://localhost:5001/ > /dev/null 2>&1; then
    echo "✅ Nginx is responding"
else
    echo "⚠️  Nginx not responding yet, checking logs..."
    docker compose logs
fi

echo "🎉 Deployment completed successfully!"
echo "📍 Website available at: http://localhost:5001"
echo "🔗 Public URL: https://eleklaszlo.hu (via nginx proxy manager)"

# Cleanup old images (optional)
# echo "🧹 Cleaning up unused Docker images..."
# docker image prune -f || true

echo "✨ All done!"
