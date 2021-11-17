# pgbackup
Postgres Database backup to remote S3 storage

## Workflow

1. Creates archived Database dump file
2. Makes an upload of files to remote S3
3. Sends a heartbeat upon successful completion of work cycle

## Installation

#### Binaries

Pre-built binaries are available [here](https://github.com/mysteriumnetwork/pgbackup/releases/latest).

#### Build from source

Alternatively, you may run it locally by building an image under the root directory

```
docker build . -t pgbackup
```

## Recognized environment variables

* `PG_HOST` - Postgres Database server hostname
* `PG_PORT` - Postgres Database server port
* `PG_DB` - Database name to be backed up
* `PG_USER` - Database user name to make a backup with
* `PG_PASS` - Database user password to make a backup with
* `AWS_S3_BUCKET` - Aws S3 or compatible S3 storage bucket
* `HEARTBEAT_URL` - Heartbeat Url to call upon successful completion of the backup
* `AWS_ENDPOINT_FILE` - (optional) S3 compatible configuration endpoint file (example [here](https://www.scaleway.com/en/docs/storage/object/api-cli/object-storage-aws-cli/))