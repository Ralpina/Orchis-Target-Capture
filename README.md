# Project description (Orchis-Target-Capture)

This repository contains Shell scripts and R scripts for the the analysis of target capture data (Angiosperms353 baits) for populations of Orchis from a hybrid zone (O. militaris, O. purpurea and their hybrids, including some individuals of O. anthropophora and O. simia). The related manuscript is in preparation (Gargiulo R. et al.).

# Table of contents
-Directory description

-Programmes used

-Pipeline: Hybpiper; genotyping in GATK

# Directory description
scripts: contains scripts for GATK and miscellaneous

etc: contains other files used (sample lists, gene lists, etc.): blacklist, samplelist

other directories (not included in this repository): data: contains fastq files (post fastqc and trimmomatic); results: contains all results

# Programmes used
bwa/0.7.17; samtools/1.13; bcftools/1.13; gatk/4.2.0.0; plink2


# Pipeline: 
Please note that most of the analyses were run using SLURM on KewHPC (https://rbg-kew-bioinformatics-utils.readthedocs.io/en/latest/), but info about job scheduling has been removed from the scripts.
For the hybpiper pipeline (including intronerate with the option supercontig): please refer to: https://github.com/mossmatters/HybPiper/wiki (see also: https://github.com/lindsawi/HybSeq-SNP-Extraction)
#### Genes/samples excluded
After the hybpiper pipeline: I created a blacklist of genes (blacklist) for which no sequence was retrieved (or only one sequence in one individuals, or only occurring in non-parental species, i.e. O. anthropophora and O. simia). Samples for which less than 50 genes were found were also removed; the final list of samples analysed is in: samplelist 

## 1) Creating reference sequences
Based on the file gene_lengths.txt output by hybpiper, the samples (parental species) for which we have retrieved the longest sequences are:

O81 - Orchis militaris

O171 - Orchis purpurea

GATK requires a reference genome, and therefore I repeat the following analyses using both parental species as references, to prevent the choice of the reference sample from affecting inference and interpretation (Every script repeated twice depending on the reference species).

In the directories O171 and O81 (created by hybpiper), I create the directory gene_excl, in which I move all the genes of the blacklist
script for copying (just in case, then I remove them) genes to gene_excl: loop_blacklist

```sh
for i in `cat blacklist.txt`; do cp -r ./results/hybpiper/O171/$i ./results/hybpiper/O171/gene_excl; done
for i in `cat blacklist.txt`; do cp -r ./results/hybpiper/O171/$i ./results/hybpiper/O81/gene_excl; done
```
then I remove them

```sh
for i in `cat blacklist.txt`; do rm -r ./results/hybpiper/O171/$i; done
for i in `cat blacklist.txt`; do rm -r ./results/hybpiper/O81/$i; done
```

Creating the references (script: create_ref) in the directory results/hybpiper/refs

```sh
cat results/hybpiper/O81/4*/O81/sequences/intron/4*_supercontig.fasta cat results/hybpiper/O81/5*/O81/sequences/intron/5*_supercontig.fasta cat results/hybpiper/O81/6*/O81/sequences/intron/6*_supercontig.fasta cat results/hybpiper/O81/7*/O81/sequences/intron/7*_supercontig.fasta > results/hybpiper/refs/militaris
cat results/hybpiper/O171/4*/O171/sequences/intron/4*_supercontig.fasta cat results/hybpiper/O171/5*/O171/sequences/intron/5*_supercontig.fasta cat results/hybpiper/O171/6*/O171/sequences/intron/6*_supercontig.fasta cat results/hybpiper/O171/7*/O171/sequences/intron/7*_supercontig.fasta > results/hybpiper/refs/purpurea
```


## 2) Preparing the reference indices for the reference sequences (bwa,samtools and gatk required)

```sh
cd /results/hybpiper/refs
bwa index militaris
bwa index purpurea

samtools faidx militaris
samtools faidx purpurea     
```

for gatk, we need to create a copy with the extension .fa, otherwise it doesn't recognise it! So I had to come back and repeat these

```sh
gatk CreateSequenceDictionary -R militaris.fa
gatk CreateSequenceDictionary -R purpurea.fa

samtools faidx militaris.fa
samtools faidx purpurea.fa
```

## 3) Mapping samples to the references and preparing the bam files correctly (samtools required)
scripts: 
mapping, mapping2

Then we need to make sure the mate pair information and insert sizes are correct in our BAM using samtools fixmate. 

GATK requires the BAM file to be sorted by coordinates.

scripts: sortfix.sh, sortfix2.sh 

## 4) Removing PCR duplicates (samtools required)

scripts: rmdupli, rmdupli2 (last more than 3 hours)

## 5)  Adding read group information (gatk required)

To perform the next steps in GATK, We will need to define the following:

    RUN_ID  for the sequencing run 
    RGID=String Read Group ID
    RGLB=String Read Group Library
    RGPL=String Read Group platform (e.g. illumina, solid)
    RGPU=String Read Group platform unit (eg. run barcode of run Id + lane number)
    RGSM=String Read Group sample name

script: addRG.sh, addRG2.sh


## 6) Getting the "known-sites"  (bcftools, samtools and gatk required)

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

## 7)  Performing Base Quality Score Recalibration (BQSR) (gatk required)

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


## 8) Running Haplotype Caller to generate GVCF files (gatk required)
scripts: haploCall_mili, haploCall_purp

## 9) Consolidating genotypes (gatk required)
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
	  
## 10) Genotyping all GVCF files (gatk required)
scripts: genotype_mili, genotype_purp (these need a lot of memory)

## 11) Hard-filtering: 
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

