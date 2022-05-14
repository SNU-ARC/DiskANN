#!/bin/bash

param_l_start=250
param_l_end=1000
for (( i=$param_l_start; i<=$param_l_end; i=i+50 )); do
  param_l+=($i)
done
param_k=1
param_t=(1 24)
param_app_on=1

algorithm=$1

if [ $# -ne 1 ]
then
  echo "usage: ./parse.sh sift1M"
  exit 1
fi

if [[ $param_app_on == 1 ]]; then
  output_file=$1"_aid_by_approx_theta_K"$param_k"_summary.txt"
else
  output_file=$1"_baseline_K"$param_k"_summary.txt"
fi

echo > $output_file
sed -i -n -e 's/\n//g' $output_file

for l in ${param_l[@]}; do
  echo $l | tr '\n' ' ' >> $output_file
done
echo >> $output_file

for t in ${param_t[@]}; do
  if [[ ( $param_app_on == 0 ) ]]; then
    name_kt="K"$param_k"_baseline_T"$t".log"
    name_kt_visit="K"$param_k"_baseline_T"$t".log"
  else
    name_kt="K"$param_k"_aid_by_approx_theta_T"$t".log"
    name_kt_visit="K"$param_k"_aid_by_approx_theta_T"$t".log"
  fi
  for l in ${param_l[@]}; do
    name_lkt=$1"_search_L"${l}$name_kt;
    cat $name_lkt | grep "===" -A 1 | awk '{printf "%s\n", $5}' | sed '/^$/d' | tr '\n' ' ' | sed 's/ /% /g'   >> $output_file
  done
    echo >> $output_file
  for l in ${param_l[@]}; do
    name_lkt=$1"_search_L"${l}$name_kt;
    cat $name_lkt | grep "===" -A 1 | awk '{printf "%s\n", $2}' | sed '/^$/d' | tr '\n' ' ' >> $output_file
  done
    echo >> $output_file

  #if [[ $t == 1 ]]; then
  #  for l in ${param_l[@]}; do
  #    name_lkt_visit="visit/"$1"_search_L"${l}$name_kt_visit;
  #    cat $name_lkt_visit | grep "Total_summary" | awk '{printf "%s\n", $5}' | tr -d ',' | tr '\n' '\t'>> $output_file
  #  done
  #  echo >> $output_file
  #  for l in ${param_l[@]}; do
  #    name_lkt_visit="visit/"$1"_search_L"${l}$name_kt_visit;
  #    cat $name_lkt_visit | grep "Total_summary" | awk '{printf "%s\n", $9}' | tr -d ',' | tr '\n' '\t' >> $output_file
  #  done
  #  echo >> $output_file
  #  for l in ${param_l[@]}; do
  #    name_lkt_visit="visit/"$1"_search_L"${l}$name_kt_visit;
  #    cat $name_lkt_visit | grep "Total_summary" | awk '{printf "%s\n", $11}' | tr -d ',' | tr '\n' '\t' >> $output_file
  #  done
  #  echo >> $output_file
  #  for l in ${param_l[@]}; do
  #    name_lkt=$1"_search_L"${l}$name_kt;
  #    cat $name_lkt | grep "search time" | awk '{printf "%s\n", $3}' | tr '\n' '\t' >> $output_file
  #  done
  #  echo >> $output_file
  #fi
  #  

  #for l in ${param_l[@]}; do
  #  name_lkt=$1"_search_L"${l}$name_kt;
  #  cat $name_lkt | grep "QPS:" | awk '{printf "%s\n", $2}' | tr '\n' '\t' >> $output_file
  #done
  #  echo >> $output_file
done
gvim $output_file
