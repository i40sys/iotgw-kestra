FROM debian:stable-slim

ARG VERSION=1.10

RUN apt-get update
RUN apt-get -y install wget openssh-client usb.ids 
RUN wget -O /tmp/glpi-agent-linux-installer.pl https://github.com/glpi-project/glpi-agent/releases/download/${VERSION}/glpi-agent-${VERSION}-linux-installer.pl
RUN chmod 755 /tmp/glpi-agent-linux-installer.pl
RUN mkdir /keys
RUN ssh-keygen -q -t rsa -N '' -f /keys/id_rsa
RUN /tmp/glpi-agent-linux-installer.pl --cron --silent

ADD entrypoint.sh /
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]
