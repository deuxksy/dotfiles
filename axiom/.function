DEBUG() {
  printf "\r\033[0;34m[DEBUG] $(date +"%Y-%m-%d %T")\033[1m $1 \033[0m\n"
}

INFO() {
  printf "\r\033[0;32m[INFO ] $(date +"%Y-%m-%d %T")\033[1m $1 \033[0m\n"
}

WARN() {
  printf "\r\033[0;33m[WARN ] $(date +"%Y-%m-%d %T")\033[1m $1 \033[0m\n"
}

ERROR() {
  printf "\r\033[0;31m[ERROR] $(date +"%Y-%m-%d %T")\033[1m $1 \033[0m\n"
}

command_exits() {
  command -v "$@" >/dev/null 2>&1
}

check_command() {
  for cli in $@; do
    DEBUG "${cli}: $(which ${cli})"
    if ! command_exits ${cli}; then
      ERROR "${cli} is not installed."
      sleep 1
      exit 127
    fi
  done
}

# awsh ${EC2-TAG-NAME}
# ec2ssh mf-prd-ec2-java
ec2ssh() {
  ec2=$1
  ec2=${ec2:=ec2-nxp-dev-cache}
  check_command aws yq session-manager-plugin &&
    aws ssm start-session \
      --target $(
        aws ec2 describe-instances \
          --filters \
          Name=tag:Name,Values=${ec2} \
          Name=instance-state-code,Values=16 \
          --output yaml | yq \
          ".Reservations[0].Instances[0].InstanceId"
      )
}

# ecssh ${CLUSTER_NAME} ${SERVICE_NAME} ${CONTAINER_NAME}
# ecssh cluster-qa-backend service-qa-api api
ecssh() {
  cluster=$1
  service=$2
  container=$3

  cluster=${cluster:=cluster-nxp-dev-backend}
  service=${service:=service-dev-api}
  container=${container:=api}

  check_command aws yq session-manager-plugin &&
    aws ecs execute-command --cluster ${cluster} \
      --interactive \
      --command "/bin/sh" \
      --container ${container} \
      --task $(
        aws ecs list-tasks \
          --cluster ${cluster} \
          --service-name ${service} \
          --desired-status RUNNING \
          --output yaml | yq \
          ".taskArns.[0]"
      )
}

ec2ls() {
  check_command aws yq
  aws ec2 describe-instances \
    --filters Name=instance-state-name,Values=running |
    yq '.Reservations[].Instances[].Tags|map(select(.Key == "Name")).[].Value'
}
