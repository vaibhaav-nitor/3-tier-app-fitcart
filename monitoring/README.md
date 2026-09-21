# Monitoring — Prometheus & Grafana (aks-fitcart-dev)

Observability for the FitCart backend and cluster, installed as a self-contained
add-on on top of `aks-fitcart-dev`. Independent of Terraform — this is entirely
Helm/kubectl, the same layer `helm/backend` and `helm/frontend` already live in.

```
monitoring/
├── values.yaml               kube-prometheus-stack values, trimmed to fit the node
├── dashboards/
│   └── jvm-micrometer.json   backend JVM/HTTP dashboard, provisioned into Grafana
└── README.md                 this file
```

## What gets installed

The [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
Helm chart, into a new `monitoring` namespace:

| Component | Role |
|---|---|
| Prometheus Operator | manages Prometheus via CRDs (`ServiceMonitor`, etc.) |
| Prometheus | scrapes and stores metrics, 24h retention, 8Gi PVC |
| Grafana | dashboards, reached only via `kubectl port-forward` |
| kube-state-metrics | Kubernetes object state (pod status, restarts, …) |
| node-exporter | node-level CPU/memory/disk |
| Alertmanager | **disabled** — no notification channels configured yet |

`helm/backend` gets a capability-guarded `ServiceMonitor` template
(`helm/backend/templates/servicemonitor.yaml`) that only renders once both
`monitoring.enabled=true` is set on that release *and* the ServiceMonitor CRD
exists in the cluster — so `helm install`/`upgrade` on the backend chart never
breaks on a cluster where this stack hasn't been installed yet.

## Why it's sized the way it is

`aks-fitcart-dev` is a single `Standard_D2s_v3` node (~1.9 vCPU / ~5.5Gi
allocatable — see `terraform/envs/dev/dev.tfvars`), already running the
backend, frontend, and in-cluster Postgres pods at roughly 350m CPU / 850Mi
combined. The chart's own defaults assume a much bigger cluster, so
`values.yaml` here trims every component's resource requests, disables
Alertmanager, caps Prometheus retention at 24h on a small volume, and runs
Grafana without persistence (its dashboards are provisioned as code — see
below — so losing ad-hoc UI edits on a pod restart is an acceptable trade for
one less PVC).

## Installing / upgrading

Run the **"[dev] Monitoring — Install/Upgrade Prometheus & Grafana"** GitHub
Actions workflow (`workflow_dispatch`, manual). It:

1. Installs/upgrades kube-prometheus-stack with `monitoring/values.yaml`.
2. Provisions `monitoring/dashboards/jvm-micrometer.json` into Grafana via a
   labeled ConfigMap (Grafana's sidecar auto-loads anything labeled
   `grafana_dashboard: "1"` in the `monitoring` namespace).
3. Re-upgrades the existing `fitcart-backend` release with
   `--reuse-values --set monitoring.enabled=true`, so its ServiceMonitor gets
   created now that the CRD exists.

Run it once after the backend has been deployed at least once (it skips step 3
with a message otherwise — re-run after a first backend deploy).

To do the same locally:

```bash
az aks get-credentials --resource-group AZET-RG-Daas-Platform --name aks-fitcart-dev

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --version 62.7.0 \
  -f monitoring/values.yaml

kubectl create configmap fitcart-backend-dashboard \
  --from-file=jvm-micrometer.json=monitoring/dashboards/jvm-micrometer.json \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap fitcart-backend-dashboard grafana_dashboard=1 -n monitoring --overwrite

helm upgrade fitcart-backend ./helm/backend \
  --namespace fitcart \
  --reuse-values \
  --set monitoring.enabled=true
```

## Accessing Grafana and Prometheus

Both are `ClusterIP` only — no public IP, by design (this is test
infrastructure; see the plan discussion in the PR/commit this was added in).
Reach them with `kubectl port-forward`, run from any machine with `kubectl`
pointed at the cluster (your laptop after `az aks get-credentials`, or a CI
runner):

```bash
# Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
# open http://localhost:3000  —  user: admin

# password (chart-generated, never committed):
kubectl get secret kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d

# Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
# open http://localhost:9090
```

In Grafana, the backend dashboard is **FitCart Backend — JVM & HTTP**. A
default Kubernetes cluster dashboard (bundled with the chart) covers
frontend/pod-level CPU, memory, and restarts — no frontend-specific
instrumentation was added, since kubelet/cAdvisor already exposes that for
every pod.

## What the backend exposes

`backend/src/main/resources/application.yml` exposes exactly two actuator
endpoints — `health` and `prometheus` — not the full actuator surface:

```
GET http://backend:8080/actuator/prometheus
```

Scraped by the `ServiceMonitor` in `helm/backend/templates/servicemonitor.yaml`
every 30s.

## Tearing down

```bash
helm uninstall kube-prometheus-stack -n monitoring
kubectl delete namespace monitoring
```

This only removes the monitoring stack — `fitcart-backend`'s
`monitoring.enabled` value stays `true` in its release history, but its
`ServiceMonitor` template simply stops rendering on the next `helm upgrade`
once the CRD is gone (the `Capabilities.APIVersions.Has` guard), so nothing
needs to be reverted on the app side.
