# MTNA/Kuha2

This Docker image provide an all-in-one single container option for hosting a Kuha2 server with OAI-PMH support. Kuha2 is a metadata server that provides descriptive social science research metadata for harvesting via multiple protocols and a growing variety of metadata standards. See project [documentation](https://kuha2.readthedocs.io/en/latest/) for more information.

This image packages:

- a nginx web server to provide a landing page and to proxy calls to the backend OAI-PMH API
- a mongodb server to store the Kuha2 documents
- a Kuha2 Document Store service
- a Kuha2 OSMH service
- a Kuha2 OAI-PMH service

## Setup

### Volumes

For persistence, the following directories **must be externalized**:

- ```/metadata```: the directory holding the DDI-XML documents to be indexed indexing
- ```/data/db```: the Mongo database

The following logs can also be externalized, particularly in a production environment:

- ```/var/log/kuha2```
- ```/var/log/mongodb```
- ```/var/log/nginx```

If you wish to create your own landing page or website, you should externalize the ```/usr/share/nginx/html/``` directory, making sure it contains at least an ```index.html``` and  ```error.html``` files. You can also customize the nginx server as describe in the [container documentation](https://hub.docker.com/_/nginx)

### Database Initialization
Most of the Kuha2 installation steps are performed in the Dockerfile, with the exception of the database initialization with can be performed by calling the relevant setup script (e.g. from container bash shell or by using the docker exec command). 

Kuha Version 1.x

```./kuha2/kuha_document_store/scripts/setup_mongodb.sh --replica mongo:27017 --replicaset ''```

Kuha Version 0.x

```./kuha2/kuha_document_store/scripts/setup_mongodb.sh --database-host=localhost```

Note that mongodb must be running for this to work. This is normally the case if the container is slready running. But if necessary, you can start the service from the bash shell by calling:

```mongod --fork --logpath /var/log/mongodb/mongod.log```


## Running the container


### Environment variables

The various Kuha2 services and processes are configured using environment variables, as described in the [platform documentation](https://kuha2.readthedocs.io/en/latest/)

The following must be adjusted at runtime for your environment (e.g. using the -e parameter :

- ```ENV KUHA_OPRH_OP_BASE_URL``` (defaults to http://localhost/oai-pmh). This should match the server public URL (e.g. http://www.mydomain.org/oai-pmh).
- ```ENV KUHA_OPRH_OP_EMAIL_ADMIN``` (defaults to admin@example.org)

### Docker run

When running the container, you must:

- set relevant environment variables
- define external volumes or storage location 
- decide which ports to expose

Here is an example for running the container on your local machine with the database, metadata, and log files stored on the system disk, and all ports open. 


```docker container run -it --rm --name kuha2 -p 80:80 -p 6001:6001 -p 6002:6002 -p 6003:6003 -p 27017 -v $(pwd)/volumes/metadata:/metadata -v $(pwd)/volumes/db:/data/db -v $(pwd)/volumes/log/kuha2:/var/log/kuha2 -v $(pwd)/volumes/log/nginx:/var/log/nginx mtna/kuha2```

A typical successful startup should look like this in 

```
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: /etc/nginx/conf.d/default.conf differs from the packaged version
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/40-start-kuha2-services.sh
40-start-kuha2-services.sh: Starting cron
Starting periodic command scheduler: cron.
40-start-kuha2-services.sh: Starting MongoDB
about to fork child process, waiting until server is ready for connections.
forked process: 47
```

Consult the kuha2 log files to verify all services have started properly and that the .


## DDI Indexing
The container is configured for use with DDI-Codebook XML files, which can be dropped in dedicated directory for automated reindexing. By default, this is scheduled every 6 hours (controlled by the /etc/crond.d/kuha2-cron file).


To trigger an immediate update, you can call the shell script directly as follows (or from the container bash shell):

```docker container exec -it kuha2 /usr/local/kuha2/kuha2-update.sh```


## Todos / Wishlist

The following improvements can be made to this container:

- Upgrade the container to Kuha 1.x.x
- Add an entrypoint script to optionaly run registry update when starting container
- Setup Mongo security: the current version use and unsecured configuration for MongoDB. Kuha2 setup script will need to be adjusted accordingly. ideally the mongo user/password should be set using environment variables
- Add runtime parameters / environment variables to
	- control cron job schedule
	- control which components to index (studies, groups variable, questions)

## Technical Notes

### Kuha2 Services

The document store can be started with:

```./kuha2/kuha_document_store/scripts/run_kuha_document_store.sh --database-host=localhost```

The OSMH services can be started with:

```./kuha2/kuha_osmh_repo_handler/scripts/run_kuha_osmh_repo_handler.sh --document-store-url=localhost:6001```

The OAI-PMH services can be started with:
```./kuha2/kuha_oai_pmh_repo_handler/scripts/run_kuha_oai_pmh_repo_handler.sh --document-store-url=http://localhost:6001/v0 --oai-pmh-base-url=http://localhost:6003/v0 --oai-pmh-admin-email=nobody@example.com```

A OAI-PMH test can be done with:

```./kuha2/kuha_oai_pmh_repo_handler/scripts/list_records.sh oai_dc```

### Kuha2 Client
To use the OAI-PMH client in the container, we must first activate the python environment:

```
cd /usr/local/kuha2
python3 -m venv kuha_client-env
. /usr/local/kuha2/kuha_client-env/bin/activate
```

#### Upsert

To load DDI from a directory 

```
python3 -m kuha_client.kuha_upsert --document-store-url=host --file-log-path=file_log --remove-absent /path/to/directory
```

For example

```
python3 -m kuha_client.kuha_upsert --document-store-url=http://localhost:6001/v0 --file-log-path=kuha.log --remove-absent /metadata
```

To exclude study_groups

```
python3 -m kuha_client.kuha_upsert --document-store-url=http://localhost:6001/v0 --file-log-path=kuha.log --remove-absent --collection studies --collection variables --collection questions --loglevel DEBUG /metadata
```

#### Delete

To delete all content

```python3 -m kuha_client.kuha_delete --document-store-url http://localhost:6001/v0 ALL ALL```


### MongoDB

The container exposes two volumes:

```
/data/configdb
/data/db
```

#### Mongo shell
[Mongo shell help](https://docs.mongodb.com/manual/reference/mongo-shell/)

```show dbs```

```use kuha_document_store```

```show collections```


### DDI
- codeBook cannot have xmlns="http://www.icpsr.umich.edu/DDI" set?
- serStmt is used to associate with a study_group and therefore must have an @ID attribute
- when updating, a study is not removed from study groups. Basically changing the serStmt/@ID creates a new study group and does not removes the study from previous one


### OAI-PMH
- [HTTP Requests](http://www.openarchives.org/OAI/openarchivesprotocol.html#HTTPRequestFormat)
- [Verbs](http://www.openarchives.org/OAI/openarchivesprotocol.html#ProtocolMessages)


## MIT License

Copyright © `2022` `Metadata Technology North America Inc.`

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the “Software”), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


## Contact
For feedback, questions, or suggestions contact <mtna@mtna.us>
