SNP-Reposition-Orthology-SM

Overview
---------

A snakemake pipeline to position SNPs on a related genome and find orthologous genes with annotations in nearby flanking regions.

Usage
---------

Input files and parameters are stored in config/config.yaml which can be edited to use different datasets.To run the pipeline run snakemake from the root directory via:
    $ snakemake --cores <THREADS>
Substituting <THREADS> for an integer number of threads to be used to run the pipeline.

To troubleshoot errors that may occur, check the STDERR output of each command in results/logs/.
