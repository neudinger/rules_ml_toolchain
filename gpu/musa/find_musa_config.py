#!/usr/bin/env python3
#
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

"""Validate the qualified SDK used by the MUSA compiler and embedded adapters."""

import os
import re
import subprocess
import sys


def inspect_sdk(root, requested_version=""):
    required = [
        "bin/mcc",
        "bin/clang-offload-bundler",
        "bin/lld",
        "bin/llvm-readobj",
        "include/musa.h",
        "include/llvm/Config/llvm-config.h",
        "lib/libclang-cpp.so.14",
        "mtgpu/bitcode/libdevice.bc",
    ]
    missing = [path for path in required if not os.path.isfile(os.path.join(root, path))]
    library_paths = set()
    for soname in ("libmusart.so", "libmublas.so", "libmudnn.so", "libmufft.so"):
        found = False
        for directory in ("lib", "lib64"):
            path = os.path.join(root, directory)
            if os.path.isdir(path) and any(
                (name == soname or name.startswith(soname + "."))
                and os.path.isfile(os.path.join(path, name))
                for name in os.listdir(path)
            ):
                library_paths.add(directory)
                found = True
                break
        if not found:
            missing.append(soname)
    if missing:
        raise ValueError("Missing required components: " + ", ".join(missing))

    output = subprocess.check_output(
        [os.path.join(root, "bin/mcc"), "--version"],
        stderr=subprocess.STDOUT,
        text=True,
    )
    match = re.search(r"(?m)^mcc version (\d+\.\d+\.\d+)\b", output)
    version = match.group(1) if match else ""
    if version != "5.1.0":
        raise ValueError("Expected MUSA SDK 5.1.0; mcc reports " + repr(version))
    if requested_version and requested_version != version:
        raise ValueError("MUSA_VERSION does not match mcc: " + requested_version)
    if not re.search(r"(?m)^clang version 14\.", output):
        raise ValueError("MUSA SDK must provide the qualified LLVM 14 compiler")
    return {
        "musa_version": version,
        "musa_version_number": "50100",
        "mcc_path": "bin/mcc",
        "library_paths": repr(sorted(library_paths)),
    }


def main():
    root = os.path.realpath(sys.argv[1] if len(sys.argv) > 1 else os.environ.get("MUSA_PATH", ""))
    try:
        config = inspect_sdk(root, os.environ.get("MUSA_VERSION", ""))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.stderr.write("Invalid MUSA toolkit at '{}': {}\n".format(root, error))
        return 1
    for key, value in config.items():
        print("{}: {}".format(key, value))
    return 0


if __name__ == "__main__":
    sys.exit(main())
