FROM ubuntu:20.04

# Run the Update
RUN apt-get update && apt-get upgrade -y

# Install pre-reqs
RUN apt-get install -y python3-pip curl ca-certificates wget gnupg lsb-release unzip vim

RUN pip3 install awscli

RUN pip3 install awscli-plugin-endpoint
RUN aws configure set plugins.endpoint awscli_plugin_endpoint

# PostgreSql Client
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install postgresql-client-13 -y
RUN pg_basebackup -V

#Make sure that your shell script file is in the same folder as your dockerfile while running the docker build command as the below command will copy the file to the /home/root/ folder for execution.
COPY . /home/root/
RUN mv /home/root/.pgpass /root/.pgpass

RUN chmod +x /home/root/backup.sh
RUN chmod 600 /root/.pgpass

#Copying script file
USER root 
#switching the user to give elevated access to the commands being executed from the k8s cron job
CMD sh /home/root/backup.sh