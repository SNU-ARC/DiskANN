// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#include <cstring>
#include <iomanip>
#include <omp.h>
#include <set>
#include <string.h>

#ifndef _WINDOWS
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#endif

#include "aux_utils.h"
#include "index.h"
#include "memory_mapper.h"
#include "utils.h"

template<typename T>
int search_memory_index(int argc, char** argv) {
  T*                query = nullptr;
  unsigned*         gt_ids = nullptr;
  float*            gt_dists = nullptr;
  size_t            query_num, query_dim, query_aligned_dim, gt_num, gt_dim;
  std::vector<_u64> Lvec;

  _u32            ctr = 2;
  diskann::Metric metric;

  if (std::string(argv[ctr]) == std::string("mips"))
    metric = diskann::Metric::INNER_PRODUCT;
  else if (std::string(argv[ctr]) == std::string("l2"))
    metric = diskann::Metric::L2;
  else if (std::string(argv[ctr]) == std::string("fast_l2"))
    metric = diskann::Metric::FAST_L2;
  else {
    std::cout << "Unsupported distance function. Currently only L2/ Inner "
                 "Product/FAST_L2 support."
              << std::endl;
    return -1;
  }
  ctr++;

  if ((std::string(argv[1]) != std::string("float")) &&
      ((metric == diskann::Metric::INNER_PRODUCT) ||
       (metric == diskann::Metric::FAST_L2))) {
    std::cout << "Error. Inner product and Fast_L2 search currently only "
                 "supported for "
                 "floating point datatypes."
              << std::endl;
  }

  std::string data_file(argv[ctr++]);
  std::string memory_index_file(argv[ctr++]);
  _u64        num_threads = std::atoi(argv[ctr++]);
  std::string query_bin(argv[ctr++]);
  std::string truthset_bin(argv[ctr++]);
  _u64        recall_at = std::atoi(argv[ctr++]);
  std::string result_output_prefix(argv[ctr++]);

// [SJ]: Variables for ADA-NNS 
#ifdef ADA_NNS
  float tau = std::atof(argv[ctr++]);
  unsigned hash_bitwidth = std::atoi(argv[ctr++]);
#endif

  bool calc_recall_flag = false;

  for (; ctr < (_u32) argc; ctr++) {
    _u64 curL = std::atoi(argv[ctr]);
    if (curL >= recall_at)
      Lvec.push_back(curL);
  }

  if (Lvec.size() == 0) {
    std::cout << "No valid Lsearch found. Lsearch must be at least recall_at."
              << std::endl;
    return -1;
  }

  diskann::load_aligned_bin<T>(query_bin, query, query_num, query_dim,
                               query_aligned_dim);

  if (file_exists(truthset_bin)) {
    diskann::load_truthset(truthset_bin, gt_ids, gt_dists, gt_num, gt_dim);
    if (gt_num != query_num) {
      std::cout << "Error. Mismatch in number of queries and ground truth data"
                << std::endl;
    }
    calc_recall_flag = true;
  }

  std::cout.setf(std::ios_base::fixed, std::ios_base::floatfield);
  std::cout.precision(2);

  diskann::Index<T> index(metric, data_file.c_str());

  index.load(memory_index_file.c_str());  // to load NSG
  std::cout << "Index loaded" << std::endl;

#ifdef ADA_NNS
  index.set_tau(tau);
  index.set_hash_bitwidth(hash_bitwidth);
#endif
  if (metric == diskann::FAST_L2)
    index.optimize_graph();

#ifdef ADA_NNS
  // [ARC-SJ]: Read or generate hash function & hashed set
  std::string hash_function_bin = memory_index_file;
  std::string hashed_set_bin = memory_index_file;
  hash_function_bin += ".hash_function_";
  hashed_set_bin += ".hashed_set_";
  hash_function_bin += std::to_string(hash_bitwidth);
  hashed_set_bin += std::to_string(hash_bitwidth);
  hash_function_bin += "b";
  hashed_set_bin += "b";
  if (index.read_hash_function(hash_function_bin.c_str())) {
    if (!index.read_hashed_set(hashed_set_bin.c_str()))
      index.generate_hashed_set(hashed_set_bin.c_str());
  }
  else {
    index.generate_hash_function(hash_function_bin.c_str());
    index.generate_hashed_set(hashed_set_bin.c_str());
  }
#endif
#ifdef PROFILE
  index.set_timer(num_threads);
#endif

  diskann::Parameters paras;
  std::string         recall_string = "Recall@" + std::to_string(recall_at);
  std::cout << std::setw(4) << "Ls" << std::setw(12) << "QPS " << std::setw(18)
            << "Mean Latency (mus)" << std::setw(15) << "99.9 Latency"
            << std::setw(12) << recall_string << std::endl;
  std::cout << "==============================================================="
               "==============="
            << std::endl;

  std::vector<std::vector<uint32_t>> query_result_ids(Lvec.size());
  std::vector<std::vector<float>>    query_result_dists(Lvec.size());

  std::vector<double> latency_stats(query_num, 0);

  // [ARC-SJ]: Minor optimization of greedy search 
  //           Allocate visited list once
  //           For large-scale dataset (e.g., DEEP100M),
  //           repeated allocation is a huge overhead
  boost::dynamic_bitset<> flags{index.get_nd(), 0};

  for (uint32_t test_id = 0; test_id < Lvec.size(); test_id++) {
    _u64 L = Lvec[test_id];
    query_result_ids[test_id].resize(recall_at * query_num);

    auto s = std::chrono::high_resolution_clock::now();
    omp_set_num_threads(num_threads);
#pragma omp parallel for schedule(dynamic, 1)
    for (int64_t i = 0; i < (int64_t) query_num; i++) {
      auto qs = std::chrono::high_resolution_clock::now();
      if (metric == diskann::FAST_L2) {
        index.search_with_opt_graph(
            query + i * query_aligned_dim, flags, recall_at, L,
            query_result_ids[test_id].data() + i * recall_at);
      } else {
        index.search(query + i * query_aligned_dim, recall_at, L,
                     query_result_ids[test_id].data() + i * recall_at);
      }
      auto qe = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> diff = qe - qs;
      latency_stats[i] = diff.count() * 1000000;
    }
    auto e = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff = e - s;


    float recall = 0;
    if (calc_recall_flag)
      recall = diskann::calculate_recall(query_num, gt_ids, gt_dists, gt_dim,
                                         query_result_ids[test_id].data(),
                                         recall_at, recall_at);

    std::sort(latency_stats.begin(), latency_stats.end());
    double mean_latency = 0;
    for (uint64_t q = 0; q < query_num; q++) {
      mean_latency += latency_stats[q];
    }
    mean_latency /= query_num;
    float qps = query_num / (float) diff.count();

    std::cout << std::setw(4) << L << std::setw(12) << qps << std::setw(18)
              << (float) mean_latency << std::setw(15)
              << (float) latency_stats[(_u64)(0.999 * query_num)]
              << std::setw(12) << recall << std::endl;
  }
#ifdef GET_DIST_COMP
  std::cout << "========Distance Compute Report========" << std::endl;
  std::cout << "# of distance compute: " << index.get_total_dist_comp() << std::endl;
  std::cout << "# of missed distance compute: " << index.get_total_dist_comp_miss() << std::endl;
  std::cout << "Ratio: " << (float)index.get_total_dist_comp_miss() / index.get_total_dist_comp()  * 100 << " %" << std::endl;
  std::cout << "Speedup: " << (float)(index.get_nd()) * query_num / index.get_total_dist_comp() << std::endl;
  std::cout << "=====================================" << std::endl;
#endif
#ifdef PROFILE
  std::cout << "========Profile Report========" << std::endl;
  double* timer = (double*)calloc(4, sizeof(double));
  for (unsigned int tid = 0; tid < num_threads; tid++) {
    timer[0] += index.get_timer(tid * 4); // visited list init time
    timer[1] += index.get_timer(tid * 4 + 1); // query hash stage time
    timer[2] += index.get_timer(tid * 4 + 2); // candidate selection stage time
    timer[3] += index.get_timer(tid * 4 + 3); // fast L2 distance compute time
  }
#ifdef ADA_NNS
    std::cout << "visited_init time: " << timer[0] / query_num << "ms" << std::endl;
    std::cout << "query_hash time: " << timer[1] / query_num << "ms" << std::endl;
    std::cout << "cand_select time: " << timer[2] / query_num << "ms" << std::endl;
    std::cout << "dist time: " << timer[3] / query_num << "ms" << std::endl;
#else
    std::cout << "visited_init time: " << timer[0] / query_num << "ms" << std::endl;
    std::cout << "dist time: " << timer[3] / query_num << "ms" << std::endl;
#endif
  std::cout << "=====================================" << std::endl;
#endif

  std::cout << "Done searching. Now saving results " << std::endl;
  _u64 test_id = 0;
  for (auto L : Lvec) {
    std::string cur_result_path =
        result_output_prefix + "_" + std::to_string(L) + "_idx_uint32.bin";
    diskann::save_bin<_u32>(cur_result_path, query_result_ids[test_id].data(),
                            query_num, recall_at);
    test_id++;
  }
  diskann::aligned_free(query);
  return 0;
}

int main(int argc, char** argv) {
#ifdef ADA_NNS
  if (argc < 13) {
    std::cout
        << "Usage: " << argv[0]
        << "  [index_type<float/int8/uint8>]  [dist_fn (l2/mips/fast_l2)] "
           "[data_file.bin]  "
           "[memory_index_path]  [num_threads] "
           "[query_file.bin]  [truthset.bin (use \"null\" for none)] "
           " [K] [result_output_prefix] [tau] [hash_bitwidth]"
#else
  if (argc < 11) {
    std::cout
        << "Usage: " << argv[0]
        << "  [index_type<float/int8/uint8>]  [dist_fn (l2/mips/fast_l2)] "
           "[data_file.bin]  "
           "[memory_index_path]  [num_threads] "
           "[query_file.bin]  [truthset.bin (use \"null\" for none)] "
           " [K] [result_output_prefix]"
#endif
           " [L1]  [L2] etc. See README for more information on parameters. "
        << std::endl;
    exit(-1);
  }
  if (std::string(argv[1]) == std::string("int8"))
    search_memory_index<int8_t>(argc, argv);
  else if (std::string(argv[1]) == std::string("uint8"))
    search_memory_index<uint8_t>(argc, argv);
  else if (std::string(argv[1]) == std::string("float"))
    search_memory_index<float>(argc, argv);
  else
    std::cout << "Unsupported type. Use float/int8/uint8" << std::endl;
}
