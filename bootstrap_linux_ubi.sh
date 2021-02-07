#!/bin/bash

set -e
set -u

SURL=https://nuanceninjas.visualstudio.com
POOL=DMO-SREImages
HOSTNAME=uwinf-pvvsta003
PAT=$1

function auto_updates() {
  sudo apt install unattended-upgrades

  printf "APT::Periodic::AutocleanInterval "7";\n" >> /etc/apt/apt.conf.d/20auto-upgrades
}

function remove_source() {
  if [ -d '/opt/agent' ]; then
    sudo rm -r /opt/agent
  fi
}

function download_agent_installer() {
  sudo mkdir -p /opt/agent
  wget https://vstsagentpackage.azureedge.net/agent/2.181.1/vsts-agent-linux-x64-2.181.1.tar.gz -P /opt/agent
}

function decompress() {
  cd /opt/agent
  /bin/tar -xvzf /opt/agent/vsts-agent-linux-x64-2.181.1.tar.gz
  chown -R root. /opt/agent
  chmod -R 777 /opt/agent
}
function deploy_agent() {
  runuser -l dragonadmin -c "/opt/agent/config.sh --unattended --url ${SURL} --auth pat --token ${PAT} --pool ${POOL} --agent ${HOSTNAME} --work _work --acceptTeeEula"
}

function configure_agent() {
  cd /opt/agent
  bash svc.sh install

  printf "[Unit]
Description=Azure Pipelines Agent (nuanceninjas.DMO-SREImages.PackerAgent)
After=network.target

[Service]
ExecStart=/opt/agent/runsvc.sh
User=dragonadmin
WorkingDirectory=/opt/agent
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=5min

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/vsts.agent.nuanceninjas.PackerAgent.service

  systemctl enable vsts.agent.nuanceninjas.PackerAgent.service
  systemctl start vsts.agent.nuanceninjas.PackerAgent.service
}

function install_packer() {
#  export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
#  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
  apt-get install unzip -y
  mkdir /opt/packer
  wget https://releases.hashicorp.com/packer/1.6.6/packer_1.6.6_linux_amd64.zip -P /opt/packer
  unzip /opt/packer/packer_1.6.6_linux_amd64.zip -d /opt/packer
  cp /opt/packer/packer /bin/
#  sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
#  sudo apt-get update && sudo apt-get install packer -y
#  runuser -l dragonadmin -c "packer version"
   /bin/packer version
}

function deploy_packer_plugins() {
#  curl -fssL https://github.com/rgl/packer-provisioner-windows-update/releases/download/v0.10.1/packer-provisioner-windows-update_0.10.1_linux_amd64.tar.gz --create-dirs /otp/packer_plugins --output /opt/packer_plugins/win_update.tar.gz
  mkdir /home/dragonadmin/.packer.d
  mkdir /opt/packer_plugins
  wget https://github.com/rgl/packer-provisioner-windows-update/releases/download/v0.10.1/packer-provisioner-windows-update_0.10.1_linux_amd64.tar.gz -O /opt/packer_plugins/win_update.tar.gz
  tar -xvzf /opt/packer_plugins/win_update.tar.gz -C /home/dragonadmin/.packer.d
}

echo -e '## Remove sources ##'
remove_source

echo -e '## Download agent isntaller ##'
download_agent_installer

echo -e '## Decompress installer ##'
decompress

echo -e '## Deploy build agent ##'
deploy_agent

echo -e '## Configure build agent ##'
configure_agent

echo -e '## Install packer ##'
install_packer

echo -e '## Deploy packer plugins ##'
deploy_packer_plugins

echo -e '## Setup auto updates ##'
auto_updates
