### GP60 Tool

This tool performs cryptosporidium subtyping by analysing the genetic diversity and characterizes the subtype based on the subtype family, short tandem repeats and secondary repeats. Gp60 tool can process WGS and Sanger sequences. 

#### Requirements

- Linux Operating system
- Docker
- Perl 

#### Expected Input

-	--fasta		Fasta file with 1 or more sanger sequences OR a fasta file containing the assembly of 1 samples
-	--blastdb	Prebuilt curated blast database
-	--data		Data type can be sanger or wgs (capitalization does not matter)

#### Expected Output

Generates the gp60 subtyping results in a tab demilited text format

#### Usage:

##### Docker:
`docker pull `

`docker run -v $(pwd)/<your input directory>:/inputData --privileged wdpbcdsphl/crypto_gp60:2.4 perl /scripts/gp60Typer.pl --blastdb db/Crypto_GP60_DB --fasta /test/testInput_SM.fasta --data sanger > results_gp60SM-15.txt
`
##### Singularity:

`singularity exec -B $(pwd)/SM_TestData:/dataIn crypto_gp60-2.4.simg perl /scripts/gp60Typer.pl --blastdb /db/Crypto_GP60_DB --fasta /dataIn/gp60_seqs.fasta --data sanger
