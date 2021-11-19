FROM centos:centos7.9.2009
ENV JENKINS_USER admin
ENV JENKINS_PASS '$$tester'
ENV CURL_OPTIONS -sSfLk
ENV JENKINS_OPTS --httpPort=-1
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ARG TARGETARCH
ARG COMMIT_SHA

RUN echo -e '[AdoptOpenJDK]\n\
name=AdoptOpenJDK\n\
baseurl=https://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/$releasever/$basearch\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public' > /etc/yum.repos.d/adoptopenjdk.repo && \
    yum update -y && yum install -y git curl adoptopenjdk-8-hotspot-8u292_b10-3 freetype fontconfig unzip which && \
    yum clean all

RUN yum install -y java java-devel wget initscripts
RUN yum install -y libffi-devel
RUN yum install -y @development
RUN yum install -y zlib-devel

ARG TARGETARCH=386
ARG COMMIT_SHA
ARG GIT_LFS_VERSION=3.0.2


ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home
ARG REF=/usr/share/jenkins/ref

ENV JENKINS_HOME $JENKINS_HOME
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}
ENV REF $REF

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p $JENKINS_HOME \
  && chown ${uid}:${gid} $JENKINS_HOME \
  && groupadd -g ${gid} ${group} \
  && useradd -N -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

# $REF (defaults to `/usr/share/jenkins/ref/`) contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p ${REF}/init.groovy.d

# Use tini as subreaper in Docker container to adopt zombie processes
COPY tini /sbin/tini
RUN chmod +x /sbin/tini

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.303}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=4dfe49cd7422ec4317a7c7a7c083f40fa475a58a7747bd94187b2cf222006ac0

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals
RUN chown -R ${user} "$JENKINS_HOME" "$REF"

ARG PLUGIN_CLI_VERSION=2.9.3
ARG PLUGIN_CLI_URL=https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${PLUGIN_CLI_VERSION}/jenkins-plugin-manager-${PLUGIN_CLI_VERSION}.jar
RUN curl -fsSL ${PLUGIN_CLI_URL} -o /opt/jenkins-plugin-manager.jar --insecure

# for main web interface:
EXPOSE ${http_port}

# will be used by attached agents:
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

# Skip initial setup
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
COPY tini-shim.sh /bin/tini
COPY jenkins-plugin-cli.sh /bin/jenkins-plugin-cli

USER root
COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/
RUN chmod +x /usr/local/bin/jenkins.sh
COPY plugins.txt /usr/share/jenkins/ref/
COPY install-plugins.sh /usr/local/bin/install-plugins.sh
RUN chmod +x /usr/local/bin/install-plugins.sh
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

USER ${user}
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN install-plugins.sh active.txt` to setup $REF/plugins from a support bundle
#COPY install-plugins.sh /usr/local/bin/install-plugins.sh
#RUN install-plugins.sh plugins.txt