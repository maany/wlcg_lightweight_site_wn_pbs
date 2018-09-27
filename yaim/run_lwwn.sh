#!/bin/bash
declare -a NODES
NODE_INDEX=0
DOCKER_RUN="sudo docker run"
# parse arguments
for i in "$@"
do
case $i in
    --ip=*)
    IP="${i#*=}"
    shift # past argument=value
    ;;
    --host=*)
    HOST="${i#*=}"
    shift # past argument=value
    ;;
    --net=*)
    NET="${i#*=}"
    shift # past argument=value
    ;;
    --node=*)
    NODES[NODE_INDEX]="${i#*=}"
    NODE_INDEX=$((NODE_INDEX + 1))
    shift # past argument=value
    ;;
    -h|--help)
    echo "Usage:"
    echo "run_lwwn.sh [--ip=<value>] [--hostname=<value>] [--node=<hostname>:<ip>] [--net=<value>] "
    printf "\n"
	echo "Options:"
	echo "1. ip: REQUIRED; The IP address to be assigned to the container."
    echo "2. host: REQUIRED; The hostname of this container on the attachable docker swarm overlay network"
	echo "3. net: REQUIRED; The name of the attachable overlay network to which the container should attach on startup. You should already have created an attachable overlay network on your swarm manager."
	echo "4. node: OPTIONAL; HOSTNAME:IP of other nodes on the same docker swarm network. The /etc/hosts inside the current container is appended with this info." 
    exit 0
esac
done

if [ -z "$IP" ]
then
    echo "Please specify the ip address for the workernode container." 
    exit 1
elif [ -z "$HOST" ]
then
    echo "Please specify the hostname for the workernode."
    exit 1
elif [ -z "$NET" ]
then
    echo "Please specify the name of the attachable docker overlay network that the container should connect to on startup."
    exit 1
fi
if [ $NODE_INDEX -eq 0 ]
then
    echo "Please note that no node hostname:ip has been specified. Therefore this can potentially create some troubles when trying to communicate over the overlay network."
    sleep 5
fi

echo  "Running docker run with this parameters:
	Hostname: $HOST
	IP ADDR: $IP
	Docker Network Name: $NET
    "
for NODE in ${NODES[@]}; do
	echo "Node hostame and IP= $NODE"
done

DOCKER_RUN="$DOCKER_RUN -itd -d"
DOCKER_RUN="$DOCKER_RUN --name ${HOST}"
DOCKER_RUN="$DOCKER_RUN --net ${NET}"
DOCKER_RUN="$DOCKER_RUN --ip ${IP}"
DOCKER_RUN="$DOCKER_RUN --hostname ${HOST}"
for NODE in ${NODES[@]}; do
    DOCKER_RUN="$DOCKER_RUN --add-host ${NODE}"
done
DOCKER_RUN="$DOCKER_RUN --privileged"
DOCKER_RUN="$DOCKER_RUN --mount type=bind,source="$(pwd)"/wn-config,target=/wn-config"
DOCKER_RUN="$DOCKER_RUN maany/lwwn-umd4 /bin/bash"

echo "The following docker command will be executed:"
echo $DOCKER_RUN
$DOCKER_RUN
sudo docker exec -it lwwn-umd4 /wn-config/init.sh
