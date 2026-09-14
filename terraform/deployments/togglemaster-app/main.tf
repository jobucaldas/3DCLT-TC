resource "kubernetes_manifest" "operators" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "operators"
      namespace = "argocd-${var.environment}"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "-1"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        path           = "k8s/helm"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd-${var.environment}"
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
}

resource "kubernetes_manifest" "togglemaster" {
  depends_on = [kubernetes_manifest.operators]
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "togglemaster"
      namespace = "argocd-${var.environment}"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "0"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        path           = "k8s"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd-${var.environment}"
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
}
