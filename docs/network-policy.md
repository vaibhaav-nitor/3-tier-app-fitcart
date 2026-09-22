# Network Policy Setup Guide

How to restrict pod-to-pod traffic for the three-tier app (frontend, backend,
database) in a Helm chart, and which files to touch.

## 1. What we are enforcing

| Service | Who can connect to it | Port | What it may connect to |
|---|---|---|---|
| frontend | anyone (publicly accessible) | 80 | backend on 8080, DNS |
| backend | frontend only | 8080 | database on 5432, DNS |
| database | backend only | 5432 | nothing |

A NetworkPolicy chooses pods by **label**, so every pod needs labels that say
which service it is. Once a pod is selected by a policy, only the traffic that
policy lists is allowed and everything else is blocked.

## 2. Prerequisites

- **A network policy engine on the cluster** (Azure Network Policy Manager,
  Calico or Cilium). Without one the NetworkPolicy objects are accepted but
  nothing is enforced. On AKS this is set when the cluster is created; enabling
  it on an existing cluster generally means recreating it.
- The target namespace (for example `tier10app`).
- `kubectl` and `helm` access to the cluster.

## 3. Files to change

| File | Change |
|---|---|
| `values.yaml` | add `global.labels` (the shared label value) |
| `templates/_helpers.tpl` | new helper that renders `global.labels` |
| `templates/<service>.yaml` (backend, frontend, database) | add labels to the pod template |
| `templates/networkpolicy.yaml` | new file holding the three policies |

### 3.1 `values.yaml`

```yaml
global:
  labels:
    project: test-1
```

This is the only place the shared label is set. Override at deploy time with
`--set global.labels.project=<value>`.

### 3.2 `templates/_helpers.tpl`

```yaml
{{- define "app.commonLabels" -}}
{{- range $k, $v := .Values.global.labels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{- end }}
```

### 3.3 Pod labels in each service's Deployment

Add the labels under `spec.template.metadata.labels` (the pod template), not
only on the Deployment's own `metadata.labels`.

```yaml
  template:
    metadata:
      labels:
        app: backend
        tier: backend        # frontend / backend / database, differs per service
        {{- include "app.commonLabels" . | trim | nindent 8 }}
```

Do not add the new labels to `spec.selector.matchLabels` or to the Service
`selector`. The Deployment selector cannot be changed after creation, and the
new labels are not needed there.

### 3.4 `templates/networkpolicy.yaml`

```yaml
# Frontend: public on 80, talks only to the backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-frontend
  namespace: tier10app
spec:
  podSelector:
    matchLabels:
      tier: frontend
      {{- include "app.commonLabels" . | trim | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - ports:
        - protocol: TCP
          port: 80
  egress:
    - to:
        - podSelector:
            matchLabels:
              tier: backend
              {{- include "app.commonLabels" . | trim | nindent 14 }}
      ports:
        - protocol: TCP
          port: 8080
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
---
# Backend: reachable from the frontend only, talks to the database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-backend
  namespace: tier10app
spec:
  podSelector:
    matchLabels:
      tier: backend
      {{- include "app.commonLabels" . | trim | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: frontend
              {{- include "app.commonLabels" . | trim | nindent 14 }}
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              tier: database
              {{- include "app.commonLabels" . | trim | nindent 14 }}
      ports:
        - protocol: TCP
          port: 5432
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
---
# Database: reachable from the backend only, no outbound traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-database
  namespace: tier10app
spec:
  podSelector:
    matchLabels:
      tier: database
      {{- include "app.commonLabels" . | trim | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: backend
              {{- include "app.commonLabels" . | trim | nindent 14 }}
      ports:
        - protocol: TCP
          port: 5432
```

The database policy lists `Egress` with no egress rules on purpose: that denies
all outbound traffic from the database.

Ports are written directly in the policy (80, 8080, 5432). If a service uses a
different port, change it here. You can split this file at each `---` into one
file per service; Helm treats it the same way.

## 4. Steps

1. Add `global.labels` to `values.yaml`.
2. Create `templates/_helpers.tpl` with the `app.commonLabels` helper.
3. In every service template, add the `tier:` label and the `include` line to
   the pod template labels.
4. Add `templates/networkpolicy.yaml`.
5. Render and check the output:
   ```bash
   helm template <release> ./helm | grep -B2 -A6 "labels:"
   helm template <release> ./helm | grep -A12 "kind: NetworkPolicy"
   ```
   Every `matchLabels` should show `tier:` and `project: "test-1"`.
6. Deploy:
   ```bash
   helm upgrade --install <release> ./helm -n <namespace>
   ```
   Changing the pod template triggers a rolling restart of each service.

## 5. Verification

Check labels and policies:

```bash
kubectl get pods -n <namespace> --show-labels
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy test-backend -n <namespace>
```

Each pod should show `project=test-1` and its `tier=`.

Connectivity tests (requires a policy engine, see section 2):

```bash
# should WORK: frontend -> backend
kubectl exec -n <namespace> deploy/frontend -- wget -qO- --timeout=3 http://backend:8080

# should FAIL (time out): frontend -> database
kubectl exec -n <namespace> deploy/frontend -- nc -zv -w 3 <database-service> 5432

# should FAIL: an unlabelled pod -> backend
kubectl run test --rm -it --image=busybox -n <namespace> -- wget -qO- --timeout=3 http://backend:8080
```

Use the database Service name your chart creates for `<database-service>`. The
tools (`wget`, `nc`) must exist in the image you exec into; if not, use a
temporary pod that carries the frontend labels.

## 6. Troubleshooting

- **Policy has no effect:** the cluster has no policy engine, or the labels in
  the policy do not match the pod labels. Compare `--show-labels` output with
  the `podSelector` in the policy.
- **Everything is blocked, including DNS:** the DNS egress rule is missing or
  the DNS pod labels differ. The `kube-dns` label `k8s-app: kube-dns` is the AKS
  default.
- **`helm upgrade` fails on the selector:** `spec.selector.matchLabels` was
  changed. Put it back to the original value; only add labels under
  `spec.template.metadata.labels`.
- **Render fails with a nil pointer:** `global.labels` is missing from
  `values.yaml`.
- **Frontend unreachable from outside:** the frontend policy must allow ingress
  on the frontend port from any source, because load balancer traffic arrives
  from node or external IPs that cannot be matched by pod labels.
