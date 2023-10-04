#FROM node:19-alpine AS release
FROM node:18 AS release

ARG GIT_REVISION
ARG GIT_REPO_URL

ENV DEBIAN_FRONTEND noninteractive

#RUN apk add --no-cache git python3 make g++
RUN apt-get update && apt-get install -y git g++ build-essential

WORKDIR /root/

RUN set -ex \
  && git clone $GIT_REPO_URL release -b $GIT_REVISION --depth 1

WORKDIR /root/release/frontend

RUN set -ex \
 && npm i \
 && npm run build

FROM nginx:1.25-alpine

RUN apk add --no-cache perl

ENV TZ=Europe/Stockholm
COPY config.json /root/
COPY vue-config.sh /docker-entrypoint.d/
COPY nginx.conf /etc/nginx/
COPY --from=release /root/release/frontend/dist/. /var/share/nginx/html/
