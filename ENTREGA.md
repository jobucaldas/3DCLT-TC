# Tech Challenge 4

Grupo:

- Gabriel Espanguero Gonzalez (RM 370713) - @gabriegonza no discord
- João Victor Bueno de Caldas (RM 372873) - @jobue no discord

Repos:
- [3DCLT](https://github.com/jobucaldas/3DCLT-TC/tree/t4)
- [analytics-service](https://github.com/jobucaldas/analytics-service/tree/t4)
- [auth-service](https://github.com/jobucaldas/auth-service/tree/t4)
- [evaluation-service](https://github.com/jobucaldas/evaluation-service/tree/t4)
- [flag-service](https://github.com/jobucaldas/flag-service/tree/t4)
- [targeting-service](https://github.com/jobucaldas/targeting-service/tree/t4)

// TODO: adicionar link tc4
Vídeo: [https://youtu.be/](https://www.youtube.com/)

## Overview da Fase 4

Neste módulo iniciamos o trabalho de monitoramento e observabilidade da aplicação, expandindo a infraestrutura com visibilidade de uso dos nodes do cluster, tracing da aplicação e automação de resposta a incidentes, para manter o MTTR baixo e corrigir falhas sem intervenção humana.

A partir do cluster das fases anteriores (EKS por Terraform, ArgoCD e CI/CD com DevSecOps), foram adicionados os serviços:

```text
Serviços (SDK OpenTelemetry)
  -> OTel Collector (um por nó)
       traces   -> New Relic (Service Map e trace distribuído)
       traces   -> spanmetrics -> métricas de requisição
       métricas -> Prometheus -> Grafana
       logs     -> Loki -> Grafana
Prometheus (alertas) -> Alertmanager
  -> Jira Service Management (incidente)
  -> Discord (notificação)
  -> AWS Lambda (self-healing)
```

## Atualização das Pipelines

Para facilitar as demonstrações nessa fase foram atualizadas as [pipelines de deployment](https://github.com/jobucaldas/3DCLT-TC/actions/workflows/deploy-demo-environment.yaml) para subir o ArgoCD inicialmente, e criada uma pipeline para introduzir [erros no serviço de auth](https://github.com/jobucaldas/3DCLT-TC/actions/workflows/simulate-auth-failure.yaml).

Também mudamos:

- O [plan do Terraform](https://github.com/jobucaldas/3DCLT-TC/actions/workflows/tf-plan.yaml) comenta no PR uma tabela com o que será criado, modificado ou destruído, e marca o comentário anterior como desatualizado. Sem o cluster no ar, o plan do app falha com um aviso no PR, em vez de um erro sem explicação.
- O CI dos serviços abre o PR de GitOps na mesma branch em que rodou (`t4`).
- Removemos o ambiente `dev` e o `k8sBootstrap.sh` para simplificar a utilização do repo e infraestrutura usando só as automações das pipelines.

## Ferramentas Escolhidas

### APM: New Relic

O plano gratuito do New Relic inclui APM com trace distribuído, ainda que apenas para um usuário. No Datadog, o plano gratuito não inclui APM fora do plano pago ou em trial, então não foi escolhido.

O New Relic recebe OTLP direto do Collector, sem agente proprietário nos serviços.

### Incidentes: Jira Service Management

Escolhemos o JSM no lugar do OpsGenie devido à sua descontinuação: a Atlassian parou de vender o OpsGenie e levou a gestão de on-call para dentro do JSM. O endpoint de integração do JSM aceita o receiver de OpsGenie do Alertmanager, então usamos o receiver nativo apontando para o JSM.

O PagerDuty também funcionaria, com receiver nativo no Alertmanager e plano gratuito. Ficamos com o JSM por ser o caminho do OpsGenie citado no enunciado e para validar na prática a integração compatível com o OpsGenie.

### Alertas: Discord, direto do Alertmanager

O Alertmanager contém um receiver nativo do Discord, sem necessidade de integração extra com o JSM.
O alerta chega diretamente mesmo se o Jira estiver fora do ar.

## Secrets

Criamos uma conta em cada ferramenta e guardamos as chaves no AWS Secrets Manager. O External Secrets leva as chaves para o cluster, então nenhuma chave fica no Git. Os secrets `grafana`, `newrelic`, `jsm` e `discord` são criados uma vez e reaproveitados quando o ambiente é recriado:

```bash
aws secretsmanager create-secret --name togglemaster/prod/grafana \
  --secret-string '{"admin-user":"admin","admin-password":"<senha>"}'
aws secretsmanager create-secret --name togglemaster/prod/newrelic \
  --secret-string '{"NEW_RELIC_LICENSE_KEY":"<chave INGEST - LICENSE>"}'
aws secretsmanager create-secret --name togglemaster/prod/jsm \
  --secret-string '{"api_key":"<chave da integração Prometheus no JSM>"}'
aws secretsmanager create-secret --name togglemaster/prod/discord \
  --secret-string '{"webhook_url":"<webhook do canal>"}'
```

O token da Lambda de self-healing é gerado pelo Terraform, e as chaves dos serviços são preenchidas pelo CD.

## Arquitetura do OpenTelemetry

A stack entrou como Applications do ArgoCD em `k8s/helm`, e sobe com o cluster no [CD](https://github.com/jobucaldas/3DCLT-TC/actions/workflows/cd.yaml):

- **kube-prometheus-stack:** Prometheus, Grafana, Alertmanager, node-exporter e kube-state-metrics num chart só, já ligados entre si.
- **Loki:** modo single binary, o suficiente para o ambiente.
- **OpenTelemetry Collector:** chart oficial, como DaemonSet.

Prometheus e Loki guardam 24h e não usam volume persistente, para não pagar armazenamento.

### Instrumentação

Os 5 serviços usam as bibliotecas oficiais do OpenTelemetry:

- Go (`auth-service` e `evaluation-service`): SDK com `otelhttp`.
- Python (`flag-service`, `targeting-service` e `analytics-service`): `opentelemetry-distro` com instrumentação de Flask, requests, psycopg2 e botocore.

Cada serviço só conhece o Collector:

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.monitoring.svc.cluster.local:4318
```

Para o trace ligar os 5 serviços, o `evaluation-service` propaga o contexto nas chamadas HTTP ao flag e ao targeting, e na mensagem do SQS (`traceparent` nos atributos). O `analytics-service` continua o mesmo trace ao ler a fila. Sem isso, o trace pararia na fila e o Service Map ficaria cortado.

### Roteamento no Collector

O Collector recebe o OTLP dos serviços, lê os logs dos contêineres do nó e decide para onde vai cada dado:

| Dado | De onde vem | Destino |
| --- | --- | --- |
| Traces | OTLP dos serviços | New Relic |
| Métricas de requisição | `spanmetrics`, a partir dos traces | Prometheus (remote write) |
| Logs | OTLP e arquivos de log dos contêineres | Loki |

Escolhas:

- **DaemonSet:** um Collector por nó lê os logs de todos os contêineres do nó e acrescenta pod, namespace e deployment em cada dado (`k8sattributes`).
- **Métricas a partir dos traces** (`spanmetrics`): taxa de requisições, erros e latência saem dos traces, então Go e Python ficam com as mesmas labels, sem exporter de métricas em cada serviço.
- **CPU, memória e restarts** não passam pelo Collector: o Prometheus coleta direto do node-exporter e do kube-state-metrics.
- **Trocar de APM** é mudar um exporter no Collector, sem tocar nos serviços.

### Dashboard

O dashboard **ToggleMaster - Saude do ecossistema** mostra CPU e memória por namespace, requisições por serviço, taxa de 5xx, restarts e logs em tempo real. Ele fica no Git (`k8s/observability/dashboards`), e o sidecar do Grafana carrega sozinho pelo ConfigMap.

## Alertas e resposta a incidentes

Os alertas ficam no Git como PrometheusRule (`k8s/observability/alerts.yaml`), e passam pelo mesmo GitOps do resto. O Grafana mostra essas regras em Alerting.

| Alerta | Quando dispara |
| --- | --- |
| `ServiceHighErrorRate` | Mais de 5% de respostas 5xx num serviço por 2 minutos |
| `ServiceHighLatency` | p95 acima de 1 segundo por 5 minutos |
| `PodRestartingFrequently` | Mais de 3 restarts em 15 minutos |
| `PodNotReady` | Pod não pronto por 5 minutos |

```yaml
- alert: ServiceHighErrorRate
  expr: |
    sum by (service_name) (rate(traces_span_metrics_calls_total{span_kind="SPAN_KIND_SERVER",http_response_status_code=~"5.."}[5m]))
    / sum by (service_name) (rate(traces_span_metrics_calls_total{span_kind="SPAN_KIND_SERVER"}[5m]))
    > 0.05
  for: 2m
```

O Alertmanager agrupa por alerta e serviço, para não mandar uma mensagem por pod, e envia o mesmo alerta em paralelo para o JSM e o Discord. Só o `ServiceHighErrorRate` do `auth-service` chama a Lambda:

```yaml
- receiver: self-healing
  continue: true
  matchers:
  - alertname = ServiceHighErrorRate
  - service_name = auth-service
```

### Self-healing

A Lambda `togglemaster-prod-self-healing` é criada pelo Terraform (`terraform/modules/self-healing`), e o Alertmanager chama a URL dela com um token. Ela olha o banco do `auth-service`:

- parado: liga o banco;
- parando ou ligando: responde 503, e o Alertmanager tenta de novo até o banco terminar de parar. Se respondesse 200, ele só reenviaria depois de 4 horas;
- no ar: reinicia o `deployment/auth-service`, igual ao `kubectl rollout restart`, e não reinicia de novo antes de 10 minutos.

```python
status = db_status()
if status == "stopped":
    start_db()
    return reply(200, {"db_started": True})
if status != "available":
    return reply(503, {"motivo": f"banco esta {status}, tente de novo"})
```

**Lambda, e não GitHub Action por webhook.** Reage em segundos, cabe no free tier e fica versionada com a infra. Uma Action levaria até um minuto para começar e precisaria de um token do GitHub guardado no Alertmanager.

Segurança:

- A URL da Lambda é pública, mas exige o token do secret `togglemaster/prod/self-healing`. O Alertmanager não assina requisições com IAM, então usamos token.
- No cluster, a Lambda só pode alterar o `deployment/auth-service`.
- Na AWS, só pode consultar e ligar o banco do `auth-service`.

### Falha simulada

A pipeline [Simulate Auth Failure](https://github.com/jobucaldas/3DCLT-TC/actions/workflows/simulate-auth-failure.yaml) para o banco do `auth-service` e manda `POST /admin/keys` por 20 minutos. Sem banco, o serviço devolve 500.

Paramos o banco em vez de injetar erro no código ou mandar um alerta falso, porque assim a falha é real e a Lambda corrige a causa.

Em seguida, o alerta entra em Firing, o Alertmanager envia o alerta ao JSM, o Discord recebe a mensagem, a Lambda liga o banco e, com os erros parados, o alerta resolve nos dois canais.

## Ambiente local

O `docker-compose.yml` passou a subir o Collector, Jaeger (no lugar do New Relic), Prometheus, Loki e Grafana, com o mesmo dashboard e os mesmos alertas do cluster, sem os dados de CPU, memória e pods, que só existem no cluster.

## Destruir o ambiente

O ambiente é derrubado pela pipeline [Terraform Destroy](https://github.com/jobucaldas/3DCLT-TC/actions/workflows/tf-destroy.yaml). Os secrets das ferramentas ficam, para a próxima subida.

## Das fases anteriores

- Cloudflare R2 guarda o estado do Terraform, separado da conta AWS.
- O Terraform é aplicado em camadas para o ArgoCD subir só com o cluster em pé.
- O CI preenche os secrets criados pelo Terraform.

## Para completar

// TODO: preencher com os prints. Apague este aviso quando terminar.

### Evidências

// TODO: print do dashboard do Grafana

// TODO: print do trace distribuído no New Relic

// TODO: print do Service Map no New Relic com os 5 serviços

// TODO: print da notificação do incidente no Discord

// TODO: print do log da Lambda de self-healing

### Custo

// TODO: print do custo durante a Fase 4
