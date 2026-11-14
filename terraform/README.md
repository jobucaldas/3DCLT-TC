# Terraform

O Terraform é aplicado em três camadas, cada uma com seu estado no Cloudflare R2:

| Camada | Pasta | O que cria |
| --- | --- | --- |
| shared | `deployments/shared` | O bucket R2 do estado e os repositórios ECR |
| infra | `deployments/togglemaster-infra` | VPC, NAT Gateway, EKS, ArgoCD, RDS, ElastiCache, SQS, DynamoDB, KMS, Secrets Manager e IAM Roles |
| app | `deployments/togglemaster-app` | As Applications do ArgoCD (`k8s/helm` e `k8s`) e o self-healing |

Os módulos usados pelas camadas ficam em `modules/`.

## Rede

- Subnets públicas: Load Balancers e NAT Gateway.
- Subnets privadas: nodes do EKS, RDS e Redis. Os bancos não têm acesso público e só aceitam conexões das subnets privadas.
- Endpoint do EKS público (para o `kubectl` de quem opera) e privado (para os nodes dentro da VPC).

```text
Entrada: Internet -> Load Balancer público -> Ingress Nginx -> Service -> Pod
Saída:   Pod -> node privado -> NAT Gateway -> Internet Gateway -> APIs da AWS e New Relic
```

O NAT Gateway, o EKS e o RDS cobram por hora. Destrua o ambiente quando terminar.

## Rodar sem o pipeline

```bash
cd deployments/togglemaster-infra
tofu init
tofu plan -var-file=prod.tfvars
tofu apply -var-file=prod.tfvars
```
