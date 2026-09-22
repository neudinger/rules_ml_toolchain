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

# ==============================================================================
# Tools: Linux x86_64, Sysroot: Linux x86_64, MUSA
# ==============================================================================

load("@local_config_musa//musa:build_defs.bzl", "musa_config")
load("@rules_cc//cc:defs.bzl", "cc_toolchain")
load("//cc/config:constants.bzl", "LIBCXX_FLAGS")
load("//cc/musa/features:musa_mcc_feature.bzl", "musa_mcc_feature")
load("//third_party/rules_cc_toolchain:toolchain_config.bzl", "cc_toolchain_config")
load("//third_party/rules_cc_toolchain/features:cc_toolchain_import.bzl", "cc_toolchain_import")
load("//third_party/rules_cc_toolchain/features:features.bzl", "cc_feature", "cc_toolchain_import_feature")

package(
    default_visibility = [
        "//cc:__pkg__",
    ],
)

MUSA_TOOLS = {
    "gcc": "wrappers/mcc_wrapper",
    "cpp": "wrappers/clang++",
    "ld": "wrappers/ld",
    "ar": "wrappers/ar",
    "gcov": "wrappers/idler",
    "llvm-cov": "wrappers/idler",
    "nm": "wrappers/idler",
    "objdump": "wrappers/idler",
    "strip": "wrappers/idler",
}

musa_mcc_feature(
    name = "musa_mcc_feature",
    enabled = True,
    gpu_architectures = musa_config().gpu_architectures,
    library_paths = musa_config().library_paths,
    mcc_path = musa_config().mcc_path,
    musa_path = musa_config().musa_path,
    musa_toolkit = "@local_config_musa//musa:musa_root",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "wrappers",
    srcs = [
        "//cc/impls/linux_x86_64_linux_x86_64_musa/wrappers:all",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "musa_toolkit_files",
    srcs = [
        "@local_config_musa//musa:toolchain_data",
    ],
)

alias(
    name = "startup_libs",
    actual = "@sysroot_linux_x86_64//:startup_libs",
    visibility = ["//visibility:public"],
)

cc_toolchain_import_feature(
    name = "startup_libs_feature",
    enabled = select({
        "//common:is_hermetic_libraries_enabled": True,
        "//conditions:default": False,
    }),
    toolchain_import = ":startup_libs",
)

alias(
    name = "std_incs",
    actual = select({
        "//common:is_stdlib_libcxx": "@llvm_linux_x86_64//:std_incs",
        "//conditions:default": "@sysroot_linux_x86_64//:std_incs",
    }),
)

alias(
    name = "std_libs",
    actual = select({
        "//common:is_stdlib_libcxx": "@llvm_linux_x86_64//:std_libs",
        "//conditions:default": "@sysroot_linux_x86_64//:std_libs",
    }),
)

# buildifier: leave-alone
cc_toolchain_import(
    name = "imports",
    deps = [
        ":std_incs",
        "@llvm_linux_x86_64//:compiler_incs",
        "@sysroot_linux_x86_64//:sys_incs",
        ":std_libs",
        "@sysroot_linux_x86_64//:sys_libs",
        "@llvm_linux_x86_64//:libclang_rt",
    ],
    visibility = ["//visibility:public"],
)

cc_toolchain_import_feature(
    name = "imports_feature",
    enabled = True,
    static_link_flags = select({
        "//common:is_static_libcxx": LIBCXX_FLAGS,
        "//conditions:default": [],
    }),
    toolchain_import = ":imports",
)

cc_feature(
    name = "hermetic_libraries_conditional",
    cc_flags = ["-nostdinc++"],
    compiler_flags = ["-nostdinc"],
    enabled = select({
        "//common:is_hermetic_libraries_enabled": True,
        "//conditions:default": False,
    }),
    linker_flags = [
        "-nostdlib",
        "-nodefaultlibs",
    ],
)

# buildifier: leave-alone
filegroup(
    name = "all",
    srcs = [
        ":imports",
        ":musa_toolkit_files",
        ":startup_libs",
        ":wrappers",
        "@llvm_linux_x86_64//:all",
    ],
)

# buildifier: leave-alone
filegroup(
    name = "compiler",
    srcs = [
        ":imports",
        ":musa_toolkit_files",
        ":wrappers",
        "@llvm_linux_x86_64//:clang",
        "@llvm_linux_x86_64//:clang++",
        "@llvm_linux_x86_64//:distro_libs",
    ],
)

# buildifier: leave-alone
filegroup(
    name = "linker",
    srcs = [
        ":compiler",
        ":startup_libs",
        ":wrappers",
        "@llvm_linux_x86_64//:distro_libs",
        "@llvm_linux_x86_64//:ld",
    ],
)

# buildifier: leave-alone
filegroup(
    name = "ar",
    srcs = [
        ":wrappers",
        "@llvm_linux_x86_64//:ar",
        "@llvm_linux_x86_64//:distro_libs",
    ],
)

# buildifier: leave-alone
filegroup(
    name = "strip",
    srcs = [
        ":wrappers",
        "@llvm_linux_x86_64//:distro_libs",
        "@llvm_linux_x86_64//:strip",
    ],
)

FEATURES_ESSENTIAL = [
    ":hermetic_libraries_conditional",
    ":imports_feature",
    ":startup_libs_feature",
    ":musa_mcc_feature",
    "//cc/musa/features:musa_defines",
    "//cc/musa/features:musa_compiler_rt",
    "//third_party/rules_cc_toolchain/features:warnings",
    "//third_party/rules_cc_toolchain/features:reproducible",
    "//third_party/rules_cc_toolchain/features:use_lld",
    "//cc/features/linux_x86_64:sysroot",
    "//third_party/rules_cc_toolchain/features:supports_pic",
    "//third_party/rules_cc_toolchain/features:position_independent_code",
    "//third_party/rules_cc_toolchain/features:position_independent_executable",
    "//third_party/rules_cc_toolchain/features:garbage_collect_symbols",
    "//cc/features:constants_merge",
    "//cc/features:dbg",
    "//cc/features:fastbuild",
    "//cc/features:opt",
    "//cc/features:detect_issues",
    "//third_party/rules_cc_toolchain/features:c++17",
    "//cc/features:allow_shlib_undefined",
    "//cc/features:supports_dynamic_linker",
    "//cc/features:supports_start_end_lib_feature",
]

cc_toolchain_config(
    name = "config",
    archiver = "@llvm_linux_x86_64//:ar",
    c_compiler = "@llvm_linux_x86_64//:clang",
    cc_compiler = "@llvm_linux_x86_64//:clang++",
    compiler_features = FEATURES_ESSENTIAL,
    cxx_builtin_include_directories = [],
    linker = "@llvm_linux_x86_64//:ld",
    strip_tool = "@llvm_linux_x86_64//:strip",
    target_cpu = "x86_64",
    target_system_name = "local",
    tool_paths = MUSA_TOOLS,
)

cc_toolchain(
    name = "toolchain",
    all_files = ":all",
    ar_files = ":ar",
    as_files = ":compiler",
    compiler_files = ":compiler",
    dwp_files = ":all",
    linker_files = ":linker",
    objcopy_files = ":all",
    strip_files = ":strip",
    supports_param_files = 1,
    toolchain_config = ":config",
    toolchain_identifier = "toolchain_linux_x86_64_linux_x86_64_musa_id",
)
