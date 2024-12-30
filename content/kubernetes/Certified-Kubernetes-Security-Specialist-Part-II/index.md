---
title: "Certified Kubernetes Security Specialist PART II"
date: 2024-12-06
draft: false
description: "My certification notes for the CKS exam"
tags: ["certs", "kubernetes", "security"]
---
Continuing from [part I](https://chxmxii.me/kubernetes/Certified-Kubernetes-Security-Specialist-Part-I/index.md). This is **part II** of the CKS exam preparation series, where I will be exploring more topics related to securing Kubernetes clusters.

## Microservices vulnerabilities;
### Manage Kubernetes Secrets;
- **Encrypt ETCD at rest;**
    - The only compoentn allowed to talk to ETCD is kube-api, hence it is responsible for encrypt/decrypt in this flow.
    - To enable encryption at rest for a specific resource create a new api object with kind `EncryptionConfiguration.`
    
    ```bash
    # generate a key using the followin cmd $( head -c 32 /dev/urandom | base64)
    apiVersion: apiserver.config.k8s.io/v1
    kind: EncryptionConfiguration
    resources:
      - resources:
        - secrets
        providers:
        - aescbc:
            keys:
            - name: key1
              secret: ffGddeJabcKMocX07jGu1hcL8bdggjH2PSIs24=
        - identity: {} #this is important to get etcd working with unencrypted secrets
    ```
    
    ```yaml
    #update the kube-apiserver.yaml manifest to include the provider config:
    #add the arg
    spec:
      containers:
      - command:
        - kube-apiserver
        - --encryption-provider-config=/etc/kubernetes/etcd/encEtcd.yaml
    #add the volume mount;
    ...
      volumeMounts:
      - mountPath: /etc/kubernetes/etcd
        name: etcd
    # add volume;
      volumes:
      - hostPath:
          path: /etc/kubernetes/etcd
          type: DirectoryOrCreate
        name: etcd
    ```
    
{{< alert cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee"  >}}
if you need to troubleshoot you can go through the logs within the /var/log/pods dir.
{{< /alert >}}    

### Container runtimes sandboxing;
- Containers are run on a shared kernel, which enables us to execute syscalls (api-like to com w/kernel) that allow us to access other containers.
- Sandboxes in the security context is an additional layer to ensure isolation.
- Sandboxes comes at a price (more resc, bad 4 heavy syscalls..).

#### kata containers;

- container runtime sandbox (Hypervisor/VM based).

#### gVisor;

- a userspace kernel for containers from google.
- Interrupts to limit the syscalls sent by the user (app1↔syscalls↔gvisor↔limited syscalls↔host kernel ↔hw)

```yaml
apiVersion: node.k8s.io/v1  # RuntimeClass is defined in the node.k8s.io API group
kind: RuntimeClass 
metadata:   # RuntimeClass is a non-namespaced resource
  name: gvisor # The name the RuntimeClass will be referenced by
handler: runsc # The name of the corresponding CRI configuration
---
...
kind: Pod
#Next time you create a new pod make sure to include the runtimeClassName
spec: 
	runtimeClassName: gvisor
	containers:
	..
```
### OS level domains;
#### Pod Security Contenxt;
- controls uid,gi at the pod/container level.

```yaml
spec:
    #pod level
    securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    containers:
    - command:
    ...
    ...
        #container level
    securityContext:
        runAsNonRoot: true
    dnsPolicy: ClusterFirst
```
    
#### Privileged;
- maps container user with the host user (root).
enable w/docker `d run --privileged`
    
```yaml
spec:
    containers:
    - command:
    ...
    ...
    securityContext:
        privileged: true
```
        
#### Privilege Escalation;
- by default, k8s allows privesc via `allowPrivilegeEscalation`, to disable set to false within the **securityContext** field.
```yaml
spec:
    containers:
    - command:
    ...
    ...
    securityContext:
        allowPrivilegeEscalation: false
```

#### Pod Security Policies;

- Enable via kube-apiserver manifest file `--enable-admission-plugins=NodeRestriction,PodSecurityPolicy.`

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
    name: default
spec:
    privileged: false  # Don't allow privileged pods!
    allowPrivilegeEscalation: false # added
    # The rest fills in some required fields.
    seLinux:
    rule: RunAsAny
    supplementalGroups:
    rule: RunAsAny
    runAsUser:
    rule: RunAsAny
    fsGroup:
    rule: RunAsAny
    volumes:
    - '*'
```
        
{{< alert cardColor="#757C88" iconColor="#1d3557" textColor="white"  >}}        
if psp is enabled, then it will be enforced on all resources. but the creator of the resource requires to see this default psp to use it.
a common approach to solve the problem (when creating a deploy is failed cuz the deploy resource doesn’t have admin perms to read the psp to create the resource) is to give the default sa to the psp.
`k create role psp-access --verb=use --resource=podsecuritypolicies`
`k create rolebinding psp-access --role=psp-access --serviceaccount=default:default`
{{< /alert >}}

### mTLS;

- mutual auth
- pod2pod encrypted communication
- both apps have client+server certs to communicate.

#### Service Meshes;

- manage all the certs between pods.
- decouple our app container from the auth/cert workload.
- all traffic is routed through a proxy/sidecar.

⇒ These routes are creates via `iptable` rules. the sidecar will needs the NET_ADMIN cap.

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: app
  name: app
spec:
  containers:
  - command:
    - sh
    - -c
    - ping google.com
    image: bash
    name: app
    resources: {}
  - command:
    - sh
    - -c
    - 'apt-get update && apt-get install -y iptables && iptables -L && sleep 1d'
    securityContext:
      capabilities:
        add: ["NET_ADMIN"] #important for the proxy container
    image: ubuntu
    name: proxy
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

## Supply chain security;

### Image Footprint

- Reduce footprint by using multistage dockerfile.
- This will eventually reduce the size of our final image.

```Dockerfile
# build stage (0)
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go
COPY app.go .
RUN CGO_ENABLED=0 go build app.go

# runtime stage
FROM alpine
COPY --from=0 /app .
CMD ["./app"]
```
  
- We can make this more secure by;
    - using a specific versions of images. (stay away from latest/default). **A**
    - avoiding runing with the root container. **B**
    - make fs RO. **C**
    - remove shell access **D**
    

```Dockerfile
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go
COPY app.go .
RUN CGO_ENABLED=0 go build app.go

# runtime stage
FROM alpine:3.12.1 (A)
RUN chmod a-w /etc (C)
RUN addgroup -S appgroup && adduser -G appgroup -h /home/appuser (B)
RUN rm -fr /bin/* (D)
COPY --from=0 /app /home/appuser/
USER appuser (B)
CMD ["/home/appuser/app"]
```
    

### Image Vulnerability Scanning

- Containers that contains exploitable packages are a problem, this could result in privesc, data leaks, ddos etc..
- Keeping an eye on your image safety is very important, so is good to do a check during the build and run time. (scan the registry when image is pushed, enforce at deploy time using OPA).
- tools;
    - Clair: opensorce vuln assessment tool, CNCF supported.
    - trivy: simple to use, one cmd to run it;

    `$ docker run ghcr.io/aquasecurity/trivy:latest image nginx`

### Static Analysis

- look at the source code and text files and parses them to check against rules and later enforce them, eg;
    - define requests & limits
    - never use sa default
    - never store sensitive data in plain text in dockerfiles or k8s resources.
- When to do the SA? for a good coverage it is recommened to do it;
    - before commiting
    - before build
    - during test phase
    - at the deploy phase using admission controller like OPA.
- **Manual approach;**
    - Simply by going through the source code and the text files.
- **Tools;**
    - **kubesec.io**;
        - opensource
        - does a score and recommend improvements
        - simple to use; `docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < ./pod.yaml`
    - **OPA conftest**;
        - Used against dockerfiles
        - Offered by OPA (uses same languge rego).
        - run using the followin cmd; `docker run --rm -v $(pwd):/project openpolicyagent/conftest test Dockerfile --all-namespaces`
        - examples;
            
            ```go
            # from https://www.conftest.dev
            package main
            
            denylist = [
              "ubuntu"
            ]
            
            deny[msg] {
              input[i].Cmd == "from"
              val := input[i].Value
              contains(val[i], denylist[_])
            
              msg = sprintf("unallowed image found %s", [val])
            }
            ---
            package commands
            
            denylist = [
              "apk",
              "apt",
              "pip",
              "curl",
              "wget",
            ]
            
            deny[msg] {
              input[i].Cmd == "run"
              val := input[i].Value
              contains(val[_], denylist[_])
            
              msg = sprintf("unallowed commands found %s", [val])
            }
            ```

### Secure Supply Chain

Secure supply chain helps us ensure that the images, libs, and other dependencies we use are safe and free from vulnerabilities.

### K8S & Container Regisitires;

- **PrivateRegistires**; create a `docker-registry` secret in kubernetes and then associate the `imagePullSecrets` to the SA.
- Container images can be run using image digest instead of a tag. e.g;
    
    ```yaml
      containerStatuses:
      - containerID: containerd://87cf84840ab758c375988491da7e71bb8c78ea435d92ccb41fe05aae19d62eae
        image: k8s.gcr.io/kube-apiserver:v1.20.2
        imageID: sha256:3ad0575b6f10437a84a59522bb4489aa88312bfde6c766ace295342bbc179d49
    ```
    

### AllowList Registries w/OPA;

- You could use OPA to limit images to specific repos.
- Constraint Templates;
    
    ```yaml
    apiVersion: templates.gatekeeper.sh/v1beta1
    kind: ConstraintTemplate
    metadata:
      name: k8strustedimages
    spec:
      crd:
        spec:
          names:
            kind: K8sTrustedImages
      targets:
        - target: admission.k8s.gatekeeper.sh
          rego: |
            package k8strustedimages
    				#if all conds are true, then violation is thrown && the pod creation is denied.
            violation[{"msg": msg}] {
              image := input.review.object.spec.containers[_].image
              not startswith(image, "docker.io/") 
              not startswith(image, "k8s.gcr.io/")
              msg := "not trusted image!"
            }
    ```
    
    ```yaml
    apiVersion: constraints.gatekeeper.sh/v1beta1
    kind: K8sTrustedImages
    metadata:
      name: pod-trusted-images
    spec:
      match:
        kinds:
          - apiGroups: [""]
            kinds: ["Pod"]
    ```
    

### ImagePolicyWebhook;

`ApiServer` ↔ `AdmissionContollers` ↔ `ImagePolicyWebhook` ↔ `External Service`

- `ImagePolicyWebhook` creates a kind of `ImageReview` which can be assessed by an external tool as part of an admission workflow.
- You can enable the imagePolicyWebhook via the kube-api manifest;
    - `--enable-admission-plugins=ImagePolicyWebhook`
    - Create a dir to house all ur admission conf. /etc/kuberentes/admision.
    - `--admission-control-config-file=path-to-admission-config.`
    - add hostPath and **volumeMount** to mount the **admissionDir** so all your config files are available within the container.
    
    ```yaml
    apiVersion: apiserver.config.k8s.io/v1
    kind: AdmissionConfiguration
    plugins:
      - name: ImagePolicyWebhook
        configuration:
          imagePolicy:
            kubeConfigFile: /etc/kubernetes/admission/kubeconf
            allowTTL: 50
            denyTTL: 50
            retryBackoff: 500
            defaultAllow: false # important: if `true`, then if policy webhook can't be reached will just allow the image.
    ```
    
    kubeconf e.g;
    
    ```yaml
    apiVersion: v1
    kind: Config
    
    # clusters refers to the remote service.
    clusters:
    - cluster:
        certificate-authority: /etc/kubernetes/admission/external-cert.pem  # CA for verifying the remote service.
        server: https://external-service:1234/check-image                   # URL of remote service to query. Must use 'https'.
      name: image-checker
    
    contexts:
    - context:
        cluster: image-checker
        user: api-server
      name: image-checker
    current-context: image-checker
    preferences: {}
    
    # users refers to the API server's webhook configuration.
    users:
    - name: api-server
      user:
        client-certificate: /etc/kubernetes/admission/apiserver-client-cert.pem     # cert for the webhook admission controller to use
        client-key:  /etc/kubernetes/admission/apiserver-client-key.pem             # key matching the cert
    ```
