#!/usr/bin/env python
import argparse
import os
import subprocess
import sys
import pandas as pd
import logging
import logging.handlers
import csv, json
import shutil
import time
import errno
import pathlib
import warnings
import glob
import base64
import gzip
import datetime
#**********************************************************


#Tool Updates
algoname = "Cryptosporidium_Genotyping"
version = 1.8
updated = datetime.date(2021,12,10)

#set color to the warning messages
#Set colors for warnings
CRED = '\033[91m' + '\nError:'
CYEL = '\033[93m' + '\nWarning:'
CGRE = '\033[92m' + '\nInfo:'
CEND = '\033[0m'

# To parse the commandline arguments
# override to split space based cmdline args
class myargumentparser(argparse.ArgumentParser):
    def convert_arg_line_to_args(self, arg_line):
        return arg_line.split()

# Parse the commandline arguments
def parse_cmdline():
    # create the parser
    parser = myargumentparser(fromfile_prefix_chars='@')
    #the environment variables
    parser.add_argument('--clientversion',type=int)
    parser.add_argument('--nthreads',help='number of threads',type=int,default=2)
    parser.add_argument('--localdir',default='./local',help='local working directory',type=str) #this is scratch
    parser.add_argument('--tempdir',help='temporary shared directory',type=str)# temp folder to save data between runs but tricky to use ,avoid it
    parser.add_argument('--resultsdir',help='results directory',type=str) #this is where we need to save our results and create a directory if needed
    parser.add_argument('--shareddir',help='base shared directory of the project',type=str) # base shared folder for thre project
    parser.add_argument('--toolsdir',default='',help='tools directory',type=str) #	custom tools, not required for this
    parser.add_argument('--scratchdir',default='',help='intermediate files directory',type=str) # not required for now
    parser.add_argument('--reference_folder',default='',help="Blast reference database",type=str) #where reference database is located
    parser.add_argument('--query',default='', help='filename for the assembled query genome', type=str) #where input is located
    # # get the known arguments of the command line
    try:
        args = parser.parse_args(['@Crypto/scripts/settings.txt'])
    except:
        args = parser.parse_args()
    return args

def directories(args):
	folders = (args.localdir,args.resultsdir)
	for f in folders:
		os.path.join(os.getcwd(),f)
		os.makedirs(f,exist_ok=True)
	return folders

#creating subdirectories
def sub_dirs(args):
    mode=0o777
    resultsub = args.resultsdir+"/results/raw"
    tempsub = args.localdir+"/sorted_blast_pair/result_tables"
    finalsub = args.localdir + "/final"
    logsub = args.resultsdir+"/logs"
    os.makedirs(resultsub,mode,exist_ok=True)
    os.makedirs(tempsub,mode,exist_ok=True)
    os.makedirs(logsub,mode,exist_ok=True)
    os.makedirs(finalsub,mode,exist_ok=True)

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

def progress(status,args):
	filename = args.resultsdir+"/logs/__progress__.txt"
	with open(filename,'w') as f:
		f.write(str(status)+"\n") #
		# f.truncate()

def RunBlast(warnlog,args):
    child_processes=[]
    #loops throught the folder for .gz fasta files
    for file in os.listdir(args.query):
        query=os.path.join(args.localdir,file)
        query=query.split('.gz')[0]
        with gzip.open(args.query + file, 'rb') as input_file, open(query,'wb') as output_file:
            output_file.write(input_file.read())
            baseq=os.path.basename(query)
            filename =os.path.splitext(baseq)[0]
            for database in os.listdir(args.reference_folder): #blastdb
                basedb=os.path.basename(database)
                dbname=basedb.split(".")[0]
                databasename =os.path.join(args.reference_folder,basedb.split(".")[0])
            try:
                p=subprocess.Popen(["blastn","-query",query,"-db",databasename,"-evalue","1e-6","-outfmt","6 qseqid sseqid pident qlen slen qstart qend sstart send","-max_target_seqs","3","-out",args.localdir+"/"+filename+"_"+dbname+".blast"],
                stdout = subprocess.PIPE,stderr=subprocess.STDOUT)
                # instead of printing the warns on console, reading the text from PIPE and redirecting to the logger function,logger object passes the log file
                for line in p.stdout:
                    warnlog.warning(line)
                    child_processes.append(p)
                    for cp in child_processes:
                        cp.wait()
            except RuntimeError as err:
                errlog.error("{} occured at RunBlast level".format(err.message))


def filter(args):
	 fpath=args.localdir+"/sorted_blast_pair"
	 for blast_result in os.listdir(args.localdir):
		 if blast_result.endswith(".blast"):
			 genename=os.path.basename(blast_result)
			 genomename=genename.split(".")[0]
			 blastresult=open(args.localdir+"/"+blast_result)
			 for line in blastresult:
				 try:
					 gene={}
					 line = line.split( )
					 qseqid=line[0]
					 sseqid=line[1]
					 pident=float(line[2])
					 qlength=float(line[3])
					 slength=float(line[4])
					 qstart=float(line[5])
					 qend=float(line[6])
					 sstart=float(line[7])
					 send=float(line[8])

					 if (pident> 97) & (abs(qend-qstart)/slength > 0.75)  :
						 gene[qseqid]=sseqid
						 for key in gene:
							 with open(fpath+"/"+genomename+".blast","a") as ofile:
								  ofile.write(genomename+"\t"+key+"\t"+gene.get(key)+"\t"\
									  +str(pident)+"\t"+str(slength)+"\t"+str(abs(qend-qstart)/slength)+"\t"+str(qstart)+"\t"+str(qend)+"\n")
								  ofile.close
				 except IOError:
					 msglog.info("no input")
			 blastresult.close()


#### Generate tables for each genome"
def generate_table(args):
	temppath = args.localdir+"/sorted_blast_pair/"
	if not "result_tables" in os.listdir(temppath):
		os.mkdir(temppath+"result_tables")
	for filename in os.listdir(temppath):
		if filename.endswith(".blast"):
			 base=filename.split(".")
			 name=base[0]
			 df=pd.read_csv(temppath+filename,sep="\t",header=None)
			 df.columns=['Genome','testgenome_gene_name','db_gene_name','pident','slength','coverage','querystart','queryend']
			 df['db']=df.db_gene_name.apply(lambda x:x.split("_")[-1])
			 df['score']=df['pident']*df['coverage']
			 #df['result']=df.sort_values(by="score",ascending=False).head(1).db_gene_name.values[0]+"_true"
			 #df=df.sort_values(by="score",ascending=False).head(6)
			 f_name=temppath+"result_tables/"+str(filename)+"_table.csv"
			 df.to_csv(f_name)

def result_table1(args):
     temppath = args.localdir+"/sorted_blast_pair/result_tables/"
     filelist=glob.glob(temppath+"*_table.csv")
     df_list=[pd.read_csv(file) for file in filelist]
     bigdf1=pd.concat(df_list,axis=0)
     bigdf1=bigdf1.drop("Unnamed: 0",axis=1)
     bigdf1.to_csv(temppath + 'result_table1.csv')

##filter best hit and insert newtype that are not in database
def filter2(args):
    temppath = args.localdir+"/sorted_blast_pair/result_tables/"
    for file in os.listdir(temppath):
        if file.endswith("_table.csv"):
            name=file.split("_table.csv")[0]
            dic1={}
            dic={}
            dic1[file]=dic
            sample=pd.read_csv(temppath+"/"+file)
            sample=sample.drop("Unnamed: 0",axis=1)
            sample['score']=sample['pident']*sample['coverage']
            table=pd.DataFrame(columns=sample.columns)
            for i in ['18s','actin','hsp70']:
                if i in str(sample['db']):
                    if (sample['db'].str.count(i).sum()) == 1:
                        dic[i]=sample[sample.db==i].db_gene_name.values[0]  #.replace('C_','C. ')
                        table=table.append(pd.DataFrame(sample[sample.db_gene_name==str([dic[i]][0])]))
                    elif (sample['db'].str.count(i).sum()) > 1:
                        dic[i]=sample[sample.db==i].sort_values(by="score",ascending=False).head(1).db_gene_name.values[0] #.replace('C_','C. ')
                        table=table.append(pd.DataFrame(sample[sample.db_gene_name==str([dic[i]][0])].iloc[0]).T) #tracking the change iloc[0] -> iloc[:,0]
                elif i not in str(sample['db']):
                    dic[i]="type not found"
                    table=table.append(pd.DataFrame(sample[sample.db_gene_name==str([dic[i]][0])])).fillna("N/A")
            f_name=temppath+str(name)+"_newtable.csv"
            f_name2=temppath+str(name)+"_newtable2.csv"
            pd.DataFrame.from_dict(dic1).to_csv(f_name, quoting=csv.QUOTE_NONE,quotechar='', escapechar=",")
            table.to_csv(f_name2)

def combine_table(args):
    temppath = args.localdir+"/sorted_blast_pair/result_tables/"
    filelist=glob.glob(temppath+"*_newtable.csv")
    df_list=[pd.read_csv(file) for file in filelist]
    bigdf=pd.concat(df_list,axis=1)
    bigdf=bigdf.drop("Unnamed: 0",axis=1)
    bigdf.index=['18s','actin','hsp70']
    bigdf.loc['result']=''
    bigdf.columns = bigdf.columns.str.split("_a").str[0]
    for i in range(0,len(bigdf.columns)):
        bigdf.loc['result'][i]=bigdf[bigdf.columns[i]].apply(lambda x:"_".join(x.split("_")[0:2])).value_counts().index[0]
        bigdf.loc['result'][i]=bigdf.loc['result'][i].replace('C_','C. ')
        # bigdf.loc['result'].to_csv(temppath +"Species_Call.csv")
        bigdf_T=bigdf.T.reset_index()
        bigdf_T.columns=['Genome','18s','actin','hsp70','Result']
        bigdf_T[['Genome','Result']].to_csv(temppath + "Species_Call.csv",header=True,index=False)
        bigdf_T.Genome=bigdf_T.Genome.apply(lambda x:x.split(".")[0])
        # bigdf_T['Result'].to_csv(temppath +"Species_Call.csv")
        filelist1=glob.glob(temppath+"*_table.csv")
        filelist2=glob.glob(temppath+"*_newtable2.csv")
        df_list=[pd.read_csv(f) for f in filelist1]
        df_list2=[pd.read_csv(f) for f in filelist2]
        bigdf1=pd.concat(df_list,axis=0)
        bigdf2=pd.concat(df_list2,axis=0)
        bigdf2=pd.DataFrame(bigdf2.drop("Unnamed: 0",axis=1))
        bigdf1.to_csv(temppath + "Blast_Raw.csv")
        bigdf2.to_csv(temppath + "Blast_Cleaned.csv") #-----------------------------------
        #final=pd.concat([bigdf2,bigdf_T],sort=False)
        final=pd.merge(bigdf2,bigdf_T,on="Genome") #tracking the change,merge -> concat
        final.to_csv(temppath + "Filtered_Results.csv")

    source_dir1=args.localdir+"/sorted_blast_pair/result_tables"
    destination=args.localdir+"/final"
    for file in os.listdir(source_dir1):
        fileprefix = ("Species_Call","Filtered_Results","Blast")
        if file.startswith(fileprefix):
            filetarget=os.path.join(destination,file)
            file=os.path.join(source_dir1,file)
            shutil.copy(file,filetarget)

def prepend_note(args):
    """Insert a disclaimer to the Species_Call file"""
    csvpath = args.localdir+"/final/Species_Call.csv"
    dummy = args.localdir+"/final/dummy.csv"
    tooluse = "Cryptosporidium_Genotyping Analysis - Species call"
    note1= "Developed by : Anusha Ginni (qxu0@cdc.gov) "
    affiliation = "Clinical Detection Surveillance/WDPB,CDC"
    toolDB = "Tool version - " + str(version) + " and Genotyping Blast Database was updated on : " + str(updated)
    disclaim = "*** Please note that the assays used are not ISO or CLIA approcertified and should not be considered diagnostic."
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
        for line in read_obj:
            write_obj.write(line)
        os.remove(csvpath) #remove the old file
        os.rename(dummy, csvpath) # rename the dummy file with the old file name

def outputdirectory(args):
    resultpath = args.localdir + "/final"  # need to create this one
    destionationpath = args.resultsdir + "/results/raw"
    for fl in os.listdir(resultpath):
        input_flname = os.path.join(resultpath, fl)
        output_flname = os.path.join(destionationpath, fl)
        with open(input_flname, 'rb') as input_file, open(output_flname, 'wb') as output_file:
            output_file.write(base64.b64encode(input_file.read()))

def do_b64decode(args):
    filepath= open(args.resultsdir + "/results/raw/Species_Call.csv",'rb')
    infile = os.path.join(args.resultsdir + "/results/raw/Final_Species_Call.csv")
    with open(infile,'wb') as fl:
        fl.write(base64.b64decode(filepath.read()))

class _msglog(object):
    def __init__(self,filename,messlog):
        self._filename=filename
        self._messlog=messlog

    def info(self,msg):
        open(self._filename,'w').write(msg)
        self._messlog.info(msg)

def main():
    args = parse_cmdline()
    directories(args)
    sub_dirs(args)
    #msglog = logger_setup('__message__', args.resultsdir+"/logs/__message__.txt")
    errlog = logger_setup('error',args.resultsdir+"/logs/error.txt")
    warnlog = logger_setup('warn',args.resultsdir+"/logs/warning.txt")
    messlog = logger_setup('message',args.resultsdir+"/logs/messages.txt")
    messlog.info("#") # file has to start with '#', to make the BN frontend parse the log file
    msglog = _msglog(args.resultsdir + "/logs/__message__.txt",messlog)

    msglog.info("{} algorithm has initiated".format(algoname))
    msglog.info("Created all required directories")
    msglog.info("Created all log files")
    try:
        progress(0,args)
        msglog.info("Blast has Started")
        RunBlast(warnlog,args)
        msglog.info("Blast has completed")

        msglog.info("Filtering the blast output")
        filter(args)
        msglog.info("First filtering is done")

        msglog.info("Generating tables from filter")
        generate_table(args)
        msglog.info("Completed tables generation")

        result_table1(args)
        msglog.info("started second filtering")
        filter2(args)
        msglog.info("Completed second filter")

        msglog.info("calling the combine_table function")
        combine_table(args)
        msglog.info("Filtered tables are now combined")
        
        msglog.info("Adding disclaimer to the Species_Call")
        prepend_note(args)

        msglog.info("Generating final results")
        outputdirectory(args)
        msglog.info("Final result tables were generated and added to the result directory")

        msglog.info("Results decoding has started")
        do_b64decode(args)
        msglog.info("Decoded files has been created for results")

        progress(100,args)
        msglog.info('Job completed successfully')
        print(CGRE + "Job has completed succesfully" + CEND)
    except RuntimeError as err:
        errlog.error('Could not handle the error, job aborted!')

if __name__ == '__main__':
     main()
