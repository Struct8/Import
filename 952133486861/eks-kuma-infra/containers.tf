resource "aws_eks_addon" "coredns_eks-kuma" {
  addon_name                  = "coredns"
  cluster_name                = aws_eks_cluster.eks-kuma.name
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.eks-kuma-nodes]
}

resource "aws_eks_addon" "kube_proxy_eks-kuma" {
  addon_name                  = "kube-proxy"
  cluster_name                = aws_eks_cluster.eks-kuma.name
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.eks-kuma-nodes]
}

resource "aws_eks_addon" "vpc_cni_eks-kuma" {
  addon_name                  = "vpc-cni"
  cluster_name                = aws_eks_cluster.eks-kuma.name
  configuration_values        = jsonencode({"env": {"ENABLE_PREFIX_DELEGATION": "true", "WARM_PREFIX_TARGET": "1", "ENABLE_POD_ENI": "true", "POD_SECURITY_GROUP_ENFORCING_MODE": "standard"}})
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.eks-kuma-nodes]
}

resource "aws_eks_cluster" "eks-kuma" {
  version                       = "1.33"
  name                          = "eks-kuma"
  bootstrap_self_managed_addons = true
  deletion_protection           = false
  enabled_cluster_log_types     = ["api"]
  force_update_version          = false
  role_arn                      = aws_iam_role.eks-kuma_role.arn
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
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
  depends_on = [aws_cloudwatch_log_group.eks-kuma-logs, aws_iam_role_policy_attachment.AmazonEKSClusterPolicy_to_eks-kuma_attach, aws_iam_role_policy_attachment.AmazonEKSVPCResourceController_to_eks-kuma_attach]
}

resource "aws_eks_node_group" "eks-kuma-nodes" {
  cluster_name    = aws_eks_cluster.eks-kuma.name
  node_group_name = "eks-kuma-nodes"
  ami_type        = "AL2023_x86_64_STANDARD"
  capacity_type   = "ON_DEMAND"
  instance_types  = ["m5.large"]
  node_role_arn   = aws_iam_role.role_eksng_eks-kuma-nodes.arn
  subnet_ids      = [aws_subnet.eks-private-a.id, aws_subnet.eks-private-b.id]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  tags = {
    Name           = "eks-kuma-nodes"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_route_table_association.aws_route_table_association_eks_private_a_rt_eks_private, aws_route.route_rt-eks-private_to_nat-eks-kuma_ipv4, aws_route_table_association.aws_route_table_association_eks_private_b_rt_eks_private, aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy_to_eks-kuma-nodes_attach, aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy_to_eks-kuma-nodes_attach, aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly_to_eks-kuma-nodes_attach]
}
