#########################################
# Builder image
#########################################
FROM openjdk:8 as builder
LABEL authors=RetailMeNot

RUN apt-get update && \
    apt-get -y install apt-transport-https && \
    echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    apt-get update && \
    apt-get -y install \
        sbt \
        gzip \
        libc6 \
        tar \
        zip \
        && \
    # make sbt use shared directories, so we can easily specify a different user to run the container
    mkdir /etc/ivy && \
    chmod -R 0777 /etc/sbt /etc/ivy && \
    echo "-sbt-dir /etc/sbt" >> /etc/sbt/sbtopts && \
    echo "-sbt-boot /etc/sbt/boot" >> /etc/sbt/sbtopts && \
    echo "-ivy /etc/ivy" >> /etc/sbt/sbtopts && \
    echo "-no-colors" >> /etc/sbt/sbtopts

WORKDIR /hydra

ADD . /hydra

RUN sbt clean test && \
    sbt universal:packageBin && \
    mkdir -p /opt/hydra && \
    unzip target/universal/hydra-*.zip -d /opt && \
    mv /opt/hydra-*/* /opt/hydra/


#########################################
# Runtime image
#########################################
FROM openjdk:alpine
LABEL authors=RetailMeNot

RUN apk update && \
    apk upgrade && \
    apk add bash

COPY --from=builder /opt/hydra/ /opt/hydra

EXPOSE 9000

CMD ["/opt/hydra/bin/hydra"]
