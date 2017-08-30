# Helpful Docker Swarm Commands

## Swarm Management

```bash
# Create a Swarm
docker swarm init
docker swarm init --advertise-addr 10.0.9.2 --listen-addr 10.0.9.2
docker swarm init --advertise-addr  etch0:7777

# Add a worker
docker swarm join-token worker
docker swarm join --token {TOKEN} node1:2377
docker info |grep ^Swarm

# Managing nodes
docker node ls
docker node promote <node_name_or_id>


# Token Rotation
docker swarm join-token --rotate  <worker|manager>

```


## Swarm Services

```bash
# Create a service
docker service create alpine ping 8.8.8.8
docker service create -p 80:80 --replicas 7 --detach=false tutum/hello-world

# Check service results
docker service ps <serviceID>

# Service Logs
docker service logs <serviceID> --follow

# Run multiple Single Services
REGISTRY=localhost:5000 TAG=1.0
for SERVICE in folderA folderB folderC; do
  docker service create --network myNetwork --detach=true \
    --name $SERVICE $REGISTRY/$SERVICE:$TAG
done

# Globally Schedule a service  (1 instance all nodes)
docker service create --name myService --network myNetwork --mode global --detach=false <image>

# Update a Service to publish it
docker service update myService --publish-add 8000:80 --detach=false

# Update a Service to depublish
docker service update myService --publish-rm 80

# Update a Service to scale it
docker service update myService --replicas 10 --detach=false

# Remove service
docker service rm <serviceID>

# Remove ALL services
docker service ls -q |xargs docker service rm

```

## Swarm Visualizer

```bash
git clone git://github.com/dockersamples/docker-swarm-visualizer
cd docker-swarm-visualizer
docker-compose up -d

docker service create  --name viz \
  --mount source=/var/run/docker.sock,type=bind,target=/var/run/docker.sock \
  --constraint node.role==manager
```

## Build Ship and Run single services

```bash
docker build -t danielscholl/idig:v0.1 .
docker push danielscholl/idig:v0.1
docker service create danielscholl/idig:v0.1
```

## Networks

```bash
# Create a Network
docker network create --driver overlay myNetwork

# List Networks
docker network ls

# Docker Service on a Network
docker service create --name redis \
  --network myNetwork  \
  redis
```

Troubleshooting Networks [nicolaka/netshoot](https://github.com/nicolaka/netshoot)

## Local Registry

```bash
docker service create --name registry \
  --publish 5000:5000 \
  registry:2.6.2

curl localhost:5000/v2/_catalog


REGISTRY=localhost:5000 TAG=1.0
for SERVICE in folderA folderB folderC; do
  docker tag myapp_$SERVICE $REGISTRY/$SERVICE:$TAG
  docker push $REGISTRY/$SERVICE
done
```

Compose File for Private Registry with Azure Blob Store

```yml
version: "3.1"

services:
  registry:
    image: registry:2.6.2
    ports:
      - "5000:5000"
    env_file: .env
    deploy:
      placement:
        constraints: [node.role == manager]
```

```bash
REGISTRY_STORAGE=azure
REGISTRY_STORAGE_AZURE_CONTAINER=<your_container>
REGISTRY_STORAGE_AZURE_ACCOUNTNAME=<your_account>
REGISTRY_STORAGE_AZURE_ACCOUNTKEY=<your_key>
```

## Swarm Stacks

```bash
# Deplay a stack
docker stack deploy myStack --compose-file docker-compose.yml

# Check a stack
docker service ps myStack_myStack

```

Sample Compose File
```yml
version: "3.1"

services:
  serviceA:
    build: folderA
    image: ${REGISTRY-localhost:5000}/folderA:${TAG-latest}
    deploy:
      mode: global
  serviceB:
    build: myImage
    deploy:
      replicas: 10
```

## Rolling Updates

```bash
# Watch Services Running
watch -n1 "docker service ps myService |grep -v Shutdown.*Shutdown"

# Update with changed policy
docker service update myService --update-parallelism 2 --update-delay 5s

# Rollback while in process deployment
docker service update myService --rollback

```

## Swarmkit Tools

```bash
# Build the tools
docker run -v /usr/local/bin:/go/bin golang \
  go get -v github.com/docker/swarmkit/...

# Alias the Command
alias swarmctl='sudo swarmctl \
  --socket /var/run/docker/swarm/control.sock'

# List Nodes (docker node ls)
swarmctl node ls

# View tasks across services
swarmctl task ls
```

## Secrets

```bash
# Create a secret
echo "shhhh don't tell" | docker secret create mySecret -
base64 /dev/urandom | head -c24 | docker secret create secureSecret -

# Run a service using secret
docker service create --name dummyservice \
  --secret mySecret \
  --secret secureSecret \
  --mode global \
  alpine sleep 1000000000
CID=$(docker ps -q --filter label=com.docker.swarm.service.name=dummyservice)
docker exec -it $CID sh
$ cat /run/secrets/mySecret
$ cat /run/secrets/secureSecret



# Mount a container to access secret
CID=$()
```


## Container Logging to ELK

```bash
# Create a logging network
docker network create --driver overlay elk_logging

# Create an elastic search service
docker service create --name elasticsearch\
  --network elk_logging \
  --constraint 'node.role==worker' \
  elasticsearch:2.4

# Create a Kibana service
docker service create --name kibana \
  --network elk_logging \
  --publish 5601:5601 \
  --constraint 'node.role==worker' \
  kibana:4.6 -e ELASTICSEARCH_URL=http://elasticsearch:9200

# Create the Logstash Service
docker service create --name logstash \
  --network elk_logging \
  --publish 12201:12201/udp \
  --constraint 'node.role==worker' \
  logstash:2.4 -e "$(cat ./apps/elk/logstash.conf)" 

```
