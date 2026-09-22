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

"""MUSA module extension for Moore Threads GPU toolchain configuration."""

load("//gpu/musa:musa_configure.bzl", "musa_configure")

def _musa_configure_ext_impl(mctx):
    musa_configure(name = "local_config_musa")

musa_configure_ext = module_extension(
    implementation = _musa_configure_ext_impl,
    doc = """MUSA module extension for configuring the Moore Threads GPU toolchain.""",
)
