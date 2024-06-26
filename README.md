# terraform-ssh-initia
Deploy celestia node on VM


## Requirements to configure a initia node

* Suggested hardware requirements:
   * CPU: 8 physical cores / 16 vCPUs
   * RAM: 128 GB
   * Storage (SSD): 4 TB NVMe drive


## Deploy initia-node


### Prepare terraform directory structure and deploy 

Example files you can take: 
```bash
git clone https://github.com/Crouton-Digital/terraform-ssh-initia.git
cd terraform-ssh-celestia/examples/initia-node
```

Example how to use module: 
```yaml
module "initia-node" {
        #  source          = "../../"
  source         = "Crouton-Digital/initia/ssh"
  version        = "0.0.1" # Set last module version

  ssh_host_ip   = "95.217.177.***"
  ssh_host_port = "22"
  ssh_host_user = "root"
  ssh_host_private_key_file = "~/.ssh/id_rsa"

  go_version       = "1.22.0"
  node_version     = "v0.2.21"
  node_type        = "testnet" # testnet | mainnet
  node_chainid     = "initiation-1"

  enable_snapshot_recovery = "true"

  enable_rpc_open         = "127.0.0.1"
  enable_service_api      = "false"
  enable_service_grpc     = "false"
  enable_service_grpc_web = "false"
  enable_service_json_rpc = "false"
  minimum-gas-prices      = "0.001uinit"

  pruning_indexer_enable    = "null"
  pruning_type              = "custom"
  pruning_keep_recent       = "100"
  pruning_keep_every        = "0"
  pruning_interval          = "17"
  pruning_snapshot_interval = "100"

}

  output "info" {
  value = module.initia-node.info
}
```

```bash
$ terraform init
$ terraform plan
$ terraform apply

$ terraform output 
```
