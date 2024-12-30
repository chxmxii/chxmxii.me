---
title: "Certified Kubernetes Security Specialist PART I"
date: 2024-12-06
draft: false
description: "My certification notes for the CKS exam"
tags: ["certs", "kubernetes", "security", "cks"]
---
As I prepare for the **CKS** exam, I will be documenting my notes here (at the high level, I won't deep dive into the topics). This is **part I** of the series. I will be updating this post as I go along.

The CKS exam is a performance-based exam that tests your ability to secure Kubernetes clusters. The exam is 2 hours long and consists of 15-20 questions. The passing score is 66%.

For those who are interested in taking the exam, you can find more information on the CNCF website:

{{< button href="https://www.cncf.io/certification/cks" target="_self" >}}
CNCF WEBSITE
{{< /button >}}

If you're looking for a great resource to prepare for the exam, I highly recommend [Kim's course](https://www.youtube.com/watch?v=d9xfB5qaOfg&t=39920s) on Youtube. In addition to **Killercoda** which has a great [scenarios](https://killer.sh/cks) that covers all the topics in the exam.

## Cluster Setup;
### GUI Elements;
- Only expose externally when necessary. or just use `kubectl port-forward`.
- kubectl proxy;
    - Establish proxy connection between localhost and the api server. (uses kubeconfig to communicate with the api server).
    - Allows access to api locally over http.
    - `localhost -> kubectl proxy -> kubectl (https) -> k8s api`
- kubectl port-forward;
    - maps the localhostPort to the podPort.
    - `localhost -> kubectl port-forward -> kubectl -> apiserver -> podPort`
    - Install and expose the kubedashboard exteranlly (not recommended).
    ```shell
    root@localhost:~ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
    root@localhost:~ k get pod,svc -n kubernetes-dashboard
    #for external access add the following line "--insecure-port=9090" to the arg inside the deployment
    root@localhost:~ k edit -nkubernetes-dashboard dashboard
    "spec:
        containers:
        - args:
            - --namespace=kubernetes-dashboard
            - --insecure-port=9090
            image: kubernetesui/dashboard:v2.3.1"
    #Patch the service type to nodePort.
    ```
⇒ Now you should be able to access to the dashboard.

### Network Policies;
By default, pods are not isolated and able to communicate with each other.
Here when NP comes to the place;
- More like a firewall rules in kubernetes.
- Implemented by CNIs.
- Namespace-scoped.
- Allow/Deny (ingress/egress) traffic for pods based on specific criteria.
```yaml
kind: NetworkPolicy
metadata:
  name: 'example'
  namespace: 'default' # <-- policy applies to this namespace
spec:
  podSelector:
    matchLabels:
      id: 'frontend' # <-- applied to these pods as the SUBJECT/TARGET
    policyTypes:
    - Egress
    egress:

    # RULE 1.
    - to: # to AND ports i.e. id=ns1 AND port=80
      - namespaceSelector:
          matchLabels:
            id: 'ns1'
      ports:
      - protoco: 'TCP'
        port: 80

    # RULE 2.
    - to:
      - podSelector:
          matchLabels:
            id: 'backend' # <-- applies to these pods in SAME namespace where the policy lives, unless otherwise specified with a `namespaceSelector` label here.
```
Deny all ingress/egress traffic.
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  - Ingress
```
{{< alert >}} Make sure to leave DNS port 53TCP/UDP open for address resolution.{{< /alert >}}

### Secure Ingress;
- Ingress is a single entry point into the cluster, that you can configure to route to different services within your cluster based on the URL path, and SSL termination. Basically a **Layer 7 Load Balancer** managed within the cluster**.**
- Once you create the resource object, an nginx config is generated inside the nginx-controller pod which then manages the routing rules.
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
 tls:
  - hosts:
      - secure-ingress.com
    secretName: secure-ingress
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
     
# curl -vk https://secure-ingress.com:31926/service2 --resolve secure-ingress.com:31926:35.244.67.113
```
### Node Metadata Protection;
- metadata service run by provider and reachable from the VMs.
- Can house sensitive data like kubelet creds.
- Create NP to restrict access.
```yaml
root@cks-master:~# curl "http://metadata.google.internal/computeMetadata/v1/instance/disks/" -H "Metadata-Flavor: Google"
0/
root@cks-master:~ cat << EOF kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cloud-metadata-deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
EOF
```

### CIS Benchmarks;
- The CIS (Center for Internet Security) consists of the process and consists of secure configuration guidelines for many platform and systems including (kubernetes).
- You can either follow the PDF guideline or use download and execte the binary.
- FOST like kube-bench allows you to scan your kubernetes cluster for any misconfiguration.

---

## Cluster Hardening;
### Role Based Access Control;
- RBAC is the use of (Cluster)Roles,(Cluster)RoleBinding and Service Accounts to shape granual access to kubernetes resources.
- Roles defines the permissions at the namespace level, whereas clusterroles defines the permissions at the cluster level.
- (Cluster)RoleBinding defines who gets them.
- Valid combinations
|Role Type | Binding Type | Scope |
|------|-------------|------------|
| Role | RoleBinding | Namespaced |
| clusterRole | clusterRoleBinding | Cluster-wide|
|clusterRole | roleBinding | Namespaced |

- Example;
```yaml
# Create a role
$ k -n red create role secret-manager --verb=get --resource=secrets -oyaml --dry-run=client
# Create a clusterRole
$ k -n red create rolebinding secret-manager --role=secret-manager --user=jane -oyaml --dry-run=client
# check permissions
k auth can-i <verb> <resources> --as <user/sa>
```

### Service Accounts & Users;
#### Users;
- Kubernetes doesn’t manage users, instead you create a certificate && key for a specific user and assign the necessary permissions using RBAC.
    1. openssl csr from user
    2. create csr resource to k8s api
    3. k8s-api signs the csr with ca
    4. crt is then available to download
    
=> 🔒 The users “client cert” must be signed by the k8s CA, and the username will be whatever under the /CN=*usernmae* part of the cert.

{{< alert cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}It is important to know that there is no way to invalidate a cert, once created, stays valid. Hence, if cert is leaked then either remove all access via RBAC, 2/ create new CA and re-issue all certs. {{< /alert >}}

#### Service Accounts;
- ServiceAccounts are used by bots,pods created by the k8s API.
- By default, there is a default service account created on every namespace. which is then automounted to every new created pods.
- You can disable automounting of a ServiceAccount `automountServiceAccountToken: false`.

### Restrict API access;

When a request is made to the k8s-api, it goes through the followin;
- Who are you? → Authentication
- What are you allowed to do? → Authorization
- Admission controller (validating/mutating webhooks)
These requests are treated as;
- A normal user
- A serviceAccount
- Anonymous access.
{{< alert cardBackground="trasnparent" textColor="white" >}}
to disable anonymous access, set the `--anonymous-auth`flag to false with the kubelet manifest.
the `--inescure-port`is set to 0 by defaul, which disables the insecure port. (only bypasses AuthN and AuthZ mods).
{{< /alert >}}

- Do’s;
    - Don’t allow anonymous access/insecure port. (anonymous-access is needed since liveness pods need it for calling k8s api anonymously).
    - Don’t expose ApiServer to the internet.
    - Restrict access from node. (nodeRestriction).
- `k config view --raw` to view the config file. (--embed-certs for a cleaner output).

**NodeRestriction Admission Controller**;
- A common reason to enable the NodeRestriction admission plugin is to prevent the worker node from labeling the master node. to do that, you have to add the following argument to the kubeapi manifest file. `--enable-admission-plugins=NodeRestriction`.

Next up, we will be looking at microservices vulnerabilities and supply chain security.

{{< button href="https://chxmxii.me/kubernetes/Certified-Kubernetes-Security-Specialist-Part-II/index.md" target="_self" >}} Part II {{< /button >}}