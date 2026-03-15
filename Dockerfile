# syntax=docker/dockerfile:1.7
ARG BASE_IMAGE=python:3.11-slim
FROM ${BASE_IMAGE}

ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG NO_PROXY=""
ARG PIP_INDEX_URL=""
ARG PIP_EXTRA_INDEX_URL=""
ARG APT_MIRROR=""

ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY} \
    PIP_INDEX_URL=${PIP_INDEX_URL} \
    PIP_EXTRA_INDEX_URL=${PIP_EXTRA_INDEX_URL} \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN if command -v apt-get >/dev/null 2>&1; then \
      if [[ -n "${APT_MIRROR}" ]]; then \
        sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}|g; s|http://security.debian.org/debian-security|${APT_MIRROR}|g" /etc/apt/sources.list || true; \
      fi; \
      apt-get update && \
      apt-get install -y --no-install-recommends ca-certificates curl git tini && \
      rm -rf /var/lib/apt/lists/*; \
    fi

WORKDIR /workspace

COPY source/app /workspace/app

RUN mkdir -p /workspace/app /var/lib/openclaw /etc/openclaw /var/log/openclaw /var/cache/openclaw && \
    if [[ -f /workspace/app/requirements.txt ]]; then \
      pip install --no-cache-dir -r /workspace/app/requirements.txt; \
    fi && \
    if [[ -f /workspace/app/pyproject.toml ]]; then \
      pip install --no-cache-dir /workspace/app; \
    fi

WORKDIR /workspace/app

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/sh", "-lc", "sleep infinity"]
