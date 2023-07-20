# Analysis of targeted capture data (Angiosperms353 bait sets) in _Orchis_ populations from a hybrid zone

This repository includes scripts for the analysis of targeted capture data (Angiosperms353 baits) from populations of _Orchis_ spp. from a hybrid zone (_O. militaris_, _O. purpurea_ and their hybrids, including some individuals of _O. anthropophora_ and _O. simia_). The associated manuscript is in preparation (Bersweden L., Gargiulo R. et al.; updates about the manuscript will be shared here). Part of the workflow was adapted from one of the tutorials at the [ConGen2021 workshop](https://github.com/renaschweizer/congen-gatk).

## Table of contents
-[Directory description](https://github.com/Ralpina/Orchis-Target-Capture#directory-description)

-[Programmes used](https://github.com/Ralpina/Orchis-Target-Capture#programmes-used)

-[Pipeline](https://github.com/Ralpina/Orchis-Target-Capture#pipeline)

## Directory description
-scripts: contains scripts for GATK and miscellaneous. Most of the analyses were run using SLURM on [KewHPC](https://rbg-kew-bioinformatics-utils.readthedocs.io/en/latest/), but info about job scheduling has been removed from the scripts.   
-etc: contains other files used (sample lists, gene lists, etc.): blacklist, samplelist  
-Other directories (not included in this repository) but referred to in the scripts:  
 --data: contains fastq files (post fastqc and trimmomatic);  
 --results: contains all results

## Programmes and tools used
[bcftools/1.13](https://github.com/samtools/bcftools/releases/); [bwa/0.7.17](https://github.com/lh3/bwa); [gatk/4.2.0.0](https://gatk.broadinstitute.org/hc/en-us); [HybPiper/1.3](https://github.com/mossmatters/HybPiper); [plink2](https://www.cog-genomics.org/plink/2.0/); [samtools/1.13](https://github.com/samtools/bcftools/releases/)

## Pipeline 
### Running HybPiper to retrieve coding sequences and introns (Angiosperms353 bait set)
For the HybPiper pipeline (including intronerate with the option supercontig), please refer to the HybPiper documentation [here](https://github.com/mossmatters/HybPiper/wiki) and [here](https://github.com/lindsawi/HybSeq-SNP-Extraction).  

### Genes/samples excluded
After HybPiper, I created a blacklist of genes (in etc/blacklist) for which either:  
-no sequence was retrieved;  
-one sequence in one individual was retrieved;   
-sequences were only occurring in non-parental species, i.e. _O. anthropophora_ and _O. simia_). Samples for which fewer than 50 genes were found were also removed; the final list of samples analysed is in: etc/samplelist. 

### 1) Creating reference sequences
Based on the file gene_lengths.txt output by hybpiper, the samples (parental species) for which we have retrieved the longest sequences are:

O81 - _Orchis militaris_

O171 - _Orchis purpurea_

GATK requires a reference genome, and therefore I repeat the following analyses using both parental species as references, to prevent the choice of the reference sample from affecting inference and interpretation.

In the directories O171 and O81 (created by hybpiper), I create the directory gene_excl, in which I move all the genes of the blacklist (just in case! then I'll remove them):

```sh
for i in `cat blacklist.txt`; do cp -r ./results/hybpiper/O171/$i ./results/hybpiper/O171/gene_excl; done
for i in `cat blacklist.txt`; do cp -r ./results/hybpiper/O171/$i ./results/hybpiper/O81/gene_excl; done
# then I'll remove them
for i in `cat blacklist.txt`; do rm -r ./results/hybpiper/O171/$i; done
for i in `cat blacklist.txt`; do rm -r ./results/hybpiper/O81/$i; done
```

Creating the references (script: create_ref) in the directory results/hybpiper/refs

```sh
cat results/hybpiper/O81/4*/O81/sequences/intron/4*_supercontig.fasta cat results/hybpiper/O81/5*/O81/sequences/intron/5*_supercontig.fasta cat results/hybpiper/O81/6*/O81/sequences/intron/6*_supercontig.fasta cat results/hybpiper/O81/7*/O81/sequences/intron/7*_supercontig.fasta > results/hybpiper/refs/militaris
cat results/hybpiper/O171/4*/O171/sequences/intron/4*_supercontig.fasta cat results/hybpiper/O171/5*/O171/sequences/intron/5*_supercontig.fasta cat results/hybpiper/O171/6*/O171/sequences/intron/6*_supercontig.fasta cat results/hybpiper/O171/7*/O171/sequences/intron/7*_supercontig.fasta > results/hybpiper/refs/purpurea
```


### 2) Preparing the reference indices for the reference sequences 
Tools required: bwa,samtools and gatk
```sh
cd /results/hybpiper/refs
bwa index militaris
bwa index purpurea

samtools faidx militaris
samtools faidx purpurea     
```
We need to create a copy with the extension .fa (or gatk wouldn't recognise it!):
```sh
gatk CreateSequenceDictionary -R militaris.fa
gatk CreateSequenceDictionary -R purpurea.fa

samtools faidx militaris.fa
samtools faidx purpurea.fa
```

### 3) Mapping samples to the references and preparing the bam files correctly 
Tool required: samtools.  
See script ```mapping.sh```  
We then need to make sure that the mate pair information and insert sizes are correct in our BAM using samtools fixmate. 
GATK requires the BAM file to be sorted by coordinates: see script ```sortfix.sh``` 

### 4) Removing PCR duplicates 
Tool required: samtools.  
See script ```rmdupli.sh```

### 5)  Adding read group information 
To perform the next steps in GATK, we will need to define the following:  
    RUN_ID  for the sequencing run 
    RGID=String Read Group ID
    RGLB=String Read Group Library
    RGPL=String Read Group platform (e.g. illumina, solid)
    RGPU=String Read Group platform unit (eg. run barcode of run Id + lane number)
    RGSM=String Read Group sample name

See script: ```addRG.sh```

### 6) Getting the "known-sites"  (bcftools, samtools and gatk required)
The next step (gatk BQSR) needs a list of known sites to work correctly.
We follow the intructions from https://gatk.broadinstitute.org/hc/en-us/articles/360035890531-Base-Quality-Score-Recalibration-BQSR-
and do an initial round of variant calling on your original, unrecalibrated data, followed by filtering, using bcftools.
As usual, we repeat the process using both O. militaris and O. purpurea as references.

```sh
mkdir ./results/known
mkdir ./results/known/militaris
mkdir ./results/known/purpurea
```

scripts: 
bcfcall, bcfilter.sh  (very fast, done for both ref. militaris and ref. purpurea)
 
the filtering process first extracts variants with not more than 2 alleles and then removes variant with either low quality or low depth
The files with the known variants are:

./results/known/militaris/calls.filter.vcf

./results/known/purpurea/calls.filter.vcf

then, generate the index from these:

```sh
gatk IndexFeatureFile -I ./results/known/militaris/calls.filter.vcf

gatk IndexFeatureFile -I ./results/known/purpurea/calls.filter.vcf
```

### 7)  Performing Base Quality Score Recalibration (BQSR) (gatk required)

```sh	
mkdir ./results/bqsr
```

scripts: BQSR, BQSR2

This has generated a recalibration table based on various covariates, see https://gatk.broadinstitute.org/hc/en-us/articles/360035890531
Next, we apply this recalibration info to our BAM files to make a new BAM with recalibrated quality scores.
 
scripts: applyBQSR, applyBQSR2

The whole recalibration procedure is applied a second time:

scripts: 
repBQSR, repBQSR2 (step baserecalibrator); reapplyBQSR, reapplyBQSR2 (step apply recalibration)
  
The covariates before and after BQSR can be compared using the tool AnalyzeCovariates in gatk, which generates plots in pdf format:

scripts: covar_mili.sh, covar_purp.sh


### 8) Running Haplotype Caller to generate GVCF files (gatk required)
scripts: haploCall_mili, haploCall_purp

### 9) Consolidating genotypes (gatk required)
```sh
mkdir ./results/called_genotypes
mkdir ./results/called_genotypes/temp
mkdir ./results/called_genotypes/temp_purp
```
this tools requires "intervals", that are the regions to include in the analysis (for example, chromosomes and positions, or contigs).
see: https://gatk.broadinstitute.org/hc/en-us/articles/360035531852-Intervals-and-interval-lists
In our case, contigs are named as as "name of the sample-gene name", so in the end I opted for using the vcf file containing the "known-variants", as list of intervals.

scripts: conso_mili; conso.purp

There are some memory constraints in the analyses above, so it is important to create temporary directories, if there are many samples.
	  
### 10) Genotyping all GVCF files (gatk required)
scripts: genotype_mili, genotype_purp (these need a lot of memory)

### 11) Hard-filtering: 
Selecting only SNPs: scripts: select_SNPs, select_SNPs2

then:

```sh
mkdir ./results/filtered_genotypes/quality_metrics/

for flag in missing-indv missing-site depth site-depth
	do vcftools --vcf ./results/filtered_genotypes/ref_militaris_SNPs.vcf \
	--${flag} \
	--out ./results/filtered_genotypes/quality_metrics/ref_militaris_quality
	done

for flag in missing-indv missing-site depth site-depth
	do vcftools --vcf ./results/filtered_genotypes/ref_purpurea_SNPs.vcf \
	--${flag} \
	--out ./results/filtered_genotypes/quality_metrics/ref_purpurea_quality
	done
	
mkdir ./results/filtered_genotypes/final_filters

vcftools --vcf ./results/filtered_genotypes/ref_militaris_SNPs.vcf \
	--minDP 10 \
	--minGQ 20 \
	--max-missing 0.75 \
	--min-alleles 2 \
	--max-alleles 2 \
	--recode \
	--out ./results/filtered_genotypes/final_filters/Hybrids_ref_militaris

vcftools --vcf ./results/filtered_genotypes/ref_purpurea_SNPs.vcf \
	--minDP 10 \
	--minGQ 20 \
	--max-missing 0.75 \
	--min-alleles 2 \
	--max-alleles 2 \
	--recode \
	--out ./results/filtered_genotypes/final_filters/Hybrids_ref_purpurea
```

LD-pruned data sets:

```sh
plink2 --indep-pairwise 50 5 0.5 --vcf Hybrids_ref_militaris.recode.vcf --allow-extra-chr --set-missing-var-ids @:#[rob]\$r,\$a --export vcf --out militaris.plink
plink2 --indep-pairwise 50 5 0.5 --vcf Hybrids_ref_purpurea.recode.vcf --allow-extra-chr --set-missing-var-ids @:#[rob]\$r,\$a --export vcf --out purpurea.plink
```

## References 
Chang CC, Chow CC, Tellier LCAM, Vattikuti S, Purcell SM, Lee JJ (2015) Second-generation PLINK: rising to the challenge of larger and richer datasets. GigaScience, 4. www.cog-genomics.org/plink/2.0/

Danecek P, Bonfield JK, Liddle J, Marshall J, Ohan V, Pollard MO, Whitwham A, Keane T, McCarthy SA, Davies RM, Li H (2021) Twelve years of SAMtools and BCFtools, GigaScience, 10(2) giab008 [33590861]

DePristo M, Banks E, Poplin R, Garimella K, Maguire J, Hartl C, Philippakis A, del Angel G, Rivas MA, Hanna M, McKenna A, Fennell T, Kernytsky A, Sivachenko A, Cibulskis K, Gabriel S, Altshuler D, Daly M (2011) A framework for variation discovery and genotyping using next-generation DNA sequencing data. Nature Genetics, 43, 491-498.

Johnson MG, Gardner, EM, Liu Y, Medina R, Goffinet B, Shaw AJ, ... & Wickett NJ (2016) HybPiper: Extracting coding sequence and introns for phylogenetics from high‐throughput sequencing reads using target enrichment. Applications in plant sciences, 4(7), 1600016.  https://doi.org/10.3732/apps.1600016

Johnson M, Goldstein S, Acuña R, & The Gitter Badger (2018) mossmatters/HybPiper: Bug Fix Reverse Complement Sequences (v1.3.1). Zenodo. https://doi.org/10.5281/zenodo.1341845

Li H, Durbin R (2009) Fast and accurate short read alignment with Burrows–Wheeler transform. Bioinformatics, 25(14), 1754–1760.

McKenna A, Hanna M, Banks E, Sivachenko A, Cibulskis K, Kernytsky A, Garimella K, Altshuler D, Gabriel S, Daly M, DePristo MA (2010) The Genome Analysis Toolkit: a MapReduce framework for analyzing next-generation DNA sequencing data. Genome Research, 20, 1297-303. 

Van der Auwera GA, O'Connor BD (2020) Genomics in the Cloud: Using Docker, GATK, and WDL in Terra (1st Edition). O'Reilly Media.




[![CC BY 4.0][cc-by-shield]][cc-by]

This work is licensed under a
[Creative Commons Attribution 4.0 International License][cc-by].

[![CC BY 4.0][cc-by-image]][cc-by]

[cc-by]: http://creativecommons.org/licenses/by/4.0/
[cc-by-image]: https://i.creativecommons.org/l/by/4.0/88x31.png
[cc-by-shield]: https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg
