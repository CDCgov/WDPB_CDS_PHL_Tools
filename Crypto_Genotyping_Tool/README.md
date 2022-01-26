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
Crypto_output  logs and raw encrypted results, and species characterization is decrypted to Final_Species_call in csv file format

 
#### Usage:
> Make sure to create the output directory before running the container,so while running you can mount the folder to capture the results in your local.
>
>> `mkdir <your_output_dirname>`

`mkdir` **`Crypto_output`**

`docker run -v $(pwd)/`**`testinput`**`:/Crypto/testinput/ -v $(pwd)/`**`Crypto_output`**`:/Crypto/resultsdir/ --privileged --rm wdpbcdsphl/cryptosporidium_genotyping:1.3`

You can replace the **testinput** folder with your input folder
