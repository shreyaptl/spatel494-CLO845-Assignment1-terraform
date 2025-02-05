# Add output variables
output "eip" {
  value = aws_eip.CLO835_week04_Assignment01_static_eip.public_ip
}