FROM node
MAINTAINER Sveinn G. Gunnarsson <sveinng@gmail.com>
WORKDIR /opt/app
EXPOSE 3000

# Install yarn from the local .tgz
RUN mkdir -p /opt
ADD yarn-0.17.9.tar.gz /opt/
RUN mv /opt/dist /opt/yarn
ENV PATH "$PATH:/opt/yarn/bin"

# Prepare package installation
ADD package.json yarn.lock /tmp/
ADD .yarn-cache.tgz /

# Install packages using Yarn
RUN cd /tmp && yarn install
RUN mkdir -p /opt/app && cd /opt/app && ln -s /tmp/node_modules

# Install build artifacts and run application
ADD ./build/ .
ENV NODE_PATH /opt/app/
CMD ["node","run.js"]
