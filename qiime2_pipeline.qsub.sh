### Job name
#PBS -N Bac_screen_${id}
### Output files
#PBS -e Bac_screen_${id}.err
#PBS -o Bac_screen_${id}.log
### Only send mail when job is aborted or terminates abnormally
#PBS -m n
### Number of nodes/cores
#PBS -l nodes=1:ppn=40:thinnode
### Minimum memory
#PBS -l mem=180gb
### Requesting time - format is <days>:<hours>:<minutes>:<seconds>
#PBS -l walltime=24:00:00


#########################################################
# loading necessary modules                             #
#########################################################

module load tools perl samtools/1.9 bedtools/2.28.0 pigz/2.3.4 mmseqs2/release_12-113e3 barrnap/0.7 emboss/6.6.0 minimap2/2.17r941 gcc intel/perflibs R/3.6.1 lftp/4.9.2

#########################################################
# setup variables and folder structure                  #
#########################################################

# Starting time/date
STARTTIME=$(date)
STARTTIME_INSEC=$(date +%s)



# Ending time/date
ENDTIME=$(date)
ENDTIME_INSEC=$(date +%s)
echo "==============================================="
echo "Pipeline started at $STARTTIME"
echo "Pipeline ended at $ENDTIME"
echo "Pipeline took $((ENDTIME_INSEC - STARTTIME_INSEC)) seconds to finish"
