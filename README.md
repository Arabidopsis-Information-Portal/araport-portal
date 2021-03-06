# Araport Docker

This is a Docker container for running the Araport Portal application.

## tl;dr

1. Clone the repo:

   `git clone https://github.com/Arabidopsis-Information-Portal/araport-portal.git`

2. Set up custom modules:

   `cd araport-portal; git submodule update --init --recursive`

3. Run the compostion:

   `docker-compose up`

4. [First run configuration](#first-run-configuration)

## Prerequisites

1. Install [Docker][1]
2. Install [Docker Compose][2]

## Environment variables

This repo includes a sample environment file [araport.env.sample](araport.env.sample). Make a copy
of this file and name it `araport.env`. Then, define the following environment variables:

- `MYSQL_DATABASE` - from the `mysql` Docker container, the name of the database to create
- `MYSQL_USER` - from the `mysql` Docker container, the username to access `MYSQL_DATABASE`
- `MYSQL_PASSWORD` - from the `mysql` Docker container, the password to access `MYSQL_DATABASE`
- `MYSQL_ROOT_PASSWORD` - from the `mysql` Docker container, the root password for the created MySQL instance

## First run configuration

The first time you start up the composition there are a couple of things we need to do to get everything
to a consistent state.

### Initialize the database

Because we're setting the database configuration in `sites/default/settings.php` from the environment
to match what we've configured for the MySQL container, Drupal will refuse to run the `install.php`
script. (This is actually for good reasons.) So we need to initialize the database ourselves.

1. Start the composition for the first time to create all the containers, in particular the data volume.

   ```
   docker-compose up
   ```

2. Start a one-time mysql container and link it to the created data volume as well as the running db.
   Mount the database dump into the container as well.

  ```
  docker run --name mysqltmp -it --rm --volumes-from araportportal_data_1 \
      --link araportportal_db_1:db --env-file araport.env \
      -v /path/to/database.mysqldump:/database.mysqldump \
      mysql bash
  ```

3. Restore the database from the mounted dump file. We've passed in the environment variables above,
   too, so we can just let the system substitute those for us.

   ```
   mysql -h db -u ${MYSQL_USER} -p${MYSQL_PASSWORD} \
       ${MYSQL_DATABASE} < /database.mysqldump
   exit
   ```

### Load public/private files

The Drupal public files directory `/araport/sites/default/files` and private files directory
`/usr/local/drupal/files` are mapped to corresponding directories in the data volume. This allows us
to persist data across containers. However, we need to be able to get data in (and out!) of the data
volume.

On first run the data volume will not have these files. Assuming you have a local copy handy, we can
start a temporary container, similar as we do for the mysql data above, and copy the files to the data
volume.

```
docker run -it --rm -v /path/to/public/files:/files \
    --volumes-from araportportal_data_1 ubuntu bash
apt-get update && apt-get install -y rsync
cd /araport/sites/default/files
rsync -avz /files/ .
exit
```

You can repeat this similarly for private files.

### Permissions

We also need to set permissions on the public and private files directories. Exec into the running
Drupal container and change ownership to `www-data`:

```
docker exec -it araportportal_drupal_1 bash
chown -R www-data:www-data /araport/sites/default/files
chown -R www-data:www-data /usr/local/drupal/files
```

### Clear the cache

It's generally a good idea to clear the cache anytime you refresh the database or public files,
because there is a good bit of transient data that Drupal caches in each. Refreshing the cache will
ensure that everything is correctly discovered. This will also confirm that the permissions
are set properly!

### Process Science Apps

You may also need to process any science apps. If you synced the private files directory from an
up-to-date copy above, you can probably skip this step.

Use `docker exec` to run the `drush` commands to check and process science apps:

```
docker exec -it araportportal_drupal_1 drush saw-chk
docker exec -it araportportal_drupal_1 drush saw-apps-proc --limit=100
```

Adjust `--limit` as necessary to process all apps, or you can just run `saw-apps-proc` multiple times
until all apps have been processed.



[1]: https://docs.docker.com/installation/
[2]: https://docs.docker.com/compose/install/
