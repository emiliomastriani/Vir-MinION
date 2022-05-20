![Screen Shot 2022-04-29 at 11 10 37 AM](https://user-images.githubusercontent.com/65239532/165880443-6ef5406d-d026-4315-a41e-71703255d58b.png)

Pipeline for 3rd Generation sequencing data from MinION
The Vir-MinION pipeline works on 3rd generation data and provide the user with a taxonomic classification of the reads through three strategies: assem-bly-based, read-based, and clustering-based. The pipelines supply the scientist with comprehen-sive results in graphical and textual format for future analyses. Finally, the pipelines equip the us-er with a stand-alone platform with dedicated and various viral databases, a requirement for working in field conditions without internet connection.

Vir-MinION requires few arguments to run, and its syntax is intuitive

Usage: VirMinION-Pipe.sh PreProcDataFolder PreProcOutFolder BaseCallConfFile BarCodeKit NumOfThread Method [--read_based | --ass_based | --clust_based]

Refer to [Vir-MinION_Installation_Manual.pdf](https://github.com/emiliomastriani/Vir-MinION/files/8588447/Vir-MinION_Installation_Manual.pdf) to install and configure Vir-MinION on your NVIDIA machine

Refer to [Vir-MinION_User_Manual.pdf](https://github.com/emiliomastriani/Vir-MinION/files/8737060/Vir-MinION_User_Manual.pdf) for a quick use of Vir-MinION

Refer to [VIRMINION-CAMISIM_DEEPSIM.txt](https://github.com/emiliomastriani/Vir-MinION/files/8737016/VIRMINION-CAMISIM_DEEPSIM.txt) for generating synthetic data using CAMISIM/DEEPSIM and run Vir-MinION using it. If you prefer to use synthetic data used during the Vir-MinION test, download the following file multi_viruses_fast5.tgz

Refer to [CreateDBs.txt](https://github.com/emiliomastriani/Vir-MinION/files/8737052/CreateDBs.txt) for a step-by-step guide on installing and configuring the DBs need by Vir-MinION
