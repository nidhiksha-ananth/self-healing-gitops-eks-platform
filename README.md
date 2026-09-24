# Self-Healing GitOps Platform on AWS EKS

A hands-on, end-to-end DevOps platform: infrastructure as code, containerized app,
CI/CD, GitOps deployment, and self-healing Kubernetes — built and debugged from
scratch, not copy-pasted.

> Every command in this repo was run personally; real errors hit along the way
> are documented below instead of hidden.

## Architecture

```
Developer
    │
    ▼
GitHub Repository (this repo)
    │
    ▼
GitHub Actions CI
    ├── Run tests (pytest)
    ├── Build Docker image
    ├── Scan image with Trivy (vulnerability scanning)
    └── Push image → Amazon ECR
    │
    ▼
Kubernetes (EKS / minikube)
    ├── Deployment (2 replicas, readiness + liveness probes)
    ├── Service
    └── Self-healing: pods automatically recreated on failure
```

*(ArgoCD/GitOps sync, HPA, and Prometheus/Grafana monitoring are being added next
— see Roadmap below.)*

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
  noted as a improvement).
- Worked around a minikube + containerd limitation where the standard
  `docker-env` bridge doesn't support builds; used `minikube image build` instead.

Full day-by-day command log and troubleshooting notes: see `docs/`.

## Roadmap

- [ ] ArgoCD — GitOps-driven deployment from a separate manifests repo
- [ ] Horizontal Pod Autoscaler + PodDisruptionBudget
- [ ] Prometheus + Grafana monitoring, AlertManager alerting
- [ ] AWS Cost Optimization companion project (Lambda-based auto-stop, budget alerts)

## Author

Built by Nidhiksha A — https://www.linkedin.com/in/nidhiksha-a-991a53220/
