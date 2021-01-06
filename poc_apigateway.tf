resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "test-s3-int-api"
  description = "API Gateway for test s3 integration Stack"
}

resource "aws_api_gateway_deployment" "api_rest_development" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "dev"

  triggers = {
    redeployment = sha1(join(",", list(
    jsonencode(aws_api_gateway_integration.devops_score_jenkins_item_integration),
    jsonencode(aws_api_gateway_integration.devops_score_sonar_item_integration),
    )))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_usage_plan" "api_rest_plan_usage" {
  name = "api_keys_rest_plan_usage"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_gateway.id
    stage  = aws_api_gateway_deployment.api_rest_development.stage_name
  }
}

resource "aws_api_gateway_api_key" "api_key_rest" {
  name = "api_key"
}

resource "aws_api_gateway_usage_plan_key" "api_plan_usage_key" {
  key_id        = aws_api_gateway_api_key.api_key_rest.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_rest_plan_usage.id
}

resource "aws_api_gateway_resource" "devops_score_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "devops-score"
}

resource "aws_api_gateway_resource" "devops_score_jenkins_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.devops_score_resource.id
  path_part   = "jenkins"
}

resource "aws_api_gateway_resource" "devops_score_jenkins_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.devops_score_jenkins_resource.id
  path_part   = "{item}"
}

resource "aws_api_gateway_method" "devops_score_jenkins_put_method" {
  rest_api_id      = aws_api_gateway_rest_api.api_gateway.id
  resource_id      = aws_api_gateway_resource.devops_score_jenkins_item_resource.id
  http_method      = "PUT"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.path.item" = true
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_method_response" "devops_score_jenkins_put_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.devops_score_jenkins_item_resource.id
  http_method = aws_api_gateway_method.devops_score_jenkins_put_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "devops_score_jenkins_item_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_resource.devops_score_jenkins_item_resource.id
  http_method          = aws_api_gateway_method.devops_score_jenkins_put_method.http_method
  integration_http_method = "PUT"
  type                 = "AWS"
  uri         = "arn:aws:apigateway:us-east-2:s3:path/${aws_s3_bucket.s3_bucket_test.bucket}/jenkins/{object}-{time}.json"
  credentials = aws_iam_role.devops_score_api_gateway_s3_integration_role.arn

  request_parameters = {
    "integration.request.header.x-amz-acl" = "'authenticated-read'"
    "integration.request.path.object" = "method.request.path.item"
    "integration.request.path.time" = "context.requestTimeEpoch"
  }

  request_templates = {
    "application/json" = file("resources/api-gateway/devops-score/jenkins-event.vm")
  }
}

resource "aws_api_gateway_integration_response" "devops_score_jenkins_item_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.devops_score_jenkins_item_resource.id
  http_method = aws_api_gateway_method.devops_score_jenkins_put_method.http_method
  status_code = aws_api_gateway_method_response.devops_score_jenkins_put_method_response_200.status_code

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_resource" "devops_score_sonar_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_resource.devops_score_resource.id
  path_part   = "sonar"
}

resource "aws_api_gateway_method" "devops_score_sonar_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.devops_score_sonar_resource.id
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.x-amz-date" = true
    "method.request.header.X-SonarQube-Project" = true
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration" "devops_score_sonar_item_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  resource_id          = aws_api_gateway_resource.devops_score_sonar_resource.id
  http_method          = aws_api_gateway_method.devops_score_sonar_post_method.http_method
  integration_http_method = "PUT"
  type                 = "AWS"
  uri         = "arn:aws:apigateway:us-east-2:s3:path/${aws_s3_bucket.s3_bucket_test.bucket}/sonarqube/{object}-{time}.json"
  credentials = aws_iam_role.devops_score_api_gateway_s3_integration_role.arn

  request_parameters = {
    "integration.request.header.x-amz-acl" = "'authenticated-read'"
    "integration.request.path.object" = "method.request.header.X-SonarQube-Project"
    "integration.request.path.time" = "context.requestTimeEpoch"
  }

  request_templates = {
    "application/json" = file("resources/api-gateway/devops-score/sonarqube-event.vm")
  }
}

resource "aws_api_gateway_method_response" "devops_score_sonar_post_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.devops_score_sonar_resource.id
  http_method = aws_api_gateway_method.devops_score_sonar_post_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "devops_score_sonar_item_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.devops_score_sonar_resource.id
  http_method = aws_api_gateway_method.devops_score_sonar_post_method.http_method
  status_code = aws_api_gateway_method_response.devops_score_sonar_post_method_response_200.status_code

  response_templates = {
    "application/json" = ""
  }
}