output "user_principal_name" {
  value = azuread_user.az104_user1.user_principal_name
}

output "user_password" {
  value     = random_password.az104_user_pw.result
  sensitive = true
}

output "group_id" {
  value       = azuread_group.it_lab_admins.id
  description = "ID групи IT Lab Administrators"
}

output "group_name" {
  value       = azuread_group.it_lab_admins.display_name
  description = "Назва групи"
}

output "invited_user_email" {
  value = azuread_invitation.guest_user.user_email_address
}

output "invitation_redeem_url" {
  value       = azuread_invitation.guest_user.redeem_url
  sensitive   = false
  description = "Посилання для прийняття запрошення та автоматичного додавання до групи"
}

output "group_url" {
  value       = "https://portal.azure.com/#view/Microsoft_AAD_IAM/GroupDetailsMenuBlade/~/Overview/groupId/${azuread_group.it_lab_admins.object_id}"
  description = "Пряме посилання на групу в Azure Portal"
}