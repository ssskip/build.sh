FROM debian:7

WORKDIR /home/testing

COPY nginx.sh ./

RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    lsb-release \
    && apt-get clean -y \
    && chmod +x nginx.sh

RUN bash -c "./nginx.sh" && nginx -V


ENTRYPOINT [""]

