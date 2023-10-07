#!/bin/bash

echo "quick3_code,candidates" > ../CantoboardTestApp/UnihanSource/Quick3Order.csv
awk '
{
        # Check if array indexed by 1st field (A[$1]) is null.
        # If yes, assign value = 2nd field ($2)
        # If no, assign value = previous value (A[$1]) comma (",") 2nd field ($2)
        A[$1] = A[$1] == "" ? $2 : A[$1]$2
}
        # END Block
END {
        # For each element in array
        # Print
        for (i in A) {
                print i","A[i]
        }
} ' quick3.txt | sort >> ../CantoboardTestApp/UnihanSource/Quick3Order.csv
