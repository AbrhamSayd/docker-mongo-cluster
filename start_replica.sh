if [ ! -z "$mongo_replica_set_name" ] && [ ! -z "$mongo_nodes_number" ]; then
  # Create a Mongo shell script to initialize the replica set
  content="rs.initiate({_id:\"$mongo_replica_set_name\", members: ["
  mongo_members=""

  i=0
  while [ $i -lt $mongo_nodes_number ]; do
    # Resolve the hostname to an IP address
    resolved_ip=$(getent hosts "mongo-$i" | awk '{print $1}')
    
    if [ -z "$resolved_ip" ]; then
      echo "Failed to resolve IP for mongo-$i"
      exit 1
    fi

    portNumber=$((27017 + i))
    member="{_id:$i, host:\"$resolved_ip:$portNumber\"}"
    
    # Append to members list
    if [ -z "$mongo_members" ]; then
      mongo_members="$member"
    else
      mongo_members="$mongo_members, $member"
    fi
    
    i=$((i + 1))  # Increment the loop counter
  done

  content="$content $mongo_members]});"

  # Create the mongo-shell file: replica_init.js
  echo "$content" > replica_init.js
  
  echo "Running MongoDB in replica set mode"

  mongod --replSet "$mongo_replica_set_name" --bind_ip 0.0.0.0 --port $port &
  until nc -z localhost $port
  do
      echo "Waiting for MongoDB to be ready"
      sleep 1
  done
  echo "MongoDB is ready"
  
  # Display the initialization script
  cat ./replica_init.js
  
  # Initialize the replica set
  mongosh < ./replica_init.js
  tail -f /dev/null
else
  echo "Starting up in standalone mode"
  mongod
fi
