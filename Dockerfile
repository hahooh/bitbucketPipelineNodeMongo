FROM node:8.15.0-stretch
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
RUN echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/3.6 main" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
RUN apt-get update
RUN apt-get install -y mongodb-org
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mkdir /etc/init
RUN echo '# Ubuntu upstart file at /etc/init/mongod.conf \
          # Recommended ulimit values for mongod or mongos  \
          # See http://docs.mongodb.org/manual/reference/ulimit/#recommended-settings \
          #
          limit fsize unlimited unlimited \
          limit cpu unlimited unlimited \
          limit as unlimited unlimited \
          limit nofile 64000 64000 \
          limit rss unlimited unlimited \
          limit nproc 64000 64000 \
          kill timeout 300 # wait 300s between SIGTERM and SIGKILL. \
          pre-start script \
            DAEMONUSER=${DAEMONUSER:-mongodb} \
            if [ ! -d /var/lib/mongodb ]; then \
              mkdir -p /var/lib/mongodb && chown mongodb:mongodb /var/lib/mongodb \
            fi \
            if [ ! -d /var/log/mongodb ]; then \
              mkdir -p /var/log/mongodb && chown mongodb:mongodb /var/log/mongodb \
            fi \
            touch /var/run/mongodb.pid \
            chown $DAEMONUSER /var/run/mongodb.pid \
          end script \
          start on runlevel [2345] \
          stop on runlevel [06] \
          script \
            ENABLE_MONGOD="yes" \
            CONF=/etc/mongod.conf \
            DAEMON=/usr/bin/mongod \
            DAEMONUSER=${DAEMONUSER:-mongodb} \
            DAEMONGROUP=${DAEMONGROUP:-mongodb} \
            if [ -f /etc/default/mongod ]; then . /etc/default/mongod; fi \
            # Handle NUMA access to CPUs (SERVER-3574) \
            # This verifies the existence of numactl as well as testing that the command works \
            NUMACTL_ARGS="--interleave=all" \
            if which numactl >/dev/null 2>/dev/null && numactl $NUMACTL_ARGS ls / >/dev/null 2>/dev/null \
            then \
              NUMACTL="$(which numactl) -- $NUMACTL_ARGS" \
              DAEMON_OPTS=${DAEMON_OPTS:-"--config $CONF"} \
            else \
              NUMACTL="" \
              DAEMON_OPTS="-- "${DAEMON_OPTS:-"--config $CONF"} \
            fi \
            if [ "x$ENABLE_MONGOD" = "xyes" ] \
            then \
              exec start-stop-daemon --start \
                  --chuid $DAEMONUSER:$DAEMONGROUP \
                  --pidfile /var/run/mongodb.pid \
                  --make-pidfile \
                  --exec $NUMACTL $DAEMON $DAEMON_OPTS \
            fi \
          end script' > /etc/init/mongodb.conf
RUN mkdir /data
RUN mkdir /data/db
RUN touch /data/db/log
RUN mongod --dbpath data/db --fork --logpath data/db/log

