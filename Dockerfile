# build is stage 1: it compiles the webapp.
FROM eclipse-temurin:8-jdk-alpine AS build

ENV ANT_VERSION=1.10.15
ENV ANT_HOME=/etc/ant-${ANT_VERSION}

WORKDIR /tmp

RUN wget -q https://dlcdn.apache.org/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
  && mkdir ant-${ANT_VERSION} \
  && tar -xzvf apache-ant-${ANT_VERSION}-bin.tar.gz \
  && mv apache-ant-${ANT_VERSION} ${ANT_HOME} \
  && rm apache-ant-${ANT_VERSION}-bin.tar.gz \
  && rm -rf ${ANT_HOME}/manual \
  && unset ANT_VERSION

ENV PATH=${PATH}:${ANT_HOME}/bin

WORKDIR /home/jgoethe
COPY . .
RUN apk add --no-cache --virtual .build-deps \
  nodejs \
  npm \
  git \
  && npm i npm@latest -g
RUN ant


# webapp is the actual running and exist serving webapp
FROM stadlerpeter/existdb:latest AS webapp 

ENV EXIST_CONTEXT_PATH=/
ENV EXIST_DEFAULT_APP_PATH=xmldb:exist:///db/apps/jgoethe

USER wegajetty
COPY --from=build /home/jgoethe/build/jgoethe-0.1.0.xar ${EXIST_HOME}/autodeploy
