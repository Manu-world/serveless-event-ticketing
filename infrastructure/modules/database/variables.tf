variable "prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "enable_pitr" {
  type    = bool
  default = true
}

variable "deletion_protection_enabled" {
  type    = bool
  default = false
}
