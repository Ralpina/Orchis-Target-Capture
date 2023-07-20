for sample in `cat samplelist.txt`
  do bwa mem -M -t 10 \
   ./results/hybpiper/refs/militaris \
   ./data/${sample}_1.fastq \
   ./data/${sample}_2.fastq | samtools view -b -h -S > results/mapping/militaris/${sample}.bam
done

for sample in `cat samplelist.txt`
  do bwa mem -M -t 10 \
   ./results/hybpiper/refs/purpurea \
   ./data/${sample}_1.fastq \
   ./data/${sample}_2.fastq | samtools view -b -h -S > results/mapping/purpurea/${sample}.bam
done

