#!/bin/bash
# Script to update csv file with new companies filing ABS-EE reports on SEC's EDGAR site

cd /home/tmo/moman822.github.io/abs-ee


Rscript add_companies.R

git add .

git commit -m "updating companies and log"

git push origin master
