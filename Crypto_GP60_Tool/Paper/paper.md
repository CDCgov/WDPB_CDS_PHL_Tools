*gp60* Tool for *Cryptosporidium* Subtyping

Anusha R. Ginni^1,2\*^, Alyssa Kelley^1,2\*^, Shatavia S. Morrison^1^,
Dawn M. Roellig^1\#^

^1^ *Waterborne Disease Prevention Branch (WDPB), Center for Disease
Control and Prevention, Atlanta, GA, USA; ^2^ Applied Science, Research
and Technology Inc, Smyrna, GA, USA*

**\***Authors contributed equally to this work.

^\#^ Corresponding author.

**Summary:**

Cryptosporidiosis is a gastrointestinal illness caused by the protozoan
parasite *Cryptosporidium*, for which there are nearly 20 species
reported to cause human infections. The parasite has a wide range of
transmission routes and vehicles, including person-to-person,
animal-to-person, water, and food. Though multiple individual protocols
comprise the standardized method for *Cryptosporidium* genotyping, there
are scant *gp60* marker-based tools for investigating the genetic
diversity of the *Cryptosporidium* species associated with human
infections, specifically *C. hominis* and *C. parvum* \[1,2,9\]. Given
their prevalence we developed the *gp60* tool to characterize *C.
hominis* and *C. parvum* subtypes and more rapidly respond to
cryptosporidiosis outbreak investigations and case surveillance.
Additionally, this tool can subtype other non-parvum and non-hominis
species.

**Statement of Need:**

Diarrheal diseases are one of the major causes of illness in children
and older adults globally. In 2016, diarrhea was the eighth leading
cause of death among all ages and fifth leading cause of death among
children younger than 5 years, according to the Global Burden of
Diseases, Injuries, and Risk Factors (GBD) Study \[3\].
*Cryptosporidium*, often referred to as 'Crypto,' is a zoonotic parasite
causing gastrointestinal and diarrheal illness called cryptosporidiosis
that can be attributed to diarrheal related deaths. It is one of the
leading causes of waterborne disease in the United States and accounts
for approximately 748,000 cases annually. Although there are 44
*Cryptosporidium* spp. and \>120 genotypes, *C. parvum* and *C. hominis*
cause \~95% of human infections \[3,4\]. Though the two species cause
the same illness, it is important to determine the species genetic
diversity and understand molecular epidemiological and geographical
distribution patterns for more efficient interventions. For these
reasons we developed the *gp60* tool to analyze and assign species and
subtypes. Regular integration and analysis of molecular characterization
and epidemiologic data can further elucidate *Cryptosporidium*
transmission patterns and cryptosporidiosis epidemiology.

The 60 kDa glycoprotein gene (*gp60*) is a commonly used marker that
characterizes *C. parvum* and *C. hominis* cases in cryptosporidiosis
outbreak and case surveillance. The *gp60* tool was developed because
not only subtyping a source to study genetic diversity but also
determines the importance for cryptosporidiosis molecular epidemiology
and as well the need for high-throughput, automated sequence analysis
methods. Using sequence data generated from *Cryptosporidium* specimens,
the tool assigns the species, subtype family, and subtype based on
sequence identity to reference sequences, short tandem repeats
(trinucleotide repeats), and secondary repeats. Nomenclature includes
subtype family (Ia, Ib, Id, Ie, If, Ig, etc. for *C. hominis* and IIa,
IIc, IId, IIe, IIf, IIg, IIh, IIi, etc. for *C. parvum*) followed by the
count of the trinucleotide repeats and the secondary repeats.

![](media/image1.png){width="3.8236122047244097in"
height="1.9819444444444445in"}

*Figure 1: Pictorial representation of the subtype nomenclature.*
Nomenclature of the *C. parvum* IIaA15G2R2 subtype, which was designated
as IIa subtype family, has 15 TCA (A15) and 2 TCG (G2) trinucleotide
repeats, and 2 secondary repeats (R2) as mentioned in Table 1.

*Table 1:* Trinucleotide and secondary repeats present in the
*Cryptosporidium* *gp60* gene and associated designation for subtype
nomenclature.

  ---------------------------------- -------------------------
  **Trinucleotide repeat (5'→3')**   **Subtype designation**
  TCA                                A
  TCG                                G
  TCT                                T
  ACATCA                             R\*
  AAA/G ACG GTG GTA AGG              R^¶^
  C/AAG AA/G GGC A                   R^+^
  ---------------------------------- -------------------------

\* Only within *C. parvum* subtype family IIa

^¶^ Only within *C. hominis* subtype family Ia

^+^ Only within *C. hominis* subtype family If

**Functionality:**

*gp60* tool is a workflow of various sub methods to allocate the subtype
nomenclature to the *Cryptosporidium* species. It utilizes the BLAST
tool and a *Cryptosporidium* specific curated database developed
in-house to align and filter the sequences. Initially, the tool checks
for all input parameters, tool requirements and then proceeds to begin
the analysis. The flow of the tool follows as below.

*Figure 2.* Functional workflow of the GP60 tool

We set threshold parameters to filter the best BLAST hit based on the
blast metrics results (i.e., coverage, identity, and query length). We
added an additional function known as non-conforming events (NCE) that
prints the NCE message in the results. These are assigned if there are
issues with the query sequences (Table 2). The tool generates the NCEs
based on the output of query sequence at each functional level and can
produce single or multiple NCEs depending on the overall output of the
query sequence.

*Table 2:* non-Conforming Events (NCE) and associated definitions

  -------------------------- --------------------------------------------------------------------------------------------------------------------
  NCE                        Description
  NCE-1\_noGp60              No *gp60* sequence detected.
  NCE-2\_coverage            Below coverage threshold (\<70%).
  NCE-3\_identity            Below percent identity threshold (\<97%). Check manually for subtype family and request to add to *gp60* database.
  NCE-4\_length              Below length threshold (\<700bp).
  NCE-5\_startAtTriNuc       Possible incomplete subtype: sequence starts at 5\' repeats.
  NCE-6\_missingTriNuc       Sequence missing 5\' repeat region.
  NCE-7\_AmbiguityInTriNuc   Incomplete subtype: ambiguous nucleotide(s) detected in 5\' repeat region.
  -------------------------- --------------------------------------------------------------------------------------------------------------------

**Implementation:**

Our *gp60* tool is a simple and quick subtyping tool for
*Cryptosporidium* *gp60* sequence analysis. It can be used as a
standalone or integrated component within an existing analysis pipeline
for *Cryptosporidium*. The tool was developed using Perl and invoked
using a simple bash script on the Linux operating system. The only
requirements to run the tool are to ensure the operating system has
NCBI-BLAST tool and Perl scripting language is installed. To invoke the
tool on command line, it is mandatory to provide the path for input
sequences, *gp60* database, and specify sequence type for the tool to
analyze the data. The tool can process whole genome sequence (WGS)
assemblies as well as Sanger sequences that are in single or
multi-sequence fasta file format. Fasta files should not be compressed,
and multiple samples can be provided in the same file for Sanger
sequences. Also, we have containerized the *gp60* tool, and it is
available on the CDC GitHub Page:
<https://github.com/CDCgov/WDPB_CDS_PHL_Tools/tree/master/Crypto_GP60_Tool>

**Acknowledgements:**

This work was supported in part by the Advanced Molecular Detection
Program of the Centers for Disease Control and Prevention, Atlanta, GA.
The authors would like to thank M.H. Seabolt and L.S. Katz for testing
functionality of the tool.

**Additional Information and Declarations:**

The findings and conclusions in this manuscript are those of the authors
and do not necessarily represent the official position of the Centers
for Disease Control and Prevention.

**References:**

1.  Alves M, Xiao L, Sulaiman I, Lal AA, Matos O, Antunes F. Subgenotype
    analysis of Cryptosporidium isolates from humans, cattle, and zoo
    ruminants in Portugal. J Clin Microbiol. 2003 Jun;41(6):2744-7. doi:
    10.1128/JCM.41.6.2744-2747.2003. PMID: 12791920; PMCID: PMC156540.

2.  Alves M, Xiao L, Antunes F, Matos O. Distribution of Cryptosporidium
    subtypes in humans and domestic and wild ruminants in Portugal.
    Parasitol Res. 2006 Aug;99(3):287-92. doi:
    10.1007/s00436-006-0164-5. Epub 2006 Mar 22. PMID: 16552512.

3.  GBD 2016 Diarrhoeal Disease Collaborators. Estimates of the global,
    regional, and national morbidity, mortality, and aetiologies of
    diarrhoea in 195 countries: a systematic analysis for the Global
    Burden of Disease Study 2016. Lancet Infect Dis. 2018
    Nov;18(11):1211-1228. doi: 10.1016/S1473-3099(18)30362-1. Epub 2018
    Sep 19. PMID: 30243583; PMCID: PMC6202444.

4.  Ryan UM, Feng Y, Fayer R, Xiao L. Taxonomy and molecular
    epidemiology of Cryptosporidium and Giardia - a 50-year perspective
    (1971-2021). Int J Parasitol. 2021 Dec;51(13-14):1099-1119. doi:
    10.1016/j.ijpara.2021.08.007. Epub 2021 Oct 26. PMID: 34715087.

5.  Chalmers RM, Smith R, Elwin K, Clifton-Hadley FA, Giles M (2011)
    Epidemiology of anthroponotic and zoonotic human cryptosporidiosis
    in England and Wales, 2004-2006. Epidemiol Infect 139 (5):700-712.
    doi:10.1017/S0950268810001688

6.  Arias-Agudelo LM, Garcia-Montoya G, Cabarcas F, Galvan-Diaz AL,
    Alzate JF. Comparative genomic analysis of the
    principal *Cryptosporidium* species that infect humans. *PeerJ*.
    2020;8:e10478. Published 2020 Dec 2. doi:10.7717/peerj.10478

7.  [Lihua Xiao](about:blank), [Caryn Bern](about:blank), [Josef
    Limor](about:blank), [Irshad Sulaiman](about:blank), [Jacquelin
    Roberts](about:blank), [William Checkley](about:blank), [Lilia
    Cabrera](about:blank), [Robert H. Gilman](about:blank), [Altaf A.
    Lal](about:blank)

> *The Journal of Infectious Diseases*, Volume 183, Issue 3, 1 February
> 2001, Pages 492--497, <https://doi.org/10.1086/318090>

8.  Genotyping method: Roellig DM, Xiao L. Cryptosporidium Genotyping
    for Epidemiology Tracking. Methods Mol Biol. 2020;2052:103-116. doi:
    10.1007/978-1-4939-9748-0\_7. PMID: 31452159.

9.  Cacciò SM, Thompson RC, McLauchlin J, Smith HV. Unravelling
    Cryptosporidium and Giardia epidemiology. Trends Parasitol. 2005
    Sep;21(9):430-7. doi: 10.1016/j.pt.2005.06.013. PMID: 16046184.
