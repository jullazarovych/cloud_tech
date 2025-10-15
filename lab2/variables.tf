variable "management_group_id" {
  type        = string
  default     = "az104-mg1"
  description = "ID for management group"
}

variable "management_group_name" {
  type        = string
  default     = "az104-mg1"
  description = "Display name for management group"
}

variable "helpdesk_group_name" {
  type        = string
  default     = "Help Desk"
  description = "Name of a group Help Desk"
}

variable "custom_role_name" {
  type        = string
  default     = "Custom Support Request"
  description = "Name of custom role"
}