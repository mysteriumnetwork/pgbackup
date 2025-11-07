#!/bin/bash

cd /home/root || exit

NOW_DATE=$(date +%d%m%Y-%H%M)
FILENAME="postgres-db-$NOW_DATE.dump"
PG_PASS_FILE=/root/.pgpass

if [ -z "$PG_HOST" ]; then
  echo "PG_HOST variable is not set. Exiting."
  exit
fi
if [ -z "$PG_PORT" ]; then
  echo "PG_PORT variable is not set. Exiting."
  exit
fi
if [ -z "$PG_DB" ]; then
  echo "PG_DB variable is not set. Exiting."
  exit
fi
if [ -z "$PG_USER" ]; then
  echo "PG_USER variable is not set. Exiting."
  exit
fi
if [ -z "$PG_PASS" ]; then
  echo "PG_PASS variable is not set. Exiting."
  exit
fi

if [ -z "$AWS_KEY_ID" ]; then
  echo "AWS_KEY_ID variable is not set. Exiting."
  exit
fi

if [ -z "$AWS_KEY" ]; then
  echo "AWS_KEY variable is not set. Exiting."
  exit
fi

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET variable is not set. Exiting."
  exit
fi

if [ -n "$AWS_ENDPOINT_FILE" ]; then
  if [ ! -e "$AWS_ENDPOINT_FILE" ]; then
    echo "$AWS_ENDPOINT_FILE file doesn't exist. More info here https://www.scaleway.com/en/docs/storage/object/api-cli/object-storage-aws-cli/. Exiting"
    exit
  fi

  cp "$AWS_ENDPOINT_FILE" /root/.aws/config
fi

echo "[default]
aws_access_key_id=$AWS_KEY_ID
aws_secret_access_key=$AWS_KEY
region=nl-ams" >/root/.aws/credentials

printf '*:*:*:*:%s\n' "$PG_PASS" >"$PG_PASS_FILE"
chmod 600 "$PG_PASS_FILE"

# /root/.pgpass need be created in the format hostname:port:database:username:password
# where we put '*' for all criteria and set only password
# example: *:*:*:*:<password>
# that is preferable way to pass credentials for pg_dump
pg_dump -Fc -h "$PG_HOST" -p "$PG_PORT" -d "$PG_DB" -U "$PG_USER" >"$FILENAME"
dump_status=$?

if [ $dump_status -eq 0 ]; then
  filesize=$(stat -c %s "$FILENAME")
  mfs=10
  if [ "$filesize" -gt "$mfs" ]; then
    echo "Postgres Database backup succeeded!"
  else
    echo "Postgres Database backup didn't succeed! Database Dump file is empty!"
    exit
  fi
else
  echo "Postgres Database backup didn't succeed! Exiting."
  exit
fi

# Uploading to s3
S3_BUCKET="$AWS_S3_BUCKET/$PG_DB/$FILENAME"
aws s3 cp "$FILENAME" "$S3_BUCKET"
aws_status=$?

if [ $aws_status -eq 0 ]; then
  echo "Backup upload to s3 succeeded!"
else
  echo "Backup upload to s3 didn't succeed! Exiting."
  exit
fi

if [ -n "$HEARTBEAT_URL" ]; then
  # shellcheck disable=SC2034
  SUCCESS_HTTP_CODE=200
  # shellcheck disable=SC2034
  MAX_RETRIES=5
  CURRENT=0
  while [[ -z "$HTTP_CODE" || "$CURRENT" -lt "$MAX_RETRIES" ]]; do
    HTTP_CODE=$(curl --silent --write-out "%{http_code}" --output /dev/null "$HEARTBEAT_URL")
    if [ "$HTTP_CODE" -eq "$SUCCESS_HTTP_CODE" ]; then exit 0; fi
    sleep $((2 ** "$CURRENT"))
    ((CURRENT = CURRENT + 1))
  done
fi
if [ "$HTTP_CODE" -ne "$SUCCESS_HTTP_CODE" ]; then
  echo "Couldn't send heartbeat after $CURRENT retries"
  exit 1
fi
