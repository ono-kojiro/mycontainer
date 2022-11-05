connect to postgres in docker:
 $ psql -h localhost -p 15432 -U postgres

attach to container:
 $ docker exec -it postgres /bin/bash

create database
 $ createdb   -h localhost -p 15432 -U postgres sampledb
 $ createuser -h localhost -p 15432 -U postgres -d $USER -W

 $ PGSSLROOTCERT=$HOME/.local/share/mkcert/rootCA.pem \
    psql -h localhost -p 15432 -U $USER sampledb

