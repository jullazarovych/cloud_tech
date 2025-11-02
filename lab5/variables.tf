variable "admin_password" {
  description = "A strong password for the VM admin account. It should meet Azure's complexity requirements."
  type        = string
  sensitive   = true 
}

variable "admin_username" {
  description = "Username for the VM administrator."
  type        = string
  default     = "localadmin"
}

variable "location" {
  description = "Azure region to deploy resources."
  type        = string
  default     = "West Europe"
}