# DiskANN with ADA-NNS

This repository for Vamana with greedy search method (baseline) and ADA-NNS.

Please refer to original [readme](https://github.com/SNU-ARC/DiskANN/blob/master/README.md).

## Building Instruction

### Compile on Ubuntu:

1. Install Dependencies:

Install the following packages through apt-get, and Intel MKL either by downloading the installer or using [apt](https://software.intel.com/en-us/articles/installing-intel-free-libs-and-python-apt-repo) (we tested with build 2019.4-070).
```
sudo apt install cmake g++ libaio-dev libgoogle-perftools-dev clang-format-4.0 libboost-dev
```

2. Compile DiskANN:

Build
```
cd build && ./build.sh
```

## Usage:

We now detail the script which can build and search for in memory-resident indices. For the description of original main binaries, please refer to original [readme](https://github.com/SNU-ARC/DiskANN/blob/master/README.md).

### Building Vamana Index

To use Vamana for ANNS, an Vamana index must be built first. Here are the instructions for building Vamana.

The parameters used to build each indices are as follows.

| Dataset          | R   | L     | Alpha|
|----------|-----------|-------------|--------------|
| SIFT1M      | 70 | 75   | 1.2    |
| GIST1M      | 70 | 75   | 1.2    |
| CRAWL       | 70 | 75   | 1.2    |
| DEEP1M      | 70 | 75   | 1.2    |
| MSONG       | 30 | 40   | 2      |
| GLOVE-100   | 70 | 75   | 1.2    |
| DEEP100M    | 70 | 75   | 1.2    |

### Search with Vamana Index

Dataset should be located in the directory `DiskANN/build/tests/.` as the following format.

e.g., `sift1M`, `gist1M`

To use the greedy search, use the `tests/evaluate_baseline.sh` script.
```
cd tests/
./evaluate_baseline.sh [dataset]
```
The argument is as follows:

(i) dataset: Name of the dataset. The script supports various real datasets (e.g., SIFT1M, GIST1M, CRAWL, DEEP1M, MSONG, GLOVE-100,  DEEP100M)

To change parameter for search (e.g., K, L, number of threads), open `evaluate_baseline.sh` and modify the parameter `K, L_SIZE, THREAD`.

To use the ADA-NNS, use the `tests/evaluate_ADA-NNS.sh` script
```
cd tests/
./evaluate_ADA-NNS.sh [dataset]
```
The argument is as follows:

(i) dataset: same as (i) above in evaluate_baseline script.

To change parameter for search (e.g., K, L, number of threads), open `evaluate_ADA-NNS.sh` and modify the parameter `K, L_SIZE, THREAD`.
