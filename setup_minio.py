#!/usr/bin/env python3
"""
MinIO Setup Script
==================
Creates required buckets and sets them to public access.

This is a standalone script for DevOps to run on EC2 servers.
It does NOT depend on any application code.

Requirements:
    pip install minio python-dotenv

Usage:
    python setup_minio.py

Environment Variables (or set in .env file):
    MINIO_HOST=localhost
    MINIO_API_PORT=9000
    MINIO_ACCESS_KEY=your_access_key
    MINIO_SECRET_KEY=your_secret_key
    MINIO_SECURE=false
"""

import json
import sys
import os

try:
    from minio import Minio
except ImportError:
    print("Error: minio package not installed")
    print("Run: pip install minio")
    sys.exit(1)

try:
    from dotenv import load_dotenv
    # Load .env file if it exists
    load_dotenv()
except ImportError:
    # dotenv is optional
    pass


# ===========================================
# CONFIGURATION - Edit these values if needed
# ===========================================
MINIO_HOST = os.getenv("MINIO_HOST", "localhost")
MINIO_PORT = os.getenv("MINIO_API_PORT", "9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "ncc_admin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "ncc_minio_password_2024")
MINIO_SECURE = os.getenv("MINIO_SECURE", "false").lower() == "true"

# Buckets to create
BUCKETS = [
    os.getenv("MINIO_BUCKET_DOCUMENTS", "documents"),
    os.getenv("MINIO_BUCKET_TEMPLATES", "templates"),
    os.getenv("MINIO_BUCKET_ATTACHMENTS", "attachments"),
    os.getenv("MINIO_BUCKET_BACKUPS", "backups"),
]
# ===========================================


def get_minio_client() -> Minio:
    """Create MinIO client."""
    endpoint = f"{MINIO_HOST}:{MINIO_PORT}"
    
    print(f"Connecting to MinIO at {endpoint}...")
    print(f"  Secure: {MINIO_SECURE}")
    
    return Minio(
        endpoint=endpoint,
        access_key=MINIO_ACCESS_KEY,
        secret_key=MINIO_SECRET_KEY,
        secure=MINIO_SECURE
    )


def create_bucket(client: Minio, bucket_name: str) -> bool:
    """Create a bucket if it doesn't exist."""
    try:
        if client.bucket_exists(bucket_name):
            print(f"  ✓ Bucket '{bucket_name}' already exists")
            return True
        
        client.make_bucket(bucket_name)
        print(f"  ✓ Bucket '{bucket_name}' created")
        return True
    except Exception as e:
        print(f"  ✗ Failed to create bucket '{bucket_name}': {e}")
        return False


def set_bucket_public(client: Minio, bucket_name: str) -> bool:
    """Set public read policy for a bucket."""
    try:
        policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": "*"},
                    "Action": ["s3:GetObject"],
                    "Resource": [f"arn:aws:s3:::{bucket_name}/*"]
                }
            ]
        }
        
        client.set_bucket_policy(bucket_name, json.dumps(policy))
        print(f"  ✓ Bucket '{bucket_name}' set to public")
        return True
    except Exception as e:
        print(f"  ✗ Failed to set public policy for '{bucket_name}': {e}")
        return False


def main():
    """Main setup function."""
    print("=" * 50)
    print("MinIO Setup Script")
    print("=" * 50)
    print()
    
    try:
        client = get_minio_client()
        # Test connection
        client.list_buckets()
        print("✓ Connected to MinIO successfully!\n")
    except Exception as e:
        print(f"✗ Failed to connect to MinIO: {e}")
        print("\nPlease check:")
        print(f"  - MinIO is running at {MINIO_HOST}:{MINIO_PORT}")
        print(f"  - Access key and secret key are correct")
        sys.exit(1)
    
    print("Creating buckets and setting public access...\n")
    
    success_count = 0
    for bucket in BUCKETS:
        print(f"[{bucket}]")
        if create_bucket(client, bucket):
            if set_bucket_public(client, bucket):
                success_count += 1
        print()
    
    print("=" * 50)
    print(f"Setup complete: {success_count}/{len(BUCKETS)} buckets configured")
    print("=" * 50)
    
    if success_count == len(BUCKETS):
        print("\n✓ All buckets are ready for public access!")
        print("\nURLs will now work without authentication tokens:")
        print(f"  http://{MINIO_HOST}:{MINIO_PORT}/documents/path/to/file.pdf")
        sys.exit(0)
    else:
        print("\n⚠ Some buckets failed to configure")
        sys.exit(1)


if __name__ == "__main__":
    main()
