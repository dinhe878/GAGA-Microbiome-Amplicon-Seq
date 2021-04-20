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
#PBS -l walltime=12:00:00


#########################################################
# loading necessary modules                             #
#########################################################

module load tools qiime2/2021.2 lftp/4.9.2

#########################################################
# setup variables and folder structure                  #
#########################################################
working_dr=/home/people/dinghe/ku_00039/people/dinghe/working_dr/amplicon_seq/qiime2

# Starting time/date
STARTTIME=$(date)
STARTTIME_INSEC=$(date +%s)

# Go to working_dr
cd $working_dr

# Importing data
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path ./GAGA_ampSeq_inputFile_manifest.tsv --input-format PairedEndFastqManifestPhred33V2 --output-path ./GAGA_ampSeq_inputFile.qza
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path ./negative_control_manifest.tsv  --input-format PairedEndFastqManifestPhred33V2 --output-path ./negative_control_seq.qza
qiime tools import --type "SampleData[PairedEndSequencesWithQuality]" --input-path ./microbial_std_manifest.tsv  --input-format PairedEndFastqManifestPhred33V2 --output-path ./microbial_std_seq.qza

# Summarize and generate visualization of the imported data
qiime demux summarize --i-data ./GAGA_ampSeq_inputFile.qza --o-visualization ./GAGA_ampSeq_inputFile.qzv
qiime demux summarize --i-data ./negative_control_seq.qza --o-visualization ./negative_control_seq.qzv
qiime demux summarize --i-data ./microbial_std_seq.qza --o-visualization ./microbial_std_seq.qzv

# Sequence quality control and generate feature table
## Sample data
qiime dada2 denoise-paired --i-demultiplexed-seqs ./GAGA_ampSeq_inputFile.qza --p-trunc-len-f 232 --p-trunc-len-r 163 --o-table ./dada2_table.qza --o-representative-sequences ./dada2_rep_set.qza --o-denoising-stats ./dada2_stats.qza --p-n-threads 40
qiime metadata tabulate --m-input-file ./dada2_stats.qza --o-visualization ./dada2_stats.qzv
qiime feature-table summarize --i-table ./dada2_table.qza --m-sample-metadata-file ./GAGA_ampSeq_metadata.tsv --o-visualization ./dada2_table.qzv

## NC
qiime dada2 denoise-paired --i-demultiplexed-seqs ./negative_control_seq.qza --p-trunc-len-f 253 --p-trunc-len-r 162 --o-table ./dada2_nc_table.qza --o-representative-sequences dada2_nc_rep_set.qza --o-denoising-stats ./dada2_nc_stats.qza --p-n-threads 40 --verbose

## Mock
qiime dada2 denoise-paired --i-demultiplexed-seqs ./microbial_std_seq.qza --p-trunc-len-f 253 --p-trunc-len-r 150 --o-table ./dada2_std_table.qza --o-representative-sequences dada2_std_rep_set.qza --o-denoising-stats ./dada2_std_stats.qza --p-n-threads 40 --verbose
qiime metadata tabulate --m-input-file ./dada2_std_stats.qza --o-visualization ./dada2_std_stats.qzv
qiime feature-table summarize --i-table ./dada2_std_table.qza --o-visualization ./dada2_std_table.qzv

# Filtering out negatve control
qiime quality-control exclude-seqs --i-query-sequences ./dada2_rep_set.qza --i-reference-sequences dada2_nc_rep_set.qza --p-method blast --p-perc-identity 0.97 --p-perc-query-aligned 0.97 --p-threads 40 --o-sequence-hits ./GAGA_ampSeq_contaminants.qza --o-sequence-misses GAGA_ampSeq_decontaminants_rep_set.qza --verbose
qiime feature-table filter-features --i-table ./dada2_table.qza --m-metadata-file GAGA_ampSeq_contaminants.qza --p-exclude-ids --o-filtered-table ./GAGA_ampSeq_decontaminants_table.qza --verbose
qiime feature-table summarize --i-table ./GAGA_ampSeq_decontaminants_table.qza --m-sample-metadata-file ./GAGA_ampSeq_metadata.tsv --o-visualization ./GAGA_ampSeq_decontaminants_table.qzv

# Generating a phylogenetic tree for diversity analysis
qiime fragment-insertion sepp --i-representative-sequences ./GAGA_ampSeq_decontaminants_rep_set.qza --i-reference-database sepp-refs-silva-128.qza --p-threads 40 --o-tree GAGA_ampSeq_decontaminants_tree.qza --o-placements GAGA_ampSeq_decontaminants_placements.qza --verbose

# Alpha Rarefaction and Selecting a Rarefaction Depth
qiime diversity alpha-rarefaction --i-table GAGA_ampSeq_decontaminants_table.qza --i-phylogeny GAGA_ampSeq_decontaminants_tree.qza --m-metadata-file GAGA_ampSeq_metadata.tsv --p-max-depth 7000 --p-min-depth 10 --o-visualization GAGA_ampSeq_decontaminants_a_raref.qzv --verbose

# Core diversity analysis
qiime diversity core-metrics-phylogenetic --i-table GAGA_ampSeq_decontaminants_table.qza --i-phylogeny ./GAGA_ampSeq_decontaminants_tree.qza --m-metadata-file GAGA_ampSeq_metadata.tsv --p-sampling-depth 7000 --p-n-jobs-or-threads 'auto' --output-dir ./core-metrics-results

# Taxonomic classification
qiime feature-classifier classify-sklearn --i-reads GAGA_ampSeq_decontaminants_rep_set.qza --i-classifier silva-138-99-515-806-nb-classifier.qza --o-classification GAGA_ampSeq_decontaminants_rep_set_tax.qza --p-n-jobs -1

# Filtering out mitochondria
qiime taxa filter-table --i-table ./GAGA_ampSeq_decontaminants_table.qza --i-taxonomy GAGA_ampSeq_decontaminants_rep_set_tax.qza --p-exclude mitochondria --o-filtered-table ./GAGA_ampSeq_final_feature_table.qza

# Plot taxa barplot (adjust most frequent taxa to be ploted by "qiime feature-table filter-features")
qiime feature-table filter-features --i-table ./GAGA_ampSeq_final_feature_table.qza --p-min-frequency 100 --o-filtered-table ./GAGA_ampSeq_final_feature_table_min100freq.qza
qiime taxa barplot --i-table ./GAGA_ampSeq_final_feature_table_min100freq.qza --i-taxonomy ./GAGA_ampSeq_decontaminants_rep_set_tax.qza --m-metadata-file ./GAGA_ampSeq_metadata.tsv --o-visualization ./GAGA_ampSeq_min100freq_barplot.qzv

# Sync the data to ERDA
lftp io.erda.dk -p 21 -e "mirror -R $(pwd) /amplicon_seq/; bye"

# Ending time/date
ENDTIME=$(date)
ENDTIME_INSEC=$(date +%s)
echo "==============================================="
echo "Pipeline started at $STARTTIME"
echo "Pipeline ended at $ENDTIME"
echo "Pipeline took $((ENDTIME_INSEC - STARTTIME_INSEC)) seconds to finish"
