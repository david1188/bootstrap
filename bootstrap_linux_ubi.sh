#!/bin/bash

set -e
set -u

readonly MASTER_CONFIG='file_roots:,  base:,    - /srv/salt,    - /srv/formulas,    - /srv/salt/roles,pillar_roots:,  base:,    - /srv/pillar,  dev:,    - /srv/pillar/dev,  production:,    - /srv/pillar/production'


function install_salt_repo() {
#  curl -L https://archive.repo.saltstack.com/apt/ubuntu/18.04/amd64/2017.7/SALTSTACK-GPG-KEY.pub | apt-key add -
  local repofile='/etc/apt/sources.list.d/saltstack.list'
  echo "deb https://archive.repo.saltstack.com/apt/ubuntu/18.04/amd64/2017.7/ $(lsb_release -cs) main" | sudo tee -a $repofile
}

function install_salt_master() {
  install_salt_repo
  apt-get update
  apt-get install salt-master salt-minion -y
  echo -e "$MASTER_CONFIG" | tr ',' '\n' > /etc/salt/master
  for service in salt-master salt-minion; do
    systemctl enable $service.service
    systemctl start $service.service
  done
}


function install_salt_minion() {
  local master=$1
  install_salt_repo
  apt-get update
  apt-get install salt-minion -y
  echo "master: $master" > /etc/salt/minion
  systemctl enable salt-minion.service
  systemctl start salt-minion.service
  salt-call saltutil.sync_grains
  salt-call saltutil.refresh_pillar
  systemctl stop salt-minion.service
  salt-call file.remove /etc/salt/minion.d/f_defaults.conf
  salt-call saltutil.sync_grains
  salt-call saltutil.refresh_pillar
  systemctl start salt-minion.service
  salt-call saltutil.sync_grains
  salt-call saltutil.refresh_pillar
  echo "startup_states: highstate" >> /etc/salt/minion
  salt-call state.highstate -l debug
  sleep 180
}


main() {
  if [[ $1 == 'master' ]]; then
     install_salt_master
  else
     install_salt_minion $2
  fi
}
main $@
