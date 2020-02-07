resource "aws_security_group" "back_end_load_balancer" {
  name        = "esgi_cloud_back_end_load_balancer"
  vpc_id      = var.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "back_end_ecs" {
  name        = "esgi_cloud_back_end_ecs"
  vpc_id      = var.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.back_end_load_balancer.id]
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "back_end_ec2_ssh" {
  name        = "esgi_cloud_back_end_ec2_ssh"
  vpc_id      = var.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "back_end" {
  name            = "cb-load-balancer"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.back_end_load_balancer.id]
  depends_on = [var.public_subnet_depends_on]
}

resource "aws_alb_target_group" "back_end" {
  name        = "cb-target-group"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc.id
  target_type = "ip"
  health_check {
    path = "/api"
    matcher = "200,404"
  }
}

resource "aws_alb_listener" "back_end" {
  load_balancer_arn = aws_alb.back_end.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.back_end.arn}"
  }
}

output "alb_hostname" {
  value = aws_alb.back_end.dns_name
}