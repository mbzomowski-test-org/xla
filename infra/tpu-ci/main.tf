module "v4_arc_cluster" {
  source = "./modules/arc-v4-container-cluster"
  project_id = "tpu-pytorch"
  cluster_name = "tpu-pytorch-tpu-ci"
  cpu_nodepool_name = "cpu-nodepool"
  cpu_node_count = 1
  tpu_nodepool_name = "tpu-nodepool"
  max_tpu_nodes = 1
  github_repo_url = "https://github.com/pytorch/xla"
  runner_image =  "gcr.io/tpu-pytorch/tpu-ci-runner:latest"
}
