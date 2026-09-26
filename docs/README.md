# Project Documentation

This folder holds supporting evidence for the main project README: screenshots taken while
building each day of the project, plus a short explanation of what each one shows.

## Contents

- `screenshots/` &mdash; key screenshots from the build, referenced in the main README

## The full story

The main [README](../README.md) covers the architecture and what was built. The highlights below
are the moments most worth a closer look:

1. **ArgoCD, Healthy & Synced** (`argocd-healthy-synced.png`) &mdash; the GitOps loop working:
   ArgoCD watching a separate manifests repo and keeping the cluster in sync with it automatically.
2. **HPA autoscaling live** (`hpa-autoscaling-live.png`) &mdash; a full cause-and-effect sequence
   captured in one terminal session: CPU load generated synthetically, HPA scaling replicas from
   2 to 4 as the 70% CPU threshold was crossed, then scaling back down once load stopped.
3. **Grafana dashboard, recording its own test** (`grafana-dashboard-hpa-scaling.png`) &mdash; the
   monitoring stack's own resource-count graph shows a visible step-change during the HPA test
   above, confirming the observability pipeline was capturing real, accurate cluster activity
   rather than static numbers.

## Notable debugging along the way

- An EKS cluster version aged out of support mid-build, and a follow-up attempt to jump straight
  to a newer version failed too, since EKS only allows sequential minor-version upgrades.
- A pinned GitHub Action (`trivy-action`) became unresolvable due to a real supply-chain security
  incident affecting its older release tags.
- The hardest bug of the project: ArgoCD reported a deployment as "Synced" against the correct Git
  commit, but a replica count change never actually applied to the cluster. After systematically
  ruling out Git content, ArgoCD's tracked revision, HPA conflicts, PVC caching, and three separate
  internal ArgoCD caches, the real cause turned out to be a manifest file that had accidentally
  been created as a duplicate Deployment definition instead of an actual Service &mdash; something
  ArgoCD had actually been warning about the whole time, initially dismissed as cosmetic.

Full command-by-command notes are kept locally as part of the project's build log.
