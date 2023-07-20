gatk GenotypeGVCFs \
   -R ./results/hybpiper/refs/purpurea.fa \
   -V  gendb://results/called_genotypes/purp_database \
   --include-non-variant-sites \
   -O ./results/raw_genotypes/purpurea_unfiltered.vcf.gz