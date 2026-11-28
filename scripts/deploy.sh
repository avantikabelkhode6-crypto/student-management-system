cat > scripts/deploy.sh <<'EOF'
#!/bin/bash
set -Eeuo pipefail

APP_DIR="/home/ubuntu/student-management-system"
DB_FILE="/home/ubuntu/student-data/students.db"
IMAGE="student-management-system:v2"
CONTAINER="student-container"

echo "Starting Student Management System deployment..."

cd "$APP_DIR"

if [[ ! -f "$DB_FILE" ]]; then
    echo "ERROR: Student database not found."
    exit 1
fi

echo "Pulling latest code..."
git pull --ff-only origin main

echo "Building Docker image..."
sudo docker build -t "$IMAGE" .

echo "Stopping existing container..."
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

echo "Checking container..."
sudo docker ps --filter "name=$CONTAINER"

echo "Deployment completed!"
EOF

chmod +x scripts/deploy.sh

