
provider "aws" {
  region = "us-east-1" 
}

module "compute" {
  source = "./modules/compute"
}

module "network" {
  source = "./modules/network"
}

module "load_balancer" {
  source = "./modules/load_balancer"
}

module "firewall" {
  source = "./modules/firewall"
}

