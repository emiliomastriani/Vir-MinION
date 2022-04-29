#!/bin/bash

#Usage VirMinION-Pipe.sh PreProcDataFolder PreProcOutFolder BaseCallConfFile BarCodeKit NumOfThread Method [--read_based | --ass_based | --clust_based]
#As an example: time VirMinION-Pipe.sh /mnt/NTFS/Nicolas_DMCP/Superpools1-10_Yunnan_bat_anal_swabs/Superpools1-10_Yunnan_bat_anal_swabs/20210128_1229_MN31711_FAO32197_552b0a36/fast5_pass/ Superpools1-10_Yunnan_bat_anal_swabs dna_r9.4.1_450bps_hac.cfg EXP-NBD104 24 --read_based      

##Pre-processing parameters
PreProcDataFolder=$1 	#Folder containing fast5 files // For example: Superpools1-10_Yunnan_bat_anal_swabs/Superpools1-10_Yunnan_bat_anal_swabs/20210128_1229_MN31711_FAO32197_552b0a36/fast5_pass/ 
PreProcOutFolder=$2 	#Folder will contain basecalled files // For example: Superpools1-10_Yunnan_bat_anal_swabs
BaseCallConfFile=$3	#Configuration file to use for basecalling // For Example: dna_r9.4.1_450bps_hac.cfg
BarCodeKit=$4		#BarCode Kit used // For example: EXP-NBD104
NumOfThread=$5		#Number of threads to use
Method=$6		#Method to use. It can be --read_based | --ass_based | --clust_based

NumOfArgs=6		
logfile="VirMinION-Pipe.log"

NanoFiltFolder="NanoFiltOut"
NanoFiltOut=$NanoFiltFolder"/"$PreProcOutFolder"filtered.fastq"

DemuOutFold=$PreProcOutFolder"_Demultiplexed_Guppy"

#Sourcing the CONDA environment (check for the right conda-path)
source /Anaconda3/bin/conda/conda.sh

clustering_func(){
	printf "Calling Clustering-based task with taxonomy classification\n"
	echo -e "$(date) Calling Clustering-based task with taxonomy classification\n" >> $logfile 2>&1
		#1. Activate conda environment
		conda activate NGSpeciesID
		#2. Execute the clustering step for every fastq file ==> 1h
		time for i in `ls *.fastq` ; do NGSpeciesID --ont --fastq $i --outfolder `echo $i | cut -d "." -f1`_consensus --consensus --abundance_ratio 0.01 --rc_identity_threshold 0.8 --medaka --t 12; done
		#2. Taxonomy classification From clustering ==> 9min
		time for i in `find . -name consensus.fasta ! -size 0`; do taxonomy.sh $i TaxoClust $NumOfThread `echo $i | cut -d "/" -f2,3 | sed 's/\//_/g'`_Clust ; done
}

assembly_func(){
	printf "Calling Assembly-based task with taxonomy classification\n"
	echo -e "$(date) Calling Assembly-based task with taxonomy classification\n" >> $logfile 2>&1
		#3. Execute the assembly step for every fastq file using MegaHit ==> 3min
		time for i in `ls *.fastq` ; do megahit -t 24 --read $i --k-list 21,41,61,81,99 --no-mercy --min-count 2 --out-dir `echo $i | cut -d "." -f1`_MegaAss ; done
		#3. From Assembly ==> 1min
		time for i in `find . -name final.contigs.fa ! -size 0`; do taxonomy.sh $i TaxoAss $NumOfThread `echo $i | cut -d "/" -f2 | sed 's/\//_/g'`; done
}

read_func(){
	printf "Calling Read-based task with taxonomy classification\n"
	echo -e "$(date) Calling Read-based task with taxonomy classification\n" >> $logfile 2>&1
		#1. From reads ==> 13min
		time for i in `ls *.fastq` ; do taxonomy.sh $i TaxoRead $NumOfThread `echo $i | cut -d "." -f1`_Read ; done
}


#Checking the number of arguments
if (( $# < $NumOfArgs ))
then
    printf "%b" "Error. Not enough arguments.\n" >&2
    printf "%b" "Usage: VirMinION-Pipe.sh PreProcDataFolder PreProcOutFolder BaseCallConfFile BarCodeKit NumOfThread Method [--read_based | --ass_based | --clust_based]  \n" >&2
    exit 1
elif (( $# > $NumOfArgs ))
then
    printf "%b" "Error. Too many arguments.\n" >&2
    printf "%b" "Usage: VirMinION-Pipe.sh PreProcDataFolder PreProcOutFolder BaseCallConfFile BarCodeKit NumOfThread Method [--read_based | --ass_based | --clust_based] \n" >&2
    exit 2
fi


##Basecalling step ==> 60min
echo "Calling pre-process task"
echo -e "$(date) Calling Basecalling task\n" >> $logfile 2>&1
time guppy_basecaller -i $PreProcDataFolder -r -s $PreProcOutFolder -c $BaseCallConfFile -x "cuda:0" --compress_fastq --require_barcodes_both_ends --trim_barcodes

##Create NanoFilt output folder
mkdir $NanoFiltFolder

##Filtering step ==> 4min
echo "Calling Filtering task"
echo -e "$(date) Calling Filtering task\n" >> $logfile 2>&1
time zcat $PreProcOutFolder/pass/*.fastq.gz | NanoFilt --maxlength 1500 -l 500 -q 10 --minGC 0.4 --maxGC 0.6 > $NanoFiltOut


##Demultiplexing step ==> 2min
echo "Calling Demultiplexing task"
echo -e "$(date) Calling Demultiplexing task\n" >> $logfile 2>&1
time guppy_barcoder -i $NanoFiltFolder --save_path $DemuOutFold -x "cuda:0" --barcode_kits $BarCodeKit

#1. Collect all barcode files independently ==> 2min on 12 barcode folders (2.5G)
echo "Collect all barcode files independently"
echo -e "$(date) Collect all barcode files independently \n" >> $logfile 2>&1
for i in `find $DemuOutFold/* -name 'barcode*' | awk -F "/" '{print $2}'`; do echo $DemuOutFold/$i; cat $DemuOutFold/$i/*.fastq > $PreProcOutFold"Demultiplexed_"$i".fastq" ; done

case $Method in
		  	("--read_based")
		    		printf "Executing Read-based taxonomy process \n"
		    		echo -e "$(date) Calling Read-based taxonomy task\n" >> $logfile 2>&1
		    		read_func ;;
		    	("--ass_based")
		    		assembly_func ;;
		    	("--clust_based")
		    		clustering_func ;;
		    	(*)
		    		echo "One of the following option must be specified: ALL|[--read_based --ass_based --clust_based] " ;;
esac