module "v4_arc_cluster" {
  source = "./modules/google-arc-v4-container-cluster"

  project_id = "tpu-pytorch"

  cluster_name = "bzmarke-test-cluster"

  cpu_nodepool_name = "cpu-nodepool"

  cpu_node_count = 1

  tpu_nodepool_name = "tpu-nodepool"

  max_tpu_nodes = 2

  github_repo_url = "https://www.github.com/mbzomowski/xla"
}
