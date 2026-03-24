#!/bin/bash
#PBS -P ob80
#PBS -q dgxa100
#PBS -lncpus=16,ngpus=1
#PBS -lmem=96GB
#PBS -lwalltime=24:00:00
#PBS -ljobfs=1GB
#PBS -l wd
#PBS -l other=hyperthread
#PBS -l storage=gdata/if89+gdata/ob80
#PBS -N colabpredict

 
module use /g/data/if89/apps/modulefiles
module load colabfold_batch/1.5.2
 
if [ -z $A3M ]; then
	echo "Please define the A3M environment variable with the -v option" >&2;
	echo "qsub -v A3M=prot/0.a3m colab_predict_long.sh" >&2;
	echo "Output will be in the dirname $A3M folder" >&2;
	exit;
fi

if  [ ! -e $A3M ]; then
	echo "$A3M was not found. Please check" >&2;
	exit;
fi

OUT=`dirname $A3M`
echo ".a3m file is $A3M. Ouput is in $OUT" >&2;

colabfold_batch --amber --templates --num-recycle 3 --use-gpu-relax $A3M $OUT

