---
title: "GID - Gitlab in Docker"
date: 2024-08-06
draft: false
description: "how to deploy gitlab ce server on docker"
tags: ["blog", "perso"]
---

## Overview

This post describes how to deploy a GitLab CE server and a GitLab Runner using Docker Compose. The setup includes:

- A GitLab CE container serving the web interface and repository management functions.
- A GitLab Runner container to execute CI/CD jobs.

## Prerequisites

- Docker
- Docker Compose

## Deployment

Save the following content as `docker-compose.yml`:

```yaml
version: '3.8'
services:

  gitlab-server:
    image: 'gitlab/gitlab-ce:latest'
    container_name: gitlab-server
    ports:
      - '8000:8000'
    environment:
      GITLAB_ROOT_EMAIL: "chxmxii.ctf@gmail.com"
      GITLAB_ROOT_PASSWORD: "v3ryl0ng&&secur3p455w0rd"
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:8000'
        nginx['listen_port'] = 8000
    volumes:
      - ./gitlab/config:/etc/gitlab
      - ./gitlab/data:/var/opt/gitlab

  gitlab-runner:
    image: gitlab/gitlab-runner:alpine
    container_name: gitlab-runner
    network_mode: 'host'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

Now you can deploy the containers using:

```bash
docker compose up -d
```

## Access

The GitLab server will be available at:  
`http://localhost:8000`

Use the specified email and password to log in.

## Notes

- GitLab data is saved locally in the `./gitlab` directory.
- The GitLab Runner uses the Docker socket to run jobs in containers.
- `network_mode: 'host'` lets the runner reach the GitLab server without extra setup.

## Registering the Runner

To register the GitLab Runner, execute the following command:

```bash
docker exec -it gitlab-runner gitlab-runner register
```

You will be asked for the following information:

- **GitLab instance URL**: `http://localhost:8000`
- **Registration token**: You can find this in GitLab under `Admin Area > Runners`
- **Description**: Any label for this runner (e.g., `local-runner`)
- **Tags**: Optional tags (e.g., `docker`)
- **Executor**: Choose `docker` and specify the default image (e.g., `alpine:latest`)

After successful registration, the runner will be ready to execute jobs from GitLab.