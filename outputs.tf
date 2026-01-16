# Frontend public IP
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

# Backend public IPs
output "backend_public_ips" {
  value = [for b in aws_instance.backend : b.public_ip]
}

# Backend private IPs
output "backend_private_ips" {
  value = [for b in aws_instance.backend : b.private_ip]
}
