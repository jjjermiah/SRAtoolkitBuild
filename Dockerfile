# Stage 1: Build stage
FROM golang:alpine AS builder

RUN apk --update --no-cache add git fuse fuse-dev;
RUN go install github.com/googlecloudplatform/gcsfuse@master
# RUN build_gcsfuse ${GOPATH}/src/github.com/googlecloudplatform/gcsfuse /tmp ${GCSFUSE_VERSION}


# Stage 2: stage 

FROM ncbi/sra-tools:latest AS build

RUN apk add --no-cache \
    curl python3 py3-crcmod
    # build-base util-linux linux-headers g++ ninja cmake git perl zlib-dev bzip2-dev \

# Install Google Cloud SDK
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh

RUN ls /usr/local/bin
RUN ls /etc/ncbi
RUN ls /google-cloud-sdk

# Stage 3
FROM alpine:latest
COPY --from=builder /go/bin/gcsfuse /usr/local/bin/gcsfuse

# Copy Google Cloud SDK from the build stage
COPY --from=build /google-cloud-sdk /google-cloud-sdk

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /etc/ncbi /etc/ncbi


# TEST 
RUN prefetch --help

RUN gcsfuse --help

RUN fasterq-dump --help


# Copy any other files or configurations you need
# COPY ... /destination/path

# Set environment variables if needed
# ENV ...

# Your entrypoint or command


# FROM ncbi/sra-tools:latest AS build 

# # RUN apk add --no-cache \
# #     build-base util-linux linux-headers g++ ninja cmake git perl zlib-dev bzip2-dev \
# #     curl python3 py3-crcmod

# # Install Google Cloud SDK
# RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
#     tar xzf google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
#     rm google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
#     ./google-cloud-sdk/install.sh
# ENV PATH="/google-cloud-sdk/bin:${PATH}"

# # Clone repositories and build
# WORKDIR /root
# ARG CMAKE_BUILD_SHARED_LIBS=1
# ARG CMAKE_BUILD_TYPE=Release
# ARG VDB_BRANCH=engineering
# ARG SRA_BRANCH=${VDB_BRANCH}
# RUN git clone -b ${VDB_BRANCH} --depth 1 https://github.com/ncbi/ncbi-vdb.git && \
#     git clone -b ${SRA_BRANCH} --depth 1 https://github.com/ncbi/sra-tools.git
# WORKDIR ncbi-vdb
# RUN sed -i.orig -e '/^\s*add_subdirectory\s*(\s*test\s*)\s*$/ d' CMakeLists.txt && \
#     sed -i.orig -e '/^\s*add_subdirectory\s*(\s*ktst\s*)\s*$/ d' libs/CMakeLists.txt
# WORKDIR /root
# RUN cmake -G Ninja -D CMAKE_BUILD_TYPE=Release \
#           -S ncbi-vdb -B build/ncbi-vdb && \
#     cmake --build build/ncbi-vdb
# RUN sed -i.orig -e '/^\s*add_subdirectory\s*(\s*kxml\|vdb-sqlite\s*)\s*$/ d' sra-tools/libs/CMakeLists.txt && \
#     sed -i.orig -e '/\bCPACK\|CPack/ d' sra-tools/CMakeLists.txt
# RUN cmake -G Ninja                                  \
#           -D CMAKE_BUILD_TYPE=Release               \
#           -D VDB_LIBDIR=/root/build/ncbi-vdb/lib    \
#           -S sra-tools -B build/sra-tools &&        \
#     cmake --build build/sra-tools --target install
# RUN mkdir -p /etc/ncbi
# RUN printf '/LIBS/IMAGE_GUID = "%s"\n' `uuidgen` > /etc/ncbi/settings.kfg && \
#     printf '/libs/cloud/report_instance_identity = "true"\n' >> /etc/ncbi/settings.kfg

# # Final image stage
# FROM alpine:latest
# RUN apk --no-cache add \
#     openjdk7-jre libstdc++ libgcc fuse

# COPY --from=build /usr/local/bin /usr/local/bin
# COPY --from=build /etc/ncbi /etc/ncbi

# # Install gcsfuse
# RUN apk --no-cache add go && \
#     go install github.com/googlecloudplatform/gcsfuse@latest

# # TEST 
# RUN prefetch --help

# RUN gcsfuse --help

# RUN fasterq-dump --help

# # FROM alpine:latest AS build
# # RUN apk add build-base util-linux linux-headers g++ ninja cmake git perl zlib-dev bzip2-dev
# # RUN apk add curl python3 py3-crcmod

# # RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
# #     tar xzf google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
# #     rm google-cloud-sdk-443.0.0-linux-x86_64.tar.gz && \
# #     ./google-cloud-sdk/install.sh
# # ENV PATH="/google-cloud-sdk/bin:${PATH}"

# # ARG CMAKE_BUILD_SHARED_LIBS=1
# # ARG CMAKE_BUILD_TYPE=Release
# # ARG VDB_BRANCH=engineering
# # ARG SRA_BRANCH=${VDB_BRANCH}
# # WORKDIR /root
# # RUN git clone -b ${VDB_BRANCH} --depth 1 https://github.com/ncbi/ncbi-vdb.git && \
# #     git clone -b ${SRA_BRANCH} --depth 1 https://github.com/ncbi/sra-tools.git
# # WORKDIR ncbi-vdb
# # RUN sed -i.orig -e '/^\s*add_subdirectory\s*(\s*test\s*)\s*$/ d' CMakeLists.txt && \
# #     sed -i.orig -e '/^\s*add_subdirectory\s*(\s*ktst\s*)\s*$/ d' libs/CMakeLists.txt
# # WORKDIR /root
# # RUN cmake -G Ninja -D CMAKE_BUILD_TYPE=Release \
# #           -S ncbi-vdb -B build/ncbi-vdb && \
# #     cmake --build build/ncbi-vdb
# # RUN sed -i.orig -e '/^\s*add_subdirectory\s*(\s*kxml\|vdb-sqlite\s*)\s*$/ d' sra-tools/libs/CMakeLists.txt && \
# #     sed -i.orig -e '/\bCPACK\|CPack/ d' sra-tools/CMakeLists.txt
# # RUN cmake -G Ninja                                  \
# #           -D CMAKE_BUILD_TYPE=Release               \
# #           -D VDB_LIBDIR=/root/build/ncbi-vdb/lib    \
# #           -S sra-tools -B build/sra-tools &&        \
# #     cmake --build build/sra-tools --target install
# # RUN mkdir -p /etc/ncbi
# # RUN printf '/LIBS/IMAGE_GUID = "%s"\n' `uuidgen` > /etc/ncbi/settings.kfg && \
# #     printf '/libs/cloud/report_instance_identity = "true"\n' >> /etc/ncbi/settings.kfg


# # # FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine

# # RUN apk --update add openjdk7-jre
# # RUN apk add --no-cache libstdc++ libgcc
# # RUN apk add --no-cache git
# # RUN apk add --update --no-cache bash ca-certificates fuse
# # COPY --from=build /usr/local/bin /usr/local/bin
# # COPY --from=build /etc/ncbi /etc/ncbi

# # RUN apk add --no-cache go

# # RUN go install github.com/googlecloudplatform/gcsfuse@latest


# # # Very basic smoke test to check if runnable
# # RUN touch foo && srapath ./foo && rm foo