#!/usr/local/bin/env nextflow

nextflow.enable.dsl=2

/*
 * update ERDA folder
 */

process updateERDA {

  // when using computerome profile
  label 'single_core'
  module 'lftp/4.9.2'

  input:
  val id

  output:
  stdout

  script:
  """
  echo "updating $id to ERDA"
  lftp io.erda.dk -p 21 -e "mirror -R $params.GAGA_Bac_screen_dir/$id/results/ /GAGA/Microbiome/Results/Latest/22012021/$id; bye"
  lftp io.erda.dk -p 21 -e "mkdir /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/metaquast/$id; mirror -R --exclude-glob *.sam $params.metaquast_dir/$id /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/metaquast/$id; bye"
  """
}
/*
 * kraken2 taxonomy profiling
 */

 process procKraken2 {

   // when using computerome profile
   label 'multi_core'
   module 'kraken/2.1.1'

   input:
   val id

   output:
   stdout

   script:
   """
   kraken2 --threads 40 --db $params.krakenDB $params.initial_assembly_dir/$id/assembly.fasta --output $params.taxonomy_profile_dir/$id/assembly.k2.out --report $params.taxonomy_profile_dir/$id/assembly.k2.report
   """

 }

 process procBracken {

   // when using computerome profile
   label 'single_core'
   module 'lftp/4.9.2:bracken/2.2'

   input:
   val id

   output:
   stdout

   script:
   """
   bracken -d $params.krakenDB -i $params.taxonomy_profile_dir/$id/assembly.k2.report -l S -o $params.taxonomy_profile_dir/$id/assembly.k2.species.bracken
   bracken -d $params.krakenDB -i $params.taxonomy_profile_dir/$id/assembly.k2.report -l C -o $params.taxonomy_profile_dir/$id/assembly.k2.class.bracken
   cat $params.taxonomy_profile_dir/$id/assembly.k2.out | cut -f 2,3 > $params.taxonomy_profile_dir/$id/assembly.k2.krona
   $kronatools_dir/ktImportTaxonomy -o $params.taxonomy_profile_dir/$id/taxonomy.krona.html $params.taxonomy_profile_dir/$id/assembly.k2.krona
   lftp io.erda.dk -p 21 -e "mkdir /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/taxonomy_profile/$id; mirror -R $taxonomy_profile_dir/$id /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/taxonomy_profile/$id; bye"
   """

 }

GAGAid_ch = Channel.fromPath(params.GAGA_IDs)
                   .splitText() { it.trim() }

workflow {

    updateERDA_results_ch = updateERDA(GAGAid_ch)
    updateERDA_results_ch.view{ it }
    procKraken2_results_ch = procKraken2(GAGAid_ch)
    procKraken2_results_ch.view{ it }
    procBracken_results_ch = procBracken(GAGAid_ch)
    procBracken_results_ch.view{ it }

}
