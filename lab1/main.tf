resource "random_password" "az104_user_pw" {
  length  = 16
  special = true
}

resource "azuread_user" "az104_user1" {
  user_principal_name = "az104-user1@${var.domain}"
  display_name        = "az104-user1"
  mail_nickname       = "az104-user1"
  password            = random_password.az104_user_pw.result
  account_enabled     = true

  job_title      = "IT Lab Administrator"
  department     = "IT"
  usage_location = "US"
}

resource "azuread_group" "it_lab_admins" {
  display_name     = "IT Lab Administrators"
  mail_enabled     = false
  security_enabled = true
  description      = "Group for IT Lab Administrators"
}

resource "azuread_invitation" "guest_user" {
  user_email_address = "juliala125@gmail.com"
  redirect_url = "https://myapps.microsoft.com"
  
  message {
    additional_recipients = []
    body = "Вітаємо! Ви запрошені до групи IT Lab Administrators. Після прийняття запрошення ви автоматично станете членом групи."
  }
}

resource "azuread_group_member" "internal_user_member" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_user.az104_user1.object_id
}

resource "azuread_group_member" "guest_user_member" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_invitation.guest_user.user_id
  
  depends_on = [azuread_invitation.guest_user]
}