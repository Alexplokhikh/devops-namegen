resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "auto-ebs-gp3"
  }

  storage_provisioner    = "ebs.csi.eks.amazonaws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [module.eks]
}

resource "kubernetes_secret_v1" "mongodb" {
  metadata {
    name = "mongodb-credentials"
  }

  data = {
    root-username = var.mongo_root_user
    root-password = var.mongo_root_password
    app-username  = var.mongo_app_user
    app-password  = var.mongo_app_password
    mongodb-url   = "mongodb://${var.mongo_app_user}:${var.mongo_app_password}@mongodb/namegen"
  }

  type = "Opaque"

  depends_on = [module.eks]
}

resource "kubernetes_config_map_v1" "mongodb_init" {
  metadata {
    name = "mongodb-init"
  }

  data = {
    "01-create-app-user.js" = <<-EOT
      db = db.getSiblingDB('namegen');
      db.createUser({
        user: '${var.mongo_app_user}',
        pwd: '${var.mongo_app_password}',
        roles: [{ role: 'readWrite', db: 'namegen' }]
      });
    EOT
  }

  depends_on = [module.eks]
}

resource "kubernetes_service_v1" "mongodb" {
  metadata {
    name = "mongodb"
  }

  spec {
    cluster_ip = "None"

    selector = {
      app = "mongodb"
    }

    port {
      name        = "mongodb"
      port        = 27017
      target_port = 27017
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_stateful_set_v1" "mongodb" {
  metadata {
    name = "mongodb"
  }

  spec {
    service_name = kubernetes_service_v1.mongodb.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:3.6"

          port {
            container_port = 27017
          }

          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mongodb.metadata[0].name
                key  = "root-username"
              }
            }
          }

          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mongodb.metadata[0].name
                key  = "root-password"
              }
            }
          }

          volume_mount {
            name       = "mongo-data"
            mount_path = "/data/db"
          }

          volume_mount {
            name       = "mongodb-init"
            mount_path = "/docker-entrypoint-initdb.d"
            read_only  = true
          }

          readiness_probe {
            tcp_socket {
              port = 27017
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "mongodb-init"

          config_map {
            name = kubernetes_config_map_v1.mongodb_init.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mongo-data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = kubernetes_storage_class_v1.gp3.metadata[0].name

        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_storage_class_v1.gp3]
}

resource "kubernetes_deployment_v1" "namegen" {
  metadata {
    name = "namegen"
    labels = {
      app = "namegen"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "namegen"
      }
    }

    template {
      metadata {
        labels = {
          app = "namegen"
        }
      }

      spec {
        container {
          name  = "namegen"
          image = "${module.ecr.repository_url}:${var.namegen_image_tag}"

          port {
            container_port = 8080
          }

          env {
            name = "MONGODB_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mongodb.metadata[0].name
                key  = "mongodb-url"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/api/random_name"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/api/random_name"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 15
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].image
    ]
  }

  depends_on = [kubernetes_stateful_set_v1.mongodb]
}

resource "kubernetes_service_v1" "namegen" {
  metadata {
    name = "namegen"

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
    }
  }

  spec {
    selector = {
      app = "namegen"
    }

    type                = "LoadBalancer"
    load_balancer_class = "eks.amazonaws.com/nlb"

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment_v1.namegen]
}

resource "random_password" "grafana" {
  length  = 18
  special = false
}

resource "helm_release" "monitoring" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/../k8s/monitoring/values.yaml")
  ]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.grafana.result
  }

  depends_on = [module.eks]
}
