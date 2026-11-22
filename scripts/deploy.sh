#!/bin/bash

echo "Starting Student Management System deployment..."

# Stop old container if it exists
sudo docker stop student-container 2>/dev/null || true

# Remove old container if it exists
sudo docker rm student-container 2>/dev/null || true

# Build latest Docker image
sudo docker build -t student-management-system:v1 .

# Start new container
sudo docker run -d \
-p 5000:5000 \
--name student-container \
student-management-system:v1

echo "Deployment completed!"

