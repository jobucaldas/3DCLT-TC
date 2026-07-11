# ToggleMaster AWS Terraform

Este Terraform cria a infraestrutura AWS necessaria para rodar os manifestos Kubernetes do projeto:

- 1 cluster EKS
- 1 node group gerenciado
- 5 repositorios ECR
- 3 bancos PostgreSQL no RDS
- 1 Redis no ElastiCache
- 1 fila SQS Standard
- 1 tabela DynamoDB
- VPC com subnets publicas, subnets privadas, Internet Gateway, NAT Gateways e security group

## Arquitetura de rede

O desenho atual usa uma topologia mais proxima de boas praticas na AWS:

- Subnets publicas: usadas para Load Balancers e NAT Gateways.
- Subnets privadas: usadas pelos nodes do EKS, RDS e Redis.
- NAT Gateway: permite que recursos privados acessem internet e servicos AWS, como ECR, SQS e DynamoDB.
- Internet Gateway: permite a entrada/saida das subnets publicas.
- RDS e Redis: continuam sem acesso publico.
- Security group de dados: permite PostgreSQL e Redis somente a partir do security group do EKS.
- Endpoint do EKS: acesso publico para seu `kubectl` local e acesso privado para comunicacao dentro da VPC.
- O Terraform cria as IAM Roles usadas pelo EKS e pelo node group
- Os Pods usam a IAM Role dos nodes do EKS para acessar SQS e DynamoDB neste ambiente de demo
  
Fluxo de saida dos Pods:

```text
Pod -> Node EKS privado -> NAT Gateway em subnet publica -> Internet Gateway -> AWS APIs/Internet
```

Fluxo de entrada esperado via Ingress:

```text
Internet -> Load Balancer publico -> Ingress Controller -> Service -> Pod privado
```

Importante: NAT Gateway tem custo por hora e por GB trafegado. Como o EKS tambem cobra por hora, destrua a infraestrutura quando terminar a demo/teste.


## 1. Configurar credenciais AWS

Confirme qual conta sera usada:

```bash
aws sts get-caller-identity
```

## 2. Configurar variaveis

Dentro desta pasta:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` e configure pelo menos:

```hcl
db_password = "senha-forte123"
```

## 3. Criar infraestrutura

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

## 4. Configurar kubectl

Use o output:

```bash
terraform output update_kubeconfig_command
```

Depois execute o comando `aws eks update-kubeconfig ...` impresso no terminal.

## 5. Enviar imagens para o ECR

Use:

```bash
terraform output ecr_repository_urls
```

Faca o build, tag e push da imagem de cada servico para seu respectivo repositorio ECR.

## 6. Atualizar Secrets e imagens do Kubernetes

Use este output para pegar os valores reais dos Secrets:

```bash
terraform output -json kubernetes_secret_values_to_encode
```

Converta cada valor para Base64 e substitua os placeholders em:

- `../k8s/auth-service/secret.yaml`
- `../k8s/flag-service/secret.yaml`
- `../k8s/targeting-service/secret.yaml`
- `../k8s/evaluation-service/secret.yaml`
- `../k8s/analytics-service/secret.yaml`

Tambem substitua a imagem de cada Deployment pela URL correspondente do ECR.

## 7. Instalar componentes do cluster

Antes de depender de Ingress e HPA, instale:

- Nginx Ingress Controller
- Metrics Server

Se o Ingress Controller criar um Load Balancer na AWS, ele ficara nas subnets publicas.

## 8. Aplicar manifestos Kubernetes

Na raiz do repositorio:

```bash
kubectl apply -k 3DCLT-TC/k8s
kubectl get pods -A
kubectl get ingress -A
```

## 9. Inicializar schemas do RDS

Como os bancos sao RDS externos, o Kubernetes nao executa automaticamente os antigos `init.sql`.

Execute os SQLs nos bancos correspondentes:

- `auth-service/db/init.sql` -> `auth_db`
- `flag-service/db/init.sql` -> `flags_db`
- `targeting-service/db/init.sql` -> `targeting_db`

Como o RDS e privado, o caminho mais simples e usar um Pod temporario com cliente PostgreSQL dentro do EKS, ou um bastion/ambiente que consiga acessar a VPC.

O banco do `auth-service` tambem precisa de uma API key para o `evaluation-service`. Para a chave de exemplo `tm_service_dev_key`, use este hash SHA-256:

```sql
INSERT INTO api_keys (name, key_hash, is_active)
VALUES (
  'evaluation-service-dev',
  'f54b19d0699e40ef10108ed46543bfe86a3bbc3250811c0a7158c6ce8ee12742',
  true
)
ON CONFLICT (key_hash) DO NOTHING;
```

## 10. Destruir infraestrutura

Quando terminar:

```bash
kubectl delete -k ../k8s
terraform destroy
```

Depois confira no console AWS se nao sobraram Load Balancers, volumes EBS, snapshots, Elastic IPs ou outros recursos.
