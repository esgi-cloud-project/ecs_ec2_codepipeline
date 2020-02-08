# # Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(var.vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = var.vpc.id
}

resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(var.vpc.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = var.vpc.id
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = var.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = element(aws_instance.NatInstance.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}