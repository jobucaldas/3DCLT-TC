Olá, somos o grupo composto pelo
João Victor Bueno de Caldas,
Gabriel Espanguero Gonzales

Aqui temos a aplicacão junto ao arquivos de containers configurados

(mostrar dockerfiles)

Como podem ver, o mesmo foi montado de forma a incluir boas práticas de seguranca como
multistage build, imagens minimas (no caso utilizamos alpine) e usuarios locais do container

Isto causou alguns problemas devido ao build da aplicacão falhar ao importar algumas das libs musl

Assim, alteramos o import destas libs para definir a versão correta compativel com o alpine
e removemos algumas libs importadas que impossibilitavam o build do executavel do go

E aqui está o docker compose com a orquestracão local deles utilizando o dynamodb local

(mostrar dockercompose)

```bash
# Executar
docker compose up -d --build --force-recreate

# Mostrar
watch -n 3 docker ps
```

Como podem ver, mesmo localmente temos o SQS rodando na cloud, porém este está no ambiente do AWS Academy
separado do ambiente 'prod' para não incorrer em custos

Agora vou rodar um script que montei pra criar as chaves que os servicos vão usar

```bash
setupServices.sh --local
```

E podemos ver a funcionalidade com alguns requests nos servicos

```bash
# Fazer requests nele

test
```

---

Nosso ambiente cloud está sendo deployado na AWS, e para isso utilizamos o terraform para facilitar
a replicacão durante o desenvolvimento do projeto e diminuir custos com a destruicão do ambiente completo

```bash
tofu init
tofu fmt
tofu validate
tofu plan
```

Vemos no plano que nossos arquivos terraform criam as roles que serão utilizadas,
criam uma vpc com subnets separadas e deployam nossos bancos RDS, sqs, elasticache e o eks,
além dos repos do ecr para enviar as imagens da aplicacão, agora vamos subir eles

```bash
tofu apply
```

(pular no video pois vai demorar)

```bash
aws secretsmanager put-secret-value \
  --secret-id togglemaster/auth-service \
  --secret-string "$(jq -n \
  --arg DATABASE_URL "$(tofu -chdir=terraform output -json kubernetes_secret_values | jq -r .auth_database_url)" \
  --arg MASTER_KEY "admin-secreto-123" \
  '{DATABASE_URL:$DATABASE_URL, MASTER_KEY:$MASTER_KEY}')"

aws secretsmanager put-secret-value \
  --secret-id togglemaster/flag-service \
  --secret-string "$(jq -n \
  --arg DATABASE_URL "$(tofu -chdir=terraform output -json kubernetes_secret_values | jq -r .flag_database_url)" \
  '{DATABASE_URL:$DATABASE_URL}')"

aws secretsmanager put-secret-value \
  --secret-id togglemaster/targeting-service \
  --secret-string "$(jq -n \
  --arg DATABASE_URL "$(tofu -chdir=terraform output -json kubernetes_secret_values | jq -r .targeting_database_url)" \
  '{DATABASE_URL:$DATABASE_URL}')"

aws secretsmanager put-secret-value \
  --secret-id togglemaster/evaluation-service \
  --secret-string "$(jq -n \
  --arg SERVICE_API_KEY "placeholder" \
  '{SERVICE_API_KEY:$SERVICE_API_KEY}')"
```

(Voltar aqui)

Podemos ver eles criados agora

(mostrar SQS, Dynamo, RDS, Redis, e Cluster na console)

Temos o SQS que serve como sistema de mensageria, desacoplando as aplicacões

O RDS que provê bancos relacionais para persistência de dados

O DynamoDB que prove mais liberdade para o banco de dados por ser NoSQL,
podendo escalar mais facilmente e não limitando o schema

E o Elasticache que funciona para streaming de dados e como um cache de dados, mais rápido que acessar o banco

Agora podemos fazer o migrate inicial dos bancos e continuar o deploy

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-eks
./migrateDB.sh
```

---

Vamos agora enviar essas imagens ao ecr
(ver repos no ecr)

```bash
# Enviar imagens
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$(tofu -chdir=terraform output -json ecr_repository_urls | jq -r '.["auth-service"]' | cut -d/ -f1)"

./buildImages.sh 1.0.0
```

Agora podemos iniciar os deployments do kubernetes com o metrics server

```bash
cd ../k8s

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

O nginx ingress controller

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

O KEDA para escalar os pods, utilizando a role do IRSA criada pelo terraform

```bash
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

helm upgrade --install keda \
  kedacore/keda \
  -n keda --create-namespace \
  --set serviceAccount.operator.annotations."eks\\.amazonaws\\.com/role-arn"="$(tofu -chdir=../terraform output -raw keda_operator_role_arn)"

kubectl get po -n keda
```

Por fim, o external secret operator, para pegar os secrets direto da AWS, também usando a role do IRSA criada pelo terraform

```bash
helm repo add external-secrets https://charts.external-secrets.io

helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true \
  --set serviceAccount.name=external-secrets \
  --set serviceAccount.annotations."eks\\.amazonaws\\.com/role-arn"="$(tofu -chdir=../terraform output -raw external_secrets_role_arn)"

kubectl get po -n external-secrets
```

Vamos verificar essas roles

```bash
kubectl get sa -n external-secrets external-secrets -o yaml | grep role-arn
kubectl get sa -n keda keda-operator -o yaml | grep role-arn
```

Assim podemos finalmente subir nossos pods

```bash
kubectl apply -k eso
kubectl apply -k .
kubectl get po -A -w
kubectl get ingress -A
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Estes pods estão pegando os secrets diretamente a partir do secret manager da AWS,
Configurado a partir do External Secret Operator que subimos com o helm

Agora vou arrumar o secret do evaluation service pra pegar uma key do auth service

```bash
curl -s -X POST http://localhost:8001/admin/keys \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer admin-secreto-123' \
     -d '{"name":"evaluation-service"}'

aws secretsmanager put-secret-value \
  --secret-id togglemaster/evaluation-service \
  --secret-string "$(jq -n \
  --arg SERVICE_API_KEY "<ts_nova_key>" \
  '{SERVICE_API_KEY:$SERVICE_API_KEY}')"
```

(mostrar secret manager e deploy na pasta k8s)

Agora vou atualizar os secrets para o deploy do evaluation

```bash
kubectl rollout restart deployment -n external-secrets external-secrets
kubectl rollout restart deployment -n togglemaster-evaluation evaluation-service
```

```bash
kubectl get external-secrets -A
```

Agora podemos ver o KEDA funcionando

```bash
kubectl get scaledobject -A
```

Ele está configurado para escalar 1 novo pod a cada 5 mensagens, com mínimo de 0 pods

---

// TODO: mostrar teste de carga com hey, ab ou postman
// TODO: Enviar mensagens no SQS e mostrar o KEDA escalando os pods
// TODO: mostrar dados no dynamoDB
// TODO: falar sobre desafios

