FROM debian:buster

LABEL description="Provides an image with Janus Gateway"

# Install system dependencies
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y \
    libmicrohttpd-dev \
    libjansson-dev \
	libssl-dev \
    libsrtp2-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
	libopus-dev \
    libogg-dev \
    libcurl4-openssl-dev \
    liblua5.3-dev \
	libconfig-dev \
    libnanomsg-dev \
    libtool \
    build-essential \
    cmake \
    autotools-dev \
    automake \
    gtk-doc-tools \
    pkg-config \
    gengetopt \
    git \
    nginx

RUN git clone --branch 0.1.16 --depth 1 https://gitlab.freedesktop.org/libnice/libnice \
    && pushd libnice \
    && ./autogen.sh \
    && ./configure --prefix=/usr \
    && make && make install \
    && popd

RUN git clone --depth 1 https://github.com/sctplab/usrsctp \
    && pushd usrsctp \
    && ./bootstrap \
    && ./configure --prefix=/usr \
    && make && make install \
    && popd

RUN git clone --branch v3.2-stable --depth 1 https://libwebsockets.org/repo/libwebsockets \
    && pushd libwebsockets \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. \
    && make && make install \
    && popd

RUN git clone --branch v0.10.0 --depth 1 https://github.com/alanxz/rabbitmq-c \
    && pushd rabbitmq-c \
    && git submodule init \
    && git submodule update \
    && mkdir build && cd build \
    &&cmake -DCMAKE_INSTALL_PREFIX=/usr .. \
    && make && make install \
    && popd

RUN git clone https://github.com/meetecho/janus-gateway.git \
    && pushd janus-gateway \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus \
    && make \
    && make install \
    && make configs \\
    && popd

COPY conf/*.cfg /opt/janus/etc/janus/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 7088 8088 8188 8089
EXPOSE 10000-10200/udp

CMD service nginx restart && /opt/janus/bin/janus --nat-1-1=${DOCKER_IP}