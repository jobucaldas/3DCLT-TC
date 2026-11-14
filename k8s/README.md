# Kubernetes

O ArgoCD aplica tudo desta pasta a partir da branch `t4`:

- `app`: Deployments, Services, Ingress, ConfigMaps, ExternalSecrets, NetworkPolicies, ServiceAccounts e regras de escala dos cinco serviços. Cada serviço tem seu namespace (`togglemaster-auth`, `togglemaster-flag` e assim por diante).
- `eso`: a ligação do External Secrets com o Secrets Manager.
- `helm`: External Secrets, Nginx Ingress, KEDA, Metrics Server, kube-prometheus-stack, Loki e OTel Collector.
- `observability`: dashboard, alertas e secrets da observabilidade.
- `migrations`: SQL dos bancos.

## Rotas do Ingress

```text
/auth       -> auth-service
/flags      -> flag-service
/targeting  -> targeting-service
/evaluation -> evaluation-service
/analytics  -> analytics-service
```

## Comandos úteis

```bash
kubectl get applications -n argocd-prod
kubectl get pods -A
kubectl get externalsecrets -A
```

ArgoCD (usuário `admin`):

```bash
kubectl -n argocd-prod get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
kubectl port-forward -n argocd-prod $(kubectl get svc -n argocd-prod -l app.kubernetes.io/component=server -o name) 8080:443
```

Os bancos são privados. As migrações rodam num pod temporário dentro do cluster, pelo CD ou com `./migrateDB.sh` na raiz do repositório.
