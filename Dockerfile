FROM alpine

RUN apk add git curl perl
RUN curl -LO https://github.com/minamijoyo/hcledit/releases/download/v0.2.17/hcledit_0.2.17_linux_amd64.tar.gz && \
    tar -xzf hcledit_0.2.17_linux_amd64.tar.gz && \
    mv hcledit /usr/local/bin/&& rm hcledit_0.2.17_linux_amd64.tar.gz && \
    chmod +x /usr/local/bin/hcledit

RUN mkdir /app
COPY . /app
WORKDIR /app