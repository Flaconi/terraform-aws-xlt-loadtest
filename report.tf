# S3 bucket to store/serve load test reports
module "report" {
  create_bucket            = var.create_report_bucket
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "5.8.2"
  bucket                   = local.reports_bucket_name
  force_destroy            = true
  acl                      = "public-read"
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  tags                     = local.tags

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${local.reports_bucket_name}/*"
      },
    ]
  })

  website = {
    index_document = "index.html"
  }
}

# IAM Policy for syncing loast test reports to s3
resource "aws_iam_policy" "mc_iam_policy_s3_sync" {
  count       = var.create_cluster && var.create_report_bucket ? 1 : 0
  name        = "xlt-${var.name}-master-controller-iam-policy-s3-sync"
  path        = "/"
  description = "IAM role policy for s3 sync"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObjectAcl",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${local.reports_bucket_name}",
          "arn:aws:s3:::${local.reports_bucket_name}/*"
        ]
      },
    ]
  })
}
