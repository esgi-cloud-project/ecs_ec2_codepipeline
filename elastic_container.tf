resource "aws_ecr_repository" "back_end" {
  name                 = "esgi-cloud-project-back_end"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "back_end" {
  name = "esgi_cloud_back_end"
}

resource "aws_iam_role" "back_end_elastic_container" {
  name = "esgi_cloud_back_end_elastic_container"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "back_end_elastic_container" {
  name = "esgi_cloud_elastic_container"
  role = "${aws_iam_role.back_end_elastic_container.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.back_end_code_pipeline.arn}",
        "${aws_s3_bucket.back_end_code_pipeline.arn}/*"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeTags",
            "ecs:CreateCluster",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:UpdateContainerInstancesState",
            "ecs:Submit*",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "dynamodb:Scan",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:GetItem"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage"
        ],
        "Resource": "${var.sqs_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "back_end_ec2" {
  name = "esgi_cloud_back_end_ec2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "back_end_ec2" {
  name = "esgi_cloud_ec2"
  role = "${aws_iam_role.back_end_ec2.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ec2:DescribeTags",
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:UpdateContainerInstancesState",
          "ecs:Submit*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "dynamodb:Scan",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:GetItem"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

data "aws_ami" "latest_ecs" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

data "template_file" "ec2_ecs_definition" {
  template = "${file("${path.module}/ecs_data.script")}"

  vars = {
    cluster_name = "esgi_cloud_back_end"
  }
}

resource "aws_iam_instance_profile" "profile" {
  name = "esgi_cloud_back_end_ec2"
  role = "${aws_iam_role.back_end_ec2.name}"
}


resource "aws_instance" "back_end" {
  ami                    = "${data.aws_ami.latest_ecs.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  subnet_id = "${aws_subnet.public[0].id}"
  iam_instance_profile = "${aws_iam_instance_profile.profile.name}"
  instance_type          = "t2.micro"
  ebs_optimized          = "false"
  source_dest_check      = "false"
  associate_public_ip_address = false
  key_name = "test-ecs"
  security_groups = ["${aws_security_group.back_end_ec2_ssh.id}"]
  user_data              = "${data.template_file.ec2_ecs_definition.rendered}"
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "30"
    delete_on_termination = "true"
  }

  lifecycle {
    ignore_changes         = ["ami", "user_data", "subnet_id", "key_name", "ebs_optimized", "private_ip"]
  }

  # depends_on = [aws_vpc_endpoint.ecs-agent, aws_vpc_endpoint.ecs-telemetry, aws_vpc_endpoint.ecs]
  depends_on = [aws_vpc_endpoint.dynamodb]
}

resource "aws_eip" "back_ec2_elasctic_ip" {
  instance = "${aws_instance.back_end.id}"
  vpc      = true
  depends_on = [var.public_subnet_depends_on]
}

data "template_file" "back_end_task_definition_ecs" {
  template = "${file("${path.module}/task_definitions_service.json")}"

  vars = {
    app_port = var.app_port 
    image = "${aws_ecr_repository.back_end.repository_url}:latest"
    event_service_url = var.sqs_id
    event_service_arn = var.sqs_arn
  }
}

resource "aws_ecs_task_definition" "back_end" {
  family                = "esgi_cloud_back_end"
  container_definitions = "${data.template_file.back_end_task_definition_ecs.rendered}"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  memory                   = "256"
  execution_role_arn = "${aws_iam_role.back_end_elastic_container.arn}"
  task_role_arn = "${aws_iam_role.back_end_elastic_container.arn}"
}

resource "aws_ecs_service" "back_end" {
  name            = "esgi_cloud_back_end"
  cluster         = "${aws_ecs_cluster.back_end.id}"
  task_definition = "${aws_ecs_task_definition.back_end.arn}"
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    security_groups  = [aws_security_group.back_end_ecs.id]
    subnets          = aws_subnet.public.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.back_end.id
    container_name   = "esgi_cloud_back_end"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.back_end, aws_instance.back_end]
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/esgi-cloud-back_end"
    tags = {
    Environment = "production"
  }
}

resource "aws_cloudwatch_log_stream" "cb_log_stream" {
  name           = "fargate"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}