FROM ubuntu:24.04

ARG PG_VER=18

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    pipx \
    unzip \
    vim \
    wget \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(uname -m)" \
 && case "${ARCH}" in \
      x86_64) AWS_ARCH="x86_64" ;; \
      aarch64|arm64) AWS_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o awscliv2.zip \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm -rf aws awscliv2.zip

RUN install -d /usr/share/postgresql-common/pgdg \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor >/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg \
 && sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
 && apt-get update \
 && apt-get install -y --no-install-recommends "postgresql-client-${PG_VER}" \
 && rm -rf /var/lib/apt/lists/*

RUN pipx install awscli-plugin-endpoint --include-deps
RUN aws configure set plugins.endpoint awscli_plugin_endpoint

COPY backup.sh /root/
RUN chmod +x /root/backup.sh

USER root
CMD bash /root/backup.sh
