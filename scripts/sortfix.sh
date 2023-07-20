for sample in `cat samplelist.txt`; do 
 samtools fixmate -m ./results/mapping/militaris/${sample}.bam ./results/mapping/militaris/${sample}.fix.bam
 samtools sort -o ./results/mapping/militaris/${sample}.sorted.bam ./results/mapping/militaris/${sample}.fix.bam
done

for sample in `cat samplelist.txt`; do 
 samtools fixmate -m ./results/mapping/purpurea/${sample}.bam ./results/mapping/purpurea/${sample}.fix.bam
 samtools sort -o ./results/mapping/purpurea/${sample}.sorted.bam ./results/mapping/purpurea/${sample}.fix.bam
done
