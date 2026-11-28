resource "helm_release" "argocd_applications" {
  version    = "1.4.1"
  name       = "argocd-apps"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  timeout    = 600
  values = [
    yamlencode({
        applications = {
          argocd-root-struct8-import = {
            name       = "argocd-root-struct8-import"
            namespace  = "argocd"
            finalizers = ["resources-finalizer.argocd.argoproj.io"]
            project    = "default"
            source = {
              repoURL        = "https://github.com/Struct8/import"
              targetRevision = "HEAD"
              path           = "."
              directory = {
                recurse = true
                include = "{**/application-*.g0ixgbid7xljdrio0rk-d.yaml,**/imageupdater-*.g0ixgbid7xljdrio0rk-d.yaml}"
              }
            }
            destination = {
              server    = "https://kubernetes.default.svc"
              namespace = "argocd"
            }
            syncPolicy = {
              automated = {
                prune      = true
                selfHeal   = true
                allowEmpty = true
              }
            }
          }
        }
      })
  ]
  depends_on = [helm_release.argocd_projects, helm_release.helm_argocd, kubernetes_namespace.argocd, kubernetes_namespace.kong, kubernetes_namespace.kuma, aws_security_group.kuma_uptime_kuma_pod_sg, aws_security_group_rule.rule_cluster_to_kuma_uptime_kuma_pod_sg_tcp_3001, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_apiserver, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_tcp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_udp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_db_instance_kuma_db_group_tcp_3306]
}

resource "helm_release" "argocd_projects" {
  version    = "1.4.1"
  name       = "argocd-projects"
  chart      = "argocd-apps"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  timeout    = 600
  values = [
    yamlencode({
        projects = {
          kuma = {
            name        = "kuma"
            namespace   = "argocd"
            description = ""
            sourceRepos = ["*"]
            destinations = [
              {
                server    = "https://kubernetes.default.svc"
                namespace = "*"
              }
            ]
            clusterResourceWhitelist = [
              {
                group = "*"
                kind  = "*"
              }
            ]
          }
        }
      })
  ]
  depends_on = [helm_release.helm_argocd, kubernetes_namespace.argocd, kubernetes_namespace.kong, kubernetes_namespace.kuma]
}

resource "helm_release" "helm_argocd" {
  name             = "argocd"
  atomic           = true
  chart            = "argo-cd"
  create_namespace = false
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  repository       = "https://argoproj.github.io/argo-helm"
  timeout          = 600
  wait             = true
  values = [
    yamlencode({
        server = {
          extraArgs = ["--insecure"]
        }
      })
  ]
  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_manifest" "netpol-default-deny-kuma" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "default-deny-ingress-kuma"
      namespace = kubernetes_namespace.kuma.metadata[0].name
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress"]
    }
  }
}

resource "kubernetes_manifest" "sgp_kuma_uptime_kuma_pod_sg_auto_mode" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "uptime-kuma-sgp"
      namespace = kubernetes_namespace.kuma.metadata[0].name
    }
    spec = {
      podSelector = {
        matchLabels = {
          "app.kubernetes.io/name" = "uptime-kuma"
        }
      }
      securityGroupSelectorTerms = [
        {
          id = aws_security_group.kuma_uptime_kuma_pod_sg.id
        }
      ]
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [aws_security_group.kuma_uptime_kuma_pod_sg, aws_security_group_rule.rule_cluster_to_kuma_uptime_kuma_pod_sg_tcp_3001, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_apiserver, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_tcp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_udp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_db_instance_kuma_db_group_tcp_3306]
}

resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
  }
  depends_on = [aws_security_group.kuma_uptime_kuma_pod_sg, aws_security_group_rule.rule_cluster_to_kuma_uptime_kuma_pod_sg_tcp_3001, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_apiserver, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_tcp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_udp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_db_instance_kuma_db_group_tcp_3306]
}

resource "kubernetes_namespace" "kuma" {
  metadata {
    name = "kuma"
  }
  depends_on = [aws_security_group.kuma_uptime_kuma_pod_sg, aws_security_group_rule.rule_cluster_to_kuma_uptime_kuma_pod_sg_tcp_3001, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_apiserver, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_tcp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_udp, aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_db_instance_kuma_db_group_tcp_3306]
}
