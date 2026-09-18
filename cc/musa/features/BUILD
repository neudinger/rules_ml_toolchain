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

"""MUSA-specific toolchain features."""

load(
    "//third_party/rules_cc_toolchain/features:features.bzl",
    "cc_feature",
)

package(default_visibility = ["//visibility:public"])

cc_feature(
    name = "musa_defines",
    compiler_flags = [
        "-DTENSORFLOW_USE_MUSA=1",
        "-DMUSA_ENABLED=1",
        "-DUSE_MUSA=1",
    ],
    enabled = True,
)

cc_feature(
    name = "musa_compiler_rt",
    compiler_flags = ["-rtlib=compiler-rt"],
    enabled = True,
    linker_flags = ["-rtlib=compiler-rt"],
)
