# Tech Challenge - Fase 3

Repositório principal da entrega da Fase 3 do projeto **ToggleMaster**, uma plataforma de feature flags baseada em microsserviços.

Nesta fase, o projeto evolui da execução local para uma arquitetura conteinerizada em Kubernetes, com infraestrutura provisionada na AWS por Terraform/OpenTofu, uso de serviços gerenciados e automação de deploy, migração e validação.

## Grupo

- Gabriel Espanguero Gonzalez - RM 370713
- João Victor Bueno de Caldas - RM 372873

## Repositórios

- [3DCLT-TC](https://github.com/jobucaldas/3DCLT-TC/tree/t3) - infraestrutura, manifests Kubernetes, Docker Compose e scripts de operação
- [auth-service](https://github.com/jobucaldas/auth-service/tree/t3) - autenticação e emissão/validação de API keys
- [flag-service](https://github.com/jobucaldas/flag-service/tree/t3) - cadastro e manutenção das feature flags
- [targeting-service](https://github.com/jobucaldas/targeting-service/tree/t3) - regras de segmentação das flags
- [evaluation-service](https://github.com/jobucaldas/evaluation-service/tree/t3) - avaliação das flags com cache Redis e envio de eventos para SQS
- [analytics-service](https://github.com/jobucaldas/analytics-service/tree/t3) - consumo de eventos da SQS e gravação no DynamoDB

## Visão geral da arquitetura

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

## Estrutura deste repositório

```text
3DCLT-TC/
  docker-compose.yml
  buildImages.sh
  setupServices.sh
  migrateDB.sh
  k8sBootstrap.sh
  k8s/
    app/
      auth-service/
      flag-service/
      targeting-service/
      evaluation-service/
      analytics-service/
    eso/
    helm/
  terraform/
    deployments/
      shared/
      togglemaster-infra/
      togglemaster-app/
    modules/
      argo/
      dynamodb/
      ecr/
      eks/
      kms/
      r2/
      rds/
      redis/
      sqs/
      vpc/
```

## Execução local

Clone os repositórios da branch `t3` no mesmo diretório:

```bash
git clone -b t3 https://github.com/jobucaldas/3DCLT-TC.git
git clone -b t3 https://github.com/jobucaldas/auth-service.git
git clone -b t3 https://github.com/jobucaldas/analytics-service.git
git clone -b t3 https://github.com/jobucaldas/evaluation-service.git
git clone -b t3 https://github.com/jobucaldas/flag-service.git
git clone -b t3 https://github.com/jobucaldas/targeting-service.git
```

Ainda no diretório pai que contém todos os repositórios, crie os arquivos `.env` dos serviços a partir dos exemplos:

```bash
cp auth-service/.env.example auth-service/.env
cp analytics-service/.env.example analytics-service/.env
cp evaluation-service/.env.example evaluation-service/.env
cp flag-service/.env.example flag-service/.env
cp targeting-service/.env.example targeting-service/.env
```

Entre no repositório principal e suba os bancos, dependências locais e serviços:

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

## Infraestrutura AWS

A infraestrutura da Fase 3 fica em `terraform/deployments/togglemaster-infra` e cria:

- VPC com subnets públicas e privadas
- NAT Gateway e Internet Gateway
- EKS com node group gerenciado
- Repositórios ECR para os serviços
- RDS PostgreSQL para os serviços com banco relacional
- ElastiCache Redis
- SQS Standard
- DynamoDB
- KMS
- Secrets Manager
- IAM Roles para EKS, External Secrets, KEDA e workloads da aplicação

Exemplo de execução:

```bash
cd terraform/deployments/togglemaster-infra
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu fmt
tofu validate
tofu plan
tofu apply
```

Configure o `kubectl` com o cluster criado:

```bash
tofu output eks_cluster_name
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
```

## Build e publicação das imagens

Após criar os repositórios ECR, faça build e push das imagens:

```bash
cd 3DCLT-TC
./buildImages.sh latest
```

O script procura os diretórios `*-service`, obtém a URI correspondente no ECR e publica cada imagem com a tag informada.

## Kubernetes

Os manifests Kubernetes ficam em `k8s/` e são organizados por responsabilidade:

- `k8s/app` contém Deployments, Services, Ingress, ConfigMaps, ExternalSecrets, NetworkPolicies, ServiceAccounts e regras de escala dos cinco serviços.
- `k8s/eso` contém a configuração do External Secrets para integração com o AWS Secrets Manager.
- `k8s/helm` contém os componentes de apoio do cluster: External Secrets, Nginx Ingress Controller, KEDA e Metrics Server.

Instale os componentes de apoio:

```bash
kubectl apply -k k8s/helm
```

Depois aplique a aplicação:

```bash
kubectl apply -k k8s
```

Verifique o estado dos recursos:

```bash
kubectl get pods -A
kubectl get ingress -A
kubectl get externalsecrets -A
kubectl get hpa -A
kubectl get scaledobject -A
```

## Migração dos bancos

Os bancos da AWS são privados, por isso as migrações são executadas a partir de um pod temporário dentro do cluster:

```bash
./migrateDB.sh
```

O script aplica os arquivos `db/init.sql` dos serviços:

- `auth-service`
- `flag-service`
- `targeting-service`

## Bootstrap e smoke tests no cluster

Depois da infraestrutura, imagens, secrets e migrações, execute:

```bash
API_KEY="tm_key_..." ./k8sBootstrap.sh
```

O script:

- aplica service accounts com IRSA para `evaluation-service` e `analytics-service`
- força sincronização dos ExternalSecrets
- reinicia os pods para recarregar variáveis de ambiente
- cria flags e regras de demonstração via Ingress
- imprime comandos de smoke test, carga e validação de SQS/DynamoDB

Rotas esperadas via Ingress:

```text
/auth       -> auth-service
/flags      -> flag-service
/targeting  -> targeting-service
/evaluation -> evaluation-service
/analytics  -> analytics-service
```

Exemplos de validação:

```bash
BASE_URL="http://<load-balancer-dns>"
API_KEY="tm_key_..."

curl "$BASE_URL/auth/health"
curl "$BASE_URL/flags/health"
curl "$BASE_URL/targeting/health"
curl "$BASE_URL/evaluation/health"

curl "$BASE_URL/auth/validate" -H "Authorization: Bearer $API_KEY"
curl "$BASE_URL/evaluation/evaluate?user_id=user-123&flag_name=enable-new-dashboard"
curl "$BASE_URL/evaluation/evaluate?user_id=user-123&flag_name=gradual-checkout"
```

## Escalabilidade

A Fase 3 inclui dois mecanismos de escala:

- `evaluation-service`: HorizontalPodAutoscaler por CPU, com alvo de 70% e até 5 réplicas.
- `analytics-service`: KEDA com trigger em SQS, escalando conforme o tamanho da fila.

Comandos úteis durante testes de carga:

```bash
kubectl get hpa -n togglemaster-evaluation
kubectl get pods -n togglemaster-evaluation
kubectl get scaledobject -n togglemaster-analytics
kubectl get pods -n togglemaster-analytics
```

Exemplo de carga no endpoint de avaliação:

```bash
ab -k -n 2000 -c 50 "$BASE_URL/evaluation/evaluate?user_id=ab-user&flag_name=enable-new-dashboard"
```

## Limpeza

Ao final dos testes, remova a aplicação e destrua a infraestrutura para evitar custos:

```bash
kubectl delete -k k8s
cd terraform/deployments/togglemaster-infra
tofu destroy
```

Também confira no console da AWS se não restaram Load Balancers, volumes EBS, snapshots, Elastic IPs ou outros recursos cobrados separadamente.
