# Methods

To determine cutoffs for the percent of reads and total number of reads assigned to *Cryptosporidium* to be considered of high enough quality for use with other WDPB tools we took into account the following:

- The quality of assemblies that were produced by Skesa after extraction of reads assigned to *Cryptosporidium*. This included the following metrics produced by Quast:
  - Percent of the reference genome covered
  - N50
  - Total alignment length	
  - Number of contigs
  - Total assembly length	
  - Length of largest contig	
  - Number of missasemblies
- The percent of a genome that had ≥20X coverage across the [reference genome](https://cryptodb.org/cryptodb/app/downloads/release-55/CparvumIowaII/fasta/data/). 

Next we will go through a few samples that have decreasing genome fraction (the total number of aligned bases in the reference, divided by the genome size) to understand how we devised these cutoffs. The methods to generate this data (minus coverage stats) is found in the `Data_Generation.sh` file.

## Example 1:

| SeqID | Percent_of_Total_Reads_Assigned_to_Taxon | Reads_Assigned_to_Cryptosporidium | Percent_of_Genome_with_20X | Genome_Fraction | N50 | Total_Alignment_Length | Number_of_Contigs | Total_Assembly_Length | Largest_Contig | Missasemblies |
| -------- | ----- | -------  | ------ | ------ | ------ | --------  | ----- | --------- | ------- | -- |
| Sample_1 | 99.87 | 401,788  | 99.313 | 99.214 | 67,207 | 9,014,980 |  301	 | 9,065,206 | 214,135 |  5 |
| Sample_2 | 99.88 | 220,627  | 98.702 | 99.182 | 61,377 | 9,012,711 |  324  | 9,063,269 | 333,080 |  7 |
| Sample_3 | 96.01 | 166,290  | 94.140 | 98.998 | 61,366 | 8,995,748 |  347  | 9,047,215 | 333,058 |  6 |
| Sample_4 | 99.83 | 101,221  | 72.566 | 98.131 | 28,219 | 8,915,834 |  744  | 8,960,051 | 133,845 |  2 |
| Sample_5 | 99.81 |  75,667  | 54.703 | 97.572 |	18,864 | 8,864,226 | 1,003 | 8,904,350 |	87,654 |  1 |
| Sample_7 | 72.04 |  70,964  | 78.454 | 92.073 | 12,217 | 8,364,960 | 1,838 | 8,392,506 |  65,785 | 17 |

In samples 1-5 there is a decrease in the number of reads belonging to *Cryptosporidium* in each sample while still having a high % of the total reads assigned to *Cryptosporidium* (low contamination). In this scenario once we get to ~100k reads belonging to *Cryptosporidium* there is no longer enough reads to get ≥75% genome covered at least 20X. A depth of coverage of 20X will allow us to have confidence in variants called in downstream processes. 

## Example 2:

| SeqID | Percent_of_Total_Reads_Assigned_to_Taxon | Reads_Assigned_to_Cryptosporidium | Percent_of_Genome_with_20X | Genome_Fraction | N50 | Total_Alignment_Length | Number_of_Contigs | Total_Assembly_Length | Largest_Contig | Missasemblies |
| --------  | ----- | ------- | ------ | ------ | ------ | --------  | ----- | --------- | ------- | -- |
| Sample_8  |	99.59 |	 17,957 |	12.838 | 88.192 |	 3,389 | 8,011,360 | 3,447 | 8,037,329 |	24,126 |	9 |
| Sample_9  |	92.93 |	 64,288 |	56.423 | 84.145 |	 5,366 | 7,644,707 | 2,928 | 7,654,896 |	35,174 | 31 |
| Sample_10 |	96.72 |  55,312 |	51.946 | 79.102 |	 4,902 | 7,185,779 | 2,838 | 7,208,940 |	50,650 | 36 |
| Sample_11 |	91.84 |	 15,042 |	 4.924 | 71.044 |	 1,391 | 6,453,726 | 5,249 | 6,460,790 |	10,924 | 11 |
| Sample_12 |	81.80 |	 16,773 |	 8.732 | 69.984 |	 1,431 | 6,357,466 | 5,138 | 6,368,661 |	10,715 | 11 |
| Sample_13 |	53.14 |	 12,993 |	 1.790 | 63.500 |	 1,262 | 5,768,451 | 5,080 | 5,776,527 |	 8,275 | 12 |

All these samples show pretty low levels of contamination (with the exception of Sample_13), however, the number of reads belonging are too low and to get a depth of >20X across most the genome and while we recover most of genome for Sample_8 we can't be highly confident in variant calls with a low depth coverage. 

## Example 3:

| SeqID | Percent_of_Total_Reads_Assigned_to_Taxon | Reads_Assigned_to_Cryptosporidium | Percent_of_Genome_with_20X | Genome_Fraction | N50 | Total_Alignment_Length | Number_of_Contigs | Total_Assembly_Length | Largest_Contig | Missasemblies |
| --------  | ----- | ------- | ----- | ------ | ------ | --------  | ----- | --------- | ------ | -- |
| Sample_15 |	37.83 |	267,402 | 2.227 |	40.296 |	 968  | 3,660,454 |	3,908 |	3,665,179 |	 5,722 | 72 |
| Sample_16 |	44.25 |	220,434 |	0.988 |	35.955 | 	1,007	| 3,266,197 |	3,412 |	3,271,398 |	 6,481 | 58 |
| Sample_17 |	57.36 |	216,715 |	7.713 |	25.386 | 	1,065	| 2,306,121 |	2,301 |	2,319,518 |	 7,536 | 46 |

These samples are interesting because they have between 216k-275k reads assigned to *Cryptosporidium* which should be more than enough to generate a quality genome based on our ≥150k cutoff, however, the percent of total reads in the sample assigned to *Cryptosporidium* are all below our cutoff of ≥75%. In all three of these samples this results in poor assembly and coverage metrics. This is likely due to the contaminiation causing uneven sequencing. 

## Example 4 - Grey Area:

| SeqID | Percent_of_Total_Reads_Assigned_to_Taxon | Reads_Assigned_to_Cryptosporidium | Percent_of_Genome_with_20X | Genome_Fraction | N50 | Total_Alignment_Length | Number_of_Contigs | Total_Assembly_Length | Largest_Contig | Missasemblies |
| --------  | ----- | ------- | ------ | ------ | ------ | --------  | ----- | --------- | ------  | -- |
| Sample_6  | 77.96 | 193,521 | 59.760 | 94.221 | 16,937 | 8,560,360 | 1,412 | 8,596,398 | 109,689 | 10 |
| Sample_14 |	76.42 |	274,896 |	0.826  | 51.85  |	 1,097 | 4,710,132 | 4,612 | 4,712,992 |  6,239  | 61 |

Welp, here is the part of the tutorial that I remind you that nothing in biology is certain. 😢 Both of these samples would pass our cuttoff, but when further examined there are concerning metrics. 

First, Sample_6 only has ~60% of the genome with 20X coverage and upon further inspection the coverage across the chromosomes is quite uneven. 

|   SeqID  | Chromosome | Percent_of_Genome_with_20X |
| -------- |  --------  | -------------------------  |
| Sample_6 |  CM000429  |	          52.52            |
| Sample_6 |  CM000430  |	          65.75            |
| Sample_6 |  CM000431  |	          53.73            |
| Sample_6 |  CM000432  |	          65.88            |
| Sample_6 |  CM000433  |	          72.20            |
| Sample_6 |  CM000434  |	          39.98            |
| Sample_6 |  CM000435  |           66.40            |
| Sample_6 |  CM000436  |           61.63            |  

Second, despite Sample_14 having 76% of all reads being assigned to *Cryptosporidium* and >274k reads belonging to *Cryptosporidium* the coverage and assembly metrics are quite poor. For instance, the genome fraction is only 51. This is a bit of an unexected result with a cause unclear and would be a candidate for resequencing. 

Thus, just because samples pass the cutoffs suggested for Percent_of_Total_Reads_Assigned_to_Taxon and Reads_Assigned_to_Cryptosporidium you will need to be on the look out for odd things later in the analysis process. 

***The cutoffs here are for general purposes and are meant to provide a guide for metrics to aim for and might be too stringent for some process.*** For example, if you only care about a few genes in the genome then a better metric would be the coverage across those genes and not the entire genome.
