import json
import os
import time
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
REQUIRED_FIELDS = ("service", "version", "commit", "environment")
RETENTION_DAYS = 90


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body, default=str),
    }


def create_deployment(event):
    try:
        data = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "body must be valid JSON"})

    missing = [field for field in REQUIRED_FIELDS if not data.get(field)]
    if missing:
        return _response(400, {"error": f"missing fields: {', '.join(missing)}"})

    item = {
        "service": data["service"],
        "deployed_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "version": data["version"],
        "commit": data["commit"],
        "environment": data["environment"],
        "deployed_by": data.get("deployed_by", "unknown"),
        "expires_at": int(time.time()) + RETENTION_DAYS * 86400,
    }
    TABLE.put_item(Item=item)
    return _response(201, item)


def list_deployments(event):
    service = (event.get("queryStringParameters") or {}).get("service")
    if not service:
        return _response(400, {"error": "service query parameter is required"})

    result = TABLE.query(
        KeyConditionExpression=Key("service").eq(service),
        ScanIndexForward=False,
        Limit=20,
    )
    deployments = [
        {k: v for k, v in item.items() if k != "expires_at"} for item in result["Items"]
    ]
    return _response(200, {"service": service, "deployments": deployments})


ROUTES = {
    "POST /deployments": create_deployment,
    "GET /deployments": list_deployments,
}


def handler(event, context):
    route = ROUTES.get(event.get("routeKey"))
    if route is None:
        return _response(404, {"error": "not found"})
    return route(event)
