# Default value can be overridden using for example:
# $ export TF_VAR_user_names='["other","names"]'
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}
