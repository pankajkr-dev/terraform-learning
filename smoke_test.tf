resource "null_resource" "alb_smoke_test" {
  triggers = {
    alb_dns = module.compute_asg.alb_dns_name
  }

  provisioner "local-exec" {
    command = "sleep 30 && wget -q --spider --timeout=15 http://${module.compute_asg.alb_dns_name}"
  }
}