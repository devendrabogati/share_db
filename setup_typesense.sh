#!/bin/bash
# setup_typesense.sh
# Quick setup script for NCC TypeSense deployment on separate machines

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TYPESENSE_HOST="${TYPESENSE_HOST:-localhost}"
TYPESENSE_PORT="${TYPESENSE_PORT:-8108}"
TYPESENSE_KEY="${TYPESENSE_KEY:-ncc_typesense_key_2024}"
TYPESENSE_VERSION="${TYPESENSE_VERSION:-29.0}"
COLLECTION_NAME="ncc_documents"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        print_error "curl not found. Please install curl."
        exit 1
    fi
    print_success "curl is installed"
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found. Installing..."
        if command -v apt &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            print_error "Could not install jq. Please install manually."
            exit 1
        fi
    fi
    print_success "jq is installed"
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker is installed: $(docker --version)"
    else
        print_warning "Docker not found. Will use binary installation."
    fi
}

# Check TypeSense health
check_typesense_health() {
    print_header "Checking TypeSense Health"
    
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/health \
            -H "X-TYPESENSE-API-KEY: ${TYPESENSE_KEY}" > /dev/null 2>&1; then
            print_success "TypeSense is healthy and responding"
            return 0
        fi
        
        echo -ne "Attempt ${attempt}/${max_attempts}...\r"
        sleep 2
        ((attempt++))
    done
    
    print_error "TypeSense is not responding on ${TYPESENSE_HOST}:${TYPESENSE_PORT}"
    print_info "Make sure TypeSense is running: docker ps | grep typesense"
    return 1
}

# Deploy with Docker
deploy_with_docker() {
    print_header "Deploying with Docker"
    
    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "ncc-typesense"; then
        print_warning "Container 'ncc-typesense' already exists"
        read -p "Remove and recreate? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker rm -f ncc-typesense
            print_success "Removed existing container"
        else
            print_info "Using existing container"
            return 0
        fi
    fi
    
    # Create volume if needed
    docker volume create typesense_data 2>/dev/null || true
    
    # Run container
    print_info "Starting TypeSense container..."
    docker run -d \
        --name ncc-typesense \
        -p ${TYPESENSE_PORT}:8108 \
        -e TYPESENSE_DATA_DIR=/data \
        -e TYPESENSE_API_KEY=${TYPESENSE_KEY} \
        -e TYPESENSE_ENABLE_CORS=true \
        -v typesense_data:/data \
        typesense/typesense:${TYPESENSE_VERSION}
    
    print_success "TypeSense container started"
    print_info "Waiting for TypeSense to be ready..."
    sleep 5
}

# Create collection schema
create_collection() {
    print_header "Creating Collection Schema"
    
    # Check if collection exists
    if curl -s http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/collections/${COLLECTION_NAME} \
        -H "X-TYPESENSE-API-KEY: ${TYPESENSE_KEY}" 2>/dev/null | grep -q '"name"'; then
        print_success "Collection '${COLLECTION_NAME}' already exists"
        return 0
    fi
    
    # Create collection
    print_info "Creating collection..."
    
    curl -X POST http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/collections \
        -H "X-TYPESENSE-API-KEY: ${TYPESENSE_KEY}" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "ncc_documents",
            "fields": [
                {"name": "id", "type": "string"},
                {"name": "document_id", "type": "string", "facet": true, "index": true},
                {"name": "chunk_id", "type": "string", "index": true},
                {"name": "chunk_index", "type": "int32"},
                {"name": "title", "type": "string", "index": true},
                {"name": "chunk_text", "type": "string", "index": true},
                {"name": "page_number", "type": "int32", "facet": true, "index": true},
                {"name": "chunk_type", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "hierarchy_path", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "section_title", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "section_level", "type": "int32", "facet": true, "optional": true},
                {"name": "section_range", "type": "string", "optional": true, "index": true},
                {"name": "chunk_part", "type": "int32", "optional": true},
                {"name": "chunk_parts_total", "type": "int32", "optional": true},
                {"name": "table_ids", "type": "string[]", "facet": true, "optional": true, "index": true},
                {
                    "name": "content_embedding",
                    "type": "float[]",
                    "num_dim": 1024,
                    "optional": true,
                    "index": true,
                    "hnsw_params": {"M": 16, "ef_construction": 200},
                    "vec_dist": "cosine"
                },
                {"name": "document_type", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "issuing_authority", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "issue_date", "type": "int64", "facet": true, "optional": true},
                {"name": "uploadbyid", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "uploadbyname", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "ai_tags", "type": "string[]", "facet": true, "optional": true, "index": true},
                {"name": "operational_themes", "type": "string[]", "facet": true, "optional": true, "index": true},
                {"name": "target_units", "type": "string[]", "facet": true, "optional": true, "index": true},
                {"name": "classification_confidence", "type": "float", "optional": true},
                {"name": "version", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "is_latest_version", "type": "bool", "facet": true, "optional": true},
                {"name": "supersedes_document_id", "type": "string", "facet": true, "optional": true, "index": true},
                {"name": "created_at", "type": "int64", "facet": true},
                {"name": "processed_at", "type": "int64", "facet": true, "optional": true}
            ],
            "default_sorting_field": "created_at",
            "enable_nested_fields": true
        }' > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Collection '${COLLECTION_NAME}' created successfully"
    else
        print_error "Failed to create collection"
        return 1
    fi
}

# Verify setup
verify_setup() {
    print_header "Verifying Setup"
    
    # Check collection exists
    local collection_info=$(curl -s http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/collections/${COLLECTION_NAME} \
        -H "X-TYPESENSE-API-KEY: ${TYPESENSE_KEY}")
    
    if echo "$collection_info" | jq -e '.name' > /dev/null 2>&1; then
        local num_fields=$(echo "$collection_info" | jq '.fields | length')
        local num_docs=$(echo "$collection_info" | jq '.num_documents')
        
        print_success "Collection Name: ${COLLECTION_NAME}"
        print_success "Total Fields: ${num_fields}"
        print_success "Documents: ${num_docs}"
    else
        print_error "Could not verify collection"
        return 1
    fi
}

# Display summary
print_summary() {
    print_header "Setup Complete!"
    
    echo ""
    echo "Configuration:"
    echo "  Host: ${TYPESENSE_HOST}"
    echo "  Port: ${TYPESENSE_PORT}"
    echo "  Collection: ${COLLECTION_NAME}"
    echo ""
    echo "Next Steps:"
    echo "  1. Dashboard: http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/dashboard"
    echo "  2. API: http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/collections"
    echo "  3. Search: curl -X GET 'http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/collections/${COLLECTION_NAME}/documents/search?q=*&query_by=chunk_text'"
    echo ""
    echo "Start indexing documents:"
    echo "  curl -X POST http://${TYPESENSE_HOST}:${TYPESENSE_PORT}/collections/${COLLECTION_NAME}/documents \\"
    echo "    -H 'X-TYPESENSE-API-KEY: ${TYPESENSE_KEY}' \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"id\": \"...\", \"document_id\": \"...\", ...}'"
    echo ""
}

# Main execution
main() {
    print_header "NCC TypeSense Setup Script"
    
    # Check prerequisites
    check_prerequisites
    
    # Ask deployment method
    echo ""
    echo "Choose deployment method:"
    echo "1) Docker (recommended)"
    echo "2) Binary (manual)"
    echo "3) Skip TypeSense installation (assume already running)"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            deploy_with_docker
            ;;
        2)
            print_info "Please install TypeSense binary manually from https://typesense.org/downloads/"
            ;;
        3)
            print_info "Skipping TypeSense installation"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Check TypeSense health
    if ! check_typesense_health; then
        exit 1
    fi
    
    # Create collection
    if ! create_collection; then
        exit 1
    fi
    
    # Verify setup
    if ! verify_setup; then
        exit 1
    fi
    
    # Print summary
    print_summary
}

# Run main function
main "$@"
