# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load(
    "@local_config_musa//musa:build_defs.bzl",
    "musa_cc_test",
    "musa_library",
)

musa_library(
    name = "vector_musa",
    srcs = ["vector_musa.mu.cc"],
    hdrs = ["vector_musa.h"],
    tags = ["musa-only"],
)

musa_cc_test(
    name = "vector_musa_test",
    srcs = ["vector_musa_test.cc"],
    tags = [
        "gpu",
        "manual",
        "musa-only",
    ],
    deps = [
        ":vector_musa",
        "@gtest//:gtest_main",
    ],
)

build_test(
    name = "vector_musa_build_test",
    targets = [":vector_musa_test"],
)

test_suite(
    name = "all",
    tests = [
        ":vector_musa_build_test",
    ],
)
