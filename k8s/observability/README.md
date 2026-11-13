# Observabilidade

Sobe Prometheus, Loki, Grafana e OTel Collector no cluster. O ArgoCD instala tudo sozinho.

## O que cada um faz

- **Prometheus**: guarda as métricas.
- **Loki**: guarda os logs.
- **Grafana**: mostra métricas e logs no dashboard.
- **OTel Collector**: recebe os dados dos serviços e envia para o Prometheus, o Loki e o New Relic.

## Passo a passo

1. Crie 3 secrets no AWS Secrets Manager:
   - `togglemaster/prod/grafana` com `admin-user` e `admin-password`
   - `togglemaster/prod/newrelic` com `NEW_RELIC_LICENSE_KEY`
   - `togglemaster/prod/jsm` com `api_key` (chave da integração Prometheus do Jira Service Management)
2. Faça o push da branch. O ArgoCD aplica sozinho.
3. Confira se os pods subiram:
   ```bash
   kubectl get po -n monitoring
   ```
4. Abra o Grafana:
   ```bash
   kubectl port-forward -n monitoring svc/kps-grafana 3000:80
   ```
   Acesse http://localhost:3000 e entre com o usuário e a senha do passo 1.
5. Abra o dashboard **ToggleMaster - Saude do ecossistema**.

## Para os serviços enviarem dados

Configure em cada serviço:

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.monitoring.svc.cluster.local:4318
OTEL_SERVICE_NAME=<nome-do-servico>
```

## Observação

Os dados são apagados se o pod reiniciar (retenção de 24h).
