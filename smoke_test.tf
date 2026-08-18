resource "null_resource" "alb_smoke_test" {
  triggers = {
    alb_dns = module.compute_asg.alb_dns_name
  }

  provisioner "local-exec" {
    command     = "powershell -Command \"Start-Sleep -Seconds 30; Invoke-WebRequest -Uri 'http://${module.compute_asg.alb_dns_name}' -UseBasicParsing -TimeoutSec 15\""
    interpreter = ["PowerShell", "-Command"]
  }
}
