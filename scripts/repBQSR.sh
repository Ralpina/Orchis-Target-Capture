gatk BaseRecalibrator \
-I ./results/bqsr/mili_recal.bam \
-R ./results/hybpiper/refs/militaris.fa \
--known-sites ./results/known/militaris/calls.filter.vcf \
-O ./results/bqsr/recal2.mili.table