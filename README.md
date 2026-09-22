# Day 1 — VPC + EKS (Terraform)

This provisions the networking (VPC, public/private subnets, NAT gateway)
and an EKS cluster with a small managed node group, matching Step 1 and
Step 2 of the project spec.

## Prerequisites

- AWS CLI installed and configured (`aws configure`)
- Terraform >= 1.5 installed
- kubectl installed
- An AWS Budget alert already set (do this in the console before running
  anything — Billing → Budgets)

## One-time setup (optional but recommended): remote state bucket

Real teams don't keep Terraform state on a laptop. Create an S3 bucket
once, manually, then uncomment the `backend "s3"` block in `providers.tf`:

```bash
aws s3api create-bucket \
  --bucket YOUR-UNIQUE-NAME-tf-state \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
```

Then edit `providers.tf`, uncomment the backend block, put your bucket
name in, and run `terraform init` again (it will offer to migrate state).

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit if you want
terraform init
terraform plan      # READ this output before applying — see what it will create
terraform apply
```

`terraform apply` will take **12-18 minutes** — most of that is EKS
control plane provisioning. This is normal, don't cancel it.

## Verify

```bash
aws eks update-kubeconfig --region ap-south-1 --name gitops-eks-dev
kubectl get nodes
```

You should see 2 nodes in `Ready` status.

## Cost control — READ THIS

An EKS control plane costs **~$0.10/hour (~$73/month)** if left running,
plus the EC2 node cost (2x t3.small is a few cents/hour) and a NAT
gateway (~$0.045/hour + data). None of this is huge for a few hours, but
it adds up if you forget about it.

**Destroy everything at the end of each work session:**

```bash
terraform destroy
```

Type `yes` when prompted. This removes the cluster, nodes, and VPC. Your
Terraform code stays in Git either way — you just re-run `terraform apply`
next time you sit down (another ~15 min).

## What's next (Day 2+)

- Add Metrics Server, AWS Load Balancer Controller, EBS CSI driver
  (Step 3 of the spec) — usually via Helm, in a separate `addons.tf`.
- Containerize the app and build the GitHub Actions CI pipeline.
- Install ArgoCD and wire up the GitOps flow.
