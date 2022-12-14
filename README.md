# DiskANN with ADA-NNS

This repository for Vamana with greedy search method (baseline) and ADA-NNS.

Please refer to original readme [here](https://github.com/SNU-ARC/DiskANN/blob/master/README.md).

## Linux build:

Install the following packages through apt-get, and Intel MKL either by downloading the installer or using [apt](https://software.intel.com/en-us/articles/installing-intel-free-libs-and-python-apt-repo) (we tested with build 2019.4-070).
```
sudo apt install cmake g++ libaio-dev libgoogle-perftools-dev clang-format-4.0 libboost-dev
```

Build
```
cd build && ./build.sh
```

## Usage:

We now detail the main binaries using which one can build and search indices which reside in memory-resident indices.

**Usage for in-memory search scripts**
================================

To use the greedy search, use the `tests/evaluate_baseline.sh` script.
-------------------------------------------------------------------------------
```
cd tests/
./evaluate_baseline.sh [dataset]
```
The argument is as follows:
(i) dataset: Name of the dataset. The script supports various real datasets (e.g., SIFT1M, SIFT10M, GIST1M, CRAWL, DEEP1M, DEEP10M, DEEP100M)

To change parameter for search (e.g., K, L, number of threads), open `evaluate_baseline.sh` and modify the parameter `K, L_SIZE, THREAD`.

To use the ADA-NNS, use the `tests/evaluate_ADA_NNS.sh` script.
-------------------------------------------------------------------------------
```
cd tests/
./evaluate_ADA_NNS.sh [dataset]
```
The argument is as follows:
(i) dataset: same as (i) above in evaluate_baseline script.

To change parameter for search (e.g., K, L, number of threads), open `evaluate_baseline.sh` and modify the parameter `K, L_SIZE, THREAD`.

**Usage for in-memory indices**
================================

To generate index, use the `tests/build_memory_index` program. 
--------------------------------------------------------------

```
./tests/build_memory_index  [data_type<int8/uint8/float>] [l2/mips] [data_file.bin]  [output_index_file]  [R]  [L]  [alpha]  [num_threads_to_use]
```

The arguments are as follows:

(i) data_type: same as (i) above in building disk index.

(ii) metric: There are two primary metric types of distance supported: l2 and mips.

(iii) data_file: same as (ii) above in building disk index, the input data file in .bin format of type int8/uint8/float.

(iv) output_index_file: memory index will be saved here.

(v) R: max degree of index: larger is typically better, range (50-150). Preferrably ensure that L is at least R.

(vi) L: candidate_list_size for building index, larger is better (typical range: 75 to 200)

(vii) alpha: float value which determines how dense our overall graph will be, and diameter will be log of n base alpha (roughly). Typical values are between 1 to 1.5. 1 will yield sparsest graph, 1.5 will yield denser graphs.

(viii) number of threads to use: indexing uses specified number of threads.


To search the generated index, use the `tests/search_memory_index` program:
---------------------------------------------------------------------------

```
./tests/search_memory_index  [index_type<float/int8/uint8>] [l2/mips] [data_file.bin]  [memory_index_path]  [query_file.bin]  [truthset.bin (use "null" for none)] [K]  [result_output_prefix]  [L1]  [L2] etc. 
```

The arguments are as follows:

(i) data type: same as (i) above in building index.

(ii) metric: There are two primary metric types of distance supported: l2 and mips.

(iii) memory_index_path: enter path of index built (argument (iii) above in building memory index).

(iv) query_bin: search on these queries, same format as data file (ii) above. The query file must be the same type as specified in (i).

(v) Truthset file. Must be in the following format: n, the number of queries (4 bytes) followed by d, the number of ground truth elements per query (4 bytes), followed by n*d entries per query representing the d closest IDs per query in integer format,  followed by n*d entries representing the corresponding distances (float). Total file size is 8 + 4*n*d + 4*n*d. The groundtruth file, if not available, can be calculated using our program, tests/utils/compute_groundtruth.

(vi) K: search for recall@k, meaning accuracy of retrieving top-k nearest neighbors.

(vii) result output prefix: will search and store the computed results in the files with specified prefix in bin format.

(viii, ix, ...) various search_list sizes to perform search with. Larger will result in slower latencies, but higher accuracies. Must be atleast the recall@ value in (vi).
