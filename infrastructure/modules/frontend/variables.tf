variable "prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "force_destroy" {
  type    = bool
  default = true
}
