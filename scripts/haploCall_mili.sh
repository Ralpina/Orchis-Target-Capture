for sample in `cat samplelist.txt`
  do gatk HaplotypeCaller \
  -I ./results/bqsr/mili_recal2.bam \
  --sample-name ${sample} \
  -R ./results/hybpiper/refs/militaris.fa \
  --emit-ref-confidence GVCF \
  -O ./results/raw_genotypes/ref_mili/${sample}.raw.snps.indels.g.vcf
done
