#!/bin/bash

# FamilyBridge Backup and Disaster Recovery Script
# Comprehensive backup strategy with HIPAA compliance and automated recovery procedures

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="FamilyBridge"
BACKUP_DIR="/var/backups/familybridge"
REMOTE_BACKUP_BUCKET="${BACKUP_BUCKET:-familybridge-backups}"
ENCRYPTION_KEY_FILE="${ENCRYPTION_KEY_FILE:-/etc/familybridge/backup.key}"
RETENTION_DAYS="${RETENTION_DAYS:-2555}" # 7 years for healthcare data

# Default values
OPERATION="backup"
BACKUP_TYPE="full"
ENVIRONMENT="production"
ENCRYPT_BACKUP=true
VERIFY_BACKUP=true
REMOTE_SYNC=true
DRY_RUN=false

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "${PURPLE}=== $1 ===${NC}" | tee -a "$LOG_FILE"
}

# Initialize logging
init_logging() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    LOG_FILE="$BACKUP_DIR/logs/backup-$timestamp.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_header "FamilyBridge Backup & Disaster Recovery"
    log_info "Operation: $OPERATION"
    log_info "Type: $BACKUP_TYPE"
    log_info "Environment: $ENVIRONMENT"
    log_info "Log file: $LOG_FILE"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            backup|restore|verify|cleanup|list)
                OPERATION="$1"
                shift
                ;;
            -t|--type)
                BACKUP_TYPE="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --no-encrypt)
                ENCRYPT_BACKUP=false
                shift
                ;;
            --no-verify)
                VERIFY_BACKUP=false
                shift
                ;;
            --no-remote)
                REMOTE_SYNC=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo -e "${WHITE}FamilyBridge Backup & Disaster Recovery${NC}"
    echo ""
    echo "Usage: $0 [OPERATION] [OPTIONS]"
    echo ""
    echo "Operations:"
    echo "  backup      Create backup (default)"
    echo "  restore     Restore from backup"
    echo "  verify      Verify backup integrity"
    echo "  cleanup     Clean up old backups"
    echo "  list        List available backups"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE           Backup type (full|incremental|differential) [default: full]"
    echo "  -e, --environment ENV     Environment (dev|staging|prod) [default: production]"
    echo "  --no-encrypt              Disable backup encryption"
    echo "  --no-verify               Skip backup verification"
    echo "  --no-remote               Skip remote backup sync"
    echo "  --dry-run                 Show what would be done"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 backup --type full --environment production"
    echo "  $0 restore --type full"
    echo "  $0 verify"
    echo "  $0 cleanup"
}

# Check prerequisites
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    # Check required commands
    local required_commands=("tar" "gzip" "openssl" "sha256sum")
    
    if [ "$REMOTE_SYNC" = true ]; then
        required_commands+=("aws") # or "gsutil" for Google Cloud
    fi
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' not found"
            exit 1
        fi
    done
    
    # Create backup directories
    mkdir -p "$BACKUP_DIR/data" "$BACKUP_DIR/logs" "$BACKUP_DIR/temp"
    
    # Check encryption key
    if [ "$ENCRYPT_BACKUP" = true ] && [ ! -f "$ENCRYPTION_KEY_FILE" ]; then
        log_info "Creating new encryption key..."
        mkdir -p "$(dirname "$ENCRYPTION_KEY_FILE")"
        openssl rand -base64 32 > "$ENCRYPTION_KEY_FILE"
        chmod 600 "$ENCRYPTION_KEY_FILE"
        log_success "Encryption key created: $ENCRYPTION_KEY_FILE"
    fi
    
    # Check disk space
    local available_space=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    local required_space=10485760 # 10GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_warning "Low disk space available for backups: $(($available_space/1024/1024))GB"
    fi
    
    log_success "Prerequisites check completed"
}

# Load environment configuration
load_environment_config() {
    log_info "Loading configuration for environment: $ENVIRONMENT"
    
    # Load from environment variables or config files
    case $ENVIRONMENT in
        "production")
            SUPABASE_URL="${SUPABASE_PROD_URL}"
            SUPABASE_SERVICE_KEY="${SUPABASE_PROD_SERVICE_ROLE_KEY}"
            DATABASE_NAME="familybridge_prod"
            ;;
        "staging")
            SUPABASE_URL="${SUPABASE_STAGING_URL}"
            SUPABASE_SERVICE_KEY="${SUPABASE_STAGING_SERVICE_ROLE_KEY}"
            DATABASE_NAME="familybridge_staging"
            ;;
        "development"|"dev")
            SUPABASE_URL="${SUPABASE_DEV_URL}"
            SUPABASE_SERVICE_KEY="${SUPABASE_DEV_SERVICE_ROLE_KEY}"
            DATABASE_NAME="familybridge_dev"
            ;;
        *)
            log_error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
        log_error "Environment configuration incomplete"
        exit 1
    fi
    
    log_success "Environment configuration loaded"
}

# Create database backup
backup_database() {
    log_header "Creating Database Backup"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/temp/database_$timestamp.sql"
    
    log_info "Backing up database: $DATABASE_NAME"
    
    # Export database using Supabase CLI or pg_dump
    if command -v supabase &> /dev/null; then
        # Use Supabase CLI
        log_info "Using Supabase CLI for database backup..."
        supabase db dump --project-ref "${SUPABASE_URL##*/}" > "$backup_file"
    else
        # Use pg_dump directly
        local db_host=$(echo "$SUPABASE_URL" | sed -n 's/.*\/\/\([^:]*\).*/\1/p')
        local db_port="${SUPABASE_PORT:-5432}"
        
        log_info "Using pg_dump for database backup..."
        PGPASSWORD="$SUPABASE_SERVICE_KEY" pg_dump \
            -h "$db_host" \
            -p "$db_port" \
            -U postgres \
            -d "$DATABASE_NAME" \
            --no-owner \
            --no-privileges \
            --verbose \
            > "$backup_file"
    fi
    
    if [ ! -f "$backup_file" ] || [ ! -s "$backup_file" ]; then
        log_error "Database backup failed or is empty"
        return 1
    fi
    
    local backup_size=$(du -h "$backup_file" | cut -f1)
    log_success "Database backup created: $backup_file ($backup_size)"
    
    echo "$backup_file" >> "$BACKUP_DIR/temp/file_list.txt"
}

# Create file system backup
backup_filesystem() {
    log_header "Creating File System Backup"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/temp/filesystem_$timestamp.tar.gz"
    
    # Define directories to backup
    local backup_dirs=(
        "/etc/familybridge"
        "/var/lib/familybridge"
        "/var/log/familybridge"
    )
    
    # Add application-specific directories if they exist
    for dir in "${backup_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log_warning "Directory not found: $dir (skipping)"
        fi
    done
    
    # Create file system backup
    log_info "Creating file system archive..."
    tar -czf "$backup_file" \
        --exclude="*.tmp" \
        --exclude="*.log" \
        --exclude="cache/*" \
        "${backup_dirs[@]}" 2>/dev/null || true
    
    if [ -f "$backup_file" ]; then
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_success "File system backup created: $backup_file ($backup_size)"
        echo "$backup_file" >> "$BACKUP_DIR/temp/file_list.txt"
    else
        log_warning "File system backup creation failed or skipped"
    fi
}

# Create application configuration backup
backup_configuration() {
    log_header "Creating Configuration Backup"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local config_backup="$BACKUP_DIR/temp/config_$timestamp.tar.gz"
    
    # Configuration files to backup
    local config_files=(
        "config/"
        "docker-compose.yml"
        "docker-compose.prod.yml"
        ".env.example"
        "scripts/"
        "fastlane/"
    )
    
    # Create configuration backup from project directory
    if [ -d "/opt/familybridge" ]; then
        cd "/opt/familybridge"
        tar -czf "$config_backup" "${config_files[@]}" 2>/dev/null || true
    else
        log_warning "Application directory not found, skipping configuration backup"
        return 0
    fi
    
    if [ -f "$config_backup" ]; then
        local config_size=$(du -h "$config_backup" | cut -f1)
        log_success "Configuration backup created: $config_backup ($config_size)"
        echo "$config_backup" >> "$BACKUP_DIR/temp/file_list.txt"
    fi
}

# Create secrets backup
backup_secrets() {
    log_header "Creating Secrets Backup"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local secrets_backup="$BACKUP_DIR/temp/secrets_$timestamp.tar.gz"
    
    # Secrets and certificates to backup
    local secret_paths=(
        "/etc/ssl/certs/familybridge"
        "/etc/letsencrypt"
        "$ENCRYPTION_KEY_FILE"
    )
    
    log_info "Creating secrets archive (encrypted)..."
    
    # Create temporary secrets directory
    local temp_secrets="$BACKUP_DIR/temp/secrets_temp"
    mkdir -p "$temp_secrets"
    
    for secret_path in "${secret_paths[@]}"; do
        if [ -e "$secret_path" ]; then
            cp -r "$secret_path" "$temp_secrets/" 2>/dev/null || true
        fi
    done
    
    # Create encrypted archive
    if [ -d "$temp_secrets" ] && [ "$(ls -A "$temp_secrets")" ]; then
        tar -czf "$secrets_backup" -C "$temp_secrets" . 2>/dev/null
        
        if [ -f "$secrets_backup" ]; then
            local secrets_size=$(du -h "$secrets_backup" | cut -f1)
            log_success "Secrets backup created: $secrets_backup ($secrets_size)"
            echo "$secrets_backup" >> "$BACKUP_DIR/temp/file_list.txt"
        fi
    else
        log_info "No secrets found to backup"
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_secrets"
}

# Encrypt backup files
encrypt_backups() {
    if [ "$ENCRYPT_BACKUP" != true ]; then
        return 0
    fi
    
    log_header "Encrypting Backup Files"
    
    if [ ! -f "$BACKUP_DIR/temp/file_list.txt" ]; then
        log_warning "No files to encrypt"
        return 0
    fi
    
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            log_info "Encrypting $(basename "$file")..."
            
            openssl enc -aes-256-cbc -salt -in "$file" -out "$file.enc" -pass file:"$ENCRYPTION_KEY_FILE"
            
            if [ -f "$file.enc" ]; then
                rm "$file"
                echo "${file}.enc" >> "$BACKUP_DIR/temp/encrypted_files.txt"
            else
                log_error "Failed to encrypt $file"
            fi
        fi
    done < "$BACKUP_DIR/temp/file_list.txt"
    
    log_success "Backup encryption completed"
}

# Create final backup archive
create_backup_archive() {
    log_header "Creating Final Backup Archive"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_archive="$BACKUP_DIR/data/familybridge_${BACKUP_TYPE}_${ENVIRONMENT}_${timestamp}.tar.gz"
    
    # Create backup metadata
    cat > "$BACKUP_DIR/temp/backup_metadata.json" << EOF
{
  "app_name": "$APP_NAME",
  "backup_type": "$BACKUP_TYPE",
  "environment": "$ENVIRONMENT",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "$(grep "version:" pubspec.yaml 2>/dev/null | sed 's/version: //' || echo "unknown")",
  "encrypted": $ENCRYPT_BACKUP,
  "retention_days": $RETENTION_DAYS,
  "created_by": "$(whoami)@$(hostname)"
}
EOF
    
    # Create final archive
    log_info "Creating final backup archive..."
    tar -czf "$backup_archive" -C "$BACKUP_DIR/temp" . 2>/dev/null
    
    if [ -f "$backup_archive" ]; then
        local archive_size=$(du -h "$backup_archive" | cut -f1)
        log_success "Backup archive created: $backup_archive ($archive_size)"
        
        # Generate checksum
        sha256sum "$backup_archive" > "$backup_archive.sha256"
        log_info "Checksum generated: $backup_archive.sha256"
        
        # Clean up temporary files
        rm -rf "$BACKUP_DIR/temp"/*
        
        echo "$backup_archive"
    else
        log_error "Failed to create backup archive"
        return 1
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log_header "Verifying All Recent Backups"
        
        # Find recent backups to verify
        local recent_backups=$(find "$BACKUP_DIR/data" -name "*.tar.gz" -mtime -7 | sort -r)
        
        if [ -z "$recent_backups" ]; then
            log_warning "No recent backups found to verify"
            return 0
        fi
        
        local verified_count=0
        local failed_count=0
        
        echo "$recent_backups" | while read -r backup; do
            if verify_single_backup "$backup"; then
                ((verified_count++))
            else
                ((failed_count++))
            fi
        done
        
        log_info "Verification complete: $verified_count verified, $failed_count failed"
    else
        verify_single_backup "$backup_file"
    fi
}

verify_single_backup() {
    local backup_file="$1"
    
    log_info "Verifying backup: $(basename "$backup_file")"
    
    # Check if file exists
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Verify checksum if available
    local checksum_file="$backup_file.sha256"
    if [ -f "$checksum_file" ]; then
        log_info "Verifying checksum..."
        if sha256sum -c "$checksum_file" &>/dev/null; then
            log_success "Checksum verification passed"
        else
            log_error "Checksum verification failed"
            return 1
        fi
    else
        log_warning "No checksum file found"
    fi
    
    # Test archive integrity
    log_info "Testing archive integrity..."
    if tar -tzf "$backup_file" &>/dev/null; then
        log_success "Archive integrity verified"
    else
        log_error "Archive integrity check failed"
        return 1
    fi
    
    # Extract and verify metadata
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir" backup_metadata.json 2>/dev/null || true
    
    if [ -f "$temp_dir/backup_metadata.json" ]; then
        local backup_timestamp=$(grep '"timestamp"' "$temp_dir/backup_metadata.json" | sed 's/.*": "//;s/".*//')
        log_info "Backup timestamp: $backup_timestamp"
    fi
    
    rm -rf "$temp_dir"
    
    log_success "Backup verification completed: $(basename "$backup_file")"
    return 0
}

# Sync backups to remote storage
sync_to_remote() {
    if [ "$REMOTE_SYNC" != true ]; then
        return 0
    fi
    
    log_header "Syncing Backups to Remote Storage"
    
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log_error "No backup file specified for remote sync"
        return 1
    fi
    
    # Sync to AWS S3 (example)
    if command -v aws &> /dev/null; then
        log_info "Syncing to AWS S3: s3://$REMOTE_BACKUP_BUCKET/"
        
        aws s3 cp "$backup_file" "s3://$REMOTE_BACKUP_BUCKET/$(basename "$backup_file")" \
            --storage-class STANDARD_IA \
            --server-side-encryption AES256
        
        # Upload checksum file
        if [ -f "$backup_file.sha256" ]; then
            aws s3 cp "$backup_file.sha256" "s3://$REMOTE_BACKUP_BUCKET/$(basename "$backup_file.sha256")"
        fi
        
        log_success "Remote sync completed"
    elif command -v gsutil &> /dev/null; then
        log_info "Syncing to Google Cloud Storage: gs://$REMOTE_BACKUP_BUCKET/"
        
        gsutil cp "$backup_file" "gs://$REMOTE_BACKUP_BUCKET/"
        
        if [ -f "$backup_file.sha256" ]; then
            gsutil cp "$backup_file.sha256" "gs://$REMOTE_BACKUP_BUCKET/"
        fi
        
        log_success "Remote sync completed"
    else
        log_warning "No remote storage CLI tools available (aws/gsutil)"
    fi
}

# Clean up old backups
cleanup_old_backups() {
    log_header "Cleaning Up Old Backups"
    
    log_info "Removing local backups older than $RETENTION_DAYS days..."
    
    local deleted_count=0
    
    find "$BACKUP_DIR/data" -name "*.tar.gz" -mtime "+$RETENTION_DAYS" -print0 | while IFS= read -r -d '' backup_file; do
        log_info "Deleting old backup: $(basename "$backup_file")"
        rm -f "$backup_file" "$backup_file.sha256"
        ((deleted_count++))
    done
    
    # Clean up old log files (keep 30 days)
    find "$BACKUP_DIR/logs" -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    log_success "Cleanup completed: $deleted_count old backups removed"
    
    # Remote cleanup
    if [ "$REMOTE_SYNC" = true ] && command -v aws &> /dev/null; then
        log_info "Setting up S3 lifecycle policy for automatic cleanup..."
        
        cat > /tmp/s3-lifecycle.json << EOF
{
    "Rules": [
        {
            "ID": "FamilyBridge-Backup-Lifecycle",
            "Status": "Enabled",
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                },
                {
                    "Days": 365,
                    "StorageClass": "DEEP_ARCHIVE"
                }
            ],
            "Expiration": {
                "Days": $RETENTION_DAYS
            }
        }
    ]
}
EOF
        
        aws s3api put-bucket-lifecycle-configuration \
            --bucket "$REMOTE_BACKUP_BUCKET" \
            --lifecycle-configuration file:///tmp/s3-lifecycle.json || true
        
        rm -f /tmp/s3-lifecycle.json
    fi
}

# List available backups
list_backups() {
    log_header "Available Backups"
    
    echo -e "${CYAN}Local Backups:${NC}"
    if [ -d "$BACKUP_DIR/data" ]; then
        local backup_count=0
        
        find "$BACKUP_DIR/data" -name "*.tar.gz" -printf "%T@ %Tc %s %p\n" | sort -nr | head -20 | while read -r timestamp date size path; do
            local filename=$(basename "$path")
            local size_human=$(numfmt --to=iec "$size")
            echo "  $date | $size_human | $filename"
            ((backup_count++))
        done
        
        if [ "$backup_count" -eq 0 ]; then
            echo "  No local backups found"
        fi
    else
        echo "  Backup directory not found"
    fi
    
    echo ""
    
    if [ "$REMOTE_SYNC" = true ]; then
        echo -e "${CYAN}Remote Backups:${NC}"
        
        if command -v aws &> /dev/null; then
            aws s3 ls "s3://$REMOTE_BACKUP_BUCKET/" --human-readable --summarize | grep "familybridge_" | tail -20 || echo "  No remote backups found or access denied"
        elif command -v gsutil &> /dev/null; then
            gsutil ls -l "gs://$REMOTE_BACKUP_BUCKET/familybridge_*" | tail -20 || echo "  No remote backups found or access denied"
        else
            echo "  Remote storage CLI not available"
        fi
    fi
}

# Restore from backup
restore_from_backup() {
    log_header "Restore from Backup"
    
    # This is a placeholder for restore functionality
    # In a real implementation, this would:
    # 1. List available backups
    # 2. Allow selection of backup to restore
    # 3. Stop services
    # 4. Extract and decrypt backup
    # 5. Restore database
    # 6. Restore file system
    # 7. Restore configuration
    # 8. Start services
    # 9. Verify restoration
    
    log_warning "Restore functionality is a placeholder"
    log_warning "Manual restore process:"
    echo "1. Stop all FamilyBridge services"
    echo "2. Extract backup archive to temporary location"
    echo "3. Decrypt files if encrypted"
    echo "4. Restore database from SQL dump"
    echo "5. Restore file system from archives"
    echo "6. Update configuration as needed"
    echo "7. Start services"
    echo "8. Verify application functionality"
}

# Main backup function
perform_backup() {
    log_header "Starting Backup Process"
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN MODE - No actual backup will be performed"
        return 0
    fi
    
    # Create all backup components
    backup_database
    backup_filesystem
    backup_configuration
    backup_secrets
    
    # Encrypt if requested
    encrypt_backups
    
    # Create final archive
    local backup_archive
    backup_archive=$(create_backup_archive)
    
    if [ -z "$backup_archive" ]; then
        log_error "Backup archive creation failed"
        return 1
    fi
    
    # Verify backup
    if [ "$VERIFY_BACKUP" = true ]; then
        verify_single_backup "$backup_archive"
    fi
    
    # Sync to remote storage
    sync_to_remote "$backup_archive"
    
    log_success "Backup process completed successfully"
    log_info "Backup location: $backup_archive"
}

# Main function
main() {
    # Initialize
    init_logging
    check_prerequisites
    load_environment_config
    
    # Execute operation
    case $OPERATION in
        "backup")
            perform_backup
            ;;
        "restore")
            restore_from_backup
            ;;
        "verify")
            verify_backup
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "list")
            list_backups
            ;;
        *)
            log_error "Invalid operation: $OPERATION"
            show_help
            exit 1
            ;;
    esac
    
    log_success "Operation '$OPERATION' completed"
}

# Parse arguments and run
parse_arguments "$@"
main