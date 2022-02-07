### Cryptosporidium Multilocus Genotyping - V1.8
#### Functionality

The main functionality of this tool is, it takes the input fasta assemblies and blasts against the reference data base that contains 18s, Actin and hsp70 genes. Species were characterized based on the percent identity and coverage with these genes and will be listed based on the number of hits that each gene has for that species. And the Final_Species_call contains the species characterization result in a readable csv format along with the encrypted blast results.

#### Requirements

- Linux Operating System
- Docker
- Python:3.7

#### Expected Input
This repository consists of Cryptosporidium Genotyping characterization tool and associated Docker files required to build a docker image.

 scripts - Genotyping tool and its support files
 
 db_all3 - Blast database
 
 Dockerfile - Dockerfile to build the image
 
 settings.txt - support file
 
 testinput - sample input to run the container
 

#### Expected Output
Crypto_output contains raw encrypted results, decrypted species characterization in the Final_Species_call file in csv format, and workflow logs  

 
#### Usage:

To build the image, clone this repository and run the command below.

`docker build -tag(optional) -file Dockerfile <location>`

To run the container, run the commands below:
 
> Make sure to create the output directory before running the container,so while running you can mount the folder to capture the results in your local.
>
>> `mkdir <your_output_dirname>`

`mkdir` **`Crypto_output`**

`docker run -v $(pwd)/`**`testinput`**`:/Crypto/testinput/ -v $(pwd)/`**`Crypto_output`**`:/Crypto/resultsdir/ --privileged --rm wdpbcdsphl/cryptosporidium_genotyping:1.8`

You can replace the **testinput** folder with your input folder

If you encounter any error while running the docker container, add --rm flag to the above command, this will clean up any running containers/file system that interrupts the current run. more info on --rm flag
docker run -v $(pwd)/testinput:/Crypto/testinput/ -v $(pwd)/Crypto_output:/Crypto/resultsdir/ --privileged **--rm** wdpbcdsphl/cryptosporidium_genotyping:1.8

