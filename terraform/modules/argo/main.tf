resource "helm_release" "argocd" {
  name             = "argocd-${var.environment}"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = "argocd-${var.environment}"
  create_namespace = true
  wait             = true
  timeout          = 600
}

resource "kubernetes_manifest" "app" {
  for_each = var.apps
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = each.key
      namespace = "argocd-${var.environment}"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        path           = "k8s/app/${each.key}"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = each.value
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
  depends_on = [helm_release.argocd]
}
