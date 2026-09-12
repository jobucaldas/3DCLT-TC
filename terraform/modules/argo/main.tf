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
