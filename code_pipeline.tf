resource "aws_s3_bucket" "back_end_code_pipeline" {
  bucket = "esgi-cloud-code-pipeline"
  acl    = "private"
}

resource "aws_iam_role" "back_end_code_pipeline" {
  name = "esgi_cloud_back_end_code_pipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "back_end_code_pipeline" {
  name = "esgi_cloud_code_pipeline"
  role = "${aws_iam_role.back_end_code_pipeline.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.back_end_code_pipeline.arn}",
        "${aws_s3_bucket.back_end_code_pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
        "Action": [
            "ecs:*",
            "iam:PassRole"
        ],
        "Resource": "*",
        "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "back_end" {
  name     = "esgi_cloud"
  role_arn = "${aws_iam_role.back_end_code_pipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.back_end_code_pipeline.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        OAuthToken = "${var.GITHUB_ACCESS_TOKEN}"
        Owner  = "esgi-cloud-project"
        Repo   = "back_end_app"
        Branch = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.back_end.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      input_artifacts  = ["build_output"]
      version          = "1"

      configuration = {
        ClusterName = "${aws_ecs_cluster.back_end.name}"
        ServiceName = "${aws_ecs_service.back_end.name}"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}