variable "aws_region" {
  type        = string
  description = "Target AWS Region"
  default     = "us-east-2"
}

variable "region_code" {
  type        = string
  description = "Shortened AWS Region Code"
  default     = "use2"
}

variable "platform" {
  type        = string
  description = "Cloud platform abbreviation"
  default     = "aws"
}

variable "product" {
  type        = string
  description = "Product or workload designation"
  default     = "backups"
}

variable "env" {
  type        = string
  description = "Deployment environment"
  default     = "prod"
}

variable "iteration" {
  type        = string
  description = "Iteration sequence"
  default     = "001"
}
