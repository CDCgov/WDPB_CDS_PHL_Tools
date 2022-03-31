#base image
FROM ubuntu:20.04

#Container details

LABEL software="Cryptosporidium 18s rRNA typing"
LABEL software.version="0.1"
LABEL description="Tool performs species genotyping of cryptosporidium using blast reference database that contains 18s rRNA marker gene"
LABEL maintainer="Anusha Ginni"
LABEl maintainer.email="qxu0@cdc.gov"

#install dependencies------

RUN apt-get update && apt-get install -y ncbi-blast+ \
python3.7 \
python3-pip &&\
apt-get autoclean

#set working directory------

WORKDIR .
COPY scripts/ Crypto18s/scripts/
COPY settings.txt Crypto18s/scripts/
COPY BlastDB_18S/ Crypto18s/BlastDB_18S/

#setting permissions

RUN chmod -R 755 Crypto18s/scripts/
RUN chmod -R 755 Crypto18s/BlastDB_18S/

#install required libraries------
RUN pip3 install -r Crypto18s/scripts/py_modules.txt

#run command
CMD ["python3", "Crypto18s/scripts/18S_tool.py"]


