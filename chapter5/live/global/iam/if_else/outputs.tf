output "if_else_directive" {
  value = "Hello, %{ if var.name != "" }${var.name}%{ else }(unnamed)%{ endif }"
}

output "ternary_operator" {
  value = "Hello, ${ var.name != "" ? var.name : "(unnamed)"}"
}
