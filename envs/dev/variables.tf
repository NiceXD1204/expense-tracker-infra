variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the CI role, in 'owner/repo' form (e.g. NiceXD1204/expense-tracker)"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group (spot)"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 2
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for Alertmanager (pod restart/crash-loop alerts). Leave empty to disable."
  type        = string
  default     = ""
  sensitive   = true
}
