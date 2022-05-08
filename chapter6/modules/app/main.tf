locals {
  environment                    = var.environment
  frontend_ip_configuration_name = "${local.environment}-example-frontend-ip"
}

module "resource_group" {
  source      = "../essential/resource_group"
  environment = local.environment
}

module "web_server_scale_set" {
  source                         = "../services/web_server_scale_set"
  environment                    = local.environment
  frontend_ip_configuration_name = local.frontend_ip_configuration_name
  lb_id                          = module.load_balancer.lb_id
  location                       = module.resource_group.resource_group_location
  resource_group_name            = module.resource_group.resource_group_name
  server_message                 = var.server_message
  subnet_id                      = module.virtual_network.subnet_id
  vm_password                    = var.vm_password
  vm_username                    = var.vm_username
}

module "load_balancer" {
  source                         = "../scaling/load_balancer"
  environment                    = local.environment
  frontend_ip_configuration_name = local.frontend_ip_configuration_name
  location                       = module.resource_group.resource_group_location
  resource_group_name            = module.resource_group.resource_group_name
}

module "virtual_network" {
  source              = "../networking/virtual_network"
  environment         = local.environment
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
}

module "autoscaling" {
  source              = "../scaling/autoscaling"
  environment         = local.environment
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
  scale_set_id        = module.web_server_scale_set.scale_set_id
}