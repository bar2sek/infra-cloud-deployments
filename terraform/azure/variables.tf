variable "location" {
  description = "Azure deployment region"
  type        = string
  default     = "centralus"
}

variable "env" {
  description = "Environment identifier"
  type        = string
  default     = "prod"
}
