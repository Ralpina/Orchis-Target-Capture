for sample in `cat samplelist.txt`
  do RUN_ID=Leif
    LANE_NUM=1
	RGID_specify=${RUN_ID}_${LANE_NUM}
	RGLB_specify=${sample}
	RGPL_specify=ILLUMINA
	RGPU_specify=${RUN_ID}_${LANE_NUM}
	RGSM_specify=${sample}
    gatk AddOrReplaceReadGroups --INPUT ./results/mapping/militaris/${sample}.unique.bam \
	--OUTPUT ./results/mapping/militaris/${sample}.uniqueRG.bam \
	--SORT_ORDER coordinate \
	--RGID ${RGID_specify} \
	--RGLB ${RGLB_specify} \
	--RGPL ${RGPL_specify} \
	--RGPU ${RGPU_specify} \
	--RGSM ${RGSM_specify} \
	--CREATE_INDEX True \
	--VALIDATION_STRINGENCY LENIENT
done
