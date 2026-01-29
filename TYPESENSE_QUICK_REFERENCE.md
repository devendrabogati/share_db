# TypeSense Quick Reference Guide

**Collection Name:** `ncc_documents`  
**Fields:** 30 total  
**Vector Dimension:** 1024 (Cohere embeddings)  
**Status:** Production Ready

---

## 🚀 Quick Start (One Command)

### Docker - Single Line
```bash
docker run -d --name ncc-typesense -p 8108:8108 \
  -e TYPESENSE_API_KEY=ncc_typesense_key_2024 \
  -v typesense_data:/data typesense/typesense:29.0 && \
sleep 5 && \
curl -X POST http://localhost:8108/collections \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" \
  -H "Content-Type: application/json" \
  -d @ncc_typesense_collection.json
```

### Script Method
```bash
./scripts/setup_typesense.sh
# Interactive setup wizard
```

### Copy Collection to Another Machine
```bash
# On source machine, export collection
curl -X GET http://localhost:8108/collections/ncc_documents \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" > collection_backup.json

# Copy ncc_typesense_collection.json to target machine
scp ncc_typesense_collection.json user@target:/tmp/

# On target machine, create collection
curl -X POST http://target-host:8108/collections \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" \
  -H "Content-Type: application/json" \
  -d @/tmp/ncc_typesense_collection.json
```

---

## 📋 Field Reference

| Field | Type | Facet | Optional | Purpose |
|-------|------|-------|----------|---------|
| **id** | string | ✗ | ✗ | Document ID |
| **document_id** | string | ✓ | ✗ | Parent document reference |
| **chunk_id** | string | ✗ | ✗ | Chunk identifier |
| **chunk_index** | int32 | ✗ | ✗ | Chunk sequence number |
| **title** | string | ✗ | ✗ | Document title |
| **chunk_text** | string | ✗ | ✗ | Content to search |
| **page_number** | int32 | ✓ | ✗ | Source page |
| **chunk_type** | string | ✓ | ✓ | section, paragraph, table |
| **hierarchy_path** | string | ✓ | ✓ | Breadcrumb path |
| **section_title** | string | ✓ | ✓ | Section name |
| **section_level** | int32 | ✓ | ✓ | Hierarchy depth |
| **section_range** | string | ✗ | ✓ | Page range in section |
| **chunk_part** | int32 | ✗ | ✓ | Part number if split |
| **chunk_parts_total** | int32 | ✗ | ✓ | Total parts |
| **table_ids** | string[] | ✓ | ✓ | Associated tables |
| **content_embedding** | float[1024] | ✗ | ✓ | Vector for similarity |
| **document_type** | string | ✓ | ✓ | Policy, Procedure, etc. |
| **issuing_authority** | string | ✓ | ✓ | Issuing organization |
| **issue_date** | int64 | ✓ | ✓ | Unix timestamp |
| **uploadbyid** | string | ✓ | ✓ | Uploader user ID |
| **uploadbyname** | string | ✓ | ✓ | Uploader name |
| **ai_tags** | string[] | ✓ | ✓ | Auto-generated tags |
| **operational_themes** | string[] | ✓ | ✓ | Operational categories |
| **target_units** | string[] | ✓ | ✓ | Target departments |
| **classification_confidence** | float | ✗ | ✓ | AI confidence (0-1) |
| **version** | string | ✓ | ✓ | Version number |
| **is_latest_version** | bool | ✓ | ✓ | Current version flag |
| **supersedes_document_id** | string | ✓ | ✓ | Replaced document |
| **created_at** | int64 | ✓ | ✗ | Creation timestamp |
| **processed_at** | int64 | ✓ | ✓ | Processing timestamp |

---

## 🔍 Common API Calls

### Check Health
```bash
curl http://localhost:8108/health \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024"
```

### List Collections
```bash
curl http://localhost:8108/collections \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" | jq
```

### Get Collection Info
```bash
curl http://localhost:8108/collections/ncc_documents \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" | jq
```

### Search Documents
```bash
curl "http://localhost:8108/collections/ncc_documents/documents/search?q=policy&query_by=chunk_text" \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" | jq
```

### Insert Document
```bash
curl -X POST http://localhost:8108/collections/ncc_documents/documents \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "chunk-001",
    "document_id": "doc-001",
    "chunk_id": "chunk-001",
    "chunk_index": 1,
    "title": "Sample Policy",
    "chunk_text": "This is a sample document",
    "page_number": 1,
    "created_at": '$(date +%s)'
  }'
```

### Faceted Search
```bash
curl "http://localhost:8108/collections/ncc_documents/documents/search?q=policy&query_by=chunk_text&facet_by=document_type,issuing_authority" \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" | jq
```

### Filter by Date Range
```bash
curl "http://localhost:8108/collections/ncc_documents/documents/search?q=*&query_by=chunk_text&filter_by=created_at:>1704067200" \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" | jq
```

### Vector Search (Hybrid)
```bash
curl -X POST "http://localhost:8108/collections/ncc_documents/documents/search" \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" \
  -H "Content-Type: application/json" \
  -d '{
    "q": "operational procedures",
    "query_by": "chunk_text",
    "vector_query": "content_embedding:([], k: 10, distance_threshold: 0.5)"
  }' | jq
```

### Bulk Insert
```bash
cat documents.jsonl | curl -X POST http://localhost:8108/collections/ncc_documents/documents/import \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" \
  --data-binary @-
```

### Count Documents
```bash
curl "http://localhost:8108/collections/ncc_documents/documents/search?q=*&query_by=chunk_text&per_page=0" \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024" | jq '.found'
```

### Delete Collection
```bash
curl -X DELETE http://localhost:8108/collections/ncc_documents \
  -H "X-TYPESENSE-API-KEY: ncc_typesense_key_2024"
```

---

## ⚙️ Configuration

### Environment Variables
```bash
TYPESENSE_HOST=localhost
TYPESENSE_PORT=8108
TYPESENSE_API_KEY=ncc_typesense_key_2024
TYPESENSE_PROTOCOL=http
TYPESENSE_COLLECTION=ncc_documents
TYPESENSE_ENABLE_CORS=true
```

### Docker Compose
```yaml
typesense:
  image: typesense/typesense:29.0
  container_name: ncc-typesense
  environment:
    TYPESENSE_API_KEY: ncc_typesense_key_2024
  ports:
    - "8108:8108"
  volumes:
    - typesense_data:/data
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Collection already exists | `curl -X DELETE .../collections/ncc_documents ...` then recreate |
| API Key mismatch | Verify key: `ncc_typesense_key_2024` |
| Port 8108 in use | Change port in docker/config or kill process: `lsof -i :8108` |
| Slow searches | Check indexes: ensure `index: true` on query fields |
| Out of memory | Increase Docker memory: `-m 4g --memory-swap 4g` |
| No results | Verify documents exist: search with `q=*` |

---

## 📊 Performance Tips

1. **Faceting:** Only on frequently filtered fields
2. **Indexing:** Enable only on searchable text fields
3. **Vectors:** Use for semantic search, not full-text
4. **Batch Inserts:** Use `/import` endpoint, not individual POST
5. **Disk Space:** Monitor with `du -sh /var/lib/typesense`

---

## 🔗 Related Files

- [Full Setup Guide](TYPESENSE_SETUP_GUIDE.md)
- [Collection JSON](ncc_typesense_collection.json)
- [Setup Script](scripts/setup_typesense.sh)
- [Python Config](src/app/domains/documents_search/config/typesense_config.py)

---

**Last Updated:** January 29, 2026  
**Status:** ✅ Current
