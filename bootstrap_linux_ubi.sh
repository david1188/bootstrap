#!/bin/bash

set -e
set -u

SURL=https://nuanceninjas.visualstudio.com
PAT=32scqoyc6eiftgtwytj74udelybz5gzhbqxflanrrrvmj4eq66ya
POOL=DMO-SREImages
HOSTNAME=uwinf-pvvsta003

readonly MASTER_CONFIG='file_roots:,  base:,    - /srv/salt,    - /srv/formulas,    - /srv/salt/roles,pillar_roots:,  base:,    - /srv/pillar,  dev:,    - /srv/pillar/dev,  production:,    - /srv/pillar/production'

function provision_agent() {
  sudo mkdir /opt/agent
  wget https://vstsagentpackage.azureedge.net/agent/2.181.1/vsts-agent-linux-x64-2.181.1.tar.gz -P /opt/agent
  cd /opt/agent
  /bin/tar -xvzf /opt/agent/vsts-agent-linux-x64-2.181.1.tar.gz
  /opt/agent/config.sh --unattended --url $SURL --auth pat --token $PAT --pool $POOL --agent $HOSTNAME --work _work --acceptTeeEula
}

provision_agent
#function install_salt_repo() {
#  wget -O - https://archive.repo.saltstack.com/apt/ubuntu/18.04/amd64/2017.7/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
#  local repofile='/etc/apt/sources.list.d/saltstack.list'
#  echo "deb https://archive.repo.saltstack.com/apt/ubuntu/18.04/amd64/2017.7/ $(lsb_release -cs) main" | sudo tee -a $repofile
#}

#function install_salt_master() {
#  install_salt_repo
#  apt-get update
#  apt-get install salt-master salt-minion -y
#  echo -e "$MASTER_CONFIG" | tr ',' '\n' > /etc/salt/master
#  for service in salt-master salt-minion; do
#    systemctl enable $service.service
#    systemctl start $service.service
#  done
#}


#function install_salt_minion() {
#  local master=$1
#  install_salt_repo
#  apt-get update
#  apt-get install salt-minion -y
#  echo "master: $master" > /etc/salt/minion
#  systemctl enable salt-minion.service
#  systemctl start salt-minion.service
#  salt-call saltutil.sync_grains
#  salt-call saltutil.refresh_pillar
#  systemctl stop salt-minion.service
#  salt-call file.remove /etc/salt/minion.d/f_defaults.conf
#  salt-call saltutil.sync_grains
#  salt-call saltutil.refresh_pillar
#  systemctl start salt-minion.service
#  salt-call saltutil.sync_grains
#  salt-call saltutil.refresh_pillar
#  echo "startup_states: highstate" >> /etc/salt/minion
#  salt-call state.highstate -l debug
#  sleep 180
#}


#main() {
#  if [[ $1 == 'master' ]]; then
#     install_salt_master
#  else
#     install_salt_minion $2
#  fi
#}
#main $@
