Docker Swarm Apps
===

Swarm Visualizer
---

```bash
# Startup the Visualizer Service
docker service create \
  --name=viz \
  --publish=8080:8080/tcp \
  --constraint=node.role==manager \
  --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  dockersamples/visualizer

# Add a LB rule to access the Visualizer
./lb.sh <unique> create visualizer 8080:8080
```

Hello World Test
---

```bash
# Start the Stack
docker stack deploy --compose-file docker-stack.yml helloworld

# Remove the Statck
docker stack rm helloworld
```

Private Registry Swarm
---

Bring up Private Registry on the Swarm
```bash
docker service create --name registry \
  --publish 5000:5000 \
  registry:2.6.2

curl localhost:5000/v2/_catalog
```

Bring up Private Registry on the LocalBox
```bash
docker-compose up -d
http://localhost:5001
```

ELK Deploy
---

Build the Stack
```bash
REGISTRY=localhost:5000 TAG=latest
docker-compose build

for SERVICE in logstash; do
  docker tag elk_$SERVICE $REGISTRY/$SERVICE:$TAG
  docker push $REGISTRY/$SERVICE
done

## Local Registry



REGISTRY=localhost:5000 TAG=1.0
for SERVICE in folderA folderB folderC; do
  docker tag myapp_$SERVICE $REGISTRY/$SERVICE:$TAG
  docker push $REGISTRY/$SERVICE
done
