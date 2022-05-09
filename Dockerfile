FROM docker.io/swiftarm/swift:5.6.1-ubuntu-focal as builder
ADD . /sources
WORKDIR /sources
RUN mkdir /output && \
    apt update && apt install -y libcurl4-openssl-dev && \
    swift package resolve && \
    swift build && \
    tar -cf /output/build.tar /sources/.build
RUN git clone https://github.com/ic-scm/openrevolution.git && \ 
    cd openrevolution && \
    clang++ -O2 ./src/converter.cpp -o /output/brstm -std=c++0x

FROM docker.io/swiftarm/swift:5.6.1-ubuntu-focal-slim
WORKDIR /code
COPY --from=builder /output/build.tar .
COPY --from=builder /output/brstm /usr/bin
RUN tar -xf build.tar
ENTRYPOINT /code/sources/.build/debug/brstmbottg    
