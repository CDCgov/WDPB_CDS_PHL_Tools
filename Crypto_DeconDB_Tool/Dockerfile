FROM ubuntu:18.04

# for easy upgrade later. ARG variables only persist during build time.
ARG K2VER="2.1.2"
ARG DBVER="2"

LABEL base.image="ubuntu:18.04"
LABEL dockerfile.version="1"
LABEL software="Kraken2"
LABEL software.version="2.1.2"
LABEL description="Taxonomic sequence classifier"
LABEL website="https://github.com/DerrickWood/kraken2"
LABEL license="https://github.com/DerrickWood/kraken2/blob/master/LICENSE"
LABEL maintainer="Jill Hagey"
LABEL maintainer.email="qpk9@cdc.gov"

# install dependencies and cleanup apt garbage
RUN apt-get update && apt-get -y --no-install-recommends install \
 python3 \
 python3-pip \
 wget \
 ca-certificates \
 zlib1g-dev \
 make \
 g++ \
 rsync \
 cpanminus && \
 rm -rf /var/lib/apt/lists/* && apt-get autoclean

# perl module required for kraken2-build
RUN cpanm Getopt::Std

# DL Kraken2, unpack, and install
RUN wget https://github.com/DerrickWood/kraken2/archive/v${K2VER}.tar.gz && \
 tar -xzf v${K2VER}.tar.gz && \
 rm -rf v${K2VER}.tar.gz && \
 cd kraken2-${K2VER} && \
 ./install_kraken2.sh . && \
 mkdir /data /kraken2-db

RUN pip3 install --no-cache-dir biopython

ENV PATH="$PATH:/kraken2-${K2VER}" \
    LC_ALL=C

ENV KRAKEN2_DEFAULT_DB="/kraken2-db/Crypto_DB_V${DBVER}"
ENV KRAKEN2_DB_PATH="/kraken2-db/Crypto_DB_V${DBVER}"

WORKDIR /data

# Copying extract_kraken_reads.py script
COPY extract_kraken_reads.py /usr/local/bin
# changing permissions on extract_kraken_reads.py 
RUN chmod 755 /usr/local/bin/extract_kraken_reads.py 
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

#add script to path
ENV PATH="$PATH:/usr/local/bin/extract_kraken_reads.py"

##### DATABASE INCLUDED WITH THIS DOCKER IMAGE: Cryptosporidium Genomes ONLY #####
COPY Crypto_DB_V${DBVER}.tar.gz ../kraken2-db/Crypto_DB_V${DBVER}.tar.gz
RUN cd ../kraken2-db && \
 tar -xvzf Crypto_DB_V${DBVER}.tar.gz && \
 rm Crypto_DB_V${DBVER}.tar.gz

# Making the inspect file to know what is in the database
RUN kraken2-inspect --db ../kraken2-db/Crypto_DB_V${DBVER} > inspect.txt
