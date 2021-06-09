#!/usr/local/bin/env nextflow

nextflow.enable.dsl=2

process getGAGAID {

  label 'single_core'

  input:
  file 'GAGA_ID_file'

  output:
  stdout

  script:
  """
  awk '{print}' < GAGA_ID_file
  """

}

/*
 * update ERDA folder
 */

process updateERDA {

  // when using computerome profile
  label 'single_core'
  module 'lftp/4.9.2'

  input:
  val id

  script:
  """
  lftp io.erda.dk -p 21 -e "mirror -R $params.GAGA_Bac_screen_dir/$id/results/ /GAGA/Microbiome/Results/Latest/22012021/$id; bye"
  """
}
/*
 * kraken2 taxonomy profiling
 */

GAGA_ID_file_ch = Channel.fromPath(params.GAGA_IDs)

workflow {

  GAGAid_ch = getGAGAID(GAGA_ID_file_ch)
  updateERDA(GAGAid_ch)

}
