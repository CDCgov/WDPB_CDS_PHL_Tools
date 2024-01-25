# Cryptosporidium GP60 Characterization Tool


### Tool Functionality

This tool's intended purpose is to perform Cryptosporidium subtyping utilizing the GP60 genomic target region within the Cryptosporidium genome. The region targets the subtype family, short tandem repeats, and secondary repeats within the sequence. The tool works with Sanger sequences and isolates whole genome contig sequences in fasta format. 

# Disclaimer

****Please note that the assays used are not ISO or CLIA-certified and should NOT be considered diagnostic!***

## Building Container

To rebuild the container, clone this repository and run the command below:
`docker build -tag(optional) -file Dockerfile <location>`

## Requirements:
- Linux Operating system 
- [Docker](https://docs.docker.com/) 
- Perl

## Expected Input:
- --fasta		Fasta file with 1 or more sanger sequences OR a fasta file containing the assembly of 1 samples
- --blastdb	Prebuilt curated blast database
- --data		Data type can be sanger or wgs (capitalization does not matter)

## Expected Output: 
Generates the gp60 subtyping results in a tab-delimited text format

### Running with Docker
``` docker run -v $(pwd)/SM_TestData:/test --privileged wdpbcdsphl/crypto_gp60:2.5 perl /scripts/gp60Typer.pl --blastdb db/Crypto_GP60_DB_2023-16-05 --fasta /test/testInput_SM.fasta --data sanger > results_gp60SM-15.txt ```


### Running with Singularity
```singularity exec -B $(pwd)/SM_TestData:/dataIn crypto_gp60-2.5.simg perl /scripts/gp60Typer.pl --blastdb /db/Crypto_GP60_DB_2023-16-05 --fasta /dataIn/gp60_seqs.fasta --data sanger```

## Developer
Developed by: Alyssa Kelly, akelley139@gmail.com

Modification by: Shatavia Morrison, SMorrison@cdc.gov

Clinical Detection Surveillance/WDPB, CDC


Tool version - 2.5


The database was updated on: 2023-11-09
