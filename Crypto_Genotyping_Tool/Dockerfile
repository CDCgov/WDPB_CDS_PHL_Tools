#base image
FROM ubuntu:20.04

#metadata
LABEL software="Cryptosporidium Genotyping"
LABEL software.version="1.8"
LABEL description="Tool performs species genotyping of cryptosporidium using blast reference database that contains 3 genes: Actin,hsp70 & 18s"
LABEL maintainer="Anusha Ginni"
LABEl maintainer.email="qxu0@cdc.gov"

#install dependencies------
RUN apt-get update && apt-get install -y ncbi-blast+ \
python3.7 \
python3-pip &&\
apt-get autoclean

#set working directory------
#RUN mkdir Crypto_output/
WORKDIR .
COPY scripts/ Crypto/scripts/
COPY settings.txt Crypto/scripts/
COPY db_all3/ Crypto/db_all3/

#setting permissions

RUN chmod -R 755 Crypto/scripts/
RUN chmod -R 755 Crypto/db_all3/

#install required libraries------
RUN pip3 install -r Crypto/scripts/modules.txt

#run command
CMD ["python3", "Crypto/scripts/Cryptosporidium_Genotyping_Revised.py"]
