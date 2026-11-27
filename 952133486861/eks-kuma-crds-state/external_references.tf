data "aws_eks_cluster" "eks-kuma" {
  name = "eks-kuma"
}




resource "terraform_data" "gateway_api_crds" {
  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --name ${data.aws_eks_cluster.eks-kuma.name} --region us-east-1
      kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
    EOT
  }
}

resource "helm_release" "app_kong_operator" {
  name             = "kong-operator"
  chart            = "kong-operator"
  repository       = "https://charts.konghq.com"
  version          = "2.44.0"
  namespace        = "kong-operator-system"
  create_namespace = true
  atomic           = true
  wait             = true
  cleanup_on_fail  = true
  timeout          = 600

  depends_on = [terraform_data.gateway_api_crds]
}
