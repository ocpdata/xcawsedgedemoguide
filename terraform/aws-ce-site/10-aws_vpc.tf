locals {
  effective_site_name = trimspace(var.site_name) != "" ? trimspace(var.site_name) : trimspace(var.environment)
  vpcs = [
    { 
      vpc_cidr      = var.vpc_cidr,
      subnet_a_cidr = cidrsubnet(var.vpc_cidr, 8, 10),
      subnet_b_cidr = cidrsubnet(var.vpc_cidr, 8, 20),
      subnet_c_cidr = cidrsubnet(var.vpc_cidr, 8, 30),
      name          = "${local.effective_site_name}-vpc"
    },
  ]
}

resource "aws_vpc" "vpc" {
  count = length(local.vpcs)

  cidr_block = local.vpcs[count.index].vpc_cidr
  tags = {
    Name = local.vpcs[count.index].name
    Environment = var.environment
  }
}

resource "aws_subnet" "subnet_a" {
  count             = length(aws_vpc.vpc)
  vpc_id            = aws_vpc.vpc[count.index].id
  cidr_block        = local.vpcs[count.index].subnet_a_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name        = "${local.vpcs[count.index].name}-a-subnet"
    Environment = var.environment
  }
}

resource "aws_subnet" "subnet_b" {
  count = length(aws_vpc.vpc)

  vpc_id            = aws_vpc.vpc[count.index].id
  cidr_block        = local.vpcs[count.index].subnet_b_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name        = "${local.vpcs[count.index].name}-b-subnet"
    Environment = var.environment
  }
}

resource "aws_subnet" "subnet_c" {
  count             = length(aws_vpc.vpc)
  vpc_id            = aws_vpc.vpc[count.index].id
  cidr_block        = local.vpcs[count.index].subnet_c_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name        = "${local.vpcs[count.index].name}-c-subnet"
    Environment = var.environment
  }
}

output "aws_vpc_ids" {
  value = aws_vpc.vpc[*].id
}

output "aws_vpc_subnet_a" {
  value = aws_subnet.subnet_a[*].id
}

output "aws_vpc_subnet_b" {
  value = aws_subnet.subnet_b[*].id
}

output "aws_vpc_subnet_c" {
  value = aws_subnet.subnet_c[*].id
}
