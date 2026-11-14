import base64
import hmac
import json
import os
import ssl
from datetime import datetime, timezone
from urllib import request

CLUSTER = os.environ.get("CLUSTER_NAME", "")
ENDPOINT = os.environ.get("CLUSTER_ENDPOINT", "")
CA = os.environ.get("CLUSTER_CA", "")
TOKEN = os.environ.get("WEBHOOK_TOKEN", "")
DB_INSTANCE = os.environ.get("DB_INSTANCE_ID", "")
COOLDOWN = 600
NAMESPACE = "togglemaster-auth"
DEPLOYMENT = "auth-service"
ANNOTATION = "kubectl.kubernetes.io/restartedAt"


def eks_token():
    import boto3
    from botocore.signers import RequestSigner

    session = boto3.session.Session()
    region = session.region_name
    signer = RequestSigner(
        session.client("sts", region_name=region).meta.service_model.service_id,
        region,
        "sts",
        "v4",
        session.get_credentials(),
        session.events,
    )
    url = signer.generate_presigned_url(
        {
            "method": "GET",
            "url": f"https://sts.{region}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
            "body": {},
            "headers": {"x-k8s-aws-id": CLUSTER},
            "context": {},
        },
        region_name=region,
        expires_in=60,
        operation_name="",
    )
    return "k8s-aws-v1." + base64.urlsafe_b64encode(url.encode()).decode().rstrip("=")


def kube(method, token, body=None):
    ctx = ssl.create_default_context(cadata=base64.b64decode(CA).decode())
    headers = {"Authorization": f"Bearer {token}"}
    if method == "PATCH":
        headers["Content-Type"] = "application/strategic-merge-patch+json"
    req = request.Request(
        f"{ENDPOINT}/apis/apps/v1/namespaces/{NAMESPACE}/deployments/{DEPLOYMENT}",
        data=json.dumps(body).encode() if body else None,
        method=method,
        headers=headers,
    )
    with request.urlopen(req, context=ctx, timeout=10) as resp:
        return json.loads(resp.read())


def db_status():
    import boto3

    rds = boto3.client("rds")
    return rds.describe_db_instances(DBInstanceIdentifier=DB_INSTANCE)["DBInstances"][0]["DBInstanceStatus"]


def start_db():
    import boto3

    boto3.client("rds").start_db_instance(DBInstanceIdentifier=DB_INSTANCE)


def recently_restarted(deployment):
    stamp = deployment["spec"]["template"]["metadata"].get("annotations", {}).get(ANNOTATION)
    if not stamp:
        return False
    return (datetime.now(timezone.utc) - datetime.fromisoformat(stamp)).total_seconds() < COOLDOWN


def reply(code, payload):
    print(json.dumps({"status": code, **payload}))
    return {"statusCode": code, "headers": {"Content-Type": "application/json"}, "body": json.dumps(payload)}


def handler(event, context):
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    if not TOKEN or not hmac.compare_digest(headers.get("authorization", ""), f"Bearer {TOKEN}"):
        return reply(401, {"error": "nao autorizado"})

    try:
        body = event.get("body") or ""
        if event.get("isBase64Encoded"):
            body = base64.b64decode(body).decode()
        alert = json.loads(body)
        labels = alert.get("commonLabels") or {}
        name, service = labels.get("alertname"), labels.get("service_name")
    except (ValueError, AttributeError):
        return reply(400, {"error": "payload invalido"})

    if alert.get("status") != "firing" or (name, service) != ("ServiceHighErrorRate", "auth-service"):
        return reply(200, {"restarted": False, "motivo": f"ignorado: {name} {service} {alert.get('status')}"})

    try:
        status = db_status() if DB_INSTANCE else "available"
        if status == "stopped":
            start_db()
            return reply(200, {"restarted": False, "db_started": True, "db": DB_INSTANCE})
        if status != "available":
            return reply(503, {"restarted": False, "motivo": f"banco {DB_INSTANCE} esta {status}, tente de novo"})
        token = eks_token()
        if recently_restarted(kube("GET", token)):
            return reply(200, {"restarted": False, "motivo": f"{DEPLOYMENT} reiniciado ha menos de {COOLDOWN}s"})
        agora = datetime.now(timezone.utc).isoformat()
        kube("PATCH", token, {"spec": {"template": {"metadata": {"annotations": {ANNOTATION: agora}}}}})
    except Exception as exc:
        return reply(500, {"error": f"falha ao curar {DEPLOYMENT}: {exc}"})
    return reply(200, {"restarted": True, "deployment": f"{NAMESPACE}/{DEPLOYMENT}"})
