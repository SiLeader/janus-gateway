FROM debian:bookworm-slim AS builder

WORKDIR /work
COPY . .

RUN apt-get update && \
    apt-get install -y libmicrohttpd-dev libjansson-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev libconfig-dev \
                       pkg-config libtool automake \
		       python3 meson ninja-build cmake git wget

RUN git clone https://gitlab.freedesktop.org/libnice/libnice && \
    cd libnice && \
    meson --prefix=/usr/local build && ninja -C build && ninja -C build install && \
    mv /usr/local/lib/x86_64-linux-gnu/libnice* /usr/local/lib

RUN wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && \
    tar xfv v2.2.0.tar.gz && \
    cd libsrtp-2.2.0 && \
    ./configure --prefix=/usr/local --enable-openssl && \
    make -j $(nproc) shared_library && make install

RUN git clone https://github.com/sctplab/usrsctp && \
    cd usrsctp && \
    ./bootstrap && \
    ./configure --prefix=/usr/local --disable-programs --disable-inet --disable-inet6 && \
    make -j $(nproc) && make install

RUN git clone https://libwebsockets.org/repo/libwebsockets && \
    cd libwebsockets && \
    git checkout v4.3-stable && \
    mkdir build && \
    cd build && \
    cmake -GNinja -DLWS_MAX_SMP=1 -DLWS_WITHOUT_EXTENSIONS=0 -DCMAKE_INSTALL_PREFIX:PATH=/usr/local -DCMAKE_C_FLAGS="-fpic" .. && \
    ninja && ninja install

RUN sh autogen.sh && \
    ./configure --prefix /usr/local && \
    make -j $(nproc) && make install && make configs


FROM debian:bookworm-slim

COPY --from=builder /usr/local /usr/local

RUN apt-get update && \
    apt-get install -y libconfig9 openssl libglib2.0-0 libjansson4 libcurl4 libmicrohttpd12 libsofia-sip-ua0 libopus0 libogg0 && \
    ldconfig

CMD ["/usr/local/bin/janus"]
