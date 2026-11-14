# Tech Challenge - Fase 4

Repositório principal do **ToggleMaster**, uma plataforma de feature flags baseada em microsserviços.

Esse repositório inclui a infraestrutura como código (Terraform), os manifests Kubernetes (ArgoCD), a stack de observabilidade, o lambda de self-healing, os pipelines de CI/CD e o ambiente para desenvolvimento local (Docker Compose).

## Grupo

- Gabriel Espanguero Gonzalez - RM 370713
- João Victor Bueno de Caldas - RM 372873

## Repositórios

- [3DCLT-TC](https://github.com/jobucaldas/3DCLT-TC/tree/t4) - infraestrutura, manifests Kubernetes, Docker Compose e scripts de operação
- [auth-service](https://github.com/jobucaldas/auth-service/tree/t4) - autenticação e emissão/validação de API keys
- [flag-service](https://github.com/jobucaldas/flag-service/tree/t4) - cadastro e manutenção das feature flags
- [targeting-service](https://github.com/jobucaldas/targeting-service/tree/t4) - regras de segmentação das flags
- [evaluation-service](https://github.com/jobucaldas/evaluation-service/tree/t4) - avaliação das flags com cache Redis e envio de eventos para SQS
- [analytics-service](https://github.com/jobucaldas/analytics-service/tree/t4) - consumo de eventos da SQS e gravação no DynamoDB

## Arquitetura

O ToggleMaster é composto por cinco serviços de aplicação:

| Serviço | Porta local | Tecnologia | Responsabilidade |
| --- | ---: | --- | --- |
| `auth-service` | 8001 | Go | Gerencia API keys e valida autenticação dos demais serviços |
| `flag-service` | 8002 | Python/Flask | Gerencia o cadastro de feature flags |
| `targeting-service` | 8003 | Python/Flask | Gerencia regras de segmentação por flag |
| `evaluation-service` | 8004 | Go | Endpoint principal de avaliação das flags, com cache em Redis |
| `analytics-service` | 8005 | Python/Flask | Worker que processa eventos da SQS e grava analytics no DynamoDB |

Fluxo principal:

```text
Cliente
  -> evaluation-service
  -> Redis
  -> flag-service / targeting-service, quando não houver cache
  -> SQS
  -> analytics-service
  -> DynamoDB
```

Na AWS, os serviços rodam em um cluster EKS. As dependências de dados são externas ao Kubernetes:

- PostgreSQL no RDS para `auth-service`, `flag-service` e `targeting-service`
- Redis no ElastiCache para cache do `evaluation-service`
- SQS para eventos de avaliação
- DynamoDB para armazenamento dos eventos analíticos
- ECR para imagens Docker dos cinco serviços
- Secrets Manager integrado ao Kubernetes por External Secrets

Observabilidade:

```text
Serviços (OpenTelemetry)
  -> OTel Collector
       -> Prometheus (métricas)  -> Grafana
       -> Loki (logs)            -> Grafana
       -> New Relic (traces e Service Map)
Prometheus -> Alertmanager
  -> Jira Service Management (incidente)
  -> Discord (notificação)
  -> AWS Lambda (self-healing)
```

## Estrutura deste repositório

```text
3DCLT-TC/
  .github/workflows/      pipelines
  docker-compose.yml      ambiente local
  buildImages.sh
  setupServices.sh
  migrateDB.sh
  k8s/
    app/
      auth-service/
      flag-service/
      targeting-service/
      evaluation-service/
      analytics-service/
    eso/                  External Secrets
    helm/                 componentes do cluster e stack de observabilidade
    migrations/           SQL dos bancos
    observability/        dashboard, alertas e secrets da observabilidade
  terraform/
    deployments/
      shared/             bucket do estado (Cloudflare R2) e ECR
      togglemaster-infra/ VPC, EKS, ArgoCD, bancos, filas
      togglemaster-app/   Applications do ArgoCD e self-healing
    modules/
      argo/
      dynamodb/
      ecr/
      eks/
      kms/
      r2/
      rds/
      redis/
      self-healing/
      sqs/
      vpc/
```

Cada pasta grande tem o seu README com os detalhes:

- [k8s/README.md](k8s/README.md): o que o ArgoCD aplica, rotas do Ingress e acesso ao ArgoCD
- [terraform/README.md](terraform/README.md): camadas, rede e como rodar sem o pipeline

## Execução local

Clone os repositórios da branch `t4` no mesmo diretório:

```bash
git clone -b t4 https://github.com/jobucaldas/3DCLT-TC.git
git clone -b t4 https://github.com/jobucaldas/auth-service.git
git clone -b t4 https://github.com/jobucaldas/analytics-service.git
git clone -b t4 https://github.com/jobucaldas/evaluation-service.git
git clone -b t4 https://github.com/jobucaldas/flag-service.git
git clone -b t4 https://github.com/jobucaldas/targeting-service.git
```

Ainda no diretório pai que contém todos os repositórios, crie os arquivos `.env` dos serviços a partir dos exemplos:

```bash
cp auth-service/.env.example auth-service/.env
cp analytics-service/.env.example analytics-service/.env
cp evaluation-service/.env.example evaluation-service/.env
cp flag-service/.env.example flag-service/.env
cp targeting-service/.env.example targeting-service/.env
```

Entre no repositório principal e suba os bancos, dependências locais e serviços (testado com Docker e Podman):

```bash
cd 3DCLT-TC
docker compose up -d
```

Configure uma API key de serviço e dados de demonstração:

```bash
./setupServices.sh
```

Valide os health checks:

```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health
```

Teste uma avaliação:

```bash
curl "http://localhost:8004/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
curl "http://localhost:8004/evaluate?user_id=user-123&flag_name=gradual-checkout"
```

Veja a observabilidade local (depois de fazer algumas requisições acima):

| O que | Onde |
| --- | --- |
| Traces | http://localhost:16686 (Jaeger) |
| Alertas e métricas | http://localhost:9090 (Prometheus) |
| Dashboard | http://localhost:3000 (Grafana) |
| Logs | http://localhost:3000, Explore, Loki |

O compose usa o mesmo dashboard e os mesmos alertas do cluster. O Jaeger substitui o New Relic. Os logs dos serviços Python chegam ao Loki por OTLP. Os de Go e as métricas de CPU e memória só existem no cluster.

## Ambiente na AWS

O ambiente `prod` roda na região `us-east-1`, no cluster EKS `togglemaster-prod-eks`. Mudanças entram por PR no `t4` e são aplicadas pelo GitHub Actions, com aprovação de um dos aprovadores do environment `prod`.

### Acesso

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-prod-eks
kubectl get applications -n argocd-prod
```

A API fica atrás do Ingress e pede a `SERVICE_API_KEY`:

```bash
BASE_URL="http://$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
API_KEY=$(aws secretsmanager get-secret-value --region us-east-1 --secret-id togglemaster/prod/evaluation-service --query SecretString --output text | jq -r .SERVICE_API_KEY)

curl -X POST "$BASE_URL/flags/flags" -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' \
  -d '{"name":"enable-new-dashboard","description":"Demo","is_enabled":true}'
curl -X POST "$BASE_URL/targeting/rules" -H "Authorization: Bearer $API_KEY" -H 'Content-Type: application/json' \
  -d '{"flag_name":"enable-new-dashboard","is_enabled":true,"rules":{"type":"PERCENTAGE","value":100}}'
curl "$BASE_URL/evaluation/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
```

### Secrets

Ficam no AWS Secrets Manager e chegam ao cluster pelo External Secrets. Os de `grafana`, `newrelic`, `jsm` e `discord` são criados uma vez à mão e reaproveitados: o destroy não apaga. Os outros o Terraform cria.

| Secret | Chaves | Quem Preenche |
| --- | --- | --- |
| `togglemaster/prod/grafana` | `admin-user`, `admin-password` | SRE -> preenche manualmente |
| `togglemaster/prod/newrelic` | `NEW_RELIC_LICENSE_KEY` | SRE -> New Relic: API Keys, chave do tipo INGEST - LICENSE |
| `togglemaster/prod/jsm` | `api_key` | SRE -> JSM: Operations, Integrations, integração Prometheus |
| `togglemaster/prod/discord` | `webhook_url` | SRE -> Discord: Configurações do canal, Integrações, Webhooks |
| `togglemaster/prod/self-healing` | URL e token da Lambda | Terraform |
| `togglemaster/prod/<serviço>` | `MASTER_KEY` (auth) e `SERVICE_API_KEY` | A pipeline preenche durante CICD |

O SRE cria o secret uma vez e troca o valor quando precisar:

```bash
aws secretsmanager create-secret --region us-east-1 --name togglemaster/prod/grafana \
  --secret-string '{"admin-user":"admin","admin-password":"<senha>"}'
aws secretsmanager put-secret-value --region us-east-1 --secret-id togglemaster/prod/grafana \
  --secret-string '{"admin-user":"admin","admin-password":"<nova-senha>"}'
```

### Criar e destruir o ambiente

- **Continuous Deployment** cria o que faltar e atualiza o resto. Na primeira subida, ele abre o PR `chore(prod): sync infra urls` com os endereços novos dos bancos e da fila. Depois do merge, roda de novo, migra os bancos e cria as chaves.
- **Deploy Demo Environment** sobe só a infra, para destravar o plan do app num PR.
- **Terraform Destroy** com `prod` derruba tudo. Depois, confira no console se não sobraram Load Balancers, volumes EBS, snapshots ou Elastic IPs.

## GitHub Actions

| Workflow | Quando roda | O que faz |
| --- | --- | --- |
| Lint Workflow e Security Tests | Todo PR e push no `t4` | pre-commit, tflint, kube-linter, Gitleaks, Trivy e Checkov |
| Terraform Plan | PR que mexe em `terraform/` | Comenta no PR a tabela do que vai ser criado, modificado ou destruído. O plan do app falha se o cluster não existir |
| Continuous Deployment | Merge no `t4` | Sobe a infra e o app, espera o ArgoCD, sincroniza URLs, migra os bancos e cria as chaves |
| Deploy Demo Environment | Manual | Sobe só a infra (VPC, EKS, bancos). Serve para destravar o plan de um PR |
| Simulate Auth Failure | Manual | Para o banco do `auth-service` e manda carga por 20 minutos |
| Terraform Destroy | Manual | Destrói o app e a infra |

Nos repositórios dos serviços, o CI faz build da imagem, publica no ECR e abre um PR `chore(gitops)` aqui no `t4` trocando a tag. Ao mergear, o ArgoCD atualiza o cluster.

## Terraform

O Terraform é aplicado em três camadas, cada uma com seu estado no Cloudflare R2:

- **shared:** bucket do estado e repositórios ECR
- **infra:** rede, EKS, ArgoCD, bancos, fila e secrets
- **app:** Applications do ArgoCD e self-healing

Detalhes de cada camada, da rede e de como rodar sem o pipeline: **[terraform/README.md](terraform/README.md)**.

## Kubernetes

Tudo em `k8s/` é aplicado pelo ArgoCD, a partir da branch `t4`. Cada serviço tem seu namespace e é exposto pelo Ingress Nginx.

Pastas, rotas do Ingress, comandos úteis e acesso ao ArgoCD: **[k8s/README.md](k8s/README.md)**.

## Observabilidade

| Ferramenta | Para quê | Como abrir |
| --- | --- | --- |
| OTel Collector | Recebe métricas, logs e traces e envia para os outros | - |
| Prometheus | Guarda as métricas e avalia os alertas | `kubectl port-forward -n monitoring svc/kps-prometheus 9090` |
| Loki | Guarda os logs de todos os contêineres | Pelo Grafana, em Explore |
| Grafana | Dashboard e busca de logs | `kubectl port-forward -n monitoring svc/kps-grafana 3000:80` |
| Alertmanager | Envia os alertas para JSM, Discord e Lambda | `kubectl port-forward -n monitoring svc/kps-alertmanager 9093` |
| New Relic | Traces e Service Map | https://one.newrelic.com, APM & Services |

No Grafana, entre com o usuário e a senha do secret `togglemaster/prod/grafana` e abra o dashboard **ToggleMaster - Saude do ecossistema**. Para logs, use Explore, Loki, e busque por exemplo:

```text
{k8s_namespace_name="togglemaster-auth"}
```

Cada serviço só precisa saber onde está o Collector:

```text
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.monitoring.svc.cluster.local:4318
OTEL_SERVICE_NAME=<nome-do-servico>
```

Os arquivos:

- `k8s/helm/otel-collector.yaml`: para onde vai cada tipo de dado
- `k8s/observability/dashboards/togglemaster.json`: o dashboard
- `k8s/observability/alerts.yaml`: os alertas

Se a conta do New Relic for da região EU, troque `otlp.nr-data.net` por `otlp.eu01.nr-data.net` em `k8s/helm/otel-collector.yaml`.

Prometheus e Loki guardam 24h e perdem os dados se o pod reiniciar.

## Alertas e self-healing

1. O alerta `ServiceHighErrorRate` dispara quando um serviço passa de 5% de respostas 5xx por 2 minutos.
2. O Alertmanager abre incidente no JSM, manda mensagem no Discord e, se for o `auth-service`, chama a Lambda `togglemaster-prod-self-healing`.
3. A Lambda olha o banco do `auth-service`:
   - parado: liga o banco;
   - parando ou ligando: responde 503, e o Alertmanager tenta de novo até o banco terminar de parar;
   - no ar: reinicia o `deployment/auth-service`, igual ao `kubectl rollout restart`. Não reinicia de novo antes de 10 minutos.

Para testar, rode o **Simulate Auth Failure**. Ele para o banco do `auth-service` e manda `POST /admin/keys` por 20 minutos, que devolve 500 sem o banco.

Acompanhe:

```bash
aws logs tail /aws/lambda/togglemaster-prod-self-healing --follow
aws rds describe-db-instances --db-instance-identifier togglemaster-prod-auth-service-db --query 'DBInstances[0].DBInstanceStatus'
kubectl get pods -n togglemaster-auth -w
```

### Diagnóstico do Alertmanager

Para testar só o roteamento (JSM, Discord e Lambda), sem derrubar nada, mande um alerta falso direto ao Alertmanager:

```bash
kubectl port-forward -n monitoring svc/kps-alertmanager 9093
curl -XPOST localhost:9093/api/v2/alerts -H 'Content-Type: application/json' \
  -d '[{"labels":{"alertname":"ServiceHighErrorRate","service_name":"auth-service","severity":"critical"},"annotations":{"summary":"Teste","description":"Alerta de teste"}}]'
```

Com o banco no ar, a Lambda reinicia o `auth-service`. Para testar a falha de verdade, use o **Simulate Auth Failure**.

Segurança:

- A URL da Lambda é pública, mas exige o token do secret `togglemaster/prod/self-healing`.
- No cluster, a Lambda só pode alterar o `deployment/auth-service` (`k8s/app/auth-service/self-healing-rbac.yaml`).
- Na AWS, só pode consultar e ligar o banco do `auth-service`.

## Escalabilidade

- `evaluation-service`: HorizontalPodAutoscaler por CPU, com alvo de 70% e até 5 réplicas.
- `analytics-service`: KEDA com trigger em SQS, escalando conforme o tamanho da fila.

```bash
kubectl get hpa -n togglemaster-evaluation
kubectl get scaledobject -n togglemaster-analytics
ab -k -n 2000 -c 50 "$BASE_URL/evaluation/evaluate?user_id=ab-user&flag_name=enable-new-dashboard"
```
