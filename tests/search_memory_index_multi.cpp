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
  //  bool        use_optimized_search = std::atoi(argv[ctr++]);
#ifdef SORT_BY_EXACT_THETA
  ctr += 3;
#endif
//#ifdef THETA_GUIDED_SEARCH
  // [SJ]: Adding approximation scheme
  std::string approx_scheme(argv[ctr++]);
  if ((approx_scheme != std::string("baseline")) &&
      (approx_scheme != std::string("test")) &&
      (approx_scheme != std::string("sort_by_exact_theta")) &&
      (approx_scheme != std::string("aid_by_exact_theta")) &&
      (approx_scheme != std::string("aid_by_approx_theta"))) {
    std::cout << "Must mention which approximation scheme to use" << std::endl;
    std::cout << "\t- baseline: No approximation scheme" << std::endl;
    std::cout << "\t- sort_by_exact_theta: Use exact angular distance instead of distance" << std::endl;
    std::cout << "\t- aid_by_exact_theta: Use exact angular distance to filter less relevant vertices" << std::endl;
    std::cout << "\t- aid_by_approx_theta: Use hamming distance of hash values to filter less relevant vertices" << std::endl;

//    return -1;
  }
  float approx_rate = std::atof(argv[ctr++]);
  unsigned hash_bitwidth = std::atoi(argv[ctr++]);
//#endif

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

  // SJ: From here, multi starts

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
  float total_recall = 0.0;
  std::vector<double> global_search_time(16, 0.0);

//  omp_set_num_threads(num_threads);
//#pragma omp parallel for schedule(dynamic, 1)
  for (unsigned int sub_num = 0; sub_num < 16; sub_num++) {
    std::string data_file_multi(data_file);
    std::string memory_index_file_multi(memory_index_file);
    data_file_multi.insert(data_file_multi.find(".fvecs.bin"), "_" + std::to_string(sub_num));
    memory_index_file_multi.insert(memory_index_file_multi.find(".index"), "_" + std::to_string(sub_num));

    diskann::Index<T> index(metric, data_file_multi.c_str());

    index.load(memory_index_file_multi.c_str());  // to load NSG
    std::cout << "Index loaded" << std::endl;

#ifdef THETA_GUIDED_SEARCH
    index._approx_rate = approx_rate;
    index._hash_bitwidth = hash_bitwidth;
#endif
    if (metric == diskann::FAST_L2)
      index.optimize_graph();

#ifdef GET_MISS_TRAVERSE
    index.total_traverse = 0;
    index.total_traverse_miss = 0;
#endif
#ifdef THETA_GUIDED_SEARCH
    // [SJ]: Load hash_function & hash_value
    std::string hash_function_bin = memory_index_file_multi;
    std::string hash_value_bin = memory_index_file_multi;
    hash_function_bin += ".hash_function_";
    hash_value_bin += ".hash_vector_";
    hash_function_bin += std::to_string(hash_bitwidth);
    hash_value_bin += std::to_string(hash_bitwidth);
    hash_function_bin += "b";
    hash_value_bin += "b";
    if (index.LoadHashFunction(hash_function_bin.c_str())) {
      if (!index.LoadHashValue(hash_value_bin.c_str()))
        index.GenerateHashValue(hash_value_bin.c_str());
    }
    else {
      index.GenerateHashFunction(hash_function_bin.c_str());
      index.GenerateHashValue(hash_value_bin.c_str());
    }
#endif
#ifdef PROFILE
    index.num_timer = 3;
    index.profile_time.resize(num_threads * index.num_timer, 0.0);
#endif

    for (uint32_t test_id = 0; test_id < Lvec.size(); test_id++) {
      _u64 L = Lvec[test_id];
      query_result_ids[test_id].resize(recall_at * query_num);
      std::vector<double> latency_stats(query_num, 0);
      auto s = std::chrono::high_resolution_clock::now();
//      omp_set_num_threads(num_threads);
//#pragma omp parallel for schedule(dynamic, 1)
      for (int64_t i = 0; i < (int64_t) query_num; i++) {
        auto qs = std::chrono::high_resolution_clock::now();
        if (metric == diskann::FAST_L2) {
          index.search_with_opt_graph(
              query + i * query_aligned_dim, recall_at, L,
              query_result_ids[test_id].data() + i * recall_at);
        } else {
          index.search(query + i * query_aligned_dim, recall_at, L,
              query_result_ids[test_id].data() + i * recall_at);
        }
        auto qe = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double> diff = qe - qs;
        latency_stats[i] = diff.count() * 1000000;
      }
      auto                          e = std::chrono::high_resolution_clock::now();
      std::chrono::duration<double> diff = e - s;

      float qps = (query_num / diff.count());
      global_search_time[sub_num] = diff.count();

      for (uint64_t q = 0; q < query_num; q++) {
        unsigned add_id = 6250000 * sub_num;
        for (unsigned tmp = 0; tmp < recall_at; tmp++) {
          query_result_ids[test_id][q * recall_at + tmp] += add_id;
        }
      }
      for (uint32_t test_id = 0; test_id < Lvec.size(); test_id++) {
        _u64 L = Lvec[test_id];
        float recall = 0;
        if (calc_recall_flag)
          recall = diskann::calculate_recall(query_num, gt_ids, gt_dists, gt_dim,
              query_result_ids[test_id].data(),
              recall_at, recall_at);

        total_recall += recall;

        std::sort(latency_stats.begin(), latency_stats.end());
        double mean_latency = 0;
        for (uint64_t q = 0; q < query_num; q++) {
          mean_latency += latency_stats[q];
        }
        mean_latency /= query_num;

        std::cout << std::setw(4) << L << std::setw(12) << qps << std::setw(18)
          << (float) mean_latency << std::setw(15)
          << (float) latency_stats[(_u64)(0.999 * query_num)]
          << std::setw(12) << recall << std::endl;
      }
    }
  }
  std::sort(global_search_time.begin(), global_search_time.end());
  std::cout << "Search Time (16-thread): " << global_search_time[15] << std::endl;
  std::cout << "QPS (16-thread): " << query_num / global_search_time[15] << std::endl;
  
  for (unsigned int iter = 0; iter < 15; iter++) {
    global_search_time[15] += global_search_time[iter];
  }
  std::cout << std::endl << "Search Time (1-thread): " << global_search_time[15] << std::endl;
  std::cout << "QPS (1-thread): " << query_num / global_search_time[15] << std::endl;
  std::cout << std::endl << "total_recall: " << total_recall << std::endl;
  //
#ifdef GET_MISS_TRAVERSE
  std::cout << "[Total_summary] # of traversed: " << index.total_traverse << ", ";
  std::cout << "# of invalid: " << index.total_traverse_miss << ", ";
  std::cout << "ratio: " << (float)index.total_traverse_miss / index.total_traverse  * 100 << std::endl;
#endif
#ifdef PROFILE
  std::cout << "========Thread Latency Report========" << std::endl;
  double* timer = (double*)calloc(index.num_timer, sizeof(double));
  for (unsigned int tid = 0; tid < num_threads; tid++) {
    timer[0] += index.profile_time[tid * index.num_timer];
    timer[1] += index.profile_time[tid * index.num_timer + 1];
    timer[2] += index.profile_time[tid * index.num_timer + 2];
  }
#ifdef THETA_GUIDED_SEARCH
    std::cout << "query_hash time: " << timer[0] / query_num << "ms" << std::endl;
    std::cout << "hash_approx time: " << timer[1] / query_num << "ms" << std::endl;
    std::cout << "dist time: " << timer[2] / query_num << "ms" << std::endl;
#else
    std::cout << "dist time: " << timer[2] / query_num << "ms" << std::endl;
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
//#ifdef THETA_GUIDED_SEARCH
//  delete[] index._hash_function;
//#endif
  diskann::aligned_free(query);
  return 0;
}

int main(int argc, char** argv) {
//#ifdef THETA_GUIDED_SEARCH
  if (argc < 14) {
    std::cout
        << "Usage: " << argv[0]
        << "  [index_type<float/int8/uint8>]  [dist_fn (l2/mips/fast_l2)] "
           "[data_file.bin]  "
           "[memory_index_path]  [num_threads] "
           "[query_file.bin]  [truthset.bin (use \"null\" for none)] "
           " [K] [result_output_prefix] [approx_scheme] [approx_rate] [hash_bitwidth]"
//#else
//  if (argc < 11) {
//    std::cout
//        << "Usage: " << argv[0]
//        << "  [index_type<float/int8/uint8>]  [dist_fn (l2/mips/fast_l2)] "
//           "[data_file.bin]  "
//           "[memory_index_path]  [num_threads] "
//           "[query_file.bin]  [truthset.bin (use \"null\" for none)] "
//           " [K] [result_output_prefix]"
//#endif
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
