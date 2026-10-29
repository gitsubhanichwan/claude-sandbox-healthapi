output "summary" {
  value = {
    cluster         = aws_ecs_cluster.this.name
    service_name    = aws_ecs_express_gateway_service.app.service_name
    service_arn     = aws_ecs_express_gateway_service.app.service_arn
    ingress_paths   = aws_ecs_express_gateway_service.app.ingress_paths
    deploy_role_arn = aws_iam_role.deploy.arn
    log_group       = aws_cloudwatch_log_group.app.name
  }
}
