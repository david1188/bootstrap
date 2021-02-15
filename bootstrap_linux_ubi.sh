#!/bin/bash

set -e
set -u

SURL=https://nuanceninjas.visualstudio.com
POOL=DMO-SREImages
HOSTNAME=${HOSTNAME}
PAT=$1


declare -a dirs
dirs=(/opt/agent
      /opt/packer
      /opt/packer_plugins
      /home/dragonadmin/.packer.d/plugins
)

function handle_source_dirs() {
for dir in ${dirs[@]}
  do
    if [[ ! -d ${dir} ]];
      then
        sudo /bin/mkdir -p ${dir}
    else
        sudo /bin/rm -r ${dir} && sudo /bin/mkdir -p ${dir}
    fi
  done
}

function download_agent_installer() {
  agent_url="https://vstsagentpackage.azureedge.net/agent/2.181.1/vsts-agent-linux-x64-2.181.1.tar.gz"

  /usr/bin/wget ${agent_url} -P /opt/agent
}

function decompress() {
  /bin/tar -xvzf /opt/agent/vsts-agent-linux-x64-2.181.1.tar.gz -C /opt/agent
  /bin/chown -R root. /opt/agent
  /bin/chmod -R 777 /opt/agent
}
function deploy_agent() {
  runuser -l dragonadmin -c "/opt/agent/config.sh --unattended --url ${SURL} --auth pat --token ${PAT} --pool ${POOL} --agent ${HOSTNAME} --work _work --acceptTeeEula"
}

function configure_agent() {
  cd /opt/agent
  #/bin/bash /opt/agent/svc.sh install
  /bin/bash svc.sh install

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

  /bin/systemctl enable vsts.agent.nuanceninjas.PackerAgent.service
  /bin/systemctl start vsts.agent.nuanceninjas.PackerAgent.service
}

function install_packer() {
  packer_installer="https://releases.hashicorp.com/packer/1.6.6/packer_1.6.6_linux_amd64.zip"

  /usr/bin/apt-get install unzip -y
  /usr/bin/wget ${packer_installer} -O /opt/packer/packer_amd64.zip
  /usr/bin/unzip /opt/packer/packer_amd64.zip -d /opt/packer
  /bin/cp /opt/packer/packer /bin/
  /bin/packer version
}

function deploy_packer_plugins() {
  packer_plugins="https://github.com/rgl/packer-provisioner-windows-update/releases/download/v0.10.1/packer-provisioner-windows-update_0.10.1_linux_amd64.tar.gz"

  /usr/bin/wget ${packer_plugins} -O /opt/packer_plugins/win_update.tar.gz
  /bin/tar -xvzf /opt/packer_plugins/win_update.tar.gz -C /home/dragonadmin/.packer.d/plugins
  /bin/chmod -R 777 /home/dragonadmin/.packer.d/plugins
}

function auto_updates() {
  /usr/bin/apt-get install unattended-upgrades
  printf "APT::Periodic::AutocleanInterval "7";\n" >> /etc/apt/apt.conf.d/20auto-upgrades
}

echo -e '## Create sources ##'
handle_source_dirs

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
