provider "aws" {
  region              = "us-east-1"
  version             = "3.5.0"
  allowed_account_ids = ["214219211678"]
}

module "cluster" {
  source = "../../modules/cluster"

  name = var.cluster_name

  vpc_config = local.vpc_config
  iam_config = local.iam_config

  envelope_encryption_enabled = false
  metrics_server              = true
  aws_alb_ingress_controller  = true
  aws_ebs_csi_driver          = var.aws_ebs_csi_driver

  critical_addons_node_group_key_name = "development"


  aws_auth_role_map = [
    {
      username = aws_iam_role.test_role.name
      rolearn  = aws_iam_role.test_role.arn
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Project = "terraform-aws-eks"
  }
}

module "node_group" {
  source = "../../modules/asg_node_group"

  cluster_config = module.cluster.config

  name     = "standard-nodes"
  key_name = "development"

  labels = {
    "cookpad.com/terraform-aws-eks-test-environment" = var.cluster_name
  }
}

module "gpu_nodes" {
  source = "../../modules/asg_node_group"

  cluster_config = module.cluster.config

  name     = "gpu-nodes"
  key_name = "development"

  gpu             = true
  instance_family = "gpu"
  instance_size   = "2xlarge"
  instance_types  = ["p3.2xlarge"]
  zone_awareness  = false
  min_size        = 1

  labels = {
    "k8s.amazonaws.com/accelerator" = "nvidia-tesla-v100"
  }

  taints = {
    "nvidia.com/gpu" = "gpu:NoSchedule"
  }
}
