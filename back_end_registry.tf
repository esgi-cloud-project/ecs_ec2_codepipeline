resource "aws_ecr_repository" "back_end" {
  name                 = "esgi-cloud-project"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "back_end" {
  name = "esgi_cloud_back_end_iam"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "example" {
  role = "${aws_iam_role.back_end.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ecr:GetAuthorizationToken",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "back_end" {
  name           = "back_end_build"

  service_role  = "${aws_iam_role.back_end.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name = "REPOSITORY_URI"
      value = aws_ecr_repository.back_end.repository_url
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/esgi-cloud-project/back_end_app"
  }
}

resource "aws_codebuild_source_credential" "back_end" {
  auth_type = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token = "${var.GITHUB_ACCESS_TOKEN}"
}

resource "aws_codebuild_webhook" "example" {
  project_name = "${aws_codebuild_project.back_end.name}"

  filter_group {
    filter {
      type = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type = "HEAD_REF"
      pattern = "master"
    }
  }
}