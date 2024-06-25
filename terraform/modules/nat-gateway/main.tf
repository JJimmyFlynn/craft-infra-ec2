/****************************************
* Elastic IPs
*****************************************/
resource "aws_eip" "nat" {
  count = var.az_count
  tags  = module.this.tags
}

/****************************************
* NAT Gateway
*****************************************/
resource "aws_nat_gateway" "default" {
  count             = var.az_count
  subnet_id         = element(var.subnet_ids.*, count.index)
  connectivity_type = "public"
  allocation_id     = element(aws_eip.nat.*.id, count.index)
  tags              = module.this.tags

  depends_on = [var.internet_gateway_id]
}
