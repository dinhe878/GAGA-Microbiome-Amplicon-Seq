#!/usr/local/bin/env nextflow

nextflow.enable.dsl=2

process getGAGAID {

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

/*
 * kraken2 taxonomy profiling
 */

GAGA_ID_file_ch = Channel.fromPath(params.GAGA_IDs)

workflow {

  GAGAid_ch = getGAGAID(GAGA_ID_file_ch)
  GAGAid_ch.view{ it.trim() }

}
