# Metrics Server for HPA
resource "kubernetes_deployment" "metrics_server" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      k8s-app = "metrics-server"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        k8s-app = "metrics-server"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "metrics-server"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.metrics_server.metadata[0].name

        container {
          name  = "metrics-server"
          image = "registry.k8s.io/metrics-server/metrics-server:v0.7.0"

          args = [
            "--cert-dir=/tmp",
            "--secure-port=10250",
            "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
            "--kubelet-use-node-status-port",
            "--metric-resolution=15s"
          ]

          resources {
            requests = {
              cpu    = "100m"
              memory = "200Mi"
            }
          }

          port {
            name           = "https"
            container_port = 10250
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path   = "/readyz"
              port   = "https"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 0
            period_seconds        = 10
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path   = "/livez"
              port   = "https"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 0
            period_seconds        = 10
            failure_threshold     = 3
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root           = true
            run_as_user               = 1000
            seccomp_profile {
              type = "RuntimeDefault"
            }
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "tmp-dir"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "tmp-dir"
          empty_dir {}
        }

        priority_class_name = "system-cluster-critical"
      }
    }
  }

  depends_on = [aws_eks_node_group.workers]
}

resource "kubernetes_service_account" "metrics_server" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      k8s-app = "metrics-server"
    }
  }
}

resource "kubernetes_cluster_role" "metrics_server" {
  metadata {
    name = "system:metrics-server"
    labels = {
      k8s-app = "metrics-server"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/metrics"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "metrics_server" {
  metadata {
    name = "system:metrics-server"
    labels = {
      k8s-app = "metrics-server"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.metrics_server.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.metrics_server.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_service" "metrics_server" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      k8s-app = "metrics-server"
    }
  }

  spec {
    selector = {
      k8s-app = "metrics-server"
    }

    port {
      name        = "https"
      port        = 443
      protocol    = "TCP"
      target_port = "https"
    }
  }
}

resource "kubernetes_api_service" "metrics_server" {
  metadata {
    name = "v1beta1.metrics.k8s.io"
    labels = {
      k8s-app = "metrics-server"
    }
  }

  spec {
    service {
      name      = kubernetes_service.metrics_server.metadata[0].name
      namespace = "kube-system"
    }

    group                    = "metrics.k8s.io"
    version                  = "v1beta1"
    insecure_skip_tls_verify = true
    group_priority_minimum   = 100
    version_priority         = 100
  }
}
