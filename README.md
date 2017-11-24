[![Docker Stars](https://img.shields.io/docker/stars/yonadev/mariadb-liquibase-update.svg)](https://hub.docker.com/r/yonadev/mariadb-liquibase-update/)
[![Docker Pulls](https://img.shields.io/docker/pulls/yonadev/mariadb-liquibase-update.svg)](https://hub.docker.com/r/yonadev/mariadb-liquibase-update/)
[![Docker Automated build](https://img.shields.io/docker/automated/yonadev/mariadb-liquibase-update.svg)](https://hub.docker.com/r/yonadev/mariadb-liquibase-update/)


Base layer for Liquibase update
=================================

This image is created as base layer for a image that contains the database schema of an application version. To use it, derive an image from it and add the root change log file to as /changelogs/changelog with your preferred file extension.

This image runs [Liquibase update](http://www.liquibase.org/documentation/update.html) with the change log ``/changelogs/changelog.\*`` and the MariaDB JDBC driver. This actually runs from the ``/changelogs/`` folder, so the paths in the ``FILENAME`` column of the ``databasechangelog`` table will be relative to that folder.

#### Example use
Derive an image from it like this:
```
FROM yonadev/mariadb-liquibase-update:3.5.3

COPY liquibase/logs /changelogs
```

Build it:
```
docker build -t your/image:1.2.3 .
```

Then run it:
```
docker run -i \
  -e USER=sa \
  -e PASSWORD=TopSecret \
  -e URL=jdbc:mariadb://dbserver:3306/thedatabase \
  your/image:1.2.3
```

The environment variables required are:

USER - the user to the target database  
PASSWORD - password to the target database  
URL - the JDBC URL

The implementation is based on [the work of Tom Beresford](https://hub.docker.com/r/beresfordt/pg-liquibase-update/~/dockerfile/).
