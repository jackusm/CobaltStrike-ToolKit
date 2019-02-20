# BUILD INSTRUCTIONS & README
# POST HERE: https://blog.obscuritylabs.com/docker-command-controll-c2/
#   1) docker build --build-arg cskey="xxxx-xxxx-xxxx-xxxx" -t cobaltstrike/cs .
#   2) docker run -d -p 192.168.2.238:50050:50050 -p 192.168.2.238:50080:80 --restart always -v /opt/Malleable-C2-Profiles:/Malleable-C2-Profiles --name "Teamserver1" cobaltstrike/cs 192.168.2.238 password /Malleable-C2-Profiles/APT/havex.profile && docker logs -f "Teamserver1"
#      docker run -d -p 192.168.2.238:50051:50050 -p 192.168.2.238:50443:443 --restart always -v /opt/Malleable-C2-Profiles:/Malleable-C2-Profiles --name "Teamserver2" cobaltstrike/cs 192.168.2.238 password /Malleable-C2-Profiles/APT/havex.profile && docker logs -f "Teamserver2"
#    NOTE: This runs docker in Detached mode, to tshoot issues or see logs do the following you can easily name the docker and start as many Teamservers with a Mallable profile like so as well. You might want to do this as CS Beacon cant have a HTTP and HTTPS listener simultanousely:
#   3) docker stop Teamserver1 && docker container rm Teamserver1
#     NOTE: This trashes the container so you can start from #2 again
#    NOTE: to go interactive we need to bypass the ENTRYPOINT
#      - docker run -ti --entrypoint "" cobaltstrike/cs bash
FROM ubuntu:16.04

# Dockerfile metadata
MAINTAINER Mpgough
LABEL version="1.1"
LABEL description="Dockerfile base for CobaltStrike. Updated to Java 11.0.2"

# setup local env
ARG cskey
ENV cs_key ${cskey}
ENV JAVA_HOME /opt/jdk-11.0.2
ENV PATH $PATH:$JAVA_HOME/bin

# docker hardcoded sh...
SHELL ["/bin/bash", "-c"]

# install proper tools
RUN apt-get update && \
    apt-get install -y wget curl net-tools sudo host

# install oracle jave
RUN cd /opt && \
    wget -c https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz && \
    tar xvf openjdk-11.0.2_linux-x64_bin.tar.gz && \
    cd jdk-11.0.2 && \
    source /etc/bash.bashrc && \
    sudo update-alternatives --install '/usr/bin/java' 'java' '/opt/jdk-11.0.2/bin/java' 1 && \
    sudo update-alternatives --install '/usr/bin/javac' 'javac' '/opt/jdk-11.0.2/bin/javac' 1 && \
    sudo update-alternatives --set 'java' '/opt/jdk-11.0.2/bin/java' && \
    sudo update-alternatives --set 'javac' '/opt/jdk-11.0.2/bin/javac'

# install CobaltStrike with license key and update
RUN var=$(curl 'https://www.cobaltstrike.com/download' -XPOST -H 'Referer: https://www.cobaltstrike.com/download' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://www.cobaltstrike.com' -H 'Host: www.cobaltstrike.com' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Connection: keep-alive' -H 'Accept-Language: en-us' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_1) AppleWebKit/604.3.5 (KHTML, like Gecko) Version/11.0.1 Safari/604.3.5' --data "dlkey=$cs_key" | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep /downloads/ | cut -d '.' -f 1) && \
    cd /opt && \
    wget https://www.cobaltstrike.com$var.tgz && \
    tar xvf cobaltstrike-trial.tgz && \
    cd cobaltstrike && \
    echo $cs_key > ~/.cobaltstrike.license && \
    ./update

# cleanup image
RUN apt-get -y clean && \
    apt-get -y autoremove

# set entry point
WORKDIR "/opt/cobaltstrike"
ENTRYPOINT ["./teamserver"]

