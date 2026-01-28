# Database Column Reference

Quick reference guide with all column names and data types for each table.

**Generated**: January 28, 2026  
**Database**: PostgreSQL 15-alpine  
**Database Name**: ncc_admin

---

## Table of Contents
1. [documents (40 columns)](#documents-table)
2. [batch_uploads (27 columns)](#batch_uploads-table)
3. [batch_upload_items (38 columns)](#batch_upload_items-table)
4. [Quick Search](#quick-search)

---

## documents Table

**Total Columns**: 40

| # | Column Name | Data Type | Nullable |
|----|-------------|-----------|----------|
| 1 | id | integer | NO |
| 2 | document_id | character varying(36) | NO |
| 3 | filename | character varying(255) | NO |
| 4 | original_filename | character varying(255) | NO |
| 5 | file_path | character varying(500) | NO |
| 6 | file_size | bigint | NO |
| 7 | content_type | character varying(100) | YES |
| 8 | bucket_name | character varying(100) | NO |
| 9 | storage_url | text | YES |
| 10 | title | character varying(500) | YES |
| 11 | document_type | character varying(100) | YES |
| 12 | issuing_authority | character varying(200) | YES |
| 13 | issue_date | timestamp without time zone | YES |
| 14 | effective_date | timestamp without time zone | YES |
| 15 | expiry_date | timestamp without time zone | YES |
| 16 | reference_number | character varying(100) | YES |
| 17 | uploadbyid | character varying(100) | YES |
| 18 | uploadbyname | character varying(200) | YES |
| 19 | extracted_text | text | YES |
| 20 | processed_content | json | YES |
| 21 | ai_classification | json | YES |
| 22 | ai_tags | json | YES |
| 23 | operational_themes | json | YES |
| 24 | target_units | json | YES |
| 25 | confidence_scores | json | YES |
| 26 | processing_status | character varying(50) | NO |
| 27 | extraction_confidence | double precision | YES |
| 28 | classification_confidence | double precision | YES |
| 29 | version | character varying(20) | YES |
| 30 | is_latest_version | boolean | YES |
| 31 | supersedes_document_id | character varying(36) | YES |
| 32 | upload_date | timestamp without time zone | NO |
| 33 | processed_at | timestamp without time zone | YES |
| 34 | created_at | timestamp without time zone | NO |
| 35 | updated_at | timestamp without time zone | NO |
| 36 | status | character varying(20) | NO |
| 37 | document_status | character varying(20) | NO |
| 38 | tag_updated_at | json | YES |
| 39 | status_updated_at | json | YES |
| 40 | normalized_filename | character varying(255) | YES |

### documents - Key Columns by Category

**Identity**:
- id (integer, PK)
- document_id (varchar 36, UNIQUE)

**File Info**:
- filename, original_filename, file_path, file_size, content_type, bucket_name, storage_url

**Metadata**:
- title, document_type, issuing_authority, issue_date, effective_date, expiry_date, reference_number

**Extracted Content**:
- extracted_text (text), processed_content (json)

**AI Analysis**:
- ai_classification (json), ai_tags (json), confidence_scores (json)
- extraction_confidence (double), classification_confidence (double)

**Themes & Units**:
- operational_themes (json), target_units (json)

**Versions**:
- version (varchar 20), is_latest_version (boolean), supersedes_document_id (varchar 36)

**Timestamps**:
- upload_date, processed_at, created_at, updated_at

**Status**:
- status (varchar 20), document_status (varchar 20), processing_status (varchar 50)

**User**:
- uploadbyid, uploadbyname

**Other**:
- normalized_filename (varchar 255), tag_updated_at (json), status_updated_at (json)

---

## batch_uploads Table

**Total Columns**: 27

| # | Column Name | Data Type | Nullable |
|----|-------------|-----------|----------|
| 1 | id | integer | NO |
| 2 | batch_id | character varying(36) | NO |
| 3 | batch_name | character varying(255) | NO |
| 4 | description | text | YES |
| 5 | original_filename | character varying(255) | YES |
| 6 | total_files | integer | NO |
| 7 | total_size_bytes | bigint | NO |
| 8 | status | character varying(50) | NO |
| 9 | progress_percentage | double precision | NO |
| 10 | files_pending | integer | NO |
| 11 | files_processing | integer | NO |
| 12 | files_completed | integer | NO |
| 13 | files_failed | integer | NO |
| 14 | files_skipped | integer | NO |
| 15 | started_at | timestamp without time zone | YES |
| 16 | completed_at | timestamp without time zone | YES |
| 17 | estimated_completion | timestamp without time zone | YES |
| 18 | error_message | text | YES |
| 19 | error_details | json | YES |
| 20 | retry_count | integer | NO |
| 21 | created_by_id | character varying(100) | NO |
| 22 | created_by_name | character varying(200) | NO |
| 23 | processing_options | json | YES |
| 24 | temp_storage_path | character varying(500) | YES |
| 25 | extraction_path | character varying(500) | YES |
| 26 | created_at | timestamp without time zone | NO |
| 27 | updated_at | timestamp without time zone | NO |

### batch_uploads - Key Columns by Category

**Identity**:
- id (integer, PK)
- batch_id (varchar 36, UNIQUE)

**Batch Info**:
- batch_name, description, original_filename

**File Counts**:
- total_files, total_size_bytes
- files_pending, files_processing, files_completed, files_failed, files_skipped

**Progress**:
- status (varchar 50)
- progress_percentage (double 0.0-100.0)
- estimated_completion (timestamp)

**Timing**:
- started_at, completed_at
- created_at, updated_at

**User**:
- created_by_id (varchar 100)
- created_by_name (varchar 200)

**Error Handling**:
- error_message (text)
- error_details (json)
- retry_count (integer)

**Paths**:
- temp_storage_path (varchar 500)
- extraction_path (varchar 500)

**Options**:
- processing_options (json)

---

## batch_upload_items Table

**Total Columns**: 38

| # | Column Name | Data Type | Nullable |
|----|-------------|-----------|----------|
| 1 | id | integer | NO |
| 2 | item_id | character varying(36) | NO |
| 3 | batch_id | character varying(36) | NO |
| 4 | filename | character varying(500) | YES |
| 5 | original_filename | character varying(500) | NO |
| 6 | file_path | character varying(1000) | YES |
| 7 | file_size | bigint | YES |
| 8 | content_type | character varying(200) | YES |
| 9 | status | character varying(50) | YES |
| 10 | processing_status | character varying(50) | YES |
| 11 | progress_percentage | double precision | YES |
| 12 | error_message | text | YES |
| 13 | error_details | json | YES |
| 14 | retry_count | integer | YES |
| 15 | processing_started_at | timestamp without time zone | YES |
| 16 | processing_completed_at | timestamp without time zone | YES |
| 17 | extracted_text | text | YES |
| 18 | ai_classification | json | YES |
| 19 | confidence_scores | json | YES |
| 20 | processing_options | json | YES |
| 21 | temp_file_path | character varying(1000) | YES |
| 22 | storage_path | character varying(1000) | YES |
| 23 | document_id | character varying(36) | YES |
| 24 | created_at | timestamp without time zone | YES |
| 25 | updated_at | timestamp without time zone | YES |
| 26 | file_path_in_zip | character varying(500) | YES |
| 27 | bucket_name | character varying(100) | YES |
| 28 | classification_confidence | double precision | YES |
| 29 | completed_at | timestamp without time zone | YES |
| 30 | error_stage | character varying(100) | YES |
| 31 | extracted_text_length | integer | YES |
| 32 | file_size_bytes | bigint | YES |
| 33 | ocr_confidence | double precision | YES |
| 34 | processing_duration_seconds | double precision | YES |
| 35 | processing_stage | character varying(100) | YES |
| 36 | started_at | timestamp without time zone | YES |
| 37 | validation_errors | json | YES |
| 38 | validation_status | character varying(50) | YES |

### batch_upload_items - Key Columns by Category

**Identity**:
- id (integer, PK)
- item_id (varchar 36, UNIQUE)
- batch_id (varchar 36, FK to batch_uploads)

**File Info**:
- filename, original_filename
- file_path (varchar 1000)
- file_size, file_size_bytes (bigint)
- content_type (varchar 200)

**Document Link**:
- document_id (varchar 36, FK to documents)

**Status & Progress**:
- status (varchar 50)
- processing_status (varchar 50)
- progress_percentage (double)
- processing_stage (varchar 100)

**Extracted Content**:
- extracted_text (text)
- extracted_text_length (integer)

**AI Analysis**:
- ai_classification (json)
- confidence_scores (json)
- classification_confidence (double)

**OCR**:
- ocr_confidence (double)

**Error Handling**:
- error_message (text)
- error_details (json)
- error_stage (varchar 100)
- validation_errors (json)
- validation_status (varchar 50)
- retry_count (integer)

**Timing**:
- processing_started_at, processing_completed_at
- completed_at, started_at
- processing_duration_seconds (double)
- created_at, updated_at

**Storage**:
- temp_file_path (varchar 1000)
- storage_path (varchar 1000)
- bucket_name (varchar 100)
- file_path_in_zip (varchar 500)

**Options**:
- processing_options (json)

---

## Quick Search

### All String/Text Columns
```
documents:
- id, document_id, filename, original_filename, file_path, content_type
- bucket_name, storage_url, title, document_type, issuing_authority
- reference_number, uploadbyid, uploadbyname, extracted_text, version
- processing_status, status, document_status, normalized_filename

batch_uploads:
- id, batch_id, batch_name, description, original_filename, status
- created_by_id, created_by_name, temp_storage_path, extraction_path
- error_message

batch_upload_items:
- id, item_id, batch_id, filename, original_filename, file_path, content_type
- status, processing_status, error_message, storage_path, document_id
- bucket_name, file_path_in_zip, error_stage, processing_stage
- extracted_text, validation_status
```

### All Numeric Columns
```
documents:
- id (integer), file_size (bigint), extraction_confidence (double)
- classification_confidence (double)

batch_uploads:
- id (integer), total_files (integer), total_size_bytes (bigint)
- progress_percentage (double), files_pending (integer), files_processing (integer)
- files_completed (integer), files_failed (integer), files_skipped (integer)
- retry_count (integer)

batch_upload_items:
- id (integer), file_size (bigint), progress_percentage (double)
- retry_count (integer), extracted_text_length (integer)
- classification_confidence (double), ocr_confidence (double)
- processing_duration_seconds (double), file_size_bytes (bigint)
```

### All JSON Columns
```
documents:
- processed_content, ai_classification, ai_tags, operational_themes
- target_units, confidence_scores, tag_updated_at, status_updated_at

batch_uploads:
- error_details, processing_options

batch_upload_items:
- ai_classification, confidence_scores, processing_options, error_details
- validation_errors
```

### All Timestamp Columns
```
documents:
- issue_date, effective_date, expiry_date, upload_date, processed_at
- created_at, updated_at

batch_uploads:
- started_at, completed_at, estimated_completion, created_at, updated_at

batch_upload_items:
- processing_started_at, processing_completed_at, created_at, updated_at
- completed_at, started_at
```

### All Boolean Columns
```
documents:
- is_latest_version
```

---

## Copy-Paste Friendly Lists

### All documents Column Names
```
id
document_id
filename
original_filename
file_path
file_size
content_type
bucket_name
storage_url
title
document_type
issuing_authority
issue_date
effective_date
expiry_date
reference_number
uploadbyid
uploadbyname
extracted_text
processed_content
ai_classification
ai_tags
operational_themes
target_units
confidence_scores
processing_status
extraction_confidence
classification_confidence
version
is_latest_version
supersedes_document_id
upload_date
processed_at
created_at
updated_at
status
document_status
tag_updated_at
status_updated_at
normalized_filename
```

### All batch_uploads Column Names
```
id
batch_id
batch_name
description
original_filename
total_files
total_size_bytes
status
progress_percentage
files_pending
files_processing
files_completed
files_failed
files_skipped
started_at
completed_at
estimated_completion
error_message
error_details
retry_count
created_by_id
created_by_name
processing_options
temp_storage_path
extraction_path
created_at
updated_at
```

### All batch_upload_items Column Names
```
id
item_id
batch_id
filename
original_filename
file_path
file_size
content_type
status
processing_status
progress_percentage
error_message
error_details
retry_count
processing_started_at
processing_completed_at
extracted_text
ai_classification
confidence_scores
processing_options
temp_file_path
storage_path
document_id
created_at
updated_at
file_path_in_zip
bucket_name
classification_confidence
completed_at
error_stage
extracted_text_length
file_size_bytes
ocr_confidence
processing_duration_seconds
processing_stage
started_at
validation_errors
validation_status
```

---

## Usage Examples

### Find Column by Name
Search this document for the column name (Ctrl+F)

### Find Column by Type
- String/Varchar columns: Search "character varying"
- Numeric columns: Search "integer", "bigint", "double precision"
- JSON columns: Search "json"
- Date columns: Search "timestamp"

### Write SQL Queries
Select specific columns:
```sql
SELECT id, document_id, filename, created_at 
FROM documents 
WHERE status = 'completed';
```

Filter by type:
```sql
-- All timestamp columns
SELECT 
  id, 
  issue_date, 
  effective_date, 
  expiry_date, 
  upload_date, 
  processed_at, 
  created_at, 
  updated_at
FROM documents
WHERE created_at > NOW() - interval '7 days';
```

---

**Last Updated**: January 28, 2026  
**Total Columns Across All Tables**: 105
