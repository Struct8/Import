resource "aws_autoscaling_group_tag" "eks-kuma-nodes_name_tag" {
  autoscaling_group_name = aws_eks_node_group.eks-kuma-nodes.resources[0].autoscaling_groups[0].name
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "eks-kuma-nodes"
  }
}
