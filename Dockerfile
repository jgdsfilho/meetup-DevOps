from python:3-buster

RUN apt-get update && apt-get install openssh-server -y

COPY id_rsa.pub /root/.ssh/authorized_keys

RUN mkdir /var/run/sshd

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]


