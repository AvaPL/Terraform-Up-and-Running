# Default value can be overridden using for example:
# $ export TF_VAR_user_names='["other","names"]'
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

variable "address_space" {
  description = "Virtual network address spaces"
  type = list(string)
  default = ["10.0.0.0/16"]
}

# Default value can be overridden using for example:
# $ export TF_VAR_subnets='{"subnet0":"10.0.0.0/24","subnet1":"10.0.1.0/24"}'
variable "subnets" {
  description = "Virtual network subnets"
  type = map(string)
  default = {
    subnet0 = "10.0.0.0/24"
  }
}