# MTNA Kuha2
#
# https://kuha2.readthedocs.io/en/latest/installation.html
#
# Run:
# docker container run -it --rm --name kuha2 -p 80:80 -p 6001:6001 -p 6002:6002 -p 6003:6003 -p 27017 mtna/kuha2
#
# Run with persistence
# docker container run -it --rm --name kuha2 -p 80:80 -p 6001:6001 -p 6002:6002 -p 6003:6003 -p 27017 -v $(pwd)/volumes/metadata:/metadata -v $(pwd)/volumes/db:/data/db -v $(pwd)/volumes/log/kuha2:/var/log/kuha2 -v $(pwd)/volumes/log/nginx:/var/log/nginx mtna/kuha2
#
# Shell:
# docker container exec -it kuha2 bash
#
#
FROM nginx:latest

LABEL maintainer="mtna@mtna.us"

#
# Utilities & Python 3
#
RUN apt-get update \
    && apt-get install -y curl htop iputils-ping iproute2 net-tools unzip vim wget zip \
    && apt-get install -y cron expect tree systemctl vim wget  \
    && apt-get install -y gnupg2 git python3-venv

# MONGO
# Based on https://www.how2shout.com/linux/how-to-install-mongodb-5-0-server-on-debian-11-bullseye/
#
WORKDIR /
RUN echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list \
    && curl -sSL https://www.mongodb.org/static/pgp/server-5.0.asc  -o mongoserver.asc \
    && gpg --no-default-keyring --keyring ./mongo_key_temp.gpg --import ./mongoserver.asc \
    && gpg --no-default-keyring --keyring ./mongo_key_temp.gpg --export > ./mongoserver_key.gpg \
    && mv mongoserver_key.gpg /etc/apt/trusted.gpg.d/ \
    && apt update \
    && apt-get install -y mongodb-org \
    && mkdir -p /data/db


#
# KUHA 2
#
WORKDIR /usr/local

RUN cd /usr/local \
    && mkdir kuha2

# install document store
# note: must initialize database in container
RUN cd /usr/local \
    && git clone --depth 1 --branch releases https://bitbucket.org/tietoarkisto/kuha_document_store kuha2/kuha_document_store \
    && chmod +x ./kuha2/kuha_document_store/scripts/*.sh \
    && ./kuha2/kuha_document_store/scripts/install_kuha_document_store_virtualenv.sh

# initialize Mongo Kuha2 database
RUN cd /usr/local \
    && mongod --fork --logpath /var/log/mongodb/mongod.log \
    && mongo -eval 'db.createUser({user: "kuha2", pwd: "kuha2", roles: [{role: "root", db: "admin"}]})' admin \
    && ./kuha2/kuha_document_store/scripts/setup_mongodb.sh --replica localhost:27017 --replicaset '' --database-user-admin kuha2 --database-pass-admin kuha2

# install OSMH
RUN cd /usr/local \
    && git clone --depth 1 --branch releases https://bitbucket.org/tietoarkisto/kuha_osmh_repo_handler kuha2/kuha_osmh_repo_handler \
    && chmod +x ./kuha2/kuha_osmh_repo_handler/scripts/*.sh \
    && ./kuha2/kuha_osmh_repo_handler/scripts/install_kuha_osmh_repo_handler_virtualenv.sh

# install OAI_PMH
RUN cd /usr/local \
    && git clone --depth 1 --branch releases https://bitbucket.org/tietoarkisto/kuha_oai_pmh_repo_handler kuha2/kuha_oai_pmh_repo_handler\ 
    && chmod +x ./kuha2/kuha_oai_pmh_repo_handler/scripts/*.sh \
    && ./kuha2/kuha_oai_pmh_repo_handler/scripts/install_kuha_oai_pmh_repo_handler_virtualenv.sh

# download client
RUN cd /usr/local \
    && git clone --depth 1 --branch releases https://bitbucket.org/tietoarkisto/kuha_client kuha2/kuha_client 

# install client
# - using . instead of source as we are using /bin/sh (not bash)
#-  added pip install wheel
RUN cd /usr/local/kuha2 \
    && python3 -m venv kuha_client-env \
    && . kuha_client-env/bin/activate \
    && cd kuha_client \
    && pip install wheel \
    && pip install -r requirements.txt \
    && pip install .

# Create a directory to hold the DDI metadata
RUN mkdir /metadata
#
# ADD KUHA2 SERVICES TO ENTRYPOINT
#
COPY 40-start-kuha2-services.sh /docker-entrypoint.d
RUN chmod 0744 /docker-entrypoint.d/40-start-kuha2-services.sh

#
# ADD KUHA2 UPDATE SCRIPT
#
RUN mkdir /var/log/kuha2
COPY kuha2-update.sh /usr/local/kuha2
RUN chmod 0744 /usr/local/kuha2/kuha2-update.sh

#
# SETUP CRON
#
COPY kuha2-cron /etc/cron.d
RUN chmod 0744 /etc/cron.d/kuha2-cron

#
# SETUP NGINX
#
RUN rm /var/log/nginx/*

COPY nginx.conf /etc/nginx/

COPY default.conf /etc/nginx/conf.d/

COPY index.html error.html /usr/share/nginx/html/

#
# ENVIRONMENT
#
ENV KUHA_DS_URL http://localhost:6001/v0
ENV KUHA_OPRH_OP_BASE_URL http://localhost/oai-pmh
ENV KUHA_OPRH_OP_EMAIL_ADMIN admin@example.org

#
# FINALIZE
#
EXPOSE 80 443 6001 6002 6003 27017
VOLUME /data /metadata
WORKDIR /usr/local

