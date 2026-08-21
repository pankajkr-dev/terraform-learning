resource "null_resource" "alb_smoke_test" {
  count = var.smoke_test_enabled ? 1 : 0

  triggers = {
    alb_dns = module.compute_asg.alb_dns_name
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting 90s for ASG instances to register and pass ALB health checks..."
      sleep 90
      count=0
      until wget -q --spider --timeout=15 "http://${module.compute_asg.alb_dns_name}" || [ $count -ge 6 ]; do
        echo "ALB target health check pending (503/502). Retrying in 15s ($count/6)..."
        sleep 15
        count=$((count+1))
      done
      wget -q --spider --timeout=15 "http://${module.compute_asg.alb_dns_name}"
    EOT
  }
}