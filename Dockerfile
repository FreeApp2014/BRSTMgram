FROM docker.io/th089/swift:5.5.2-focal as builder
ADD . /sources
WORKDIR /sources
RUN mkdir /output && \
    apt update && apt install -y libcurl4-openssl-dev && \
    swift package resolve && \
    # cp ./.build/checkouts/SwiftyJSON/Sources/SwiftyJSON/SwiftyJSON.swift .build/checkouts/telegram-bot-swift/Sources/TelegramBotSDK/SwiftyJSON/ && \
    swift build && \
    tar -cvf /output/build.tar /sources/.build
RUN git clone https://github.com/ic-scm/openrevolution.git && \ 
    cd openrevolution && \
    clang++ -O2 ./src/converter.cpp -o /output/brstm -std=c++0x

FROM docker.io/th089/swift:5.5.2-focal
WORKDIR /code
COPY --from=builder /output/build.tar .
COPY --from=builder /output/brstm /usr/bin
RUN tar -xvf build.tar
ENTRYPOINT /code/sources/.build/debug/brstmbottg    
