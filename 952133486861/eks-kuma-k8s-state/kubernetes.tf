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
  depends_on = [helm_release.argocd_projects, helm_release.helm_argocd, kubernetes_namespace.argocd, kubernetes_namespace.kong, kubernetes_namespace.kuma]
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

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
  }
}

resource "kubernetes_namespace" "kuma" {
  metadata {
    name = "kuma"
  }
}
