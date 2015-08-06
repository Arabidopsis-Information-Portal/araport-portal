# Araport Docker

This is a Docker container for running the Araport Portal application.

## tl;dr

1. Clone the repo:

   `git clone https://github.com/Arabidopsis-Information-Portal/araport-portal.git`

2. Set up custom modules:

   `cd araport-portal; git submodule update --init --recursive`

3. Run the compostion:

   `docker-compose up`

## Prerequisites

1. Install [Docker][1]
2. Install [Docker Compose][2]
3. Setup the [environment][#environment-variables]
4. Setup any [initial data][#getting-initial-data-into-the-container]

## Environment variables

This repo includes a sample environment file [araport.env.sample](araport.env.sample). Make a copy
of this file and name it `araport.env`. Then, define the following environment variables:

- `MYSQL_DATABASE` - from the `mysql` Docker container, the name of the database to create
- `MYSQL_USER` - from the `mysql` Docker container, the username to access `MYSQL_DATABASE`
- `MYSQL_PASSWORD` - from the `mysql` Docker container, the password to access `MYSQL_DATABASE`
- `MYSQL_ROOT_PASSWORD` - from the `mysql` Docker container, the root password for the created MySQL instance

## Getting initial data into the container

If you are setting up a new instance, you'll want to get some initial data into the container, such
as the database, public and private files, etc.

Once you already have a running instance it is probably easier to restore the database/files using
the backup_migrate module.

### MySQL data

If you are setting up a brand-new instance, you can probably skip this section. MySQL and Drupal will
configure everything from scratch, simply by following the Drupal installation instructions.

More likely, though, is you are setting up a secondary or development instance and you probably want
to populate the database with a database dump from production (or other existing database location).

1. Start the composition for the first time to create all the containers, in particular the data volume.

   `docker-compose up`

2. Start a one-time mysql container and link it to the created data volume as well as the running db.
   Mount the database dump into the container as well.

  ```
  docker run --name mysqltmp -it --rm --volumes-from araportportal_data_1 \
      --link araportportal_db_1:db --env-file araport.env \
      -v /path/to/database.mysqldump:/database.mysqldump \
      mysql bash
  ```

3. `exec` into the container and restore from `database.mysqldump`

   `mysql -h db -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < /database.mysqldump`
   `exit`


### Drupal public/private files

The Drupal public files directory `/araport/sites/default/files` and private files directory
`/usr/local/drupal/files` are mapped to corresponding directories in the data volume. This allows us
to persist data across containers. However, we need to be able to get data in (and out!) of the data
volume.

If you have copies of the public/private files directories you can start a temporary container,
similar as we do for MySQL data, link the data volume, and copy the files to the data volume.

```
docker run -it --rm -v /path/to/public/files:/files --volumes-from araportportal_data_1 ubuntu bash
apt-get install -y rsync
cd /araport/sites/default/files
rsync -avz /files/ .
exit
```

You can repeat this similarly for private files.



[1]: https://docs.docker.com/installation/
[2]: https://docs.docker.com/compose/install/