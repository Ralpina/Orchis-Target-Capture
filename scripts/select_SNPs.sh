gatk SelectVariants \
	-R ./results/hybpiper/refs/militaris.fa \
	-O ./results/filtered_genotypes/ref_militaris_SNPs.vcf \
	-V ./results/raw_genotypes/militaris_unfiltered.vcf.gz \
	--select-type-to-include SNP

gatk SelectVariants \
	-R ./results/hybpiper/refs/purpurea.fa \
	-O ./results/filtered_genotypes/ref_purpurea_SNPs.vcf \
	-V ./results/raw_genotypes/purpurea_unfiltered.vcf.gz \
	--select-type-to-include SNP
