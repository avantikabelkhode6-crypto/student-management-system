cat > scripts/backup.sh <<'EOF'
#!/bin/bash
set -Eeuo pipefail

DB_FILE="/home/ubuntu/student-data/students.db"
BACKUP_DIR="/home/ubuntu/backups"
BUCKET="student-management-backups-913491613255"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SNAPSHOT="$BACKUP_DIR/students_$TIMESTAMP.db"
ARCHIVE="$BACKUP_DIR/students_$TIMESTAMP.tar.gz"

echo "Starting database backup..."

mkdir -p "$BACKUP_DIR"

if [[ ! -f "$DB_FILE" ]]; then
    echo "ERROR: Database not found: $DB_FILE"
    exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed."
    exit 1
fi

trap 'echo "ERROR: Backup failed."; rm -f "$SNAPSHOT"; exit 1' ERR

echo "Creating SQLite snapshot..."
python3 - "$DB_FILE" "$SNAPSHOT" <<'PY'
import sqlite3
import sys

with sqlite3.connect(sys.argv[1]) as source:
    with sqlite3.connect(sys.argv[2]) as destination:
        source.backup(destination)
PY

echo "Compressing backup..."
tar -czf "$ARCHIVE" -C "$BACKUP_DIR" "$(basename "$SNAPSHOT")"
rm -f "$SNAPSHOT"

echo "Uploading to S3..."
aws s3 cp "$ARCHIVE" "s3://$BUCKET/"

echo "Backup completed successfully!"
echo "S3 location: s3://$BUCKET/$(basename "$ARCHIVE")"
EOF

chmod +x scripts/backup.sh

