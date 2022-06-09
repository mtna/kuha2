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

Since release 1.x of Kuha2, the MongoDB database stored under /data/db is initialized and ready to use. If you need an external version you can either copy the directory out of the container or use the following procedure:

1. Launch the container with the /data/db directory externalized, which will create a clean Mondgo DB database
2. Login the container bash shell (e.g. `docker container exec -it kuha2 bash`)
3. Run the following command ```/usr/local/kuha2/kuha_document_store/scripts/setup_mongodb.sh --replica localhost:27017 --replicaset '' --database-user-admin kuha2 --database-pass-admin kuha2```

If you are using the now deprecated version 0.x, follow a similar procedure as above, but instead run the following command: 
```/usr/local/kuha2/kuha_document_store/scripts/setup_mongodb.sh --database-host=localhost```
Note that this will prompt you for an admin user id and password. You can enter any value like root/root.

## Running the container

### Environment variables

The various Kuha2 services and processes are configured using environment variables, as described in the [platform documentation](https://kuha2.readthedocs.io/en/latest/)

The following must be adjusted at runtime for your environment (e.g. using the docker run -e parameter):

- ```ENV KUHA_OPRH_OP_BASE_URL``` (defaults to http://localhost/oai-pmh). This should match the server public URL (e.g. http://www.mydomain.org/oai-pmh).
- ```ENV KUHA_OPRH_OP_EMAIL_ADMIN``` (defaults to admin@example.org)

Other environment variables you should consider setting as they are used by the OAI-PMH Identify verb are `KUHA_OPRH_OP_BASE_URL`, `KUHA_OPRH_OP_EMAIL_ADMIN`, `KUHA_OPRH_OP_REPO_NAME`


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

Consult the kuha2 log files to verify all services have started properly.


## DDI Indexing
The container is configured for use with DDI-Codebook XML files, which can be dropped in dedicated directory for automated reindexing. By default, this is scheduled every 6 hours (controlled by the /etc/crond.d/kuha2-cron file).

To trigger an immediate update, you can call the shell script directly as follows (or from the container bash shell):

```docker container exec -it kuha2 /usr/local/kuha2/kuha2-update.sh```


## Roadmap

The following improvements can be made to this container:

- Add an entry point script to optionally run registry update when starting container
- Setup Mongo security: the current version use and unsecured configuration for MongoDB. Kuha2 setup script will need to be adjusted accordingly. ideally the mongo user/password should be set using environment variables
- Add runtime parameters / environment variables to
	- control cron job schedule
	- control which components to index (studies, groups variable, questions)

## References

### Kuha2
- [Official Documentation](https://kuha2.readthedocs.io/)
- [BitBucket repository](https://bitbucket.org/tietoarkisto/workspace/projects/KUH)

### OAI-PMH

- [The Open Archives Initiative Protocol for Metadata Harvesting](http://www.openarchives.org/OAI/openarchivesprotocol.html)
- [HTTP Requests](http://www.openarchives.org/OAI/openarchivesprotocol.html#HTTPRequestFormat)
- [Verbs](http://www.openarchives.org/OAI/openarchivesprotocol.html#ProtocolMessages)

### DDI
- [DDI Alliance](https://ddialliance.org/)


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
For feedback, questions, or suggestions contact <pascal.heus@mtna.us>
