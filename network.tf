# # Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

# resource "aws_subnet" "private" {
#   count             = var.az_count
#   cidr_block        = cidrsubnet(var.vpc.cidr_block, 8, count.index)
#   availability_zone = data.aws_availability_zones.available.names[count.index]
#   vpc_id            = var.vpc.id
# }

resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(var.vpc.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = var.vpc.id
  map_public_ip_on_launch = false
}

# resource "aws_security_group" "vpc_endpoint_security_group" {
#   name        = "esgi_cloud_back_end_vpc_endpoint"
#   vpc_id      = var.vpc.id

#   ingress {
#     protocol    = "tcp"
#     from_port   = 80
#     to_port     = 80
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     protocol    = "tcp"
#     from_port   = 443
#     to_port     = 443
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_vpc_endpoint" "ecs-agent" {
#   vpc_id       = var.vpc.id
#   service_name = "com.amazonaws.eu-west-3.ecs-agent"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.vpc_endpoint_security_group.id
#   ]
#   subnet_ids = aws_subnet.public.*.id
#   private_dns_enabled = true
# }
# resource "aws_vpc_endpoint" "ecs-telemetry" {
#   vpc_id       = var.vpc.id
#   service_name = "com.amazonaws.eu-west-3.ecs-telemetry"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.vpc_endpoint_security_group.id
#   ]
#   subnet_ids = aws_subnet.public.*.id
#   private_dns_enabled = true
# }
# resource "aws_vpc_endpoint" "ecs" {
#   vpc_id       = var.vpc.id
#   service_name = "com.amazonaws.eu-west-3.ecs"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.vpc_endpoint_security_group.id
#   ]
#   subnet_ids = aws_subnet.public.*.id
#   private_dns_enabled = true
# }

# resource "aws_vpc_endpoint" "dynamodb" {
#   vpc_id       = var.vpc.id
#   service_name = "com.amazonaws.eu-west-3.dynamodb"
# }