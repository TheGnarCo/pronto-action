# Default values of ARGs in global scope
ARG NODE_VER=16.17.0
ARG YARN_VER=1.22.19
ARG RUBY_VER=3.1.2

# https://hub.docker.com/_/node
FROM node:${NODE_VER}-alpine3.16 as nodejs

# https://hub.docker.com/_/ruby
FROM ruby:${RUBY_VER}-alpine3.16
ARG NODE_VER # stage local scope
ARG YARN_VER # stage local scope

# Install Node.js
ENV NODE_VERSION ${NODE_VER}
ENV YARN_VERSION ${YARN_VER}
RUN mkdir -p /opt
COPY --from=nodejs /opt/yarn-v${YARN_VERSION} /opt/yarn
COPY --from=nodejs /usr/local/bin/node /usr/local/bin/
COPY --from=nodejs /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
RUN ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npx

# Install Rubygems and dependencies
WORKDIR /pronto

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN set -eux; \
    apk add --no-cache --virtual .ruby-builddeps \
        alpine-sdk \
        cmake \
        openssl \
        openssl-dev \
    ; \
    bundle install --jobs 20 --retry 5 \
    ; \
    apk del --purge --no-network .ruby-builddeps \
    ; \
    apk add --no-cache \
        jq \
    ;

COPY entrypoint.sh entrypoint.sh
