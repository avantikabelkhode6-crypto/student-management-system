#!/bin/bash
set -Eeuo pipefail

APP_DIR="/home/ubuntu/student-management-system"
DB_FILE="/home/ubuntu/student-data/students.db"
IMAGE="student-management-system:1.0"
CONTAINER="student-container"

echo "Starting Student Management System deployment..."

cd "$APP_DIR"

if [[ ! -f "$DB_FILE" ]]; then
    echo "ERROR: Student database not found at $DB_FILE"
    exit 1
fi

echo "Pulling latest code from GitHub..."
git pull --ff-only origin main

echo "Building Docker image..."
sudo docker build -t "$IMAGE" .

echo "Stopping old container if it exists..."
if sudo docker container inspect "$CONTAINER" >/dev/null 2>&1; then
    sudo docker stop "$CONTAINER"
    sudo docker rm "$CONTAINER"
fi

echo "Starting updated container..."
sudo docker run -d \
    --name "$CONTAINER" \
    -p 5000:5000 \
    -v "$DB_FILE:/app/students.db" \
    --restart unless-stopped \
    "$IMAGE"

echo "Deployment successful!"
echo "Application: http://EC2-PUBLIC-IP:5000"
exit 0
