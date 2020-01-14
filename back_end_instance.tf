resource "aws_ecs_cluster" "esgi_cloud_back_end" {
  name = "esgi_cloud_back_end"
}

resource "aws_iam_role" "back_end_ecs" {
  name = "esgi_cloud_ecs_back_end"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "esgi_cloud_back_end" {
  family                = "esgi_cloud_back_end"
  container_definitions = "${file("task_definitions_service.json")}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = "${aws_iam_role.back_end_ecs.arn}"
}

resource "aws_ecs_service" "esgi_cloud_back_end" {
  name            = "esgi_cloud_back_end"
  cluster         = "${aws_ecs_cluster.esgi_cloud_back_end.id}"
  task_definition = "${aws_ecs_task_definition.esgi_cloud_back_end.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = [aws_subnet.private.id]
    assign_public_ip = true
  }
}