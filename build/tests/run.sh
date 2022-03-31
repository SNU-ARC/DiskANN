#!/bin/bash
export TIME=$(date '+%Y%m%d%H%M')
K=(10)
L_SIZE=(10)
#L_SIZE=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)
#K=(100)
#L_SIZE=(200)
#L_SIZE=(100 110 120 130 140 150 160 170 180 190 200)

vamana_sift1M() {
  if [ ! -f "sift1M/sift_base.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin sift1M/sift_base.fvecs sift1M/sift_base.fvecs.bin
  fi
  if [ ! -f "sift1M/sift_query.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin sift1M/sift_query.fvecs sift1M/sift_query.fvecs.bin
  fi
  if [ ! -f "sift1M/sift_groundtruth.ivecs.bin" ]; then
    echo "ivecs to bin"
    ./utils/ivecs_to_bin sift1M/sift_groundtruth.ivecs sift1M/sift_groundtruth.ivecs.bin
  fi
  if [ ! -f "sift1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 sift1M/sift_base.fvecs.bin sift1M.index 70 75 1.2 24
  fi
  echo "Perform searching using Vamana index (L${1}K${2})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index float fast_l2 sift1M/sift_base.fvecs.bin sift1M.index 1 sift1M/sift_query.fvecs.bin \
    sift1M/sift_groundtruth.ivecs.bin ${2} sift1M_search_L${1}K${2} ${3} 0.25 512  ${1} > sift1M_search_L${1}K${2}_${3}.log 
}

vamana_gist1M() {
  if [ ! -f "gist1M/gist_base.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin gist1M/gist_base.fvecs gist1M/gist_base.fvecs.bin
  fi
  if [ ! -f "gist1M/gist_query.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin gist1M/gist_query.fvecs gist1M/gist_query.fvecs.bin
  fi
  if [ ! -f "gist1M/gist_groundtruth.ivecs.bin" ]; then
    echo "ivecs to bin"
    ./utils/ivecs_to_bin gist1M/gist_groundtruth.ivecs gist1M/gist_groundtruth.ivecs.bin
  fi
  if [ ! -f "gist1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 gist1M/gist_base.fvecs.bin gist1M.index 70 75 1.2 24
  fi
  echo "Perform searching using Vamana index (L${1}K${2})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index float fast_l2 gist1M/gist_base.fvecs.bin gist1M.index 1 gist1M/gist_query.fvecs.bin \
    gist1M/gist_groundtruth.ivecs.bin ${2} gist1M_search_L${1}K${2} ${3} 0.3 1024 ${1} > gist1M_search_L${1}K${2}_${3}.log 
}

if [ "${1}" == "sift1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      vamana_sift1M ${l} ${k} ${2}
    done
  done
elif [ "${1}" == "gist1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      vamana_gist1M ${l} ${k} ${2}
    done
  done
elif [ "${1}" == "all" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      vamana_sift1M ${l} ${k} ${2}
      vamana_gist1M ${l} ${k} ${2}
    done
  done
else
  echo "Please use either 'sift1M' or 'gist1M' as an argument"
fi
