gatk AnalyzeCovariates \
  -before ./results/bqsr/recal.mili.table \
  -after ./results/bqsr/recal2.mili.table \
  -plots ./results/bqsr/AnalyzeCovariates_round1_mili.pdf

gatk AnalyzeCovariates \
  -before ./results/bqsr/recal.purp.table \
  -after ./results/bqsr/recal2.purp.table \
  -plots ./results/bqsr/AnalyzeCovariates_round1_purp.pdf
