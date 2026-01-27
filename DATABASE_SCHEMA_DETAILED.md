# NCC Database Schema Documentation

**Last Updated:** January 27, 2026  
**Database:** PostgreSQL 15-alpine  
**Database Name:** `ncc_admin`  
**User:** `ncc_user`

---

## Table of Contents
1. [Overview](#overview)
2. [Documents Table](#documents-table)
3. [Batch Uploads Table](#batch-uploads-table)
4. [Batch Upload Items Table](#batch-upload-items-table)
5. [Relationships & Foreign Keys](#relationships--foreign-keys)
6. [Indexes & Performance](#indexes--performance)
7. [Data Types Reference](#data-types-reference)
8. [Common Queries](#common-queries)

---

## Overview

The NCC database consists of three main tables that handle document management and batch processing:

- **documents**: Stores processed documents with metadata, content extraction, and AI classifications
- **batch_uploads**: Manages batch upload sessions with progress tracking
- **batch_upload_items**: Individual files within batch uploads with processing status

### Key Statistics

| Table | Rows | Purpose |
|-------|------|---------|
| documents | 10 | Store processed documents |
| batch_uploads | 10 | Track batch upload sessions |
| batch_upload_items | 10 | Track individual items in batches |

---

## Documents Table

### Purpose
Stores documents with full metadata, extracted content, AI classifications, and processing status.

### Schema

```sql
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  document_id VARCHAR(36) UNIQUE NOT NULL,
  filename VARCHAR(255) NOT NULL,
  original_filename VARCHAR(255) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  file_size BIGINT NOT NULL,
  content_type VARCHAR(100),
  bucket_name VARCHAR(100) NOT NULL,
  storage_url TEXT,
  title VARCHAR(500),
  document_type VARCHAR(100),
  issuing_authority VARCHAR(200),
  issue_date TIMESTAMP,
  effective_date TIMESTAMP,
  expiry_date TIMESTAMP,
  reference_number VARCHAR(100),
  uploadbyid VARCHAR(100),
  uploadbyname VARCHAR(200),
  extracted_text TEXT,
  processed_content JSON,
  ai_classification JSON,
  ai_tags JSON,
  operational_themes JSON,
  target_units JSON,
  confidence_scores JSON,
  processing_status VARCHAR(50) NOT NULL,
  extraction_confidence DOUBLE PRECISION,
  classification_confidence DOUBLE PRECISION,
  version VARCHAR(20),
  is_latest_version BOOLEAN,
  supersedes_document_id VARCHAR(36),
  upload_date TIMESTAMP NOT NULL,
  processed_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  status VARCHAR(20) NOT NULL,
  document_status VARCHAR(20) NOT NULL,
  tag_updated_at JSON,
  status_updated_at JSON,
  normalized_filename VARCHAR(255)
);
```

### Column Details

#### Identity & File Information
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **id** | integer | 4 bytes | NO | Auto-increment | Primary key |
| **document_id** | varchar | 36 | NO | - | UUID identifying the document |
| **filename** | varchar | 255 | NO | - | Processed/stored filename |
| **original_filename** | varchar | 255 | NO | - | Original uploaded filename |
| **file_path** | varchar | 500 | NO | - | Path in storage (S3/MinIO) |
| **file_size** | bigint | 8 bytes | NO | - | File size in bytes |
| **normalized_filename** | varchar | 255 | YES | - | Normalized for duplicate detection |

#### Storage & Access
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **content_type** | varchar | 100 | YES | - | MIME type (e.g., application/pdf) |
| **bucket_name** | varchar | 100 | NO | - | S3 bucket name (ncc-local-testing) |
| **storage_url** | text | - | YES | - | Full presigned URL for access |

#### Document Metadata
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **title** | varchar | 500 | YES | - | Document title |
| **document_type** | varchar | 100 | YES | - | Type classification (e.g., Policy, Procedure) |
| **issuing_authority** | varchar | 200 | YES | - | Organization that issued the document |
| **issue_date** | timestamp | - | YES | - | When document was issued |
| **effective_date** | timestamp | - | YES | - | When document becomes effective |
| **expiry_date** | timestamp | - | YES | - | When document expires |
| **reference_number** | varchar | 100 | YES | - | Unique reference/code |
| **uploadbyid** | varchar | 100 | YES | - | User ID who uploaded |
| **uploadbyname** | varchar | 200 | YES | - | User name who uploaded |

#### Content Extraction
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **extracted_text** | text | - | YES | - | Full text extracted from document |
| **processed_content** | json | - | YES | - | Structured processed content |
| **extraction_confidence** | double | 8 bytes | YES | - | Confidence score for extraction (0.0-1.0) |

#### AI Analysis & Classification
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **ai_classification** | json | - | YES | - | AI-generated classification results |
| **classification_confidence** | double | 8 bytes | YES | - | Confidence of classification (0.0-1.0) |
| **ai_tags** | json | - | YES | - | AI-generated tags/keywords |
| **confidence_scores** | json | - | YES | - | Confidence scores for all analyses |
| **operational_themes** | json | - | YES | - | Identified operational themes |
| **target_units** | json | - | YES | - | Target units/departments |

#### Processing Status & Versioning
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **processing_status** | varchar | 50 | NO | - | Current processing state |
| **status** | varchar | 20 | NO | - | Document status (active, archived, etc.) |
| **document_status** | varchar | 20 | NO | - | Life cycle status |
| **version** | varchar | 20 | YES | - | Version number |
| **is_latest_version** | boolean | - | YES | - | Flag for latest version |
| **supersedes_document_id** | varchar | 36 | YES | - | ID of document this supersedes |

#### Timestamps & Metadata Updates
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **upload_date** | timestamp | - | NO | - | When originally uploaded |
| **processed_at** | timestamp | - | YES | - | When processing completed |
| **created_at** | timestamp | - | NO | - | Record creation time |
| **updated_at** | timestamp | - | NO | - | Last record update time |
| **tag_updated_at** | json | - | YES | - | Last tag update details |
| **status_updated_at** | json | - | YES | - | Last status update details |

### Indexes

```sql
-- Primary Key
CONSTRAINT "documents_pkey" PRIMARY KEY (id)

-- Unique Constraints
CONSTRAINT "ix_documents_document_id" UNIQUE (document_id)

-- Search Indexes
INDEX "idx_documents_created_at" (created_at)
INDEX "idx_documents_filename" (filename)
INDEX "idx_documents_document_type" (document_type)
INDEX "idx_documents_processing_status" (processing_status)
INDEX "idx_documents_status" (status)
INDEX "idx_documents_issue_date" (issue_date)
INDEX "idx_documents_issuing_authority" (issuing_authority)
INDEX "idx_documents_normalized_filename" (normalized_filename)

-- Composite Indexes
INDEX "idx_documents_duplicate_check" (original_filename, file_size, content_type)
INDEX "idx_documents_latest_version" (original_filename, content_type, is_latest_version)
INDEX "idx_documents_version" (version, is_latest_version)
INDEX "idx_documents_supersedes" (supersedes_document_id)
```

### Processing Status Values
- `pending` - Awaiting processing
- `processing` - Currently being processed
- `completed` - Successfully processed
- `failed` - Processing failed
- `archived` - Document archived

---

## Batch Uploads Table

### Purpose
Manages batch upload sessions, tracking progress and status of multiple file uploads in a single batch.

### Schema

```sql
CREATE TABLE batch_uploads (
  id INTEGER PRIMARY KEY,
  batch_id VARCHAR(36) UNIQUE NOT NULL,
  batch_name VARCHAR(255) NOT NULL,
  description TEXT,
  original_filename VARCHAR(255),
  total_files INTEGER NOT NULL DEFAULT 0,
  total_size_bytes BIGINT NOT NULL DEFAULT 0,
  status VARCHAR(50) NOT NULL DEFAULT 'created',
  progress_percentage DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  files_pending INTEGER NOT NULL DEFAULT 0,
  files_processing INTEGER NOT NULL DEFAULT 0,
  files_completed INTEGER NOT NULL DEFAULT 0,
  files_failed INTEGER NOT NULL DEFAULT 0,
  files_skipped INTEGER NOT NULL DEFAULT 0,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  estimated_completion TIMESTAMP,
  error_message TEXT,
  error_details JSON,
  retry_count INTEGER NOT NULL DEFAULT 0,
  created_by_id VARCHAR(100) NOT NULL,
  created_by_name VARCHAR(200) NOT NULL,
  processing_options JSON,
  temp_storage_path VARCHAR(500),
  extraction_path VARCHAR(500),
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);
```

### Column Details

#### Batch Identity
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **id** | integer | 4 bytes | NO | Auto-increment | Primary key |
| **batch_id** | varchar | 36 | NO | - | UUID for batch |
| **batch_name** | varchar | 255 | NO | - | Human-readable batch name |
| **description** | text | - | YES | - | Batch description |

#### File Counts & Size
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **total_files** | integer | 4 bytes | NO | 0 | Total files in batch |
| **total_size_bytes** | bigint | 8 bytes | NO | 0 | Total size of all files |
| **original_filename** | varchar | 255 | YES | - | Original upload filename |

#### Progress Tracking
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **status** | varchar | 50 | NO | 'created' | Batch status |
| **progress_percentage** | double | 8 bytes | NO | 0.0 | Overall progress (0-100) |
| **files_pending** | integer | 4 bytes | NO | 0 | Count of pending files |
| **files_processing** | integer | 4 bytes | NO | 0 | Count of files being processed |
| **files_completed** | integer | 4 bytes | NO | 0 | Count of completed files |
| **files_failed** | integer | 4 bytes | NO | 0 | Count of failed files |
| **files_skipped** | integer | 4 bytes | NO | 0 | Count of skipped files |

#### Timing Information
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **started_at** | timestamp | - | YES | - | When batch processing started |
| **completed_at** | timestamp | - | YES | - | When batch processing completed |
| **estimated_completion** | timestamp | - | YES | - | Estimated completion time |

#### Error Handling
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **error_message** | text | - | YES | - | Last error message |
| **error_details** | json | - | YES | - | Detailed error information |
| **retry_count** | integer | 4 bytes | NO | 0 | Number of retries |

#### User & Configuration
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **created_by_id** | varchar | 100 | NO | - | ID of user who created batch |
| **created_by_name** | varchar | 200 | NO | - | Name of user who created batch |
| **processing_options** | json | - | YES | - | Processing configuration (upload_type, etc.) |
| **temp_storage_path** | varchar | 500 | YES | - | Path to temporary storage |
| **extraction_path** | varchar | 500 | YES | - | Path for extracted content |

#### Timestamps
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **created_at** | timestamp | - | NO | now() | Record creation time |
| **updated_at** | timestamp | - | NO | now() | Last update time (auto-updated) |

### Status Values
- `created` - Batch created, waiting to start
- `processing` - Currently processing files
- `completed` - All files processed successfully
- `failed` - Batch failed during processing
- `paused` - Processing paused
- `cancelled` - Batch cancelled

### Indexes

```sql
-- Primary Key
CONSTRAINT "batch_uploads_pkey" PRIMARY KEY (id)

-- Unique Constraints
CONSTRAINT "batch_uploads_batch_id_key" UNIQUE (batch_id)

-- Search Indexes
INDEX "idx_batch_uploads_batch_id" (batch_id)
INDEX "idx_batch_uploads_created_at" (created_at)
INDEX "idx_batch_uploads_status" (status)
INDEX "idx_batch_uploads_created_by" (created_by_id)
```

### Triggers
```sql
TRIGGER "update_batch_uploads_updated_at"
  BEFORE UPDATE ON batch_uploads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```
*Automatically updates `updated_at` timestamp on any update*

---

## Batch Upload Items Table

### Purpose
Tracks individual files within batch uploads with detailed processing status, extraction results, and error handling.

### Schema

```sql
CREATE TABLE batch_upload_items (
  id INTEGER PRIMARY KEY,
  item_id VARCHAR(36) UNIQUE NOT NULL,
  batch_id VARCHAR(36) NOT NULL REFERENCES batch_uploads(batch_id),
  filename VARCHAR(500),
  original_filename VARCHAR(500) NOT NULL,
  file_path VARCHAR(1000),
  file_size BIGINT,
  file_size_bytes BIGINT,
  content_type VARCHAR(200),
  status VARCHAR(50) DEFAULT 'pending',
  processing_status VARCHAR(50) DEFAULT 'queued',
  progress_percentage DOUBLE PRECISION DEFAULT 0.0,
  processing_stage VARCHAR(100),
  validation_status VARCHAR(50),
  error_stage VARCHAR(100),
  error_message TEXT,
  error_details JSON,
  validation_errors JSON,
  retry_count INTEGER DEFAULT 0,
  extracted_text TEXT,
  extracted_text_length INTEGER,
  ai_classification JSON,
  confidence_scores JSON,
  classification_confidence DOUBLE PRECISION,
  ocr_confidence DOUBLE PRECISION,
  processing_options JSON,
  temp_file_path VARCHAR(1000),
  storage_path VARCHAR(1000),
  bucket_name VARCHAR(100),
  file_path_in_zip VARCHAR(500),
  document_id VARCHAR(36),
  processing_started_at TIMESTAMP,
  processing_completed_at TIMESTAMP,
  completed_at TIMESTAMP,
  started_at TIMESTAMP,
  processing_duration_seconds DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Column Details

#### Item Identity
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **id** | integer | 4 bytes | NO | Auto-increment | Primary key |
| **item_id** | varchar | 36 | NO | - | UUID for item |
| **batch_id** | varchar | 36 | NO | - | Foreign key to batch_uploads |
| **document_id** | varchar | 36 | YES | - | Link to created document |

#### File Information
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **filename** | varchar | 500 | YES | - | Processed filename |
| **original_filename** | varchar | 500 | NO | - | Original filename |
| **file_path** | varchar | 1000 | YES | - | File path in storage |
| **file_size** | bigint | 8 bytes | YES | - | File size (may be legacy) |
| **file_size_bytes** | bigint | 8 bytes | YES | - | File size in bytes |
| **content_type** | varchar | 200 | YES | - | MIME type |
| **file_path_in_zip** | varchar | 500 | YES | - | Path within ZIP archive |

#### Status & Progress
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **status** | varchar | 50 | YES | 'pending' | File status |
| **processing_status** | varchar | 50 | YES | 'queued' | Processing state |
| **progress_percentage** | double | 8 bytes | YES | 0.0 | Progress (0-100) |
| **processing_stage** | varchar | 100 | YES | - | Current processing stage |
| **validation_status** | varchar | 50 | YES | - | Validation result |

#### Error Handling
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **error_message** | text | - | YES | - | Error message |
| **error_details** | json | - | YES | - | Detailed error info |
| **validation_errors** | json | - | YES | - | Validation error details |
| **error_stage** | varchar | 100 | YES | - | Stage where error occurred |
| **retry_count** | integer | 4 bytes | YES | 0 | Retry attempts |

#### Content Extraction
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **extracted_text** | text | - | YES | - | Extracted text content |
| **extracted_text_length** | integer | 4 bytes | YES | - | Length of extracted text |
| **ocr_confidence** | double | 8 bytes | YES | - | OCR confidence (0.0-1.0) |

#### AI Analysis
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **ai_classification** | json | - | YES | - | AI classification results |
| **classification_confidence** | double | 8 bytes | YES | - | Classification confidence |
| **confidence_scores** | json | - | YES | - | All confidence scores |

#### Storage & Configuration
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **processing_options** | json | - | YES | - | Processing options |
| **temp_file_path** | varchar | 1000 | YES | - | Temporary file location |
| **storage_path** | varchar | 1000 | YES | - | Final storage location |
| **bucket_name** | varchar | 100 | YES | - | S3 bucket name |

#### Timing Information
| Column | Type | Size | Nullable | Default | Description |
|--------|------|------|----------|---------|-------------|
| **processing_started_at** | timestamp | - | YES | - | When processing started |
| **processing_completed_at** | timestamp | - | YES | - | When processing completed |
| **completed_at** | timestamp | - | YES | - | Alternative completion timestamp |
| **started_at** | timestamp | - | YES | - | Alternative start timestamp |
| **processing_duration_seconds** | double | 8 bytes | YES | - | Total processing time |
| **created_at** | timestamp | - | YES | now() | Record creation time |
| **updated_at** | timestamp | - | YES | now() | Last update time |

### Status Values
- `pending` - Waiting to be processed
- `processing` - Currently being processed
- `completed` - Successfully processed
- `failed` - Processing failed
- `skipped` - Skipped processing

### Processing Stages
- `upload` - File uploaded
- `validation` - File validation
- `extraction` - Content extraction
- `ocr` - OCR processing
- `classification` - AI classification
- `embedding` - Embedding generation
- `storage` - Storage finalization

### Indexes

```sql
-- Primary Key
CONSTRAINT "batch_upload_items_pkey" PRIMARY KEY (id)

-- Unique Constraints
CONSTRAINT "batch_upload_items_item_id_key" UNIQUE (item_id)

-- Foreign Key
CONSTRAINT "batch_upload_items_batch_id_fkey" FOREIGN KEY (batch_id)
  REFERENCES batch_uploads(batch_id)

-- Search Indexes
INDEX "idx_batch_items_batch_id" (batch_id)
INDEX "idx_batch_items_item_id" (item_id)
INDEX "idx_batch_items_status" (status)
INDEX "idx_batch_items_processing_status" (processing_status)
```

### Triggers
```sql
TRIGGER "update_batch_upload_items_updated_at"
  BEFORE UPDATE ON batch_upload_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```
*Automatically updates `updated_at` timestamp on any update*

---

## Relationships & Foreign Keys

### Documents → Batch Upload Items
- **Relationship**: One document can be created from one batch item
- **Link**: `batch_upload_items.document_id` → `documents.document_id`
- **Type**: Optional (one-to-zero-or-one)

### Batch Uploads → Batch Upload Items
```
Batch Uploads (1) ──→ (N) Batch Upload Items
```
- **Constraint**: `batch_upload_items.batch_id` → `batch_uploads.batch_id`
- **Action**: ON DELETE CASCADE (delete items when batch is deleted)
- **Importance**: CRITICAL - Enforces referential integrity

### Processing Flow
```
User Creates Batch
        ↓
Batch Upload Created (status='created')
        ↓
Batch Upload Items Created (status='pending')
        ↓
Item Processing Starts (processing_status='processing')
        ↓
Content Extraction → OCR → Classification → Embedding
        ↓
Document Created (from item data)
        ↓
Item Marked Complete (status='completed')
        ↓
Batch Progress Updated
```

---

## Indexes & Performance

### Index Summary

| Table | Index Name | Columns | Type | Purpose |
|-------|-----------|---------|------|---------|
| documents | ix_documents_document_id | document_id | UNIQUE | Fast document lookup |
| documents | idx_documents_created_at | created_at | BTREE | Recent documents |
| documents | idx_documents_filename | filename | BTREE | File search |
| documents | idx_documents_duplicate_check | (filename, file_size, type) | BTREE | Duplicate detection |
| batch_uploads | batch_uploads_batch_id_key | batch_id | UNIQUE | Batch identification |
| batch_uploads | idx_batch_uploads_status | status | BTREE | Status filtering |
| batch_upload_items | batch_upload_items_item_id_key | item_id | UNIQUE | Item identification |
| batch_upload_items | idx_batch_items_batch_id | batch_id | BTREE | Batch filtering |

### Performance Recommendations

1. **Bulk Insert**: Use batch inserts for batch_upload_items
2. **Status Updates**: Index on status columns for filtering
3. **Date Range Queries**: Index on created_at, upload_date
4. **Duplicate Detection**: Composite index helps identify duplicates
5. **Version Tracking**: Use `is_latest_version` + `original_filename` for efficient lookups

---

## Data Types Reference

### Numeric Types
| Type | Size | Range | Use Case |
|------|------|-------|----------|
| **integer** | 4 bytes | -2,147,483,648 to 2,147,483,647 | IDs, counts |
| **bigint** | 8 bytes | -9,223,372,036,854,775,808 to ... | File sizes, large numbers |
| **double precision** | 8 bytes | 15+ decimal digits | Confidence scores, percentages |

### String Types
| Type | Typical Size | Use Case |
|------|--------------|----------|
| **varchar(N)** | N bytes | Fixed max length fields (filenames, IDs) |
| **text** | Variable | Unlimited length (extracted text, descriptions) |

### Date/Time
| Type | Precision | Use Case |
|------|-----------|----------|
| **timestamp without time zone** | 1 microsecond | Event timestamps |

### Structured Data
| Type | Use Case | Example |
|------|----------|---------|
| **json** | Flexible metadata | `{"confidence": 0.95, "tags": ["policy", "urgent"]}` |
| **boolean** | Binary flags | `is_latest_version`, `active` |

---

## Common Queries

### Find Latest Document Versions
```sql
SELECT * FROM documents 
WHERE is_latest_version = true 
AND original_filename = 'ncc_ml.pdf'
ORDER BY created_at DESC;
```

### Get Batch Upload Progress
```sql
SELECT 
  batch_id,
  batch_name,
  status,
  progress_percentage,
  files_completed,
  files_failed,
  files_pending,
  total_files
FROM batch_uploads
WHERE batch_id = 'a9112844-4e90-4d10-a2b8-aac97bec5141';
```

### Find Failed Items in Batch
```sql
SELECT 
  item_id,
  original_filename,
  status,
  error_message,
  error_stage
FROM batch_upload_items
WHERE batch_id = 'a9112844-4e90-4d10-a2b8-aac97bec5141'
AND status = 'failed'
ORDER BY created_at DESC;
```

### Get Processing Statistics
```sql
SELECT 
  processing_status,
  COUNT(*) as count,
  AVG(processing_duration_seconds) as avg_duration,
  MAX(processing_duration_seconds) as max_duration
FROM batch_upload_items
GROUP BY processing_status;
```

### Find Documents by Classification
```sql
SELECT 
  document_id,
  original_filename,
  ai_classification,
  classification_confidence
FROM documents
WHERE document_type = 'Policy'
AND classification_confidence > 0.8
ORDER BY classification_confidence DESC;
```

### List Recent Uploads by User
```sql
SELECT 
  batch_id,
  batch_name,
  created_by_name,
  total_files,
  status,
  created_at
FROM batch_uploads
WHERE created_by_id = 'user_id'
ORDER BY created_at DESC
LIMIT 10;
```

### Check for Duplicate Documents
```sql
SELECT 
  original_filename,
  file_size,
  COUNT(*) as count,
  ARRAY_AGG(document_id) as document_ids
FROM documents
GROUP BY original_filename, file_size
HAVING COUNT(*) > 1;
```

### OCR Confidence Analysis
```sql
SELECT 
  COUNT(*) as total_items,
  AVG(ocr_confidence) as avg_confidence,
  MIN(ocr_confidence) as min_confidence,
  MAX(ocr_confidence) as max_confidence
FROM batch_upload_items
WHERE content_type LIKE 'application/pdf'
AND ocr_confidence IS NOT NULL;
```

---

## Maintenance & Operations

### Backup Considerations
- **Size**: ~100MB+ depending on extracted_text and JSON fields
- **Growth Rate**: ~5-10 rows per batch (batch_upload_items grow fastest)
- **Retention**: Consider archiving old batches and documents

### Monitoring
Monitor these metrics:
- Failed batch uploads
- Average processing duration
- OCR confidence scores
- Extraction confidence scores
- Storage growth

### Cleanup
```sql
-- Archive old completed batches (older than 30 days)
DELETE FROM batch_upload_items 
WHERE batch_id IN (
  SELECT batch_id FROM batch_uploads 
  WHERE completed_at < now() - interval '30 days'
  AND status = 'completed'
);

DELETE FROM batch_uploads
WHERE completed_at < now() - interval '30 days'
AND status = 'completed';
```

---

## Related Configuration

From `.env`:
```
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=ncc_admin
POSTGRES_USER=ncc_user
S3_BUCKET_DOCUMENTS=ncc-local-testing
CHUNK_SIZE=800
MAX_CHUNKS_PER_DOC=100
```

---

## Document Version Control

| Date | Change | Author |
|------|--------|--------|
| 2026-01-27 | Initial complete schema documentation | Database Team |

---

**For questions or updates, please refer to the development team or database administrator.**
