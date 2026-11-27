resource "kubectl_manifest" "tgb_tg-kuma" {
  yaml_body = <<-YAML
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-kuma-tgb
  namespace: "${kubernetes_namespace.kuma.metadata[0].name}"
spec:
  targetGroupARN: "${data.aws_lb_target_group.tg-kuma.arn}"
  targetType: ip
  serviceRef:
    name: kong-proxy-static
    port: 80
YAML
}
