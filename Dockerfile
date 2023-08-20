FROM golang:1.20.5-alpine as builder

RUN apk add git

ARG GCSFUSE_REPO="/run/gcsfuse/"
ADD . ${GCSFUSE_REPO}
WORKDIR ${GCSFUSE_REPO}
RUN go mod init github.com/googlecloudplatform/gcsfuse
RUN go install ./tools/build_gcsfuse
RUN build_gcsfuse . /tmp $(git log -1 --format=format:"%H")


FROM alpine:latest AS build
RUN apk add build-base util-linux linux-headers g++ ninja cmake git perl zlib-dev bzip2-dev
RUN apk add curl python3 py3-crcmod

RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh
ENV PATH="/google-cloud-sdk/bin:${PATH}"

ARG CMAKE_BUILD_SHARED_LIBS=1
ARG CMAKE_BUILD_TYPE=Release
ARG VDB_BRANCH=engineering
ARG SRA_BRANCH=${VDB_BRANCH}
WORKDIR /root
RUN git clone -b ${VDB_BRANCH} --depth 1 https://github.com/ncbi/ncbi-vdb.git && \
    git clone -b ${SRA_BRANCH} --depth 1 https://github.com/ncbi/sra-tools.git
WORKDIR ncbi-vdb
RUN sed -i.orig -e '/^\s*add_subdirectory\s*(\s*test\s*)\s*$/ d' CMakeLists.txt && \
    sed -i.orig -e '/^\s*add_subdirectory\s*(\s*ktst\s*)\s*$/ d' libs/CMakeLists.txt
WORKDIR /root
RUN cmake -G Ninja -D CMAKE_BUILD_TYPE=Release \
          -S ncbi-vdb -B build/ncbi-vdb && \
    cmake --build build/ncbi-vdb
RUN sed -i.orig -e '/^\s*add_subdirectory\s*(\s*kxml\|vdb-sqlite\s*)\s*$/ d' sra-tools/libs/CMakeLists.txt && \
    sed -i.orig -e '/\bCPACK\|CPack/ d' sra-tools/CMakeLists.txt
RUN cmake -G Ninja                                  \
          -D CMAKE_BUILD_TYPE=Release               \
          -D VDB_LIBDIR=/root/build/ncbi-vdb/lib    \
          -S sra-tools -B build/sra-tools &&        \
    cmake --build build/sra-tools --target install
RUN mkdir -p /etc/ncbi
RUN printf '/LIBS/IMAGE_GUID = "%s"\n' `uuidgen` > /etc/ncbi/settings.kfg && \
    printf '/libs/cloud/report_instance_identity = "true"\n' >> /etc/ncbi/settings.kfg


FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine
RUN apk --update add openjdk7-jre
RUN apk add --no-cache libstdc++ libgcc
RUN apk add --update --no-cache bash ca-certificates fuse
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /etc/ncbi /etc/ncbi
COPY --from=builder /tmp/bin/gcsfuse /usr/local/bin/gcsfuse
COPY --from=builder /tmp/sbin/mount.gcsfuse /usr/sbin/mount.gcsfuse

# Very basic smoke test to check if runnable
RUN touch foo && srapath ./foo && rm foo