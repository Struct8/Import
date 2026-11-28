resource "kubectl_manifest" "calico_crds_eks-kuma" {
  for_each          = data.helm_template.calico_crds_eks-kuma.manifests
  force_conflicts   = true
  server_side_apply = true
  yaml_body         = each.value
}
