output "name" {
  description = "Resource group name, whether created or looked up."
  value       = local.group.name
}

output "id" {
  description = "Resource group ID."
  value       = local.group.id
}

output "location" {
  description = "Resource group region. Callers place resources here so they follow the group rather than a separately configured region."
  value       = local.group.location
}
