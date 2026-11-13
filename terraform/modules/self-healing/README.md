# Self-healing

Reinicia o `auth-service` sozinho quando o alerta de erros 5xx dispara.

## Como funciona

1. O Prometheus dispara o alerta `ServiceHighErrorRate` (mais de 5% de erros 5xx).
2. O Alertmanager avisa o JSM e chama a função Lambda deste módulo.
3. A Lambda reinicia o `deployment/auth-service`, igual ao `kubectl rollout restart`.

## O que o Terraform cria

- A função Lambda e a URL dela.
- A permissão da Lambda no cluster (access entry do EKS).
- O secret `togglemaster/prod/self-healing` com a URL e o token. O Alertmanager lê esse secret pelo External Secrets.

A Lambda só pode alterar o `auth-service`. Isso está no `Role` em `k8s/app/auth-service/self-healing-rbac.yaml`.

## Testar

1. Abra o Alertmanager:
   ```bash
   kubectl port-forward -n monitoring svc/kps-alertmanager 9093
   ```
2. Envie um alerta de teste:
   ```bash
   curl -XPOST localhost:9093/api/v2/alerts -H 'Content-Type: application/json' \
     -d '[{"labels":{"alertname":"ServiceHighErrorRate","service_name":"auth-service","severity":"critical"},"annotations":{"summary":"Teste","description":"Alerta de teste"}}]'
   ```
3. Em até 1 minuto, veja o pod reiniciando e o log da Lambda:
   ```bash
   kubectl get po -n togglemaster-auth -w
   aws logs tail /aws/lambda/togglemaster-prod-self-healing --since 5m
   ```

## Segurança

- A URL da Lambda é pública, mas exige o token. Sem o token, a resposta é 401.
- Só reinicia o `auth-service`, e só para o alerta `ServiceHighErrorRate`.
- Não reinicia de novo se o último reinício foi há menos de 10 minutos.
