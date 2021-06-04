FROM openjdk:8

WORKDIR /opt/mariadb

# Create dirs
RUN mkdir -p /opt/liquibase &&\
  mkdir -p /opt/jdbc_drivers &&\
  mkdir -p /home/rundir &&\
  mkdir /scripts

ENV REPO_BASE_URL https://repo1.maven.org/maven2

# Add liquibase
ENV LIQUIBASE_VERSION 4.3.5
ADD ${REPO_BASE_URL}/org/liquibase/liquibase-core/${LIQUIBASE_VERSION}/liquibase-core-${LIQUIBASE_VERSION}.tar.gz /opt/liquibase/liquibase-core-bin.tar.gz
WORKDIR /opt/liquibase
RUN tar -xzf liquibase-core-bin.tar.gz &&\
  rm liquibase-core-bin.tar.gz &&\
  chmod +x /opt/liquibase/liquibase &&\
  ln -s /opt/liquibase/liquibase /usr/local/bin/

WORKDIR /

# Add MariaDB JDBC driver
ENV DRIVER_VERSION 2.7.3
ENV DRIVER_JAR mariadb-java-client-${DRIVER_VERSION}.jar
ADD ${REPO_BASE_URL}/org/mariadb/jdbc/mariadb-java-client/${DRIVER_VERSION}/mariadb-java-client-${DRIVER_VERSION}.jar /opt/jdbc_drivers/${DRIVER_JAR}
RUN chmod 644 /opt/jdbc_drivers/${DRIVER_JAR}

# Add update script
COPY update.sh /scripts/
RUN chmod +x /scripts/update.sh

# Prepare for running container
WORKDIR /home/rundir
CMD ["/scripts/update.sh"]
