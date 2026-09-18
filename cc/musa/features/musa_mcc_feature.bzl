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

"""MUSA MCC feature rule for feature-based toolchain configuration."""

load(
    "@rules_cc//cc:action_names.bzl",
    "ACTION_NAMES",
    "ALL_CC_COMPILE_ACTION_NAMES",
    "CC_LINK_EXECUTABLE_ACTION_NAMES",
    "DYNAMIC_LIBRARY_LINK_ACTION_NAMES",
)
load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "FeatureInfo",
    "env_entry",
    "env_set",
    "flag_group",
    "flag_set",
    _feature = "feature",
)

ALL_ACTIONS = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cc_flags_make_variable,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.lto_indexing,
    ACTION_NAMES.lto_backend,
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.cpp_link_static_library,
    ACTION_NAMES.clif_match,
]

def _join_path(root, package, path):
    if path:
        return root + "/" + package + "/" + path
    return root + "/" + package

def _musa_mcc_feature_impl(ctx):
    workspace_root = ctx.attr.musa_toolkit.label.workspace_root
    package = ctx.attr.musa_toolkit.label.package
    musa_path = _join_path(workspace_root, package, ctx.attr.musa_path)
    mcc_path = _join_path(workspace_root, package, ctx.attr.musa_path + "/" + ctx.attr.mcc_path)

    library_paths = [musa_path + "/" + path for path in ctx.attr.library_paths]
    if not library_paths:
        library_paths = [
            musa_path + "/lib",
            musa_path + "/lib64",
        ]
    env_entries = [
        env_entry("MCC_PATH", mcc_path),
        env_entry("MUSA_PATH", musa_path),
        env_entry("MUSA_LIBRARY_PATH", ":".join(library_paths)),
    ]
    if ctx.attr.gpu_architectures:
        env_entries.append(env_entry("MUSA_GPU_ARCHS", ",".join(ctx.attr.gpu_architectures)))

    common_flags = ["--musa-path=" + musa_path]
    for arch in ctx.attr.gpu_architectures:
        common_flags.append("--offload-arch=" + arch)

    return _feature(
        name = ctx.label.name,
        enabled = ctx.attr.enabled,
        provides = ctx.attr.provides,
        flag_sets = [
            flag_set(
                actions = CC_LINK_EXECUTABLE_ACTION_NAMES +
                          DYNAMIC_LIBRARY_LINK_ACTION_NAMES +
                          ALL_CC_COMPILE_ACTION_NAMES,
                flag_groups = [
                    flag_group(flags = common_flags),
                ],
            ),
        ],
        env_sets = [env_set(
            actions = ALL_ACTIONS,
            env_entries = env_entries,
        )],
    )

musa_mcc_feature = rule(
    implementation = _musa_mcc_feature_impl,
    attrs = {
        "enabled": attr.bool(default = True),
        "provides": attr.string_list(),
        "musa_toolkit": attr.label(
            mandatory = True,
            doc = "Label pointing to the MUSA toolkit root.",
        ),
        "gpu_architectures": attr.string_list(
            default = [],
            doc = "MUSA target architectures, for example mp_21 or mp_22.",
        ),
        "library_paths": attr.string_list(
            default = [],
            doc = "Library directories relative to the MUSA toolkit root.",
        ),
        "musa_path": attr.string(
            mandatory = True,
            doc = "Path to the MUSA installation directory inside the configured repository.",
        ),
        "mcc_path": attr.string(
            mandatory = True,
            doc = "Path to mcc relative to musa_path.",
        ),
    },
    provides = [FeatureInfo],
)
