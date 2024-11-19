#!/bin/bash

echo "--------------------- FREE-NGROCK ----------------------------"
echo "---- by vitobotta         [https://github.com/vitobotta/] ----"
echo "---- powered by Carolus74 [https://github.com/carolusx74] ----"
echo "--------------------------------------------------------------"

echo "ENV MODE            [$MODE]"
echo "ENV PORTS:          [$PORTS]"
echo "ENV PROXY_HOST:     [$PROXY_HOST]"
echo "ENV PROXY_SSH_PORT: [$PROXY_SSH_PORT]"
echo "ENV PROXY_SSH_USER: [$PROXY_SSH_USER]"
echo "ENV APP_IP:         [$APP_IP]"


check_if_ssh_file_exist(){
  if [ -e ssh.key ]
    then
      echo "ssh.key file LOADED     :)"
      true
    else
      echo "ssh.key FILE NOT FOUND  :/"
      false
  fi
}

set_ssh_key_file_permission(){
  echo "<<SETs SSH KEY FILE PERMISSION>>"

  if check_if_ssh_file_exist; then
    echo "Appliying chmod 400 to ssh.key file..."
    permisos=$( stat -c "%a" "ssh.key")
    echo "Previous ssh.key file permission    [$permisos]"
    chmod 400 /ssh.key
    permisos=$( stat -c "%a" "ssh.key")
    echo "Final ssh.key file permission       [$permisos]"
  else
    echo "There is no ssh.key file to verify. [WARNING, current mode $MODE]"
  fi
}


close_connection() {
  echo ">>> CLOSE CONNECTION!!"
  pkill -3 autossh
  exit 0
}

set_ssh_key_file_permission

trap close_connection TERM

case ${MODE} in
  "proxy" )
    TUNNELS=""

    for MAPPINGS in $(echo ${PORTS} | awk -F, '{for (i=1;i<=NF;i++)print $i}'); do
      IFS=':' read -r -a MAPPING <<< "$MAPPINGS"; unset IFS

      read -r -d '' TUNNELS <<-EOS
${TUNNELS}

server {
    listen ${MAPPING[0]};

    proxy_pass 127.0.0.1:${MAPPING[1]};
    proxy_responses 0;
}
EOS
    done

    export TUNNELS

    bash -c "envsubst < /nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"
    ;;

  "app" )
    DOCKER_HOST="$(getent hosts host.docker.internal | cut -d' ' -f1)"
    #APP_IP="${APP_IP:-$DOCKER_HOST}" #Si no tengo ip custom, configura la del DOCKER_HOST
    if [ -z "${APP_IP}" ]; then
      APP_IP=$(ip -4 route show default | cut -d' ' -f3)
    fi

    TUNNELS=" "

    for MAPPINGS in $(echo ${PORTS} | awk -F, '{for (i=1;i<=NF;i++)print $i}'); do
      IFS=':' read -r -a MAPPING <<< "$MAPPINGS"; unset IFS
      TUNNELS="${TUNNELS} -R ${MAPPING[1]}:${APP_IP}:${MAPPING[0]} "
    done

    echo "SOLVED APP_IP and/or HOST_IP: [$APP_IP]"
    echo "DEFINED TUNNELS:              [$TUNNELS]"
    echo "<<ATTEMPT SSH CONNECTION>>"

    echo "autossh -M 0 -o "PubkeyAuthentication=yes" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=5" -o "ServerAliveCountMax 3" -i /ssh.key ${TUNNELS} ${PROXY_SSH_USER}@${PROXY_HOST} -p ${PROXY_SSH_PORT}"
    autossh -M 0 -o "PubkeyAuthentication=yes" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=5" -o "ServerAliveCountMax 3" -i /ssh.key ${TUNNELS} ${PROXY_SSH_USER}@${PROXY_HOST} -p ${PROXY_SSH_PORT}

    while true; do
      sleep 1 &
      wait $!
    done

    exit 0
    ;;
esac
