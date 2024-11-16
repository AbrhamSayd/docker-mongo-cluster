#!/bin/bash

if [ ! -z "$mongo_node_name" ] && [ ! -z "$mongo_replica_set_name" ]; then
  # Create a mongo shell to initialize the replica set.
  # Required environmental variables: $mongo_replica_set_name, $mongo_nodes_number, $mongo_node_name
  content="rs.initiate({_id:\"$mongo_replica_set_name\", members: ["
  mongo_members="{_id: 0, host:\"${mongo_node_name}-0\"}"
  i=1
  while [ $i -lt $mongo_nodes_number ]; do
    portNumber=$((27017 + i))
    mongo_members="$mongo_members, {_id:$i, host:\"${mongo_node_name}-$i:$portNumber\"}"
    ((i++));
  done;
  content="$content $mongo_members]});"
  # create the mongo-shell file: replica_init.js
  echo $content > replica_init.js
  
  echo "Running mongo as Replicamode"

  mongod --replSet $mongo_replica_set_name --bind_ip 0.0.0.0 --port $port &
  until nc -z localhost $port
  do
      echo "Wait mongoDB to be ready"
      sleep 1
  done
  echo "MongoDB is ready"
  cat ./replica_init.js
  # Start replica set
  mongosh < ./replica_init.js
  tail -f /dev/null
else
	echo "Starting up in standalone mode"
    mongod
fi