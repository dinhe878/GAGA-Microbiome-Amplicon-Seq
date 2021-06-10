#!/usr/local/bin/env nextflow

nextflow.enable.dsl=2

process test {

  input:
  val id

  output:
  stdout

  script:
  """
  printf $id
  """
  
}
/*
 * update ERDA folder
 */

process updateERDA {

  // when using computerome profile
  label 'multi_core'
  module 'lftp/4.9.2'

  input:
  val id

  output:
  stdout

  script:
  """
  echo "updating $id to ERDA"
  lftp io.erda.dk -p 21 -e "mirror -R $params.GAGA_Bac_screen_dir/$id/results/ /GAGA/Microbiome/Results/Latest/22012021/$id; bye"
  """
}
/*
 * kraken2 taxonomy profiling
 */

GAGAid_ch = Channel.fromPath(params.GAGA_IDs)
                         .splitText()

workflow {

    GAGAid_ch_again = test(GAGAid_ch)
    GAGAid_ch_again.view{ it }
//    results_ch = updateERDA(GAGAid_ch)
//  results_ch.view{ it }

}
