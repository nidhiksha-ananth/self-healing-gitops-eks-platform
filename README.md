# Self-Healing GitOps Platform on AWS EKS

A hands-on, end-to-end DevOps platform: infrastructure as code, containerized app,
CI/CD, GitOps deployment, and self-healing Kubernetes — built and debugged from
scratch, not copy-pasted.

> Built while transitioning from a Helpdesk Support role into Cloud/DevOps.
> Every command in this repo was run personally; real errors hit along the way
> are documented below instead of hidden.

## Architecture

```
Developer
    │
    ▼
GitHub Repository (app code — this repo)
    │
    ▼
GitHub Actions CI
    ├── Run tests (pytest)
    ├── Build Docker image
    ├── Scan image with Trivy (vulnerability scanning)
    └── Push image → Amazon ECR
    │
    ▼
GitHub Repository (gitops-eks-manifests — separate repo, deployment config)
    │
    ▼
ArgoCD (watches the manifests repo, auto-syncs on every commit)
    │
    ▼
Kubernetes (EKS / minikube)
    ├── Deployment (readiness + liveness probes)
    ├── Service
    ├── Self-healing at 2 levels:
    │     • Kubernetes: pods automatically recreated on failure
    │     • ArgoCD: manual cluster drift automatically reverted to match Git
    └── Rollback: reverting a Git commit reverts the live deployment
```

*(HPA and Prometheus/Grafana monitoring are being added next — see Roadmap below.)*

## Tech Stack

| Layer | Tools |
|---|---|
| Infrastructure as Code | Terraform, `terraform-aws-modules` (VPC, EKS) |
| Cloud | AWS (VPC, EKS, ECR, IAM) |
| Containers | Docker |
| Orchestration | Kubernetes (EKS for production-parity, minikube for local dev) |
| CI/CD | GitHub Actions |
| Security scanning | Trivy (container vulnerability scanning) |
| App | Python (Flask) |

## What This Demonstrates

- **Infrastructure as Code** — VPC (public/private subnets, NAT gateway), EKS cluster, and node
  group fully provisioned via Terraform using community modules.
- **Containerization** — Flask API packaged with a security-conscious Dockerfile
  (non-root user, health check, gunicorn instead of the dev server).
- **CI/CD pipeline** — every push runs tests, builds the image, scans it for
  vulnerabilities with Trivy, and pushes to Amazon ECR.
- **Kubernetes self-healing** — readiness/liveness probes wired to a `/health`
  endpoint; verified live by deleting a running pod and watching Kubernetes
  automatically recreate it to match the desired replica count.
- **GitOps with ArgoCD** — deployment config lives in a [separate manifests
  repo](https://github.com/nidhiksha-ananth/gitops-eks-manifests), watched and
  auto-synced by ArgoCD. No manual `kubectl apply` after initial setup.
- **GitOps rollback** — reverting a Git commit (`git revert`) automatically
  reverts the live deployment; verified end-to-end.
- **GitOps self-heal (drift correction)** — manually changing the cluster
  outside of Git is automatically detected and reverted by ArgoCD within
  seconds, keeping Git as the single source of truth.
- **Cost-conscious cloud practice** — infrastructure is destroyed after every
  session (`terraform destroy`) and verified clean via AWS CLI, with local
  minikube used for iteration to avoid unnecessary cloud spend.

## Repository Structure

```
.
├── app/                      # Flask Task API
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── tests/
├── k8s-manifests/            # Kubernetes Deployment + Service
├── .github/workflows/ci.yml  # CI/CD pipeline
├── vpc.tf, eks.tf, ecr.tf     # Terraform infrastructure
└── docs/                     # Notes, screenshots, troubleshooting log
```

## Running It Yourself

**Infrastructure:**
```bash
cd terraform-dir-name-here   # wherever the .tf files live in this repo
terraform init
terraform apply
```

**App, locally on minikube:**
```bash
minikube start --driver=docker
minikube image build -t task-api:local ./app
kubectl apply -f k8s-manifests/deployment.yaml
kubectl apply -f k8s-manifests/service.yaml
kubectl port-forward service/task-api 8080:80
curl http://localhost:8080/health
```

**Try the self-healing behavior yourself:**
```bash
kubectl get pods
kubectl delete pod <any-pod-name-from-above>
kubectl get pods -w   # watch a replacement appear automatically
```

## Real Issues Hit & Fixed (not a smooth tutorial run)

- Deprecated EKS Kubernetes version blocked new node group creation; learned EKS
  only allows sequential minor-version upgrades, not direct jumps — rebuilt clean
  on a supported version.
- A pinned GitHub Action (`trivy-action`) became unresolvable due to a real
  supply-chain security incident affecting older tags — repinned to a version
  the maintainers confirmed safe post-incident.
- Found a real bug: in-memory app state doesn't persist correctly across multiple
  Kubernetes replicas, since the Service load-balances across pods with separate
  memory — confirmed the fix requires externalizing state (not implemented yet,
  noted as an improvement).
- Worked around a minikube + containerd limitation where the standard
  `docker-env` bridge doesn't support builds; used `minikube image build` instead.
- ArgoCD reported "Synced" against the correct Git commit, but a config change
  never actually applied to the cluster. Systematically ruled out Git content,
  ArgoCD's tracked revision, HPA conflicts, PVC caching, and three separate
  internal ArgoCD caches (repo-server, Redis, application-controller) before
  finding the real cause: `service.yaml` had accidentally been created as a
  duplicate Deployment manifest instead of an actual Service — confirmed via
  ArgoCD's own "RepeatedResourceWarning," initially dismissed as cosmetic.
- ArgoCD's default Helm install (7 pods) was too heavy for an 8GB machine,
  causing `repo-server` to CrashLoopBackOff from failed health checks under
  memory pressure. Fixed with a custom Helm values file disabling unused
  components and setting explicit resource limits — 5 pods, 0 restarts.

Full day-by-day command log and troubleshooting notes: see `docs/`.

## Roadmap

- [x] ArgoCD — GitOps-driven deployment from a separate manifests repo
- [ ] Horizontal Pod Autoscaler + PodDisruptionBudget
- [ ] Prometheus + Grafana monitoring, AlertManager alerting
- [ ] AWS Cost Optimization companion project (Lambda-based auto-stop, budget alerts)

## Author

Built by [Your Name] — [LinkedIn link] — transitioning into Cloud/DevOps from a
Helpdesk Support background.
