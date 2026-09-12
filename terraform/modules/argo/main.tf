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

resource "kubernetes_manifest" "requirements" {
  for_each = local.required_operators
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
        repoURL        = each.value.repoURL
        chart          = each.value.chart
        targetRevision = each.value.revision
        helm = each.key == "external-secrets" ? {
          parameters = [{ name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = var.external_secrets_role_arn }]
        } : each.key == "keda" ? {
          parameters = [{ name = "serviceAccount.operator.annotations.eks\\.amazonaws\\.com/role-arn", value = var.keda_operator_role_arn }]
        } : {}
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = each.value.namespace
      }
      syncPolicy = {
        automated   = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
  depends_on = [helm_release.argocd]
}
