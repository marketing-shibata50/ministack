import json
import os


def handler(event, context):
    path = event.get("rawPath", "/")
    body = {
        "lang": "python",
        "path": path,
        "db_host": os.environ.get("DB_HOST"),
        "assets_bucket": os.environ.get("ASSETS_BUCKET"),
    }
    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }
