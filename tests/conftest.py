import os

# Handler modules create DynamoDB table clients at import time.
os.environ.setdefault("TABLE_NAME", "event-ticketing-table")
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_REGION", "us-east-1")
