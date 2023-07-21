gatk BaseRecalibrator \
-I ./results/bqsr/mili_recal.bam \
-R ./results/hybpiper/refs/militaris.fa \
--known-sites ./results/known/militaris/calls.filter.vcf \
-O ./results/bqsr/recal2.mili.table

gatk BaseRecalibrator \
-I ./results/bqsr/purp_recal.bam \
-R ./results/hybpiper/refs/purpurea.fa \
--known-sites ./results/known/purpurea/calls.filter.vcf \
-O ./results/bqsr/recal2.purp.table 
