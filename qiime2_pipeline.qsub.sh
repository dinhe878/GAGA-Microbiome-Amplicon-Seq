### Job name
### Output files
#PBS -e metagenome_${id}.err
#PBS -o metagenome_${id}.log
### Only send mail when job is aborted or terminates abnormally
#PBS -m n
### Number of nodes/cores
#PBS -l nodes=1:ppn=40:thinnode
### Minimum memory
#PBS -l mem=180gb
### Requesting time - format is <days>:<hours>:<minutes>:<seconds>
#PBS -l walltime=6:00:00

#########################################################
# loading necessary modules                             #
#########################################################

module load qiime2/2021.2 lftp/4.9.2

#########################################################
# setup variables and folder structure                  #
#########################################################

amplicon_seq_dir=/home/people/dinghe/ku_00039/people/dinghe/working_dr/amplicon_seq
qiime_wd=/home/people/dinghe/ku_00039/people/dinghe/working_dr/amplicon_seq/qiime2/runs/28052021

# Starting time/date
STARTTIME=$(date)
STARTTIME_INSEC=$(date +%s)
echo "===== Qiime2 pipeline starts ======"

# additinal variables can be passed through commandline option (-v):

#########################################################
# main pipeline                                         #
#########################################################

# Generating manifest file (paths to the original pair-end seq files)
cd $qiime_wd

ls -ld $amplicon_seq_dir/raw_seq_data/GAGA_samples/CSE_sample/Cleandata/*_1.fq.gz | awk '{split($0,a,"\/"); print a[14]"\t/"a[2]"/"a[3]"/"a[4]"/"a[5]"/"a[6]"/"a[7]"/"a[8]"/"a[9]"/"a[10]"/"a[11]"/"a[12]"/"a[13]"/"a[14]}' | sed -E "s/(WH.*)_1\.fq.*\t/\1\t/g" >> CSE_sample_input_manifest_1.tsv
ls -ld $amplicon_seq_dir/raw_seq_data/GAGA_samples/CSE_sample/Cleandata/*_2.fq.gz | awk '{split($0,a," "); print a[9]}' >> CSE_sample_input_manifest_2.tsv
paste -d "\t" CSE_sample_input_manifest_1.tsv CSE_sample_input_manifest_2.tsv > CSE_sample_input_manifest.tsv
rm  CSE_sample_input_manifest_*

ls -ld $amplicon_seq_dir/raw_seq_data/GAGA_samples/KIZ_sample/Cleandata/*_1.fq.gz | awk '{split($0,a,"\/"); print a[14]"\t/"a[2]"/"a[3]"/"a[4]"/"a[5]"/"a[6]"/"a[7]"/"a[8]"/"a[9]"/"a[10]"/"a[11]"/"a[12]"/"a[13]"/"a[14]}' | sed -E "s/(WH.*)_1\.fq.*\t/\1\t/g" >> KIZ_sample_input_manifest_1.tsv
ls -ld $amplicon_seq_dir/raw_seq_data/GAGA_samples/KIZ_sample/Cleandata/*_2.fq.gz | awk '{split($0,a," "); print a[9]}' >> KIZ_sample_input_manifest_2.tsv
paste -d "\t" KIZ_sample_input_manifest_1.tsv KIZ_sample_input_manifest_2.tsv > KIZ_sample_input_manifest.tsv
rm KIZ_sample_input_manifest_*

ls -ld $amplicon_seq_dir/raw_seq_data/NC/Cleandata/CSE/*_1.fq.gz | awk '{split($0,a,"\/"); print a[14]"\t/"a[2]"/"a[3]"/"a[4]"/"a[5]"/"a[6]"/"a[7]"/"a[8]"/"a[9]"/"a[10]"/"a[11]"/"a[12]"/"a[13]"/"a[14]}' | sed -E "s/(WH.*)_1\.fq.*\t/\1\t/g" >> NC_CSE_input_manifest_1.tsv
ls -ld $amplicon_seq_dir/raw_seq_data/NC/Cleandata/CSE/*_2.fq.gz | awk '{split($0,a," "); print a[9]}' >> NC_CSE_input_manifest_2.tsv
paste -d "\t" NC_CSE_input_manifest_1.tsv NC_CSE_input_manifest_2.tsv > NC_CSE_input_manifest.tsv
rm NC_CSE_input_manifest_*

ls -ld $amplicon_seq_dir/raw_seq_data/NC/Cleandata/KIZ/*_1.fq.gz | awk '{split($0,a,"\/"); print a[14]"\t/"a[2]"/"a[3]"/"a[4]"/"a[5]"/"a[6]"/"a[7]"/"a[8]"/"a[9]"/"a[10]"/"a[11]"/"a[12]"/"a[13]"/"a[14]}' | sed -E "s/(WH.*)_1\.fq.*\t/\1\t/g" >> NC_KIZ_input_manifest_1.tsv
ls -ld $amplicon_seq_dir/raw_seq_data/NC/Cleandata/KIZ/*_2.fq.gz | awk '{split($0,a," "); print a[9]}' >> NC_KIZ_input_manifest_2.tsv
paste -d "\t" NC_KIZ_input_manifest_1.tsv NC_KIZ_input_manifest_2.tsv > NC_KIZ_input_manifest.tsv
rm NC_KIZ_input_manifest_*

ls -ld $amplicon_seq_dir/raw_seq_data/STD/Cleandata/*_1.fq.gz | awk '{split($0,a,"\/"); print a[13]"\t/"a[2]"/"a[3]"/"a[4]"/"a[5]"/"a[6]"/"a[7]"/"a[8]"/"a[9]"/"a[10]"/"a[11]"/"a[12]"/"a[13]}' | sed -E "s/(WH.*)_1\.fq.*\t/\1\t/g" >> STD_pairend_input_manifest_1.tsv
ls -ld $amplicon_seq_dir/raw_seq_data/STD/Cleandata/*_2.fq.gz | awk '{split($0,a," "); print a[9]}' >> STD_pairend_input_manifest_2.tsv
paste -d "\t" STD_pairend_input_manifest_1.tsv STD_pairend_input_manifest_2.tsv > STD_pairend_input_manifest.tsv
rm STD_pairend_input_manifest_*

# fix the sample-id in manifest files
awk 'NR==FNR{map[$2]=$1;next}{for (old in map) {sub(old,map[old])} print}' CSE_sample_metadata.tsv <(cat CSE_sample_input_manifest.tsv) > CSE_sample_input_manifest_new.tsv
rm CSE_sample_input_manifest.tsv
mv CSE_sample_input_manifest_new.tsv CSE_sample_input_manifest.tsv

awk 'NR==FNR{map[$2]=$1;next}{for (old in map) {sub(old,map[old])} print}' KIZ_sample_metadata.tsv <(cat KIZ_sample_input_manifest.tsv) > KIZ_sample_input_manifest_new.tsv
rm KIZ_sample_input_manifest.tsv
mv KIZ_sample_input_manifest_new.tsv KIZ_sample_input_manifest.tsv

# Importing data
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path CSE_sample_input_manifest.tsv --input-format PairedEndFastqManifestPhred33V2 --output-path CSE_sample_inputFile.qza
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path NC_CSE_input_manifest.tsv --input-format PairedEndFastqManifestPhred33V2 --output-path CSE_NC_inputFile.qza
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path KIZ_sample_input_manifest.tsv --input-format PairedEndFastqManifestPhred33V2 --output-path KIZ_sample_inputFile.qza
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path NC_KIZ_input_manifest.tsv --input-format PairedEndFastqManifestPhred33V2 --output-path KIZ_NC_inputFile.qza
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path STD_pairend_input_manifest.tsv --input-format PairedEndFastqManifestPhred33V2 --output-path STD_inputFile.qza

# Summarize and visualize the imported data
qiime demux summarize --i-data CSE_sample_inputFile.qza --o-visualization CSE_sample_inputFile.qzv
qiime demux summarize --i-data KIZ_sample_inputFile.qza --o-visualization KIZ_sample_inputFile.qzv
qiime demux summarize --i-data CSE_NC_inputFile.qza --o-visualization CSE_NC_inputFile.qzv
qiime demux summarize --i-data KIZ_NC_inputFile.qza --o-visualization KIZ_NC_inputFile.qzv
qiime demux summarize --i-data STD_inputFile.qza --o-visualization STD_inputFile.qzv

# Denoise
qiime dada2 denoise-paired --i-demultiplexed-seqs CSE_sample_inputFile.qza --p-trunc-len-f 250 --p-trunc-len-r 200 --o-table CSE_sample_dada2_table.qza --o-representative-sequences CSE_sample_dada2_rep_set.qza --o-denoising-stats CSE_sample_dada2_denoise_stats.qza --p-n-threads 40
qiime dada2 denoise-paired --i-demultiplexed-seqs KIZ_sample_inputFile.qza --p-trunc-len-f 253 --p-trunc-len-r 231 --o-table KIZ_sample_dada2_table.qza --o-representative-sequences KIZ_sample_dada2_rep_set.qza --o-denoising-stats KIZ_sample_dada2_denoise_stats.qza --p-n-threads 40
qiime dada2 denoise-paired --i-demultiplexed-seqs CSE_NC_inputFile.qza --p-trunc-len-f 254 --p-trunc-len-r 188 --o-table CSE_NC_dada2_table.qza --o-representative-sequences CSE_NC_dada2_rep_set.qza --o-denoising-stats CSE_NC_dada2_denoise_stats.qza --p-n-threads 40
qiime dada2 denoise-paired --i-demultiplexed-seqs KIZ_NC_inputFile.qza --p-trunc-len-f 238 --p-trunc-len-r 231 --o-table KIZ_NC_dada2_table.qza --o-representative-sequences KIZ_NC_dada2_rep_set.qza --o-denoising-stats KIZ_NC_dada2_denoise_stats.qza --p-n-threads 40
qiime dada2 denoise-paired --i-demultiplexed-seqs STD_inputFile.qza --p-trunc-len-f 253 --p-trunc-len-r 166 --o-table STD_dada2_table.qza --o-representative-sequences STD_dada2_rep_set.qza --o-denoising-stats STD_dada2_denoise_stats.qza --p-n-threads 40

## update ERDA folder ()
lftp io.erda.dk -p 21 -e "mirror -R $(pwd) /amplicon_seq/qiime2/28052021; bye"

# Ending time/date
ENDTIME=$(date)
ENDTIME_INSEC=$(date +%s)
echo "===== Qiime2 pipeline ends ======"
echo "Pipeline started at $STARTTIME"
echo "Pipeline ended at $ENDTIME"
echo "Pipeline took $((ENDTIME_INSEC - STARTTIME_INSEC)) seconds to finish"
