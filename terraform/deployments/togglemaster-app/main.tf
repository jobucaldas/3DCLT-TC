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
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}

module "self_healing" {
  source = "../../modules/self-healing"

  project_name     = var.project_name
  environment      = var.environment
  cluster_name     = var.cluster_name
  cluster_endpoint = data.aws_eks_cluster.main.endpoint
  cluster_ca       = data.aws_eks_cluster.main.certificate_authority[0].data

  db_instance_identifier = "${var.project_name}-${var.environment}-auth-service-db"
}
