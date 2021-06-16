#!/usr/bin/env python3
# coding=utf-8

import sys

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(sys.argv[0] + "<rime dict path> <comman words dict>")
        exit(-1)
    
    inputPath = sys.argv[1]
    commonWordPath = sys.argv[2]

    with open(commonWordPath) as f:
        lines = f.read().splitlines()
        common_word_dict = set(lines)
        
    with open(inputPath) as f:
        lines = f.read().splitlines()

    output = []
    for line in lines:
        if '\t' in line:
            parsedLine = line.split('\t')
            c = parsedLine[0]
            if len(c) == 1 and len(parsedLine) < 3:
                if c not in common_word_dict:
                    line += "\t0%"
                    # print(line)
        output.append(line)
    
    with open(inputPath, "w") as outputFile:
        print("\n".join(output), file=outputFile)

    exit(0)