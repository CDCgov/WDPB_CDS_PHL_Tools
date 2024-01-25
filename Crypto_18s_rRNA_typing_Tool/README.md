# Cryptosporidium 18s rRNA Typing


### Tool Functionality

This tool's intended purpose is to identify Cryptosporidium species based on the characterization of the 18s rRNA gene. 

This tool has been converted into a Docker container for ease of use.

# Disclaimer

****Please note that the assays used are not ISO or CLIA-certified and should NOT be considered diagnostic!***

## Building Container
This repository consists of Cryptosporidium 18s rRNA typing characterization scripts, database, and associated Docker file required to build a docker image.

To rebuild the container, clone this repository and run the command below:
`docker build -tag(optional) -file Dockerfile <location>`

- Scripts folder
- Curated blast database - BlastDB_18s
- Test input files - to ensure the docker container runs as expected
- Docker file - if you would like to build a container on your own
- Settings.txt - dependencies script support file

## Requirements:

- Linux Operating system 
- [Docker](https://docs.docker.com/) 
- Python 3.7

## Expected Input:

Illumina Denovo assembly files in fasta format. 

We suggest using the WDPB CDS PHL crypto_decon_db_tool to determine if your sequencing data set is optimal for genome assembly before using this tool. Also, we tested this tool with the Skesa assembler.


## Expected Output: 

A csv format file with the following columns: query_genome,db_bestmatch,pident,alignment_length,coverage,bitscore,species


### Running with Docker

First, create an output directory before running the container. This output directory will be mounted to the container to capture your results locally.
``` mkdir <your_output_directory>```

Next, pull down the docker container (Make sure to pull the latest tag)

```
docker pull wdpbcdsphl/crypto_18s_typing:0.3
```
```
docker run -v $(pwd)/testdata:/Crypto18s/test1/ -v $(pwd)/18s_output:/Crypto18s/resultsdir/ --privileged wdpbcdsphl/crypto_18s_typing:0.3
```

You can replace the testdata folder with your input folder

If you encounter any errors while running the docker container, add --rm flag to the above command, this will clean up any running containers/file system that interrupts the current run. [refer --rm flag here](https://docs.docker.com/engine/reference/run/#clean-up---rm)

```
docker run -v $(pwd)/testdata:/Crypto18s/test1/ -v $(pwd)/18s_output:/Crypto18s/resultsdir/ --privileged **--rm** wdpbcdsphl/cryptosporidium_18s_typing:0.3
```

**Note Make sure all your files are in the same directory from where you are running the image, if not change the paths to respective locations

Please replace the testinput with your input assemblies folder/

Bind the User_settings.txt file as is, it is just to mirror the paths that are present at the root level in the docker container for singularity to exec and access the folders

If you want to access the intermediate files, add -B $(pwd)/some_dir:/Crypto18s/localdir/ to the singularity exec command.

### Running with Singularity
First, pull down the container
```
singularity pull docker://wdpbcdsphl/crypto_18s_typing:0.3
```
Run the container with Singularity:

```
singularity exec -B $(pwd)/user_settings.txt:/Crypto18s/scripts/settings.txt -B $(pwd)/testdata:/Crypto18s/test1/ -B $(pwd)/18s_output:/Crypto18s/resultsdir/ **crypto_18s_typing_0.2.sif** python3 /Crypto18s/scripts/18S_tool.py 
```
Note:
please replace the testdata with your samples folder (make sure your samples are in fasta format)

Bind the User_settings.txt file as is, it is just to mirror the paths that are present at the root level in the docker container for singularity to exec and access the folders

If you want to access the intermediate files, add -B $(pwd)/some_dir:/Crypto18s/localdir/ to the singularity exec command

### Developer
Developed by: Anusha Ginni (qux0@cdc.gov) Clinical Detection Surveillance/WDPB, CDC Tool version - 0.3, The database was updated on: 2023-09-28
