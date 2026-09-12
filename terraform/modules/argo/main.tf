resource "helm_release" "argocd" {
  name             = "argocd-${var.environment}"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = "argocd-${var.environment}"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [yamlencode({
    extraObjects = [
      {
        apiVersion = "argoproj.io/v1alpha1"
        kind       = "Application"
        metadata = {
          name      = "operators"
          namespace = "argocd-${var.environment}"
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
      },
      {
        apiVersion = "argoproj.io/v1alpha1"
        kind       = "Application"
        metadata = {
          name      = "togglemaster"
          namespace = "argocd-${var.environment}"
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
    ]
  })]
}
