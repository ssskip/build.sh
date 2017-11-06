from ubuntu:latest

WORKDIR /tmp

COPY nginx.sh /tmp/

RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    lsb-release \
    && apt-get clean -y \
    && chmod +x nginx.sh

RUN bash -c "./nginx.sh" && nginx -V


ENTRYPOINT [""]