import argparse
import os
import subprocess
import sys
import pandas as pd
import logging
import logging.handlers
import csv
import shutil
import time
import errno
import pathlib
import warnings
import glob
import gzip
import datetime

#set color to the warning messages
#Set colors for warnings
CRED = '\033[91m' + '\nError:'
CYEL = '\033[93m' + '\nWarning:'
CGRE = '\033[92m' + '\nInfo:'
CEND = '\033[0m'

#Tool details
algoname = "Crypto_18S_RNA_typing"
version=0.1
Ref_Db_updated=datetime.date(2021,12,10)

#Set colors for cmdline messages/warnings
CRED = '\033[91m' + '\nError:'
CYEL = '\033[93m' + '\nWarning:'
CGRE = '\033[92m' + '\nStatus:'
CEND = '\033[0m'

class myargumentparser(argparse.ArgumentParser):
    # override to split space based cmdline args
    def convert_arg_line_to_args(self, arg_line):
        return arg_line.split()

def cmdline_args():
    parser = myargumentparser(fromfile_prefix_chars='@')
    parser.add_argument('--reference_folder',default='',help="Blast Reference Database",type=str) # where reference database is located
    parser.add_argument('--query',default='', help='filename for the assembled query genome', type=str) # where fasta assemblies are located
    parser.add_argument('--resultsdir',default='',help='results directory',type=str) #this is where intermediate files and results are saved
    parser.add_argument('--localdir', help='scratch location for intermediate files', type=str) # just a place holder
    args = parser.parse_args(['@/Crypto18s/scripts/settings.txt'])
    return args

def dirs(args):
    folder= (args.resultsdir,args.localdir)
    for f in folder:
        os.path.join(os.getcwd(),f)
        os.makedirs(f, exist_ok=True)

def subdirs(args):
    mode=0o777
    resultsub = args.resultsdir+"/Results"
    tempsub = args.localdir+"/sorted_blastresults"
    logsub = args.resultsdir+"/logs"
    os.makedirs(resultsub,mode,exist_ok=True)
    os.makedirs(tempsub,mode,exist_ok=True)
    os.makedirs(logsub,mode,exist_ok=True)

#logging function
def logger_setup(logname,logfile,level=logging.INFO,filemode='w'):
    '''To create loggers through out the program,just call the function where required'''
    format = logging.Formatter('%(asctime)s\t%(levelname)s\t%(message)s')
    filehandler = logging.FileHandler(logfile)
    filehandler.setFormatter(format)
    logger = logging.getLogger(logname)
    logger.setLevel(level)
    logger.addHandler(filehandler)
    return logger

def run_blastn(args):
    child_processes=[]
    for file in os.listdir(args.query):
        query=os.path.join(args.localdir,file)
        with open(args.query + file,'rb') as input_file, open(query,'wb') as output_file:
            output_file.write(input_file.read())
            output_file.close()
            input_file.close()
            #os.system("cp testinput/18s_seqs.fasta localdir/18s_seqs.fasta")
            baseq=os.path.basename(query)
            filename=os.path.splitext(baseq)[0]
            for database in os.listdir(args.reference_folder): #this is the blast reference db
                basedb=os.path.basename(database)
                dbname=basedb.split(".")[0]
                databasename =os.path.join(args.reference_folder,basedb.split(".")[0])
                # print(basedb,basedb.split(".",2)[0])
                # new_basedb=".".join(basedb.split(".",2)[:2])
                # print(basedb,new_basedb)
                # databasename =os.path.join(args.reference_folder,new_basedb)
                # print("this is dbname", databasename)
            try:
                p = subprocess.Popen(["blastn","-query",query,"-db",databasename,"-evalue","1e-6","-outfmt","6 qseqid sseqid pident length qcovs mismatch gapopen qlen slen bitscore","-out",args.localdir+"/"+filename+".blast"],
                stdout = subprocess.PIPE,stderr=subprocess.STDOUT)
                for line in p.stdout:
                    # warnlog.warning(line)
                    child_processes.append(p)
                    for cp in child_processes:
                        cp.wait()
            except RuntimeError as err:
                errlog.error("{} occured at RunBlast level".format(err.message))

def blast_output(args):
    fpath=args.localdir+"/sorted_blastresults"
    for blast_result in os.listdir(args.localdir):
        if blast_result.endswith(".blast"):
            genename=os.path.basename(blast_result)
            genomename=genename.split(".")[0]
            blastresult=open(args.localdir+"/"+blast_result)
            # qseqid sseqid pident length qcov mismatch gapopen qlen slen bitscore
            for line in blastresult:
                try:
                    gene={}
                    line = line.split( )
                    qseqid=line[0]
                    sseqid=line[1]
                    pident=float(line[2])
                    length=(line[3])
                    qcovs=float(line[4])
                    mismatch=(line[5])
                    gapopen=(line[6])
                    qlen=(line[7])
                    slen=(line[8])
                    bitscore=(line[9])

                    if (pident> 98) & (qcovs > 75)  :
                        gene[qseqid]=sseqid
                        for key in gene:
                            with open(fpath+"/"+genomename+".blast","a") as ofile:
                                ofile.write(key+"\t"+gene.get(key)+"\t"+str(pident)+"\t"+str(length)+"\t"+str(qcovs)+"\t"+str(mismatch)+"\t"+str(gapopen)+"\t"+str(qlen)+"\t"+str(slen)+"\t"+str(bitscore)+"\n")
                                ofile.close
                except IOError:
                    # msglog.info("no input")
                    blastresult.close()

def write_csvs(args):
    blastpath=args.localdir+"sorted_blastresults/"
    if not "blast_cvs" in os.listdir(blastpath):
        os.makedirs(blastpath+"blast_csv",exist_ok=True)
    for file in os.listdir(blastpath):
        if file.endswith(".blast"):
            filename=file.split(".")[0]
            blast_data=pd.read_csv(blastpath+file, sep="\t", header=None)
            # print("line 166", blast_data)
            blast_data.columns=["query_genome","db_bestmatch","pident","alignment_length","coverage","mismatch","gapopen","query_length","subject_length","bitscore"]
            # print("line 168", blast_data)
            blast_csvfmt=blastpath+"blast_csv/"+str(filename)+".csv"
            # print("line 166", blast_csvfmt)
            blast_data.to_csv(blast_csvfmt)

def capture_blast(args):
    dir=args.localdir+"/sorted_blastresults/blast_csv/"
    src=args.localdir
    dest=args.resultsdir
    dummy=args.resultsdir+"/dummyfile"
    prefix="NOTE: Since the sample did not meet the threshold parameters, blast data was added to results for manual validation"
    header=("query_genome"+"\t"+"db_bestmatch"+"\t"+"pident"+"\t"+"length"+"\t"+"qcovs"+"\t"+"mismatch"+"\t"+"gapopen"+"\t"+"qlen"+"\t"+"slen"+"\t"+"bitscore")
    if len(os.listdir(dir)) == 0:
        # print("dir is empty")
        for file in os.listdir(args.localdir):
            if file.endswith(".blast"):
                shutil.copy(src+file,dest+file)
                with open(dest+file,'r') as read_obj,open(dummy,'w') as write_obj:
                    write_obj.write(prefix)
                    write_obj.write("\n")
                    write_obj.write("\n")
                    write_obj.write(header)
                    write_obj.write("\n")
                    for line in read_obj:
                        write_obj.write(line)
                    os.remove(dest+file) #remove the old file
                    os.rename(dummy, dest+file) # rename the dummy file


def filter_besthit(args):
    i=0
    besthits=[]
    resultpath=args.resultsdir+"/Results"
    csvpath=args.localdir+"sorted_blastresults/blast_csv/"
    for file in os.listdir(csvpath):
        if file.endswith(".csv"):
            filename=file.split(".")[0]
            data=pd.read_csv(csvpath+file,sep=",",index_col=False)
            data = data.drop(["Unnamed: 0","mismatch","gapopen","query_length","subject_length"],axis=1)
            data["rank"]=data[["query_genome","pident","coverage","bitscore"]].apply(tuple,axis=1).rank(method='dense',ascending=False).astype(int)
            species=data["db_bestmatch"].str.split('_',2, expand=True)
            data["species"] = species[0]+"."+species[1]
            data = data.assign(NCE_warning=np.where(data["alignment_length"] < 700,"Alignment length is <700bp,do BLAST manual check for Identity and coverage","-"))
            # print(data)
            rankeddata = data.sort_values(["rank"])
            selecthits = rankeddata["rank"]==1
            Filtered_hits=rankeddata[selecthits].drop(["rank"], axis=1)

            if i ==0:
                Filtered_hits.to_csv(args.resultsdir+"/Results"+"/18S_results.csv",index=False)
            else:
                Filtered_hits.to_csv(args.resultsdir+"/Results"+"/18S_results.csv",mode='a',index=False, header = False)
            i+=1

def disclaimer(args):
    """Insert a disclaimer to the 18s_results file"""
    csvpath = args.resultsdir+"/Results/18S_results.csv"
    dummy = args.resultsdir+"/Results/dummy.csv"
    tooluse = "Cryptosporidium 18S rRNA typing Analysis"
    note1= "Developed by : Anusha Ginni (qxu0@cdc.gov) "
    affiliation = "Clinical Detection Surveillance/WDPB,CDC"
    toolDB = "Tool version - " + str(version) + " and 18S Blast Database was updated on : " + str(Ref_Db_updated)
    disclaim = "Disclaimer: Please note that the assays used are not ISO or CLIA certified and should NOT be considered diagnostic."
    with open(csvpath,'r') as read_obj, open(dummy,'w') as write_obj:
        write_obj.write(tooluse)
        write_obj.write("\n")
        write_obj.write(note1)
        write_obj.write(affiliation)
        write_obj.write("\n")
        write_obj.write(toolDB)
        write_obj.write("\n")
        write_obj.write(disclaim)
        write_obj.write('\n')
        write_obj.write('\n')
        write_obj.write('\n')
        for line in read_obj:
            write_obj.write(line)
        os.remove(csvpath) #remove the old file
        os.rename(dummy, csvpath) # rename the dummy file with the old file name

def main():
    args = cmdline_args()
    dirs(args)
    subdirs(args)
    run_blastn(args)
    blast_output(args)
    write_csvs(args)
    capture_blast(args)
    filter_besthit(args)
    disclaimer(args)
    print(CGRE + "Job has completed successfully" + CEND)

if __name__=='__main__':
    main()
