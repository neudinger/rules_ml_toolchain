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

load("@rules_cc//cc:defs.bzl", "cc_library")

licenses(["restricted"])

package(default_visibility = ["//visibility:private"])

exports_files(
    ["musa_dist"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "all_files",
    srcs = glob(["%{musa_root}/**"], allow_empty = True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "musa_root",
    srcs = [":all_files"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "mcc",
    srcs = glob(["%{musa_root}/%{mcc_path}"], allow_empty = True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_offload_bundler",
    srcs = glob(["%{musa_root}/bin/clang-offload-bundler"], allow_empty = True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "lld",
    srcs = glob(["%{musa_root}/bin/lld"], allow_empty = True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "llvm_readobj",
    srcs = glob(["%{musa_root}/bin/llvm-readobj"], allow_empty = True),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "libdevice",
    srcs = glob(["%{musa_root}/mtgpu/bitcode/libdevice.bc"], allow_empty = True),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "musa_llvm14_headers",
    defines = ["__MTGPU__"],
    hdrs = glob(
        [
            "%{musa_root}/include/clang/**/*.h",
            "%{musa_root}/include/clang-c/**/*.h",
            "%{musa_root}/include/lld/**/*.h",
            "%{musa_root}/include/llvm/**/*.h",
            "%{musa_root}/include/llvm-c/**/*.h",
        ],
        allow_empty = True,
    ),
    textual_hdrs = glob(
        [
            "%{musa_root}/include/clang/**/*.def",
            "%{musa_root}/include/clang/**/*.inc",
            "%{musa_root}/include/clang/**/*.td",
            "%{musa_root}/include/lld/**/*.def",
            "%{musa_root}/include/lld/**/*.inc",
            "%{musa_root}/include/lld/**/*.td",
            "%{musa_root}/include/llvm/**/*.def",
            "%{musa_root}/include/llvm/**/*.inc",
            "%{musa_root}/include/llvm/**/*.td",
        ],
        allow_empty = True,
    ),
    includes = ["%{musa_root}/include"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "libclang_cpp_file",
    srcs = glob(["%{musa_root}/lib/libclang-cpp.so.14"], allow_empty = True),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "libclang_cpp",
    srcs = [":libclang_cpp_file"],
    visibility = ["//visibility:public"],
)


cc_library(
    name = "musa_llvm14",
    visibility = ["//visibility:public"],
    deps = [
        ":libclang_cpp",
        ":musa_llvm14_headers",
    ],
)

filegroup(
    name = "toolchain_data",
    srcs = ["toolchain_identity.txt"] + glob(
        [
            "%{musa_root}/bin/**",
            "%{musa_root}/include/**",
            "%{musa_root}/lib/**",
            "%{musa_root}/lib64/**",
            "%{musa_root}/mtgpu/**",
        ],
        allow_empty = True,
    ),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "toolchain_identity",
    srcs = ["toolchain_identity.txt"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "musa_headers",
    hdrs = glob(["%{musa_root}/include/**/*.h"], allow_empty = True),
    includes = ["%{musa_root}/include"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "musa_runtime",
    hdrs = glob(["%{musa_root}/include/**/*.h"], allow_empty = True),
    includes = ["%{musa_root}/include"],
    srcs = glob(["%{musa_root}/**/libmusart.so*"], allow_empty = True),
    visibility = ["//visibility:public"],
)

alias(
    name = "musart",
    actual = ":musa_runtime",
    visibility = ["//visibility:public"],
)


cc_library(
    name = "mublas",
    hdrs = glob(["%{musa_root}/include/**/*.h"], allow_empty = True),
    includes = ["%{musa_root}/include"],
    srcs = glob(["%{musa_root}/**/libmublas.so*"], allow_empty = True),
    visibility = ["//visibility:public"],
)

# The embedded XLA muFFT adapter links this SDK library in isolation.
# The core PJRT plugin remains free of vendor-library link edges.
cc_library(
    name = "mufft",
    hdrs = glob(["%{musa_root}/include/**/*.h"], allow_empty = True),
    includes = ["%{musa_root}/include"],
    srcs = glob(["%{musa_root}/**/libmufft.so*"], allow_empty = True),
    data = glob([
        "%{musa_root}/**/libmtfft-device-*.so*",
        "%{musa_root}/**/libmusart.so*",
    ], allow_empty = True),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "mudnn",
    hdrs = glob(["%{musa_root}/include/**/*.h"], allow_empty = True),
    includes = ["%{musa_root}/include"],
    srcs = glob(["%{musa_root}/**/libmudnn.so*"], allow_empty = True),
    data = glob(
        ["%{musa_root}/**/libmudnn_*.so*"], allow_empty = True,
    ),
    visibility = ["//visibility:public"],
)



config_setting(
    name = "using_musa",
    define_values = {
        "using_musa": "true",
    },
    visibility = ["//visibility:public"],
)
