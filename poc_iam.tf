resource "aws_iam_role" "devops_score_api_gateway_s3_integration_role" {
  name               = "devops-score-s3-apigateway-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_api_gateway.json
}

resource "aws_iam_policy" "s3_policy_devops_score_api_gateway" {
  name   = "s3-api-gateway-devops-score-policy-all"
  policy = data.aws_iam_policy_document.s3_api_gateway.json
}

resource "aws_iam_role_policy_attachment" "apigateway_devops_score_to_s3" {
  role       = aws_iam_role.devops_score_api_gateway_s3_integration_role.name
  policy_arn = aws_iam_policy.s3_policy_devops_score_api_gateway.arn
}