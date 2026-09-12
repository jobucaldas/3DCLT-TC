output "release_name" {
  value = helm_release.argocd.name
}
output "namespace" {
  value = helm_release.argocd.namespace
}
