#!/bin/bash
if [[ $# -ne 3 ]]; then
    echo "usage:" $0 "base test n_runs"
	echo "example:" $0 "./stockfish_base ./stockfish_test 10"
    exit 1
fi

base=$1
test=$2
n_runs=$3

# temporary files initialization
cat /dev/null > base000.txt
cat /dev/null > test000.txt
cat /dev/null > tmp000.txt

# preload of CPU/cache/memory
($base bench >/dev/null 2>&1)&
($test bench >/dev/null 2>&1)&
wait

# bench loop: SMP bench with background subshells
for k in `seq 1 $n_runs`;
  do
    printf "run %3d /%3d\n" $k $n_runs
	
	# swap the execution order to avoid bias
    if [ $((k%2)) -eq 0 ];
	  then
        ($base bench >/dev/null 2>> base000.txt)&
        ($test bench >/dev/null 2>> test000.txt)&
        wait
      else
        ($test bench >/dev/null 2>> test000.txt)&
        ($base bench >/dev/null 2>> base000.txt)&
        wait
    fi
  done

# text processing to extract nps values
cat base000.txt | grep second | grep -Eo '[0-9]{1,}' > base001.txt
cat test000.txt | grep second | grep -Eo '[0-9]{1,}' > test001.txt

for k in `seq 1 $n_runs`;
  do
    echo $k >> tmp000.txt
  done

printf "\nrun\tbase\ttest\tdiff\n"
paste tmp000.txt base001.txt test001.txt | awk '{printf "%3d  %d  %d  %+d\n", $1, $2, $3, $3-$2}'
paste base001.txt test001.txt | awk '{printf "%d\t%d\t%d\n", $1, $2, $2-$1}' > tmp000.txt

# compute: sample mean, 1.96 * std of sample mean (95% sample means), speedup
cat tmp000.txt | awk '{sum1 += $1 ; sumq1 += $1**2 ;sum2 += $2 ; sumq2 += $2**2 ;sum3 += $3 ; sumq3 += $3**2 } END {printf "\nbase = %10d +/- %d\ntest = %10d +/- %d\ndiff = %10d +/- %d\nspeedup = %.6f\n\n", sum1/NR , NR/(NR-1)*sqrt(sumq1/NR - (sum1/NR)**2)/sqrt(NR)*1.96 , sum2/NR , NR/(NR-1)*sqrt(sumq2/NR - (sum2/NR)**2)/sqrt(NR)*1.96 , sum3/NR  , NR/(NR-1)*sqrt(sumq3/NR - (sum3/NR)**2)/sqrt(NR)*1.96 , (sum2 - sum1)/sum1 }'

# remove temporary files 
rm -f base000.txt test000.txt tmp000.txt base001.txt test001.txt