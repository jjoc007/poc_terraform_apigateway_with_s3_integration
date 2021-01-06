data "aws_iam_policy_document" "s3_api_gateway" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectRetention",
      "s3:PutObjectVersionAcl",
      "s3:PutObjectVersionTagging",
      "s3:PutObjectTagging",
      "s3:PutObjectLegalHold",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.s3_bucket_test.bucket}/*"]
  }
}

data "aws_iam_policy_document" "assume_role_policy_api_gateway" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com"
      ]
    }
  }
}