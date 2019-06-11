FROM centos:latest

#======= Install utility for compile package 
RUN yum install -y wget tar unzip bind sudo gcc make tar ruby-devel gcc make rpm-build rubygems

#======== Install openjdk-devel-1.8.0.212 for OpenJDK Development Environment =========
# java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6 for OpenJDK Runtime Environment
RUN yum install -y java-1.8.0-openjdk-devel-1.8.0.212.b04-0.el7_6

RUN yum install apr-devel openssl-devel -y

COPY build.sh /tmp/build.sh
RUN chmod 755 /tmp/build.sh
