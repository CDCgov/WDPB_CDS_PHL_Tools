# Cryptosporidium Decontamination Sequencing Read Identiier


## Tool Functionality

This tool's intended purpose is to assist with the identification of high quality Cryptosporidium next generation sequencing reads from an Illumina paired end data set for whole genome isolate sequencing. This tool has been converted into a Docker container.  The container has a Kraken2 custom database to identify sequences that belong to *Cryptosporidium* spps. Additionally, there is a script (`extract_kraken_reads.py`) included in the container to extract out the sequences that belong to *Cryptosporidium*.  Also, The `inspect.txt` file has the full list of *Cryptosporidium* spps that are contained the container.

Based on our internal assessment a minimum threshold of XX% percentage should be classified based on the custom *Cryptosporidium* kraken database to determine if a NGS sequencing read set is acceptable for other WDPB CDS PHL developed tools.

### Disclaimer

****Please note that the assays used are not ISO or CLIA-certified and should NOT be considered diagnostic!***

## Building Container

If you want to rebuild the container you can with the following command, but you will need to **also** build a Kraken2 database to include in it before. 

`docker build -t wdpbcdsphl/crypto_decon_db:1.0 . --force-rm`

It's easier to just pull the container from [dockerhub](https://hub.docker.com/r/wdpbcdsphl/crypto_decon_db), the command for which are below. 

## Requirements:

- Linux Operating system or Windows Subsystem for Linux ([WSL](https://jvhagey.github.io/Tutorials/mydoc_wsl.html))
- [Docker](https://docs.docker.com/) or [Singularity](https://singularity-userdoc.readthedocs.io/en/latest/) 

## Expected Input:

This workflow as **TWO** steps and **BOTH** must be completed. 

## Kraken2

**--use-names**      Print scientific names instead of just taxids  
**--report**         Print a report with aggregrate counts/clade to file  
**--paired**         The filenames provided have paired-end reads  
**--output**         Print output to filename (default: stdout); "-" will suppress normal output  

If you aren't familiar with kraken2 you can learn more with these resources:
- [kraken2 manual](https://ccb.jhu.edu/software/kraken2/)
- [kraken2 github](https://github.com/DerrickWood/kraken2/wiki)
- [kraken2 paper](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1891-0)

## extract_kraken_reads.py 

**-s file_1.fastq -s2 file_2.fastq**                    Fastq files you passed to Kraken2 with the `--paired` flag    
**-o file_Kclean_1.fastq -o2 file_Kclean_2.fastq**      The name you want to assign to the forward and reverse reads after extracting *Cryptosporidium* sequences  
**--report reportFile.txt**                             Report file that came from Kraken2 `--report`  
**-k reportFile.kraken**                                Output file that came from Kraken2 `--output` 

If you aren't familiar with krakentools you can learn more with these resources:
- [krakentools](https://github.com/jenniferlu717/KrakenTools)

## Expected Output: 

Kraken2 will create two files:
- File_name.txt (report)
- File_name.kraken 

The output of Kraken2 is tab-delimited file, described in [Kraken2 documentation](https://github.com/DerrickWood/kraken2/wiki/Manual#output-formats), with one line per taxon. Kraken 2's standard sample report format is tab-delimited with one line per taxon. The fields of the output, from left-to-right, are as follows:

1. Percentage of fragments covered by the clade rooted at this taxon
2. Number of fragments covered by the clade rooted at this taxon
3. Number of fragments assigned directly to this taxon
4. A rank code, indicating (U)nclassified, (R)oot, (D)omain, (K)ingdom, (P)hylum, (C)lass, (O)rder, (F)amily, (G)enus, or (S)pecies. Taxa that are not at any of these 10 ranks have a rank code that is formed by using the rank code of the closest ancestor rank with a number indicating the distance from that rank. E.g., "G2" is a rank code indicating a taxon is between genus and species and the grandparent taxon is at the genus rank.
5. NCBI taxonomic ID number
6. Indented scientific name

The scientific names are indented using space, according to the tree structure specified by the taxonomy. Taxa with no reads assigned to (or under) them will not have any output produced. 

You can generate different outputs if you change the arguments presented in this documentation. Consult Kraken2 documenation and `kraken2 --help` for more information. 

The script `extract_kraken_reads.py` will create new versions of the forward and reverse reads you give it. You can name these whatever you want. 

## Step 1: Running Kraken2

### Running with Docker

First, pull down docker container

```
docker pull wdpbcdsphl/crypto_decon_db:1.0
```

To get a full list of arguments for Kraken2 run the following. **You will need to make sure you are in the directory where the samples you want to run are located. Or you can change `$PWD` to the actual path where the files are.**

```
docker run -v $PWD:/data wdpbcdsphl/crypto_decon_db:1.0 kraken2 --help
```

You can run Kraken2 on your samples with the following line, but will need to change a the files names:
- `file_1.fastq` and `file_2.fastq` should be the name of your input sequence files. 
- `reportFile.txt` and `reportFile.kraken` should be names you choose and can be whatever you want, but keep the same extensions (i.e. `.txt` and `.kraken`).

```
docker run -v $PWD:/data wdpbcdsphl/crypto_decon_db:1.0 kraken2 --use-names --report reportFile.txt --paired file_1.fastq file_2.fastq --output reportFile.kraken
```

**Note you might need to add the flag `--privileged` after `-v` if you get an error regarding permissions being denied.** If you are certain that there are sequences in your fastq files (i.e. they aren't empty), the error might look something like this.

```
Loading database information... done.
0 sequences (0.00 Mbp) processed in 0.000s (0.0 Kseq/m, 0.00 Mbp/m).
  0 sequences classified (-nan%)
  0 sequences unclassified (-nan%)
```

### Running with Singularity

First, pull down the container

```
singularity pull crypto_decon_db.sif docker://wdpbcdsphl/crypto_decon_db:1.0
```

You might need to check where singularity has it cache. It's default is `~$HOME/.singularity/cache/`. You can change this by editing `SINGULARITY_CACHEDIR` in your `~/.bash_profile` by adding the following lines to that file. Make sure you change `$PATH` to the path you actually want. 

```
export SINGULARITY_PULLFOLDER=/$PATH/Singularity_Containers
export SINGULARITY_CACHEDIR=/$PATH/Singularity_Containers
```

Once the sif file is downloaded we can run Kraken2. **Again, make sure you are in the directory were your files are located!!**

```
singularity exec $SINGULARITY_CACHEDIR/crypto_decon_db.sif kraken2 --use-names --report reportFile.txt --paired file_1.fastq file_2.fastq --output reportFile.kraken
```

## Step 2: Extracting Sequences 

### Running with Docker

To complete the workflow run the script to extract the reads that belong to *Cryptosporidium*. You need to change the following in the line below to make the script run with your files:
- `file_1.fastq` and `file_2.fastq` should be the name of your input sequence files. 
- `file_Kclean_1.fastq`, `file_Kclean_2.fastq` should be custom names for output files, but keep the same extensions (i.e. `.fastq`). 
- `reportFile.txt` and `reportFile.kraken` should be the same as the names you choose in step 1 for the kraken2 output. 

```
docker run -v $PWD:/data wdpbcdsphl/crypto_decon_db:1.0 extract_kraken_reads.py --include-children --fastq-output --taxid 5806 -s file_1.fastq -s2 file_2.fastq -o file_Kclean_1.fastq -o2 file_Kclean_2.fastq --report reportFile.txt -k reportFile.kraken
```

**Note you might need to add the flag `--privileged` after `-v` if you get an error regarding permissions being denied.**

This script (`extract_kraken_reads.py`) was originally written by Jen Lu @ John Hopkins and can be found [here](https://github.com/jenniferlu717/KrakenTools). Edits were made to work with our sequences data and the issue was discussed and documented [here](https://github.com/jenniferlu717/KrakenTools/issues/16). If you get output that does not extract any sequences (see example below) and you have reason to believe there is *Cryptosporidium* in the sample contact the WDPB Bioinformatics team for assistance debugging. 

```
PROGRAM START TIME: 11-19-2021 08:54:26
        1 taxonomy IDs to parse
>> STEP 1: PARSING KRAKEN FILE FOR READIDS AZTI526.kraken
        0.00 million reads processed
        0 read IDs saved
>> STEP 2: READING SEQUENCE FILES AND WRITING READS
        0 read IDs found (0.00 mill reads processed)
        0 read IDs found (0.00 mill reads processed)
        0 reads printed to file
        Generated file: file_Kclean_1.fastq
        Generated file: file_Kclean_2.fastq
```

**However, you should note that this type of output could also mean that you have no reads assigned to Cryptosporidium.** To double check that there are *Cryptosporidium* sequences in your sample see how many reads map to a [*Cryptosporidium* reference squence](https://cryptodb.org/common/downloads/release-54/CparvumIowaII/fasta/data/CryptoDB-54_CparvumIowaII_Genome.fasta) using an alignment software like [bowtie2](https://github.com/BenLangmead/bowtie2). 

### Running with Singularity

Complete the workflow by extracting the reads assigned to *Cryptosporidium*. **Make sure you are in the directory were your files are located!!**

Just like with Docker you need to change the following in the line below to make the script run with your files:
- `file_1.fastq` and `file_2.fastq` should be the name of your input sequence files. 
- `file_Kclean_1.fastq`, `file_Kclean_2.fastq` should be custom names for output files, but keep the same extensions (i.e. `.fastq`, `.txt` and `.kraken`). 
- `reportFile.txt` and `reportFile.kraken` should be the same as the names you choose in step 1 for the kraken2 output.  

```
singularity exec $SINGULARITY_CACHEDIR/crypto_decon_db.sif extract_kraken_reads.py --include-children --fastq-output --taxid 5806 -s file_1.fastq -s2 file_2.fastq -o file_Kclean_1.fastq -o2 file_Kclean_2.fastq --report reportFile.txt -k reportFile.kraken
```

## What is in the database?

To find out what species are contained in the database run one of the following lines:

### Docker

```
docker run -v $PWD:/data wdpbcdsphl/crypto_decon_db:1.0 kraken2-inspect --db ../kraken2-db/Crypto_DB_V2 > inspect.txt
more inspect.txt
```

### Singularity

```
singularity exec $SINGULARITY_CACHEDIR/crypto_decon_db.sif kraken2-inspect --db ../kraken2-db/Crypto_DB_V2 > inspect.txt
more inspect.txt
```

## Developer
Developed by: Jill V. Hagey, (qpk9@cdc.gov) 
Clinical Detection Surveillance/WDPB, CDC
Tool version - 1.0
Database was updated on: 2021-12-22
