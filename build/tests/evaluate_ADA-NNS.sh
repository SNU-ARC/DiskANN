#!/bin/bash
export TIME=$(date '+%Y%m%d%H%M')
MAX_THREADS=`nproc --all`
THREAD=(1)
K=(10) 
L_SIZE=(30)

vamana_sift1M() {
  # Convert base set, query set, groundtruth set to Vamana format
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

  # Build proximity graph
  if [ ! -f "sift1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 sift1M/sift_base.fvecs.bin sift1M.index 70 75 1.2 24
  fi

  # Perform search
  echo "Perform searching using Vamana index (sift1M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index_ADA_NNS float fast_l2 sift1M/sift_base.fvecs.bin sift1M.index ${4} sift1M/sift_query.fvecs.bin \
    sift1M/sift_groundtruth.ivecs.bin ${2} sift1M_search_L${1}K${2}T${4}_${3} 0.25 512 ${1} > sift1M_search_L${1}K${2}_${3}_T${4}.log 
}

vamana_sift10M() {
  # Convert base set, query set, groundtruth set to Vamana format
  if [ ! -f "sift10M/sift10m_base.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin sift10M/sift10m_base.fvecs sift10M/sift10m_base.fvecs.bin
  fi
  if [ ! -f "sift10M/sift10m_query.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin sift10M/sift10m_query.fvecs sift10M/sift10m_query.fvecs.bin
  fi
  if [ ! -f "sift10M/sift10m_groundtruth.ivecs.bin" ]; then
    echo "ivecs to bin"
    ./utils/ivecs_to_bin sift10M/sift10m_groundtruth.ivecs sift10M/sift10m_groundtruth.ivecs.bin
  fi

  # Build proximity graph
  if [ ! -f "sift10M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 sift10M/sift10m_base.fvecs.bin sift10M.index 70 75 1.2 24
  fi

  # Perform search
  echo "Perform searching using Vamana index (sift10M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index_ADA_NNS float fast_l2 sift10M/sift10m_base.fvecs.bin sift10M.index ${4} sift10M/sift10m_query.fvecs.bin \
    sift10M/sift10m_groundtruth.ivecs.bin ${2} sift10M_search_L${1}K${2}T${4}_${3} 0.25 512 ${1} > sift10M_search_L${1}K${2}_${3}_T${4}.log 
}

vamana_gist1M() {
  # Convert base set, query set, groundtruth set to Vamana format
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

  # Build proximity graph
  if [ ! -f "gist1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 gist1M/gist_base.fvecs.bin gist1M.index 70 75 1.2 24
  fi

  # Perform search
  echo "Perform searching using Vamana index (gist1M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index_ADA_NNS float fast_l2 gist1M/gist_base.fvecs.bin gist1M.index ${4} gist1M/gist_query.fvecs.bin \
    gist1M/gist_groundtruth.ivecs.bin ${2} gist1M_search_L${1}K${2}T${4}_${3} 0.3 1024 ${1} > gist1M_search_L${1}K${2}_${3}_T${4}.log 
}

vamana_crawl() {
  # Convert base set, query set, groundtruth set to Vamana format
  if [ ! -f "crawl/crawl_base.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin crawl/crawl_base.fvecs crawl/crawl_base.fvecs.bin
  fi
  if [ ! -f "crawl/crawl_query.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin crawl/crawl_query.fvecs crawl/crawl_query.fvecs.bin
  fi
  if [ ! -f "crawl/crawl_groundtruth.ivecs.bin" ]; then
    echo "ivecs to bin"
    ./utils/ivecs_to_bin crawl/crawl_groundtruth.ivecs crawl/crawl_groundtruth.ivecs.bin
  fi

  # Build proximity graph
  if [ ! -f "crawl.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 crawl/crawl_base.fvecs.bin crawl.index 70 75 1.2 24
  fi

  # Perform search
  echo "Perform searching using Vamana index (crawl_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index_ADA_NNS float fast_l2 crawl/crawl_base.fvecs.bin crawl.index ${4} crawl/crawl_query.fvecs.bin \
    crawl/crawl_groundtruth.ivecs.bin ${2} crawl_search_L${1}K${2}T${4}_${3} 0.3 512 ${1} > crawl_search_L${1}K${2}_${3}_T${4}.log 
}

vamana_deep1M() {
  # Convert base set, query set, groundtruth set to Vamana format
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

  # Build proximity graph
  if [ ! -f "deep1M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 deep1M/deep1m_base.fvecs.bin deep1M.index 70 75 1.2 24
  fi

  # Perform search
  echo "Perform searching using Vamana index (deep1M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index_ADA_NNS float fast_l2 deep1M/deep1m_base.fvecs.bin deep1M.index ${4} deep1M/deep1m_query.fvecs.bin \
    deep1M/deep1m_groundtruth.ivecs.bin ${2} deep1M_search_L${1}K${2}T${4}_${3} 0.3 512 ${1} > deep1M_search_L${1}K${2}_${3}_T${4}.log 
}

vamana_deep10M() {
  # Convert base set, query set, groundtruth set to Vamana format
  if [ ! -f "deep10M/deep10M_base.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin deep10M/deep10M_base.fvecs deep10M/deep10M_base.fvecs.bin
  fi
  if [ ! -f "deep10M/deep10M_query.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin deep10M/deep10M_query.fvecs deep10M/deep10M_query.fvecs.bin
  fi
  if [ ! -f "deep10M/deep10M_groundtruth.ivecs.bin" ]; then
    echo "ivecs to bin"
    ./utils/ivecs_to_bin deep10M/deep10M_groundtruth.ivecs deep10M/deep10M_groundtruth.ivecs.bin
  fi

  # Build proximity graph
  if [ ! -f "deep10M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 deep10M/deep10M_base.fvecs.bin deep10M.index 70 75 1.2 24
  fi

  # Perform search
  echo "Perform searching using Vamana index (deep10M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index_ADA_NNS float fast_l2 deep10M/deep10M_base.fvecs.bin deep10M.index ${4} deep10M/deep10M_query.fvecs.bin \
    deep10M/deep10M_groundtruth.ivecs.bin ${2} deep10M_search_L${1}K${2}T${4}_${3} 0.3 512 ${1} > deep10M_search_L${1}K${2}_${3}_T${4}.log 
}


vamana_deep100M_1T() {
  # Convert base set, query set, groundtruth set to Vamana format
  if [ ! -f "deep100M/deep100M_base.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin deep100M/deep100M_base.fvecs deep100M/deep100M_base.fvecs.bin
  fi
  if [ ! -f "deep100M/deep100M_query.fvecs.bin" ]; then
    echo "fvecs to bin"
    ./utils/fvecs_to_bin deep100M/deep100M_query.fvecs deep100M/deep100M_query.fvecs.bin
  fi
  if [ ! -f "deep100M/deep100M_groundtruth.ivecs.bin" ]; then
    echo "ivecs to bin"
    ./utils/ivecs_to_bin deep100M/deep100M_groundtruth.ivecs deep100M/deep100M_groundtruth.ivecs.bin
  fi

  # Build proximity graph
  if [ ! -f "deep100M.index" ]; then
    echo "Generating Vamana index"
    ./build_memory_index float l2 deep100M/deep100M_base.fvecs.bin deep100M.index 70 75 1.2 24
  fi

  # Perform search
  echo "Perform searching using Vamana index (deep100M_L${1}K${2}T${4})"
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  ./search_memory_index_ADA_NNS float fast_l2 deep100M/deep100M_base.fvecs.bin deep100M.index ${4} deep100M/deep100M_query.fvecs.bin \
    deep100M/deep100M_groundtruth.ivecs.bin ${2} deep100M_search_L${1}K${2}T${4}_${3} 0.3 512 ${1} > \
    deep100M_search_L${1}K${2}_${3}_T${4}.log 
}

vamana_deep100M_16T() {
  export sub_num=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
  for id in ${sub_num[@]}; do
    # Convert base set, query set, groundtruth set to Vamana format
    if [ ! -f "deep100M/deep100M_base_${id}.fvecs.bin" ]; then
      echo "fvecs to bin"
      ./utils/fvecs_to_bin deep100M/deep100M_base_${id}.fvecs deep100M/deep100M_base_${id}.fvecs.bin
    fi
    if [ ! -f "deep100M/deep100M_query.fvecs.bin" ]; then
      echo "fvecs to bin"
      ./utils/fvecs_to_bin deep100M/deep100M_query.fvecs deep100M/deep100M_query.fvecs.bin
    fi
    if [ ! -f "deep100M/deep100M_groundtruth.ivecs.bin" ]; then
      echo "ivecs to bin"
      ./utils/ivecs_to_bin deep100M/deep100M_groundtruth.ivecs deep100M/deep100M_groundtruth.ivecs.bin
    fi

    # Build proximity graph
    if [ ! -f "deep100M_${id}.index" ]; then
      echo "Generating Vamana index"
      ./build_memory_index float l2 deep100M/deep100M_base_${id}.fvecs.bin deep100M_${id}.index 70 75 1.2 24
    fi
  done
  echo "Perform searching using Vamana index (deep100M_L${1}K${2}T${4})"

  # Perform search
  sudo sh -c "sync && echo 3 > /proc/sys/vm/drop_caches"
  for id in ${sub_num[@]}; do
    ./search_memory_index_ADA_NNS float fast_l2 deep100M/deep100M_base_${id}.fvecs.bin deep100M_${id}.index ${4} deep100M/deep100M_query.fvecs.bin \
      deep100M/deep100M_groundtruth.ivecs.bin ${2} deep100M_search_L${1}K${2}T${4}_${id}_${3} 0.3 512 ${id} ${1} > \
      deep100M_search_L${1}K${2}_${3}_T${4}_${id}.log &
  done
  wait
  awk 'NR==10{ print; exit }' deep100M_search_L${1}K${2}_${3}_T${4}_0.log >> deep100M_search_L${1}K${2}_${3}_T${4}.log
  awk 'NR==11{ print; exit }' deep100M_search_L${1}K${2}_${3}_T${4}_0.log >> deep100M_search_L${1}K${2}_${3}_T${4}.log
  for id in ${sub_num[@]}; do
    awk 'NR==12{ print $0; exit }' deep100M_search_L${1}K${2}_${3}_T${4}_${id}.log >> deep100M_search_L${1}K${2}_${3}_T${4}.log
  done
  cat deep100M_search_L${1}K${2}_${3}_T${4}.log | awk '{sum += $5;} {if(NR==3) min = $2} {if($2 < min) min = $2} END { print "min_qps: " min; print "recall: " sum; }' >> deep100M_search_L${1}K${2}_${3}_T${4}.log 
}

if [ "${1}" == "sift1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_sift1M ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "sift10M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_sift10M ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "gist1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_gist1M ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "crawl" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_crawl ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "deep1M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_deep1M ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "deep10M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_deep10M ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "deep100M" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_deep100M ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "deep100M_16T" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_deep100M_16T ${l} ${k} ADA-NNS ${t}
      done
    done
  done
elif [ "${1}" == "all" ]; then
  for k in ${K[@]}; do
    for l_size in ${L_SIZE[@]}; do
      declare -i l=l_size
      for t in ${THREAD[@]}; do
        vamana_sift1M ${l} ${k} ADA-NNS ${t}
#        vamana_sift10M ${l} ${k} ADA-NNS ${t}
        vamana_gist1M ${l} ${k} ADA-NNS ${t}
        vamana_crawl ${l} ${k} ADA-NNS ${t}
        vamana_deep1M ${l} ${k} ADA-NNS ${t}
#        vamana_deep10M ${l} ${k} ADA-NNS ${t}
        vamana_deep100M ${l} ${k} ADA-NNS ${t}
        vamana_deep100M_16T ${l} ${k} ADA-NNS 1
      done
    done
  done
else
  echo "Please use either 'sift1M', 'gist1M', 'crawl', 'deep1M', 'deep100M', 'deep100M_16T' as an argument"
fi
