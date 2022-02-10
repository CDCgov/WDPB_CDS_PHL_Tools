for f in /~/Kraken_Decon_Data/*_L001_clean_R1.fastq
do
	fname=$(basename $f _L001_clean_R1.fastq)
	ErrorOutDir=~/Kraken_Decon_Data/Error_Out_Files
	indir=~/Kraken_Decon_Data
	outdir=~/Kraken_Decon_Data/quast_results
	Refdir=~/Reference_Genomes
	DB=~/Kraken_DB/Crypto_DB_V2
	echo $fname
	echo "#! /bin/bash -l" > $fname.Docker_stats.sh
	echo "## -- begin embedded SGE options --" >> $fname.Docker_stats.sh
	echo "# save the standard output text to this file instead of the default jobID.o file" >> $fname.Docker_stats.sh
	echo "#$ -o $ErrorOutDir/${fname}_Docker_stats.out" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "# save the standard error text to this file instead of the default jobID.e file" >> $fname.Docker_stats.sh
	echo "#$ -e $ErrorOutDir/${fname}_Docker_stats.err" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "# Rename the job to be this string instead of the default which is the name of the script" >> $fname.Docker_stats.sh
	echo "#$ -N F${fname}_Docker_stats" >> $fname.Docker_stats.sh
	echo "# " >> $fname.Docker_stats.sh
	echo "# Requesting shared memory across 6 cpus" >> $fname.Docker_stats.sh
	echo "#$ -pe smp 6" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "# Requesting 20G of Memory for the job" >> $fname.Docker_stats.sh
	echo "#$ -l h_vmem=20G" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "# Refer all file reference to work the current working directory which is the directory from which the script was qsubbed" >> $fname.Docker_stats.sh
	echo "#$ -cwd" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "# Always run in the default queue" >> $fname.Docker_stats.sh
	echo "#$ -q all.q" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "## -- end embedded SGE options --" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "" >> $fname.Docker_stats.sh
	echo "echo "I am running on node:" `hostname`" >> $fname.Docker_stats.sh
	echo "mkdir -p $outdir" >> $fname.Docker_stats.sh
	echo "mkdir -p $ErrorOutDir" >> $fname.Docker_stats.sh
	echo "#" >> $fname.Docker_stats.sh
	echo "module load kraken/2.0.8" >> $fname.Docker_stats.sh
	echo "module load Skesa/2.3.0" >> $fname.Docker_stats.sh
	echo "module load quast/5.0" >> $fname.Docker_stats.sh
	echo "cd $indir" >> $fname.Docker_stats.sh
	echo "#if [ -L ${fname}_L001_clean_R1.fastq ]; then cat ${fname}_L001_clean_R1.fastq > ${fname}_clean_R1.fastq; cat ${fname}_L001_clean_R2.fastq > ${fname}_clean_R2.fastq; fi" >> $fname.Docker_stats.sh
	echo "#if [ -L ${fname}_L002_clean_R1.fastq ]; then cat ${fname}_L002_clean_R1.fastq >> ${fname}_clean_R1.fastq; cat ${fname}_L002_clean_R2.fastq >> ${fname}_clean_R2.fastq; fi" >> $fname.Docker_stats.sh
	echo "kraken2 --use-names --threads 10 --db $DB --report ${fname}_report.txt --paired ${fname}_clean_R1.fastq ${fname}_clean_R2.fastq --output ${fname}.kraken" >> $fname.Docker_stats.sh
	echo "python /scicomp/home-pure/qpk9/bin/KrakenTools-master/extract_kraken_reads.py --include-children --fastq-output --taxid 5806 -s ${fname}_clean_R1.fastq -s2 ${fname}_clean_R2.fastq -o ${fname}_Kclean_R1.fastq -o2 ${fname}_Kclean_R2.fastq --report ${fname}_report.txt -k ${fname}.kraken" >> $fname.Docker_stats.sh
	echo "time skesa --fastq ${fname}_Kclean_R1.fastq,${fname}_Kclean_R2.fastq --cores 10 --memory 50 --contigs_out ${fname}_contigs_skesa.fa" >> $fname.Docker_stats.sh
	echo "time quast.py --eukaryote -o $outdir -r $Refdir/CryptoDB-54_CparvumIowaII_Genome.fasta ${fname}_contigs_skesa.fa --features $Refdir/CryptoDB-54_CparvumIowaII.gff" >> $fname.Docker_stats.sh
qsub $fname.Docker_stats.sh
done
