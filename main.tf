# Manage an S3 bucket for remote Terraform state
resource "aws_s3_bucket" "this" {
  bucket        = var.remote_state_bucket
  force_destroy = false

  tags = var.tags
}

# Block any form of public access to this bucket
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable S3 bucket versioning to keep full revision history of our state files
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server side encryption for S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Manage a DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "this" {
  name         = var.dynamodb_table
  table_class  = "STANDARD"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  server_side_encryption {
    enabled = true
  }
  lifecycle {
    # this is to work around a bug that results in an apparent permanent diff
    # on this attribute
    ignore_changes = [
      table_class
    ]
  }

  tags = var.tags
}
