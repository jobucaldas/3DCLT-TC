locals {
  service_apps = [
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service",
  ]
}

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
    extraObjects = concat([
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
          name      = "external-secrets-config"
          namespace = "argocd-${var.environment}"
        }
        spec = {
          project = "default"
          source = {
            repoURL        = var.repo_url
            targetRevision = var.target_revision
            path           = "k8s/eso"
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
      ],
      [
        for service_app in local.service_apps : {
          apiVersion = "argoproj.io/v1alpha1"
          kind       = "Application"
          metadata = {
            name      = service_app
            namespace = "argocd-${var.environment}"
          }
          spec = {
            project = "default"
            source = {
              repoURL        = var.repo_url
              targetRevision = var.target_revision
              path           = "k8s/app/${service_app}"
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
    )
  })]
}
