#!/bin/bash

module load tools anaconda3/4.4.0 flye/2.8 perl lftp/4.9.2 pigz/2.3.4 seqtk/1.3 seqkit/0.13.2 anaconda2/4.4.0 quast/5.0.2 kraken/2.1.1 bracken/2.2 minimap2/2.20r1061 samtools/1.12

raw_reads_dr=/home/projects/ku_00039/people/dinghe/data/GAGA/Raw_genome_reads
initial_assembly_dir=/home/people/dinghe/ku_00039/people/dinghe/working_dr/metagenome_assembly/initial_assembly/metaflye/metagenome_candidate_reads
GAGA_Bac_screen_dir=/home/people/dinghe/ku_00039/people/dinghe/working_dr/metagenome_lgt/GAGA/${id}
metaquast_dir=/home/people/dinghe/ku_00039/people/dinghe/working_dr/metagenome_assembly/assembly_assessment/metaquast
taxonomy_profile_dir=/home/people/dinghe/ku_00039/people/dinghe/working_dr/metagenome_assembly/assembly_assessment/taxonomy_profile
krakenDB=/home/people/dinghe/ku_00039/people/dinghe/krakenDB/kraken_STD_21052021
kronatools_dir=/home/people/dinghe/github/Krona/KronaTools/bin

## update ERDA folder (Bac screen)
lftp io.erda.dk -p 21 -e "mirror -R $GAGA_Bac_screen_dir/results/ /GAGA/Microbiome/Results/Latest/22012021/${id}; bye"

## update ERDA folder (Metagenome_assembly/assembly_assessment/metaquast)
lftp io.erda.dk -p 21 -e "mkdir /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/metaquast/${id}; mirror -R --exclude-glob *.sam $metaquast_dir/${id} /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/metaquast/${id}; bye"

cd $taxonomy_profile_dir
mkdir ${id}
cd ${id}
kraken2 --threads 40 --db $krakenDB $initial_assembly_dir/${id}/assembly.fasta --output assembly.k2.out --report assembly.k2.report
bracken -d $krakenDB -i assembly.k2.report -l S -o assembly.k2.species.bracken
bracken -d $krakenDB -i assembly.k2.report -l C -o assembly.k2.class.bracken
## generate visualization with Krona
cat assembly.k2.out | cut -f 2,3 > assembly.k2.krona
$kronatools_dir/ktImportTaxonomy assembly.k2.krona
## update ERDA folder (Metagenome_assembly/assembly_assessment/taxonomy_profile)
lftp io.erda.dk -p 21 -e "mkdir /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/taxonomy_profile/${id}; mirror -R $taxonomy_profile_dir/${id} /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/taxonomy_profile/${id}; bye"
