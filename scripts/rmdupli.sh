for sample in `cat samplelist.txt`; do 
 samtools markdup -r ./results/mapping/militaris/${sample}.sorted.bam ./results/mapping/militaris/${sample}.unique.bam
done

for sample in `cat samplelist.txt`; do 
 samtools markdup -r ./results/mapping/purpurea/${sample}.sorted.bam ./results/mapping/purpurea/${sample}.unique.bam
done

