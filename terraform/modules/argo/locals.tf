locals {
  required_operators = {
    external-secrets = {
      repoURL   = "https://charts.external-secrets.io"
      chart     = "external-secrets"
      revision  = "0.10.6"
      namespace = "external-secrets"
    }
    ingress-nginx = {
      repoURL   = "https://kubernetes.github.io/ingress-nginx"
      chart     = "ingress-nginx"
      revision  = "4.11.3"
      namespace = "ingress-nginx"
    }
    keda = {
      repoURL   = "https://kedacore.github.io/charts"
      chart     = "keda"
      revision  = "2.14.2"
      namespace = "keda"
    }
    metrics-server = {
      repoURL   = "https://kubernetes-sigs.github.io/metrics-server"
      chart     = "metrics-server"
      revision  = "3.12.2"
      namespace = "kube-system"
    }
  }
}
