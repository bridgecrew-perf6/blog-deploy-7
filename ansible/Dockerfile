FROM ubuntu:bionic

RUN apt-get update
RUN apt-get -y install \
    python3 \
    python3-nacl \
    python3-pip \
    sudo 

RUN mkdir -p /ansible

COPY requirements.txt /ansible/requirements.txt
RUN pip3 install -r /ansible/requirements.txt

COPY . /ansible/playbook

ENV ANSIBLE_CONFIG=/ansible/playbook/ansible.cfg
RUN ansible-playbook /ansible/playbook/ghost.yml --inventory /ansible/playbook/inventory.yml 
