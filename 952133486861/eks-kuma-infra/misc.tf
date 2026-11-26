resource "kubectl_manifest" "tgb_tg-kuma" {
  yaml_body = <<-YAML
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-kuma-tgb
  namespace: "kuma"
spec:
  targetGroupARN: "${aws_lb_target_group.tg-kuma.arn}"
  targetType: ip
  serviceRef:
    name: kong-proxy-static
    port: 80
YAML
  depends_on = [helm_release.aws_lbc_kuma-alb]
}
