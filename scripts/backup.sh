#!/bin/bash
set -Eeuo pipefail

DB_FILE="/home/ubuntu/student-data/students.db"
BACKUP_DIR="/home/ubuntu/backups"
BUCKET="student-management-backups-913491613255"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SNAPSHOT="$BACKUP_DIR/students_$TIMESTAMP.db"
ARCHIVE="$BACKUP_DIR/students_$TIMESTAMP.tar.gz"

trap 'echo "ERROR: Backup failed. Check the error above."; exit 1' ERR

echo "Starting database backup..."

mkdir -p "$BACKUP_DIR"

if [[ ! -f "$DB_FILE" ]]; then
    echo "ERROR: Database file not found: $DB_FILE"
    exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed."
    exit 1
fi

echo "Creating a consistent SQLite database snapshot..."
python3 - "$DB_FILE" "$SNAPSHOT" <<'PY'
import sqlite3
import sys

source = sqlite3.connect(sys.argv[1])
destination = sqlite3.connect(sys.argv[2])
source.backup(destination)
destination.close()
source.close()
PY

echo "Creating timestamped archive..."
tar -czf "$ARCHIVE" -C "$BACKUP_DIR" "$(basename "$SNAPSHOT")"
rm -f "$SNAPSHOT"

echo "Uploading archive to S3..."
aws s3 cp "$ARCHIVE" "s3://$BUCKET/"

echo "Backup completed successfully!"
echo "Backup file: $ARCHIVE"
echo "S3 location: s3://$BUCKET/$(basename "$ARCHIVE")"
exit 0
