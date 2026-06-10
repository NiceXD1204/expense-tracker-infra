output "state_bucket" {
  description = "S3 bucket holding Terraform state for the platform module"
  value       = aws_s3_bucket.tf_state.bucket
}

output "lock_table" {
  description = "DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.tf_locks.name
}

output "backend_config_hcl" {
  description = "Paste this into envs/<env>/backend.hcl (or pass via -backend-config flags)"
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.tf_state.bucket}"
    key            = "envs/dev/terraform.tfstate"
    region         = "${var.region}"
    dynamodb_table = "${aws_dynamodb_table.tf_locks.name}"
    encrypt        = true
  EOT
}
