# Observability Stack — monitoring and logging

unit "cloudwatch" {
  source = "tfr:///terraform-aws-modules/cloudwatch/aws//modules/log-group?version=5.6.0"
  path   = "monitoring/cloudwatch"
}

unit "prometheus" {
  source = "tfr:///terraform-aws-modules/managed-service-prometheus/aws?version=3.0.0"
  path   = "monitoring/prometheus"

  autoinclude {
    dependency "eks" {
      config_path = "../../platform/containers/eks"
    }
    inputs = {
      eks_cluster_id = dependency.eks.outputs.cluster_id
    }
  }
}
