#!/bin/bash

set -e
set -u

SURL=https://nuanceninjas.visualstudio.com
POOL=DMO-SREImages
HOSTNAME=uwinf-pvvsta003
PAT=$1

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

  printf "
  [Unit]
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
