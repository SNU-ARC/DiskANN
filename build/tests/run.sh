#!/bin/bash
export TIME=$(date '+%Y%m%d%H%M')
MAX_THREADS=`nproc --all`
#THREAD=(1 ${MAX_THREADS})
THREAD=(1 2 4 8 16 ${MAX_THREADS})
#THREAD=(1 2 4 8 10 12 14 16 18 20 22 ${MAX_THREADS})
K=(10)
L_SIZE=(30 31 32 33 34 35 36 37 38 39)
#L_SIZE=(10 17 18 20 23 30 31 36 39 40 50 60 70 71 80 90 91 100 110 120 130 140 150 160 170 180 190 200)

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
  echo "Perform searching using Vamana index (sift1M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index float fast_l2 sift1M/sift_base.fvecs.bin sift1M.index ${4} sift1M/sift_query.fvecs.bin \
    sift1M/sift_groundtruth.ivecs.bin ${2} sift1M_search_L${1}K${2}T${4} ${3} 0.25 512  ${1} > sift1M_search_L${1}K${2}_${3}_T${4}.log 
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
  echo "Perform searching using Vamana index (gist1M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index float fast_l2 gist1M/gist_base.fvecs.bin gist1M.index ${4} gist1M/gist_query.fvecs.bin \
    gist1M/gist_groundtruth.ivecs.bin ${2} gist1M_search_L${1}K${2}T${4} ${3} 0.3 1024 ${1} > gist1M_search_L${1}K${2}_${3}_T${4}.log 
}

vamana_deep1M() {
  if [ ! -f "deep1M/deep1m_base.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin deep1M/deep1m_base.fvecs deep1M/deep1m_base.fvecs.bin
  fi
  if [ ! -f "deep1M/deep1m_query.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin deep1M/deep1m_query.fvecs deep1M/deep1m_query.fvecs.bin
  fi
  if [ ! -f "deep1M/deep1m_groundtruth.ivecs.bin" ]; then
    echo "ivecs to bin"
    ./utils/ivecs_to_bin deep1M/deep1m_groundtruth.ivecs deep1M/deep1m_groundtruth.ivecs.bin
  fi
  if [ ! -f "deep1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 deep1M/deep1m_base.fvecs.bin deep1M.index 70 75 1.2 24
  fi
  echo "Perform searching using Vamana index (deep1M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index float fast_l2 deep1M/deep1m_base.fvecs.bin deep1M.index ${4} deep1M/deep1m_query.fvecs.bin \
    deep1M/deep1m_groundtruth.ivecs.bin ${2} deep1M_search_L${1}K${2}T${4} ${3} 0.3 512 ${1} > deep1M_search_L${1}K${2}_${3}_T${4}.log 
}

if [ "${1}" == "sift1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_sift1M ${l} ${k} ${2} ${t}
      done
    done
  done
elif [ "${1}" == "gist1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_gist1M ${l} ${k} ${2} ${t}
      done
    done
  done
elif [ "${1}" == "deep1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_deep1M ${l} ${k} ${2} ${t}
      done
    done
  done
elif [ "${1}" == "all" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_sift1M ${l} ${k} ${2} ${t}
        vamana_gist1M ${l} ${k} ${2} ${t}
        vamana_deep1M ${l} ${k} ${2} ${t}
      done
    done
  done
else
  echo "Please use either 'sift1M' or 'gist1M' or 'deep1M' as an argument"
fi
