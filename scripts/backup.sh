#!/bin/bash

echo "Starting database backup..."

# Create backup directory
mkdir -p backups

# Generate backup filename with date and time
BACKUP_FILE="backups/students_$(date +%Y%m%d_%H%M%S).db"

# Copy database from Docker container
sudo docker cp student-container:/app/students.db "$BACKUP_FILE"

echo "Backup completed successfully!"
echo "Backup saved at: $BACKUP_FILE"

