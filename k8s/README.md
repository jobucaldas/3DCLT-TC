# Kubernetes manifests

These manifests deploy only the 5 application services. Data services are expected to be managed outside Kubernetes, for example with AWS RDS, ElastiCache, SQS and DynamoDB.

Each service has its own namespace:

- `togglemaster-auth`
- `togglemaster-analytics`
- `togglemaster-evaluation`
- `togglemaster-flag`
- `togglemaster-targeting`

## Structure

The manifests are separated by responsibility. The root `kustomization.yaml` is only an aggregator for `kubectl apply -k k8s`.

```text
k8s/
  auth-service/
    configmap.yaml
    secret.yaml
    service.yaml
    deployment.yaml
  flag-service/
    configmap.yaml
    secret.yaml
    service.yaml
    deployment.yaml
  targeting-service/
    configmap.yaml
    secret.yaml
    service.yaml
    deployment.yaml
  evaluation-service/
    configmap.yaml
    secret.yaml
    service.yaml
    deployment.yaml
    hpa.yaml
  analytics-service/
    configmap.yaml
    secret.yaml
    service.yaml
    deployment.yaml
    hpa.yaml
  ingress/
    analytics-ingress.yaml
    auth-ingress.yaml
    evaluation-ingress.yaml
    flag-ingress.yaml
    targeting-ingress.yaml
  namespaces/
    analytics.yaml
    auth.yaml
    evaluation.yaml
    flag.yaml
    targeting.yaml
```

## Cluster prerequisites

Install Metrics Server, required by the HPA:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Install Nginx Ingress Controller before applying the Ingress manifest. If you are using AWS Academy, use the existing `LabRole` in the EKS cluster and node group as described in the challenge PDF.

## Build local images

From the repository root:

```bash
docker build -t auth-service:latest ./auth-service
docker build -t flag-service:latest ./flag-service
docker build -t targeting-service:latest ./targeting-service
docker build -t evaluation-service:latest ./evaluation-service
docker build -t analytics-service:latest ./analytics-service
```

For kind, load the images into the cluster:

```bash
kind load docker-image auth-service:latest
kind load docker-image flag-service:latest
kind load docker-image targeting-service:latest
kind load docker-image evaluation-service:latest
kind load docker-image analytics-service:latest
```

## Use ECR images

For the cloud delivery, push the 5 images to ECR and update the image references before applying:

```bash
kubectl kustomize k8s
```

Edit each service deployment:

- [auth-service/deployment.yaml]
- [flag-service/deployment.yaml]
- [targeting-service/deployment.yaml]
- [evaluation-service/deployment.yaml]
- [analytics-service/deployment.yaml]

Replace:

```text
auth-service:latest
flag-service:latest
targeting-service:latest
evaluation-service:latest
analytics-service:latest
```

with your ECR image URLs, for example:

```text
123456789012.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest
```

## Apply

```bash
kubectl apply -k k8s
kubectl -n togglemaster-auth get pods
kubectl -n togglemaster-analytics get pods
kubectl -n togglemaster-evaluation get pods
kubectl -n togglemaster-flag get pods
kubectl -n togglemaster-targeting get pods
kubectl get hpa -A
kubectl get ingress -A
```

## Test locally

Use port-forwarding from separate terminals:

```bash
kubectl -n togglemaster-auth port-forward svc/auth-service 8001:8001
kubectl -n togglemaster-flag port-forward svc/flag-service 8002:8002
kubectl -n togglemaster-targeting port-forward svc/targeting-service 8003:8003
kubectl -n togglemaster-evaluation port-forward svc/evaluation-service 8004:8004
kubectl -n togglemaster-analytics port-forward svc/analytics-service 8005:8005
```

Health checks:

```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health
```

## Development credentials

The manifests include this placeholder API key for service-to-service calls:

```text
tm_service_dev_key
```

The master key is:

```text
admin-secreto-123
```

Before applying to AWS, replace the placeholder values in the per-service Secrets.

The application services use fully qualified Kubernetes DNS names to reach each other across namespaces:

```text
auth-service.togglemaster-auth.svc.cluster.local
flag-service.togglemaster-flag.svc.cluster.local
targeting-service.togglemaster-targeting.svc.cluster.local
```

Data dependencies are external and must be configured with AWS endpoints:

```text
auth-service -> RDS PostgreSQL auth database
flag-service -> RDS PostgreSQL flag database
targeting-service -> RDS PostgreSQL targeting database
evaluation-service -> ElastiCache Redis and SQS
analytics-service -> SQS and DynamoDB
```

## AWS

`evaluation-service` and `analytics-service` read SQS/DynamoDB settings from their own ConfigMaps and Secrets.

For the cloud delivery, replace the base64 values in these files:

- [auth-service/secret.yaml](C:/Users/gabri/Documents/FIAP/clone/k8s/auth-service/secret.yaml): `DATABASE_URL`, `MASTER_KEY`
- [flag-service/secret.yaml](C:/Users/gabri/Documents/FIAP/clone/k8s/flag-service/secret.yaml): `DATABASE_URL`
- [targeting-service/secret.yaml](C:/Users/gabri/Documents/FIAP/clone/k8s/targeting-service/secret.yaml): `DATABASE_URL`
- [evaluation-service/secret.yaml](C:/Users/gabri/Documents/FIAP/clone/k8s/evaluation-service/secret.yaml): `REDIS_URL`, `AWS_SQS_URL`, AWS credentials
- [analytics-service/secret.yaml](C:/Users/gabri/Documents/FIAP/clone/k8s/analytics-service/secret.yaml): `AWS_SQS_URL`, AWS credentials

Encode values with:

```bash
echo -n "value" | base64
```

For a real environment, replace:

- `AWS_SQS_URL`
- `AWS_DYNAMODB_TABLE`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`, if needed

If you run on EKS with IAM roles for service accounts, remove the static AWS credential env vars and bind the proper service account instead.

Important: because the auth database is external, the `SERVICE_API_KEY` used by `evaluation-service` must exist in the auth database. You can create it through `auth-service` and then update `evaluation-service/secret.yaml`, or seed the same key hash directly in RDS.

## Ingress routes

The Ingress expects Nginx and exposes these path prefixes:

- `/auth` -> `auth-service` in `togglemaster-auth`
- `/flags` -> `flag-service` in `togglemaster-flag`
- `/targeting` -> `targeting-service` in `togglemaster-targeting`
- `/evaluation` -> `evaluation-service` in `togglemaster-evaluation`
- `/analytics` -> `analytics-service` in `togglemaster-analytics`

There is one Ingress resource per service because standard Kubernetes Ingress backends reference Services in the same namespace as the Ingress.

- `auth-service-ingress`
- `flag-service-ingress`
- `targeting-service-ingress`
- `evaluation-service-ingress`
- `analytics-service-ingress`

Example:

```bash
curl http://<load-balancer-dns>/auth/health
curl http://<load-balancer-dns>/evaluation/health
```

## Autoscaling

The challenge requires HPA for:

- `evaluation-service`
- `analytics-service`

Both are configured with CPU target at 70%.
They are configured separately:

- [evaluation-service/hpa.yaml](C:/Users/gabri/Documents/FIAP/clone/k8s/evaluation-service/hpa.yaml)
- [analytics-service/hpa.yaml](C:/Users/gabri/Documents/FIAP/clone/k8s/analytics-service/hpa.yaml)

For the demo:

```bash
kubectl get hpa -A
kubectl -n togglemaster-evaluation get pods
kubectl -n togglemaster-analytics get pods
```

Generate load against `evaluation-service`, then watch replicas:

```bash
kubectl get hpa -A -w
```
