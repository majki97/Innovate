aws_region        = "us-east-1"
cluster_name      = "karpenter-demo"
cluster_version   = "1.34"
vpc_cidr          = "10.0.0.0/16"
karpenter_version = "1.6.0"

tags = {
  Environment = "dev"
  Project     = "karpenter-demo"
  Terraform   = "true"
}
