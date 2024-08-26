#checkov:skip=CKV_DOCKER_3: we intend to use `root` user
#checkov:skip=CKV_DOCKER_4: we intend to download chez archive
ARG CHEZ_VERSION=10.0.0

FROM ubuntu:22.04 AS build
ARG CHEZ_VERSION

SHELL ["/bin/bash", "-c"]

ENV PATH "/root/.pack/bin:/root/.idris2/bin:$PATH"

# hadolint ignore=DL3008,DL3015
RUN apt-get update && apt-get install --yes gcc make libgmp3-dev git gnupg libx11-dev libncurses-dev && rm -rf /var/lib/apt/lists/*

ENV SCHEME=chezscheme

WORKDIR /opt/chezscheme
ADD https://github.com/cisco/ChezScheme/releases/download/v${CHEZ_VERSION}/csv${CHEZ_VERSION}.tar.gz cs.tar.gz
RUN tar xzf cs.tar.gz
WORKDIR /opt/chezscheme/csv${CHEZ_VERSION}

RUN ./configure --installschemename=$SCHEME
RUN make
RUN make install

WORKDIR /opt/idris2-pack

COPY Makefile .
COPY src src
COPY micropack micropack
COPY micropack.bash .
COPY pack.ipkg .
COPY pack-admin.ipkg .
RUN true

RUN make micropack SCHEME=$SCHEME

FROM ubuntu:22.04
ARG CHEZ_VERSION

# hadolint ignore=DL3008,DL3015
RUN apt-get update && apt-get install --yes gcc make libgmp3-dev git libx11-dev libncurses-dev && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/chezscheme /opt/chezscheme
WORKDIR /opt/chezscheme/csv${CHEZ_VERSION}
RUN make install

WORKDIR /

SHELL ["/bin/bash", "-c"]

ENV HOME="/root"
ENV PACK_DIR="$HOME/.pack"

ENV PATH "$PACK_DIR/bin:$PATH"
COPY --from=build $PACK_DIR $PACK_DIR

HEALTHCHECK CMD pack help || exit 1
