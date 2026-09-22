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

"""Qualified MUSA SDK for the S4000 / mp_22 toolchain."""

MUSA_REDIST = struct(
    version = "5.1.0",
    version_number = 50100,
    llvm_major = 14,
    mcc_path = "bin/mcc",
    library_paths = ["lib"],
    gpu_architectures = ["mp_22"],
    device = "S4000",
    url = "https://github.com/neudinger/rules-ml-toolchain-redists/releases/download/musa-v5.1.0-musa_sdk_5_1_0_cc2_2_deb-ubuntu-x86_64/musa-toolkit-5.1.0-musa_sdk_5_1_0_cc2_2_deb-ubuntu-x86_64.tar.zst",
    sha256 = "afa05b1e73c4816e063fb695c889e37877599aa021a4ef8dba08998c1f3b1f9f",
    root = "musa",
)
