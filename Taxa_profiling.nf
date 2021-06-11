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
  echo lftp io.erda.dk -p 21 -e "mirror -R $params.GAGA_Bac_screen_dir/$id/results/ /GAGA/Microbiome/Results/Latest/22012021/$id; bye"
  echo lftp io.erda.dk -p 21 -e "mkdir /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/metaquast/$id; mirror -R --exclude-glob *.sam $params.metaquast_dir/$id /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/metaquast/$id; bye"
  """
}
/*
 * kraken2 taxonomy profiling
 *
 * kraken2 & preparing a file for procBracken
 */

process procKraken2 {

  // when using computerome profile
  label 'multi_core'
  module 'kraken/2.1.1'

  input:
  val id

  output:
  tuple file("${id}.assembly.k2.report"), file("${id}.assembly.k2.krona")

  script:
  """
  echo kraken2 --threads 40 --db $params.krakenDB $params.initial_assembly_dir/$id/assembly.fasta --output $params.taxonomy_profile_dir/$id/assembly.k2.out --report assembly.k2.report
  echo cat $params.taxonomy_profile_dir/$id/assembly.k2.out | cut -f 2,3 > assembly.k2.krona
  echo cp assembly.k2.report $params.taxonomy_profile_dir/$id/
  echo cp assembly.k2.krona $params.taxonomy_profile_dir/$id/
  """

}

process procBracken {

  // when using computerome profile
  label 'single_core'
  module 'lftp/4.9.2:bracken/2.2'

  input:
  tuple file(k2Report), file(k2Krona)

  output:
  tuple file('assembly.k2.species.bracken'), file('assembly.k2.class.bracken'), file('taxonomy.krona.html')

  script:
  """
  echo bracken -d $params.krakenDB -i $k2Report -l S -o assembly.k2.species.bracken
  echo bracken -d $params.krakenDB -i $k2Report -l C -o assembly.k2.class.bracken
  echo $params.kronatools_dir/ktImportTaxonomy -o taxonomy.krona.html $k2Krona
  echo cp assembly.k2.species.bracken $params.taxonomy_profile_dir/$id/
  echo cp assembly.k2.class.bracken $params.taxonomy_profile_dir/$id/
  echo cp taxonomy.krona.html $params.taxonomy_profile_dir/$id/
  echo lftp io.erda.dk -p 21 -e "mkdir /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/taxonomy_profile/$id; mirror -R $params.taxonomy_profile_dir/$id /GAGA/Microbiome/Metagenome_assembly/assembly_assessment/taxonomy_profile/$id; bye"
  """

}

GAGAid_ch = Channel.fromPath(params.GAGA_IDs)
                   .splitText() { it.trim() }

workflow {

    updateERDA_results_ch = updateERDA(GAGAid_ch)
    updateERDA_results_ch.view{ it }
    procKraken2_results_ch = procKraken2(GAGAid_ch)
    procKraken2_results_ch.view{ it }
    procBracken_results_ch = procBracken(procKraken2_results_ch)
    procBracken_results_ch.view{ it }

}
