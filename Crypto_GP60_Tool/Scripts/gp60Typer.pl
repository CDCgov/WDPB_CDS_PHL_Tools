#!/usr/bin/perl
#Author: Alyssa Kelley
#Modification: Shatavia Morrison
#Function: gp60 subtype fasta sequences
use strict;
use Getopt::Long;
our $VERSION = 0.8.8;


# Static variables
my $MIN_IDENT = 97;
my $MIN_LEN = 700;
my $SPEC_ID = "CR"; #Species ID for Cryptosporidium samples for MEPI lab
my $MIN_REPEAT = 9; #min size tri-nuc repeat region (3 repeats)

#Parse input arguments
my $BlastDB; #blast database with path
my $inFasta; #fasta file with sequences to subtype
my $SEQ_TYPE; #Sanger or WGS
my $OUT; #Output file and path
my $OUT_path; #path to output only
my $MIN_COV;
my $BNS; #If set, call BioNumerics related functions
my $mepiFlag; #set for internal ID parsing
my $help; #prints usage if set
GetOptions ("blastdb=s" => \$BlastDB,
	"fasta=s" => \$inFasta,
	"data=s" => \$SEQ_TYPE,
	"out=s" => \$OUT,
	"bns!" => \$BNS, #more coming soon
	"mepi!" => \$mepiFlag,
	"help!" => \$help)
or die usage();
$SEQ_TYPE = lc($SEQ_TYPE);

if ($help) {

	die usage();
}
if ($BlastDB eq "") {

	print STDERR "\nArgument --blastdb is required.\n";
	die usage();
}
if (!(glob("$BlastDB.*"))) { #Checks if files with pattern exist

	print STDERR "\nBlast database '$BlastDB' not found. Please check path.\n";
	die usage();
}
if ($inFasta eq "") {

	print STDERR "\nArgument --fasta is required.\n";
	die usage();
} else {
	if (!(-e $inFasta)) {

		print STDERR "\nFasta file not found. Please check path.\n";
		die usage();
	}
	if ($inFasta =~ m/\.gz$/) {

		print STDERR "\nFasta file cannot be gzipped.\n";
		die usage();
	}
}
if ($SEQ_TYPE eq "wgs") {

	$MIN_COV = 0; #not applicable, still checks for length
	#Will later be changed to check min coverage of database hit
} elsif ($SEQ_TYPE eq "sanger") {

	$MIN_COV = 70;
} elsif ($SEQ_TYPE eq ""){

	print STDERR "\nArgument --data is required.\n";
	die usage();
} else {

	print STDERR "\nInvalid data type for --data.\n";
	die usage();
}
if ($OUT ne "") {

	#Check if output is just directory - fail
	my $dirCheck = $OUT =~ m/\/$/;
	if ($dirCheck == 1) {

		print STDERR "Output needs to be a filename and can include path.\n";
		die usage();
	}
	#Check if correct extension is added
	$dirCheck = $OUT =~ m/\.txt$/;
	if ($dirCheck == 0) {

		$OUT .= ".txt";
	}
	#Get output directory
	if (index($OUT, "/") != -1) {

		my @path = split("/", $OUT);
		pop @path;
		$OUT_path = join("/", @path);
		$OUT_path .= "/";
	}
	#Check if directory exist, if not, create
	if (!(-d $OUT_path)) { 

		system("mkdir $OUT_path");
	}
}

#Error messages
my $SEQ_ERR_MSG = "Sequence not found.";
my $ERR_COV = "Below coverage threshold (<$MIN_COV%).";
my $ERR_IDENT = "Below percent identity threshold (<$MIN_IDENT%). Check manually for subtype family and request to add to gp60 database.";
my $ERR_Len = "Below length threshold (<$MIN_LEN" . "bp).";
my $ERR_TRI = "Possible incomplete subtype: sequence starts at 5' repeats.";
my $ERR_TRIMISS = "Sequence missing 5' repeat region.";
#my $ERR_AMB = "Incomplete subtype: ambiguous nucleotide(s) detected in 5' repeat region. Check chromatogram or consider resequencing.";
my $ERR_AMB = "Incomplete subtype: ambiguous nucleotide(s) detected in 5' repeat region.";
my $ERR_MISS = "No gp60 sequence detected.";


## Begin analysis ##
# Blast fasta against gp60 databse
my @fastaPath = split("/", $inFasta);
my @blastBase = split("\\.", $fastaPath[-1]);
pop @blastBase;
my $tempBlastOut = join(".", @blastBase);
my $BlastOutput = $OUT_path . $tempBlastOut . "_blastResults.txt";
system("blastn -task blastn -query $inFasta -db $BlastDB -outfmt \"6 qseqid sseqid pident length qcovhsp mismatch gapopen qstart qend sstart send qlen slen bitscore qseq\" -out $BlastOutput");

#Parse Blast input and return best hit per query sequence
#my $ref_bestBlastHits = parseBlastInput($BlastDB);
my $ref_bestBlastHits = parseBlastInput($BlastOutput);
my @bestBlastHits = @$ref_bestBlastHits;

#Filter Blast Hits using thresholds
my ($ref_filteredBestHits, $ref_queryIDs, $ref_failedBHWarnings, $ref_hitQuality) = filterBlastHits(\@bestBlastHits, $MIN_COV, $MIN_IDENT, $MIN_LEN);
my @filteredBestHits = @$ref_filteredBestHits; #pass
my @queryIDs = @$ref_queryIDs;
my @failedBHWarnings = @$ref_failedBHWarnings;
my @hitQuality = @$ref_hitQuality; #contains a number code used later

#Check if query matched hit's tri-repeat region
my ($ref_hitQuality2, $ref_failedBHWarnings2) = checkHitTriRepeat(\@bestBlastHits, \@hitQuality, \@failedBHWarnings);
@hitQuality = @$ref_hitQuality2; #update
@failedBHWarnings = @$ref_failedBHWarnings2; #update

##Retrieve and format gp60 sequences
my ($ref_gp60Seqs, $ref_warnings3, $ref_hitQuality3) = retrieveSeqs(\@filteredBestHits, \@failedBHWarnings, $SEQ_TYPE, $inFasta, \@hitQuality); #change to hitQuality2
my @gp60Seqs = @$ref_gp60Seqs;
@failedBHWarnings = @$ref_warnings3; #update
@hitQuality = @$ref_hitQuality3; #update

#subtype sequences
my ($ref_gp60Subtypes, $ref_warnings4) = subtypeGp60Sequences(\@filteredBestHits, \@failedBHWarnings, \@hitQuality, \@gp60Seqs);
my @gp60Subtypes = @$ref_gp60Subtypes;
@failedBHWarnings = @$ref_warnings4; #update


## Output ##
my $labinfo = "Cryptosporidium GP 60 Subtyping Analysis\nDeveloped by : Alyssa Kelly Clinical Detection Surveillance - WDPB,CDC\nTool version - 1.0 and GP60 Database was updated on : 2020-03-30\nNote: Please note that the assays used are not ISO or CLIA-certified and should not be considered diagnostic.\n\n\n";
my $header = "SampleID\tgp60_Subtype\tFasta_Header\tDatabase_Best_Match\tLength(bp)\t";
$header .= "Blast_Identity\tCoverage\tNCE\n";

#Format and check results
my $out_results;
if ($SEQ_TYPE eq "sanger") {

	#Collect all Fasta headers to check for missing results
	my @fastaHeaders;
	my @fastaStatus;
	open FILE, $inFasta, or die $!;
	while (my $line = <FILE>) {

		chomp $line;
		my $fheader = $line =~ m/^>/;
		if ($fheader ne "") {

			$line =~ s/^>//;
			my ($line2, $t1) = split(" ", $line, 2); #parse same as blast
			$line = $line2;
			if ($mepiFlag) {

				my ($id, $t1) = split("_", $line, 2);
				if (index($id, $SPEC_ID) != -1) {

					$id =~ s/^$SPEC_ID//g;
				}
				push(@fastaHeaders, $id);
				push(@fastaStatus, 0);
			} else {

				push(@fastaHeaders, $line);
				push(@fastaStatus, 0);
			}
		}
	}
	close FILE;

	my $o = 0;
	foreach (@queryIDs) {

		#Mark ID as found
		my $z = 0;
		foreach(@fastaHeaders) {

			if ($fastaHeaders[$z] eq $queryIDs[$o]) {

				$fastaStatus[$z] = 1;
				last;
			}
			$z++;
		}

		#save results
		my ($qseqid, $sseqid, $pident, $length, $qcovhsp, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $qlen, $slen, $bscore, $qseq) = split("\t", $bestBlastHits[$o]);

		$out_results .= "$queryIDs[$o]\t$gp60Subtypes[$o]\t$qseqid\t$sseqid\t$qlen\t$pident";
		$out_results .= "\t$qcovhsp\t$failedBHWarnings[$o]\n";
		$o++;
	}
	#Check if all Fasta headers gave results
	my $x = 0;
	foreach(@fastaHeaders) {

		if ($fastaStatus[$x] == 0) {

			$out_results .= "$fastaHeaders[$x]\t\t\t\t\t\t\t$ERR_MISS\n";
		}
		$x++;
	}
	

} elsif ($SEQ_TYPE eq "wgs") { #only print best result

	my $bestResult;
	my $bestScore = -1;
	my $o = 0;
	foreach (@queryIDs) {

		my ($qseqid, $sseqid, $pident, $length, $qcovhsp, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $qlen, $slen, $bscore, $qseq) = split("\t", $bestBlastHits[$o]);

		if ($bscore > $bestScore) {

			$bestResult = "$gp60Subtypes[$o]\t$qseqid\t$sseqid\t$qlen\t$pident";
			$bestResult .= "\t$qcovhsp\t$failedBHWarnings[$o]";
			$bestScore = $bscore;
		}
		$o++;
	}

	my @wgsPath = split("/", $inFasta);
	my @baseName = split("\\.", $wgsPath[-1]);
	pop @baseName;
	my $wgsID = join(".", @baseName);

	#Check if no results
	if ($bestResult eq "") {

		$out_results .= "$wgsID\t\t\t\t\t\t\t$ERR_MISS\n";
	} else {

		$out_results .= "$wgsID\t$bestResult\n";
	}
} else {

	print "Unknown data type. Sanger or WGS only.\n";
	exit;
}

#Print output
if ($OUT ne "") {

	open OFILE, '>', $OUT, or die $!;
	print OFILE $labinfo;
	print OFILE $header;
	print OFILE $out_results;
	close OFILE;
} else {
	print $labinfo;
	print $header;
	print $out_results;
}

##
## Subroutines ##
##

# Find the best hit for each query ID
# Returns an array containing the best hit per query
sub parseBlastInput {

	my $filename = @_[0];
	my @results; #full blast line
	my @tempIDs;
	my @tempBscore;

	open FILE, $filename, or die $!;
	while (my $line = <FILE>) {

		$line =~ s/\r\n/\n/; #remove windows characters
		chomp $line;
		my ($qseqid, $sseqid, $pident, $length, $qcovhsp, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $qlen, $slen, $bscore, $qseq) = split("\t", $line);

		#Format sample ID if mepi flag set
		my $id = $qseqid;
		my $t1;
		if ($mepiFlag) {

			($id, $t1) = split("_", $qseqid, 2);
			if (index($id, $SPEC_ID) != -1) {

				$id =~ s/^$SPEC_ID//g;
			}
		}
		

		#Keep new ID for downstream
		##my ($t1, $rest) = split("\t", $line, 2); #TEST
		#$line = "$id\t$rest"; #edit
		
		my $x = 0;
		my $flag = 0; # flag = 1 if query id already in list
		foreach (@tempIDs) {

			if ($tempIDs[$x] eq $id) {

				$flag = 1;
				if ($tempBscore[$x] < $bscore) { #Update new best match

					$tempBscore[$x] = $bscore;
					$results[$x] = $line;
				}
				last;
			}
			$x++;
		}
		if ($flag == 0) {

			push(@tempIDs, $id);
			push(@tempBscore, $bscore);
			push(@results, $line);
		}
	}
	close FILE;
	return(\@results);
}

# Filter blast results based on query coverage,
# identity, and length
sub filterBlastHits {

	my $ref_allHits = @_[0];
	my @allHits = @$ref_allHits;
	my $minCov = @_[1];
	my $minIdent = @_[2];
	my $minLen = @_[3];
	my @quality; # 0/1 pass/fail thresholds
	my $statFlag = 0; #1 if below any thresholds

	my @passingHits;
	my @tempIDs;
	my @failedHits;
	my @failedWarnings;

	my $z = 0;
	foreach (@allHits) {

		my $tempWarnings;
		my $failedFlag = 0;
		my $flagCov = 0;
		my $flagIdent = 0;
		my $flagLen = 0;

		my ($qseqid, $sseqid, $pident, $length, $qcovhsp, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $qlen, $slen, $bscore, $qseq) = split("\t", $allHits[$z]);

		my $id = $qseqid;
		my $t1;
		if ($mepiFlag) {

			($id, $t1) = split("_", $qseqid, 2);
			if (index($id, $SPEC_ID) != -1) {

				$id =~ s/^$SPEC_ID//g;
			}
		}

		#Check thresholds
		if ($pident < $minIdent) {

			#$flagIdent = 1;
			$failedFlag = 1;
			$tempWarnings .= "$ERR_IDENT ";
		}
		if ($qcovhsp < $minCov) { 

			#$flagCov = 1; 
			$failedFlag = 1;
			$tempWarnings .= "$ERR_COV ";
		}
		if ($SEQ_TYPE eq "wgs") {

			if ($length < $minLen) {

				$failedFlag = 1;
				$tempWarnings .= "$ERR_Len ";
			}
		} elsif ($SEQ_TYPE eq "sanger") {

			if ($qlen < $minLen)  {
				#$flagLen = 1;
				$failedFlag = 1;
				$tempWarnings .= "$ERR_Len ";
			} 
		}
		
		if ($failedFlag == 1) {

			chop $tempWarnings; #remove last char (\s)
			#$statFlag = 1;
		}
			push(@failedWarnings, $tempWarnings);
			push(@passingHits, $allHits[$z]);
			push(@tempIDs, $id);
			push(@quality, $failedFlag);
		$z++;
	}
	
	return (\@passingHits, \@tempIDs, \@failedWarnings, \@quality);
}

# Checks if query matched within database match's
# tri repeat region
sub checkHitTriRepeat {

	my $ref_bestHits = @_[0];
	my $ref_hitQual = @_[1];
	my $ref_warnings = @_[2];

	my @bestHits = @$ref_bestHits;
	my @hitQual = @$ref_hitQual;
	my @warnings = @$ref_warnings;

	my $i = 0;
	foreach (@bestHits) {

		my ($qseqid, $sseqid, $pident, $length, $qcovhsp, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $qlen, $slen, $bscore, $qseq) = split("\t", $bestHits[$i]);

		#Check match orientation
		if ($sstart > $send) {

			my $tempStart = $send;
			$send = $sstart;
			$sstart = $tempStart;
		}

		#parse sseqid for subtype family, special character, and repeat coords
		my ($genus, $species, $subFamily, $coords, $rest) = split("_", $sseqid, 5);

		# Grab tri-repeat coordinates
		my ($start_coord, $stop_coord) = split("-", $coords);

		if ((($stop_coord-$MIN_REPEAT+1) <= $sstart) & ($coords ne "NA")) {

			#add warning
			if ($warnings[$i] eq "") {

				$warnings[$i] = "$ERR_TRIMISS";
			} else {

				$warnings[$i] .= " $ERR_TRIMISS";
			}

			#add quality score if not one already
			if ($hitQual[$i] == 0) {

				$hitQual[$i] = 2;
			}
		}
		$i++;
	}
	return (\@hitQual, \@warnings);
}

# Calls appropriate subroutine to extract gp60 sequence
# and formats sequence
sub retrieveSeqs {

	my $ref_bestHits = @_[0];
	my $ref_warnings = @_[1];
	my $type = @_[2];
	my $filename = @_[3];
	my $ref_hitQual3 = @_[4];

	my @bestHits = @$ref_bestHits;
	my @warnings = @$ref_warnings;
	my @hitQual3 = @$ref_hitQual3;

	my $ref_Seqs;

	if(lc($type) eq "sanger") {

		($ref_Seqs) = extractSangerSeqs(\@bestHits, \@hitQual3, $filename);
		
	} elsif (lc($type) eq "wgs") {

		($ref_Seqs) = extractWGSseqs(\@bestHits);
	}
	
	my @Seqs = @$ref_Seqs;

	my $x = 0;
	foreach (@Seqs) {

		if ($Seqs[$x] eq "") {

			if ($warnings[$x] eq "") {

				$warnings[$x] = $SEQ_ERR_MSG;
			} else {

				$warnings[$x] .= " $SEQ_ERR_MSG";
			}

			#update hit quality status if sequence not found
			# and hit quality in good standing
			if ($hitQual3[$x] == 0) {

				$hitQual3[$x] = 3;
			}
			$x++;
			next;
		} else {

			$Seqs[$x] =~ s/-//g; #remove dashes

			#reverse comp if necessary
			my ($qseqid, $sseqid, $pident, $length, $qcovhsp, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $qlen, $slen, $bscore, $qseq) = split("\t", $bestHits[$x]);

			if ($sstart > $send) {
				my $revcomp = reverse $Seqs[$x];
				$revcomp =~ tr/ATGCatgc/TACGtacg/;
				$revcomp =~ tr/YRKMyrkm/RYMKrymk/; #update added iupac complements
				$revcomp =~ tr/DVHBdvhb/HBDVhbdv/; #update added iupac complements 2

				$Seqs[$x] = $revcomp;
			}
		}
		$x++;
	}

	return (\@Seqs, \@warnings, \@hitQual3);
}

# If input is Sanger sequence, extract sequence
# from fasta file
sub extractSangerSeqs {

	my $ref_bestHits = @_[0];
	my $ref_hitQual = @_[1];
	my $filename = @_[2];

	my @bestHits = @$ref_bestHits;
	my @hitQual = @$ref_hitQual;
	my $tempQual;

	my $numIDs = scalar(@bestHits);
	my $countIDs = 0; #stop parsing file when all IDs found
	my @seqs;


	# Write default error for sequences
	# As sequences are found, errors will be replaced
	foreach (@bestHits) {

		#push(@seqs, $SEQ_ERR_MSG);
		push(@seqs, "");
	}

	open FILE, $filename or die $!;
	my $samplePlace; #keeps track of which sample location in array
	my $matchFlag = 0;
	while (my $line = <FILE>) {

		$line =~ s/\r\n/\n/; #remove windows characters
		chomp $line;
		if (index($line, ">") != -1) {

			$matchFlag = 0; #reset
			$samplePlace = 0; #reset

			#parse fasta header as blast would
			my ($ID, $t1) = split(" ", $line, 2);
			$ID =~ s/^>//;
			my $i = 0;
			foreach(@bestHits) {

				my ($contigID, $t1) = split("\t", $bestHits[$i], 2);
				if ($contigID eq $ID) {

					$matchFlag = 1;
					$countIDs++;
					$samplePlace = $i;
					last;
				}
				$i++;
			}
		} elsif ($matchFlag == 1) {

			$seqs[$samplePlace] .= $line;
		}
		#stop parsing file if all seqs found
		if(($countIDs == $numIDs) & ($matchFlag == 0)) {

			last;
		}
	}
	close FILE;

	return (\@seqs);
}


# If input is WGS assembly, extract sequence
# from blast output qseq
sub extractWGSseqs {

	my $ref_bestHits = @_[0];
	my @bestHits = @$ref_bestHits;
	my @seqs;

	my $i = 0;
	foreach (@bestHits) {

		my @blastCols = split("\t", $bestHits[$i]);

		my $tempSeq = $blastCols[-1];
		if ($tempSeq =~ /[0-9]/) { #sequence empty or numeric value

			push(@seqs, "");
		} else {

			push(@seqs, $tempSeq);
		}
		
		$i++;
	}

	return (\@seqs);
}

# Checks for warnings
# Then calls the appropriate subtyping functions
#based on species
sub subtypeGp60Sequences {

	my $ref_bestHits = @_[0];
	my $ref_warnings = @_[1];
	my $ref_hitQual = @_[2];
	my $ref_seqs = @_[3];

	my @bestHits = @$ref_bestHits;
	my @warnings = @$ref_warnings;
	my @hitQual = @$ref_hitQual;
	my @seqs = @$ref_seqs;

	my @gp60;

	my $i = 0;
	foreach (@bestHits) {

		push(@gp60, ""); #create a space
		
		if ($hitQual[$i] == 1) { #failed thresholds - no subtyping

			$i++;
			next;
		}

		#Find subtype family and any special end characters
		my $endChar = "";
		my $subFamily = "";

		my ($qseqid, $sseqid, $pident, $length, $qcovhsp, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $qlen, $slen, $bscore, $qseq) = split("\t", $bestHits[$i]);
		my ($t1, $species, $hitSubFamily, $t4) = split("_", $sseqid, 4);

		my $familyOnly = 0;
		#Check if hit contains subtype family without repeat typing
		if (index($hitSubFamily, "A") != -1) {

			#parse based on the first occurence of A
			my ($sub, $rest) = split("A", $hitSubFamily, 2);
			$subFamily = $sub;

			#check if additional character at end of subtype
			my $char = substr($hitSubFamily, -1);
			if ($char =~ /^[a-zA-Z]/) {

				$endChar = $char;
			}
		} else {

			$subFamily = $hitSubFamily;
		}
		
		# Print only subtype family if missing repeat region
		# or if missing
		if (($hitQual[$i] == 2) | ($hitQual[$i] == 3)) {

			$gp60[$i] = $subFamily;
			$i++;
			next;
		}

		#Check for general genotype results (i.e. deermouse genotype III)
		#print "$subFamily\n\n";
		if (index(lc($subFamily), "deermouse") != -1) {

			$subFamily =~ s/-//g;
			$subFamily =~ s/genotype/_genotype_/g; #formats general genotypes
		}

		## Subtype repeats ##
		if ((lc($species) eq "ubiquitum") | (lc($species) eq "felis") | (index(lc($subFamily), "deermouse") != -1)) {

			#No repeats traditionally found: ubiquitum, felis
			#No repeats for subtypes with genotype in name ****
			#Do not call repeat subtyping functions
			$gp60[$i] = $subFamily;
		} else {

			my ($triRepeats, $triWarns) = FindTriRepeats($seqs[$i]); #update
			my $rRepeats = FindRRepeats($subFamily, $seqs[$i]);
			my $tempSubtype = $subFamily . $triRepeats . $rRepeats . $endChar;
			$gp60[$i] = $tempSubtype;
			if ($triWarns ne "") { #update testing 5/25/2021

				if ($warnings[$i] eq "") { 
					$warnings[$i] = "$triWarns"; 
				}
				else { 
					$warnings[$i] .= " $triWarns"; 
				}
			}
		}

		#Check if sequence starts at tri-repeat
		my $repeatStart = $seqs[$i] =~ m/^([CT]C[AGT]((A?[CTG]C[AGTNRYWSKM]))+)(A)/g;
		if ($repeatStart == 1) {

			if ($warnings[$i] eq "") {

				$warnings[$i] = "$ERR_TRI";
			} else {

				$warnings[$i] .= " $ERR_TRI";
			}

		}

		$i++;
	}
	return (\@gp60, \@warnings);
}

# Searches GP60 motifs and finds
# the number of TCA, TCG, TCT repeats
# in the input sequence.
sub FindTriRepeats {

	#The regex here needs to match the same one thats found 
	# in function subtypeGp60Sequences{} when checking if the
	# sequence starts at tri-nuc repeat

	my @matches = @_[0] =~ m/([CT]C[AGT]((A?[CTG]C[AGTNRYWSKM]))+)(A)/g;

	my $warnings = "";
	my $repeats = "";
	my $largestMatch = 0;
	my $x = 0;
	#Find match with the most repeats
	foreach (@matches) {

		#TEST

		my $tempACount = ($matches[$x] =~ s/CA/CA/g); #TEST
		my $tempGCount = ($matches[$x] =~ s/CG/CG/g); #TEST
		my $tempTCount = ($matches[$x] =~ s/CT/CT/g); #TEST
		my $totalCounts = $tempACount + $tempGCount + $tempTCount; #TEST

		my $numA = ($matches[$x] =~ s/A/A/g);
		my $insertA = $numA - $tempACount;
		my $alimit = 2;
		
		#print "$matches[$x]\t$totalCounts\tNum A's:$insertA\n";
		#if (length($matches[$x]) > $largestMatch) {
		#if ($totalCounts > $largestMatch) { #TEST
		if (($totalCounts > $largestMatch) & ($insertA < $alimit)) { #TEST

			#$largestMatch = length($matches[$x]);
			$largestMatch = $totalCounts;
			$repeats = $matches[$x];
		}
		$x++;
	}
	
	my $motif = "";

	#count repeats
	my $ACount = ($repeats =~ s/CA/CA/g); #update
	my $GCount = ($repeats =~ s/CG/CG/g); #update
	my $TCount = ($repeats =~ s/CT/CT/g); #update

	#Keep track of ambiguous nucleotides
	my $amb = ($repeats =~ s/[NRYWSKM]/[NRYWSKM]/g); #update
	if ($amb > 0) {

		$warnings = $ERR_AMB;
	}

	my $results = "";
	if ($ACount != "") { $results .= "A$ACount"; }
	if ($GCount != "") { $results .= "G$GCount"; }
	if ($TCount != "") { $results .= "T$TCount"; }

	return ($results, $warnings);
}

#Find subtype family specific R repeats
sub FindRRepeats {

	@_[1] =~ s/-//g; #remove gaps from alignments
	my $rCount; # is empty if there are no matched patterns
	
	if (@_[0] eq "Ia") { #C. hominis

		$rCount = (@_[1] =~ s/A[AG][AG]ACGGTG(GT)?AAGG//g);

	} elsif (@_[0] eq "If") { #C. hominis

		#[CA]	AGA/AAA	[AG]
		#$rCount = (@_[1] =~  s/[CA]AGA[AG]GGCA//g);
		$rCount = (@_[1] =~  s/[CA]A[GA]A[AG]GGCA//g);

	} elsif (@_[0] eq "IIa") { #C. parvum

		$rCount = (@_[1] =~ s/ACATCA//g);

	} elsif (@_[0] eq "IXa") { #C. tyzzeri

		$rCount = (@_[1] =~ s/[AG]TTCTGGT[AG]CT[GA][AG][AC]G[AG]T[AT]//g);
	} elsif (@_[0] eq "XIIIa") { #C. erinaci

		$rCount = (@_[1] =~ s/ACATCA//g);
	}

	if ($rCount ne "") {

		return("R$rCount");
	}
}


sub usage {

"
  This script performs gp60 subtyping on Sanger or WGS sequences from a fasta file. Fasta file cannot be gzipped.
  Multiple samples can be in the same file for Sanger data.
  Usage: $0 --fasta sequences.fasta --blastdb path/database --data (sanger|wgs) [--other options]
  --fasta	A fasta file; can be gzipped.
  --blastdb	Path and name of gp60 blast database to use.
  --data	Data type can be 'wgs' or 'sanger'.
  --out		Output filename and path. Optional. 
		Prints to CWD/STDOUT if not specificied.
  --mepi	Flag to parse MEPI lab sample ID from fasta headers
  --bns		Flag that calls BioNumerics related functions.
  --help	Displays this usage statement.
"
}

