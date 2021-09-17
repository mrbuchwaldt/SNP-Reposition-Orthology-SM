#Filter longest isoform for genes in each genome
#~/Projects/scripts_bin/filterFastaLongest.py ~/REFS/Bcarinata/Bcarinata.v2.genome/Bcarinata.v2.pep.fasta > Bcarinata.LongestIsoforms.genes.prot.fasta
#~/Projects/scripts_bin/filterFastaLongest.py ~/REFS/Athaliana/TAIR11/Araport11_genes.201606.pep.fasta > Athaliana.LongestIsoforms.genes.prot.fasta

configfile: "config/config.yaml"

#Run everything to produce the output of the MCScanX software
rule all:
    input: "results/Ortho/snp.collinearity"

rule clean:


#Filter the protein sequences to only contain the longest isoform for each gene.
rule FilterFastaLongestIsoform:
    input: lambda wildcards: config["OrthoGenomes"][wildcards.genome]
    output: "data/{genome}.LongestIsoforms.genes.prot.fasta"
    log: "results/logs/Orthology.FilterFastaLongestIsoform.{genome}.err.log"
    shell:
        "../scripts/filterFastaLongest.py {input} > {output} 2> {log}"

#cat Athaliana.LongestIsoforms.genes.prot.fasta Bcarinata.LongestIsoforms.genes.prot.fasta > snp.fa
rule CombineSeqs:
    input: expand("data/{genome}.LongestIsoforms.genes.prot.fasta", genome=config["OrthoGenomes"])
    output: "data/CombinedLongestIsoforms.fa"
    log: "results/logs/Orthology.CombineSeqs.err.log"
    shell:
        "cat {input} > {output} 2> {log}"

#makeblastdb -dbtype prot -in snp.fa -input_type fasta -out snp.protdb
rule MakeBlastDB:
    input: rules.CombineSeqs.output
    output: expand("data/Ortho/snp.protdb.{ext}", ext=['phr', 'pin', 'psq'])
    log: "results/logs/Orthology.MakeBlastDB.err.log"
    params:
        dbtype="prot",
        intype="fasta",
        outdb="data/Ortho/snp.protdb"
    conda:
        "../envs/align.yaml"
    shell:
        "makeblastdb -dbtype {params.dbtype} -in {input} -input_type {params.intype} -out {params.outdb} 2> {log}"

#blastp -query snp.fasta -db snp.protdb -num_alignments 5 -outfmt 6 -out snp.blast -num_threads 32
rule BlastAllIsoforms:
    input:
        q=rules.CombineSeqs.output,
        db=expand("data/Ortho/snp.protdb.{ext}", ext=['phr', 'pin', 'psq'])
    output: "results/Ortho/snp.blast"
    log: "results/logs/Orthology.BlastAllIsoforms.err.log"
    threads: 32
    params:
        ofmt="6",
        nalign="5",
        db=rules.MakeBlastDB.params.outdb
    conda:
        "../envs/align.yaml"
    shell:
        """
        blastp -query {input.q} -db {params.db} \
            -num_alignments {params.nalign} \
            -outfmt {params.ofmt} \
            -num_threads {threads} \
            -out {output} 2> {log}
        """

#cat ~/REFS/Bcarinata/Bcarinata.v2.genome/Bcarinata.v2.genes.gff3 ~/Athaliana/TAIR11/Araport11_GFF3_genes_transposons.Mar92021.gff > snp.gff
rule CombineGenomeGFFs:
    input: 
        g1=config["GenomeGFF1"],
        g2=config["GenomeGFF2"]
    output: "results/Ortho/snp.gff"
    log: "results/logs/Orthology.CombineGenomeGFFs.err.log"
    shell:
        """
        cat {input.g1} {input.g2} 2> {log} | \
        grep \"mRNA\" | \
        cut -f1,4,5,9 | \
        sed 's/ID=\([^;]*\).*/\\1/' | \
        awk -F'\t' '{{print $1,$4,$2,$3}}' OFS='\t' > {output}
        """

#Run MCScanX on the generated datafiles in results/Ortho
rule MCScanXOrthology:
    input:
        blast=rules.BlastAllIsoforms.output,
        gff=rules.CombineGenomeGFFs.output
    output:
        col="results/Ortho/snp.collinearity"
    log: "results/logs/Orthology.MCScanXOrthology.err.log"
    params:
        rundir="results/Ortho/snp"
    shell:
        "~/bin/MCScanX-master/MCScanX -a -b 2 {params.rundir} > {log} 2>&1"

rule ExtractGeneOrthologs:
    input: rules.MCScanXOrthology.output.col
    output: "results/Ortho/orthologs.txt"
    log: "results/logs/Orthology.ExtractGeneOrthologs.err.txt"
    shell:
        ""




