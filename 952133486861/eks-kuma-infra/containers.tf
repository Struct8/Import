resource "aws_eks_cluster" "eks-kuma" {
  version                       = "1.37"
  name                          = "eks-kuma"
  bootstrap_self_managed_addons = false
  deletion_protection           = false
  enabled_cluster_log_types     = ["api"]
  force_update_version          = false
  role_arn                      = aws_iam_role.eks-kuma_role.arn
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.role_eksauto_eks-kuma.arn
  }
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }
  storage_config {
    block_storage {
      enabled = true
    }
  }
  tags = {
    Name           = "eks-kuma"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    subnet_ids              = [aws_subnet.eks-private-a.id, aws_subnet.eks-private-b.id]
  }
  depends_on = [aws_iam_role_policy_attachment.AmazonEKSWorkerNodeMinimalPolicy_to_eks-kuma_attach, aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryPullOnly_to_eks-kuma_attach, aws_cloudwatch_log_group.eks-kuma-logs, aws_iam_role_policy_attachment.AmazonEKSClusterPolicy_to_eks-kuma_attach, aws_iam_role_policy_attachment.AmazonEKSVPCResourceController_to_eks-kuma_attach, aws_iam_role_policy_attachment.AmazonEKSComputePolicy_to_eks-kuma_attach, aws_iam_role_policy_attachment.AmazonEKSBlockStoragePolicyV2_to_eks-kuma_attach, aws_iam_role_policy_attachment.AmazonEKSLoadBalancingPolicy_to_eks-kuma_attach, aws_iam_role_policy_attachment.AmazonEKSNetworkingPolicy_to_eks-kuma_attach]
}
