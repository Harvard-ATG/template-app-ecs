output "service_arn" {
  value = aws_ecs_service.main.id
}
output "task_definition_arn" {
  value = aws_ecs_task_definition.main.arn
}
output "task_definition_arn_without_revision" {
  value = aws_ecs_task_definition.main.arn_without_revision
}
output "security_group_arn" {
  value = aws_security_group.ecs_sg.arn
}
output "security_group_id" {
  value = aws_security_group.ecs_sg.id
}
output "task_role_arn" {
  value = aws_iam_role.task_role.arn
}
output "task_role_name" {
  value = aws_iam_role.task_role.name
}
output "task_execution_role_arn" {
  value = aws_iam_role.task_execution_role.arn
}
