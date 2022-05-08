output "public_ip" {
  description = "Public IP"
  value       = module.load_balancer.public_ip
}