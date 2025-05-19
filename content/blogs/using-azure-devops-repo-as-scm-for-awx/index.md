---
title: "Authenticating AWX with Azure DevOps Personal Access Tokens"
date: 2024-08-06
draft: false
description: "how to set up Azure DevOps Repo as a SCM for AWX"
tags: ["blog", "perso"]
---

# Intro

If you’ve ever tried syncing a Git repository from Azure DevOps into AWX, you’ve probably run into some weird issues. You add your token, but AWX still prompts for a password or fails silently with an annoying error message `fatal: Authentication failed`. Here’s how I got around that using a clean and working approach.

## What's the problem?

The authentication mechanism for Azure DevOps requires a personal access token (PAT) passed via an Authorization header as mentionned [here](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Linux). But AWX doesn’t natively support this, and custom credentials don’t help much with this scenario as they can’t influence Git headers directly. so how can we authenticate awx with Azure DevOps PATs?

## Solution

While digging the internet trying to find a way to authenticate I found this [solution](https://forum.ansible.com/t/using-azure-devops-repo-as-scm-for-awx-project-fails-to-authenticate/6819/3) which suggests using SSH Keys, but many companies (including mine) disables the SSH authentication as a security measure. however I spent many hours trying to find a way to inject the `http.extraHeader` header, The first thing came to mind is creating a custom ExecutionEnvironement and inject `git config --global http.<uri>.extraheader 'Authorization: Basic $PAT_B64_ENC'` inside the container, this could work,
https://github.com/ansible/awx/blob/devel/awx/playbooks/project_update.yml
{
  "GIT_CONFIG_COUNT": "1",
  "GIT_CONFIG_KEY_0": "http.extraHeader",
  "GIT_CONFIG_VALUE_0": "Authorization: Basic $(printf ':$PAT' | base64)",
  "GIT_SSL_NO_VERIFY": "true"
}

https://stackoverflow.com/questions/74870052/git-config-count-git-config-key-equivalent-features-in-git-versions-2-31

TBD