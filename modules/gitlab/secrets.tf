resource "random_password" "gitlab_initial_root_password" {
  length  = 32
  special = true
}

resource "kubernetes_secret" "gitlab_initial_root_password" {
  metadata {
    name      = "gitlab-initial-root-password"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }

  data = {
    password = random_password.gitlab_initial_root_password.result
  }

  type = "Opaque"
}

resource "random_password" "postgresql_password" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "gitlab_postgresql_password" {
  metadata {
    name      = "gitlab-postgresql-password"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }

  data = {
    "postgresql-password"          = random_password.postgresql_password.result
    "postgresql-postgres-password" = random_password.postgresql_password.result
  }

  type = "Opaque"
}

resource "random_password" "redis_password" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "gitlab_redis_secret" {
  metadata {
    name      = "gitlab-redis-secret"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }

  data = {
    "redis-password" = random_password.redis_password.result
  }

  type = "Opaque"
}

resource "random_password" "gitaly_token" {
  length  = 64
  special = false
}

resource "kubernetes_secret" "gitlab_gitaly_secret" {
  metadata {
    name      = "gitlab-gitaly-secret"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }

  data = {
    token = random_password.gitaly_token.result
  }

  type = "Opaque"
}

resource "random_password" "shell_secret" {
  length  = 64
  special = false
}

resource "kubernetes_secret" "gitlab_shell_secret" {
  metadata {
    name      = "gitlab-shell-secret"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }

  data = {
    secret = random_password.shell_secret.result
  }

  type = "Opaque"
}

resource "random_password" "rails_secret_key_base" {
  length  = 128
  special = false
}

resource "random_password" "rails_otp_key_base" {
  length  = 128
  special = false
}

resource "random_password" "rails_db_key_base" {
  length  = 128
  special = false
}

resource "random_password" "rails_openid_connect_signing_key" {
  length  = 128
  special = false
}

resource "random_password" "rails_ci_jwt_signing_key" {
  length  = 128
  special = false
}

resource "kubernetes_secret" "gitlab_rails_secret" {
  metadata {
    name      = "gitlab-rails-secret"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }

  data = {
    "secrets.yml" = yamlencode({
      production = {
        secret_key_base                   = random_password.rails_secret_key_base.result
        otp_key_base                     = random_password.rails_otp_key_base.result
        db_key_base                      = random_password.rails_db_key_base.result
        openid_connect_signing_key       = random_password.rails_openid_connect_signing_key.result
        ci_jwt_signing_key               = random_password.rails_ci_jwt_signing_key.result
      }
    })
  }

  type = "Opaque"
}