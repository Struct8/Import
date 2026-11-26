resource "aws_iam_openid_connect_provider" "eks_oidc_eks-kuma" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_tls_eks-kuma.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks-kuma.identity[0].oidc[0].issuer
}

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy_kuma-alb" {
  name        = "AWSLoadBalancerControllerIAMPolicy_kuma-alb"
  description = "AWS Load Balancer Controller IAM Policy"
  path        = "/"
  policy      = data.http.lbc_iam_policy_kuma-alb.response_body
}

data "aws_iam_policy_document" "doc_trust_lbc_kuma-alb" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_eks-kuma.arn]
      type        = "Federated"
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:aws-lbc-kuma-alb"]
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc_eks-kuma.url, "https://", "")}:sub"
    }
  }
}

resource "aws_iam_role" "eks-kuma_role" {
  name = "eks-kuma_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "eks-kuma_role"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_eksng_eks-kuma-nodes" {
  name = "role_eksng_eks-kuma-nodes"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "role_eksng_eks-kuma-nodes"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_lbc_kuma-alb" {
  name               = "role_lbc_kuma-alb"
  assume_role_policy = data.aws_iam_policy_document.doc_trust_lbc_kuma-alb.json
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly_to_eks-kuma-nodes_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.role_eksng_eks-kuma-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy_to_eks-kuma_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-kuma_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController_to_eks-kuma_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-kuma_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy_to_eks-kuma-nodes_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.role_eksng_eks-kuma-nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy_to_eks-kuma-nodes_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.role_eksng_eks-kuma-nodes.name
}

resource "aws_iam_role_policy_attachment" "role_lbc_kuma-alb_attach" {
  policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy_kuma-alb.arn
  role       = aws_iam_role.role_lbc_kuma-alb.name
}
