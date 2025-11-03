output "load_balancer_public_ip" {
  description = "public IP address of load B=balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}