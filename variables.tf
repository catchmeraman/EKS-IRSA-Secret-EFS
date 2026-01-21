variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type for nodes"
  type        = string
}

variable "iam_user_arn" {
  description = "IAM user ARN for cluster access"
  type        = string
}
