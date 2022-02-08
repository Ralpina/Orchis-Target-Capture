bcftools view --max-alleles 2 ./results/known/purpurea/calls.bcf | bcftools filter -s LowQual -e '%QUAL<30 || DP<10' > ./results/known/purpurea/calls.filter.vcf


