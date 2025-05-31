


variable "aws_region" {
  description = "AWS region for main resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "bucket_name" {
  description = "S3 bucket name for hosting static content"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name (e.g., don-blanc-co.com)"
  type        = string
}

variable "alternate_domain_name" {
  description = "Alternate domain name (e.g., www.don-blanc-co.com)"
  type        = string
  default     = ""
}

variable "certificate_subject_alternative_names" {
  description = "List of alternate names for ACM certificate"
  type        = list(string)
  default     = []
}