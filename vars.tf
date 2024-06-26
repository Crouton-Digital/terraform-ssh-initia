variable "ssh_host_ip" {}
variable "ssh_host_port" {}
variable "ssh_host_user" {}
variable "ssh_host_private_key_file" {
  default = "~/.ssh/id_rsa"
}

variable "go_version" {}
variable "node_version" {}
variable "node_chainid" {
  default = "initiation-1"
}
variable "node_type" {
  default = "testnet"
}
variable "enable_snapshot_recovery" {
  default = "true"
}

variable "enable_rpc_open" {
  default = "127.0.0.1"
}
variable "enable_service_api" {
  default = "false"
}
variable "enable_service_grpc" {
  default = "false"
}
variable "enable_service_grpc_web" {
  default = "false"
}
variable "enable_service_json_rpc" {
  default = "false"
}
variable "minimum-gas-prices" {
  default = "false"
}

variable "pruning_indexer_enable" {
  default = "null"
}
variable "pruning_type" {
  default = "custom"
}
variable "pruning_keep_recent" {
  default = "100"
}
variable "pruning_keep_every" {
  default = "0"
}
variable "pruning_interval" {
  default = "17"
}
variable "pruning_snapshot_interval" {
  default = "100"
}

locals {

  install_update_packages =<<EOT
. ~/.bash_profile
sudo apt update && sudo apt upgrade -y && \
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop screen unzip bc fail2ban htop lz4 -y
EOT

install_go =<<EOT
. ~/.bash_profile
cd ~
! [ -x "$(command -v go)" ] && {
  VER="${var.go_version}"
  wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
  rm "go$VER.linux-amd64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
}
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
. ~/.bash_profile
go version
EOT

install_app = <<EOT
. ~/.bash_profile
cd $HOME
rm -rf initia
git clone https://github.com/initia-labs/initia.git initia
cd initia
git checkout ${ var.node_version }
make install
initiad version --long | grep -e version -e commit

EOT


  init_node = <<EOT
. ~/.bash_profile
initiad init VALIDATOR_NAME --chain-id ${var.node_chainid} && \
initiad config set client chain-id ${var.node_chainid} && \
initiad config set client keyring-backend test

wget https://storage.crouton.digital/${var.node_type}/initia/files/genesis.json -O $HOME/.initia/config/genesis.json
wget https://storage.crouton.digital/${var.node_type}/initia/files/addrbook.json -O $HOME/.initia/config/addrbook.json

EXTERNAL_IP=$(wget -qO- eth0.me)

sed -i.bak \
    -e "s/\(proxy_app = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$((1 + 266))58\"/" \
    -e "s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$((1 + 266))57\"/" \
    -e "s/\(pprof_laddr = \"\)\([^:]*\):\([0-9]*\).*/\1localhost:$((1 + 60))60\"/" \
    -e "/\[p2p\]/,/^\[/{s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$((1 + 266))56\"/}" \
    -e "/\[p2p\]/,/^\[/{s/\(external_address = \"\)\([^:]*\):\([0-9]*\).*/\1$${EXTERNAL_IP}:$((1 + 266))56\"/; t; s/\(external_address = \"\).*/\1$${EXTERNAL_IP}:$((1 + 266))56\"/}" \
    -e "s/\(prometheus_listen_addr = \":\)\([0-9]*\).*/\1$((1 + 266))60\"/"                            $HOME/.initia/config/config.toml

sed -i.bak \
    -e "/\[api\]/,/^\[/{s/\(address = \"tcp:\/\/\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$((1 + 13))17\4/}" \
    -e "/\[grpc\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$((1 + 90))90\4/}" \
    -e "/\[grpc-web\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$((1 + 90))91\4/}" \
    -e "/\[json-rpc\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$((1 + 85))45\4/}" \
    -e "/\[json-rpc\]/,/^\[/{s/\(ws-address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$((1 + 85))46\4/}"  $HOME/.initia/config/app.toml

echo "export NODE=http://localhost:$((1+266))57" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
initiad config set client node $NODE

sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=initia_node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which initiad) start --home $HOME/.initia
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

EOT


restart_service = <<EOT
. ~/.bash_profile
sudo systemctl daemon-reload && \
sudo systemctl enable initiad && \
sudo systemctl restart initiad
EOT

  web_service = <<EOT
. ~/.bash_profile
sed -i.bak -e "/^\[rpc\]/,/^laddr =/s|laddr = \"tcp://127\.0\.0\.1:|laddr = \"tcp://${var.enable_rpc_open}:|"        $HOME/.initia/config/config.toml
sed -i.bak -e "/^\[api\]/,/^enable/s|^enable *=.*|enable = '${var.enable_service_api}'|"                                    $HOME/.initia/config/app.toml
sed -i.bak -e "/^\[grpc\]/,/^enable/s|^enable *=.*|enable = '${var.enable_service_grpc}'|"                                   $HOME/.initia/config/app.toml
sed -i.bak -e "/^\[grpc-web\]/,/^enable/s|^enable *=.*|enable = '${var.enable_service_grpc_web}'|"                               $HOME/.initia/config/app.toml
sed -i.bak -e "/^\[json-rpc\]/,/^enable/s|^enable *=.*|enable = '${var.enable_service_json_rpc}'|"                               $HOME/.initia/config/app.toml
sed -i.bak -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = '${var.minimum-gas-prices}'|"                           $HOME/.initia/config/app.toml
EOT


  pruning_setting = <<EOT
. ~/.bash_profile
sed -i.bak -e "s/^indexer *=.*/indexer = \"${var.pruning_indexer_enable}\"/"                                                     $HOME/.initia/config/config.toml
sed -i.bak -e "s/^pruning *=.*/pruning = \"${var.pruning_type}\"/"                                                   $HOME/.initia/config/app.toml
sed -i.bak -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"${var.pruning_keep_recent}\"/"                              $HOME/.initia/config/app.toml
sed -i.bak -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"${var.pruning_keep_every}\"/"                                  $HOME/.initia/config/app.toml
sed -i.bak -e "s/^pruning-interval *=.*/pruning-interval = \"${var.pruning_interval}\"/"                                     $HOME/.initia/config/app.toml
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"${var.pruning_snapshot_interval}\"/"                                  $HOME/.initia/config/app.toml
EOT

snapshot_node = <<EOT
. ~/.bash_profile
sudo systemctl stop initiad
cp $HOME/.initia/data/priv_validator_state.json $HOME/.initia/priv_validator_state.json.backup
rm -rf $HOME/.initia/data
curl https://storage.crouton.digital/${var.node_type}/initia/snapshots/initia_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.initia
mv $HOME/.initia/priv_validator_state.json.backup $HOME/.initia/data/priv_validator_state.json

sudo systemctl restart initiad

EOT



  info = <<EOT
For read  logs: sudo journalctl -u initiad -f
For aditional info, please read docs: https://crouton.digital/services/testnets/initia

EOT

}