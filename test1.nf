#!/usr/local/bin/env nextflow

nextflow.enable.dsl=2

/*
 * update ERDA folder
 */

process updateERDA {

    shell:
    '''
    lftp io.erda.dk -p 21 -e "mirror -R $GAGA_Bac_screen_dir/results/ /GAGA/Microbiome/Results/Latest/22012021/!{params.GAGA_IDs}; bye"
    '''
}

/*
 * kraken2 taxonomy profiling
 */

process convertToUpper {

    input:
    file y

    output:
    stdout

    """
    cat $y | tr '[a-z]' '[A-Z]'
    """
}

params.greeting  = 'Hello world!'
greeting_ch = Channel.from(params.greeting)

workflow {

    letters_ch = splitLetters(greeting_ch)
    uppercase_ch = convertToUpper( letters_ch.flatten() )
    uppercase_ch.view{ it.trim() }

}
