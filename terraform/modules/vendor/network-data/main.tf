locals {
  vpc_id                  = var.vpc_ids[var.env]
  public_subnet_ids       = var.public_subnet_ids[var.env]
  private_subnet_ids      = var.private_subnet_ids[var.env]
  vpn_private_cidr_blocks = var.vpn_private_cidr_blocks
}
