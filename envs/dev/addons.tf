# Cluster add-ons installed via Helm as part of `terraform apply`, per the project spec.

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.3"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  depends_on = [module.platform]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.7"
  namespace        = "argocd"
  create_namespace = true

  # Expose the ArgoCD UI via the ingress controller's load balancer for easy access.
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  # ArgoCD server speaks HTTP behind the ingress; this avoids redirect loops with TLS terminated at the LB.
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [helm_release.ingress_nginx]
}

locals {
  alertmanager_config = var.slack_webhook_url == "" ? null : {
    global = {
      resolve_timeout = "5m"
      slack_api_url   = var.slack_webhook_url
    }
    route = {
      receiver = "default"
      routes = [
        {
          matchers = ["alertname = KubePodCrashLooping"]
          receiver = "slack-notifications"
        },
      ]
    }
    receivers = [
      { name = "default" },
      {
        name = "slack-notifications"
        slack_configs = [
          {
            channel       = "#alerts"
            send_resolved = true
            title         = "{{ .CommonAnnotations.summary }}"
            text          = "{{ .CommonAnnotations.description }}"
          },
        ]
      },
    ]
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "65.5.1"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      alertmanager = local.alertmanager_config == null ? {} : {
        config = local.alertmanager_config
      }
      # Keep storage requests modest for a small spot node group.
      prometheus = {
        prometheusSpec = {
          resources = {
            requests = { cpu = "100m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }
        }
      }
    })
  ]

  depends_on = [module.platform]
}
