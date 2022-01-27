#!/bin/bash
export TIME=$(date '+%Y%m%d%H%M')
K=(10)
#L_SIZE=(13)
L_SIZE=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)
#K=(100)
#L_SIZE=(200)
#L_SIZE=(100 110 120 130 140 150 160 170 180 190 200)

if [ "${1}" == "sift1M" ]; then
  if [ ! -f "sift1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 sift1M/sift_base.fvecs.bin sift1M.index 70 75 1.2 24
  fi
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=k*l_size
      echo "Perform searching using Vamana index (L${l}K${k})"
      if [ "${2}" == "baseline" ]; then
        ./search_memory_index float fast_l2 sift1M/sift_base.fvecs.bin sift1M.index 1 sift1M/sift_query.fvecs.bin \
          sift1M/sift_groundtruth.ivecs.bin ${k} sift1M_search_L${l}K${k} ${l} > sift1M_search_L${l}K${k}_${2}.log 
      else
        ./search_memory_index float fast_l2 sift1M/sift_base.fvecs.bin sift1M.index 1 sift1M/sift_query.fvecs.bin \
          sift1M/sift_groundtruth.ivecs.bin ${k} sift1M_search_L${l}K${k} ${2} 0.3 512  ${l} > sift1M_search_L${l}K${k}_${2}.log 
      fi
    done
  done
elif [ "${1}" == "gist1M" ]; then
  if [ ! -f "gist1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 gist1M/gist_base.fvecs.bin gist1M.index 70 75 1.2 24
  fi
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=k*l_size
      echo "Perform searching using Vamana index (L${l}K${k})"
      if [ "${2}" == "baseline" ]; then
        ./search_memory_index float fast_l2 gist1M/gist_base.fvecs.bin gist1M.index 1 gist1M/gist_query.fvecs.bin \
          gist1M/gist_groundtruth.ivecs.bin ${k} gist1M_search_${l}_${k} ${l} > gist1M_search_L${l}K${k}_${2}.log 
      else
        ./search_memory_index float fast_l2 gist1M/gist_base.fvecs.bin gist1M.index 1 gist1M/gist_query.fvecs.bin \
          gist1M/gist_groundtruth.ivecs.bin ${k} gist1M_search_${l}_${k} ${2} 0.3 1024 ${l} > gist1M_search_L${l}K${k}_${2}.log 
      fi
    done
  done
elif [ "${1}" == "all" ]; then
  if [ ! -f "sift1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 sift1M/sift_base.fvecs.bin sift1M.index 70 75 1.2 24
  fi
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=k*l_size
      echo "Perform searching using Vamana index (L${l}K${k})"
      if [ "${2}" == "baseline" ]; then
        ./search_memory_index float fast_l2 sift1M/sift_base.fvecs.bin sift1M.index 1 sift1M/sift_query.fvecs.bin \
          sift1M/sift_groundtruth.ivecs.bin ${k} sift1M_search_${l}_${k} ${l} > sift1M_search_L${l}K${k}_${2}.log
      else
        ./search_memory_index float fast_l2 sift1M/sift_base.fvecs.bin sift1M.index 1 sift1M/sift_query.fvecs.bin \
          sift1M/sift_groundtruth.ivecs.bin ${k} sift1M_search_L${l}K${k} ${2} 0.3 512  ${l} > sift1M_search_L${l}K${k}_${2}.log 
      fi
    done
  done

  if [ ! -f "gist1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 gist1M/gist_base.fvecs.bin gist1M.index 70 75 1.2 24
  fi
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=k*l_size
      echo "Perform searching using Vamana index (L${l}K${k})"
      if [ "${2}" == "baseline" ]; then
        ./search_memory_index float fast_l2 gist1M/gist_base.fvecs.bin gist1M.index 1 gist1M/gist_query.fvecs.bin \
          gist1M/gist_groundtruth.ivecs.bin ${k} gist1M_search_${l}_${k} ${l} > gist1M_search_L${l}K${k}_${2}.log
      else
        ./search_memory_index float fast_l2 gist1M/gist_base.fvecs.bin gist1M.index 1 gist1M/gist_query.fvecs.bin \
          gist1M/gist_groundtruth.ivecs.bin ${k} gist1M_search_${l}_${k} ${2} 0.3 1024 ${l} > gist1M_search_L${l}K${k}_${2}.log 
      fi
    done
  done
else
  echo "Please use either 'sift' or 'gist' as an argument"
fi
