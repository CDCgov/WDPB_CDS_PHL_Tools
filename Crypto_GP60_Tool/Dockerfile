FROM ubuntu:20.04

LABEL maintainer="Alyssa Kelley"
LABEL software="Cryptosporidium_GP60_Subtyping"
LABEL software.version="1.0"

WORKDIR .
COPY BlastDB_gp60/ db/
COPY Scripts/ scripts/
COPY Test_Input/ testdata/


RUN chmod -R 755 /scripts
RUN chmod -R 755 /db
RUN chmod -R 755 /testdata


RUN apt-get update && apt-get install -y ncbi-blast+=2.9.0-2 && \
    apt-get clean

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.UTF-8

ENTRYPOINT ["perl", "/scripts/gp60Typer.pl"]

