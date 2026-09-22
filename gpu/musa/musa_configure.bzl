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

"""Repository rule for Moore Threads MUSA toolkit autoconfiguration."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//gpu/musa:musa_redist.bzl", "MUSA_REDIST")

_DISTRIBUTION_PATH = "musa/musa_dist"
_TF_NEED_MUSA = "TF_NEED_MUSA"
_HERMETIC_MUSA_VERSION = "HERMETIC_MUSA_VERSION"
_HERMETIC_MUSA_GPU_ARCHS = "HERMETIC_MUSA_GPU_ARCHS"

def auto_configure_fail(msg):
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("\n%sMUSA Configuration Error:%s %s\n" % (red, no_color, msg))

def _enable_musa(repository_ctx):
    return repository_ctx.os.environ.get(_TF_NEED_MUSA) == "1"

def _tpl_path(repository_ctx, labelname):
    if labelname.startswith("musa:"):
        return repository_ctx.path(Label("//gpu/musa:%s.tpl" % labelname[5:]))
    return repository_ctx.path(Label("//gpu/musa:%s.tpl" % labelname))

def _tpl(repository_ctx, tpl, substitutions = {}, out = None):
    if not out:
        out = tpl.replace(":", "/")
    repository_ctx.template(
        out,
        _tpl_path(repository_ctx, tpl),
        substitutions,
    )

def _remove_root_dir(path, root_dir):
    if path.startswith(root_dir + "/"):
        return path[len(root_dir) + 1:]
    return path

def _split_archs(repository_ctx):
    archs = repository_ctx.os.environ.get(_HERMETIC_MUSA_GPU_ARCHS, ",".join(MUSA_REDIST.gpu_architectures))
    architectures = [a.strip() for a in archs.split(",")]
    if architectures != MUSA_REDIST.gpu_architectures:
        auto_configure_fail("{} must be {}; requested {}".format(_HERMETIC_MUSA_GPU_ARCHS, ",".join(MUSA_REDIST.gpu_architectures), repr(archs)))
    return architectures

def _is_file(path):
    return path.exists and not path.is_dir

def validate_musa_layout(repository_ctx, musa_path):
    """Checks required files in the checksum-pinned SDK without executing tools.

    Args:
        repository_ctx: The repository context.
        musa_path: The extracted SDK root relative to the repository.
    """
    required = [
        MUSA_REDIST.mcc_path,
        "bin/clang-offload-bundler",
        "bin/lld",
        "bin/llvm-readobj",
        "include/musa.h",
        "include/llvm/Config/llvm-config.h",
        "lib/libclang-cpp.so.{}".format(MUSA_REDIST.llvm_major),
        "mtgpu/bitcode/libdevice.bc",
    ]
    missing = [name for name in required if not _is_file(repository_ctx.path(paths.join(musa_path, name)))]
    libraries = []
    for directory in MUSA_REDIST.library_paths:
        path = repository_ctx.path(paths.join(musa_path, directory))
        if path.is_dir:
            libraries.extend(path.readdir())
    for soname in ["libmusart.so", "libmublas.so", "libmudnn.so", "libmufft.so"]:
        if not any([
            _is_file(path)
            for path in libraries
            if path.basename == soname or path.basename.startswith(soname + ".")
        ]):
            missing.append(soname)
    if missing:
        auto_configure_fail("Missing required components: " + ", ".join(missing))

def _setup_musa_distro(repository_ctx):
    version = repository_ctx.os.environ.get(_HERMETIC_MUSA_VERSION, MUSA_REDIST.version)
    if version != MUSA_REDIST.version:
        auto_configure_fail("{} must be {}; requested {}".format(_HERMETIC_MUSA_VERSION, MUSA_REDIST.version, repr(version)))

    # Reject unsupported targets before downloading or inspecting the SDK.
    _split_archs(repository_ctx)
    repository_ctx.report_progress("Downloading and extracting MUSA toolkit from {}".format(MUSA_REDIST.url))
    repository_ctx.download_and_extract(
        url = MUSA_REDIST.url,
        output = _DISTRIBUTION_PATH,
        sha256 = MUSA_REDIST.sha256,
    )
    return paths.join(_DISTRIBUTION_PATH, MUSA_REDIST.root)

def _write_toolchain_identity(repository_ctx, enabled, musa_root):
    """Writes the canonical, path-free identity inputs for bridge hashing."""
    architectures = _split_archs(repository_ctx) if enabled else []
    fields = [
        ("schema", "xla-musa-toolchain-v1"),
        ("enabled", "1" if enabled else "0"),
        ("musa_root", musa_root),
        ("musa_version", MUSA_REDIST.version if enabled else "0"),
        ("musa_version_number", str(MUSA_REDIST.version_number) if enabled else "0"),
        ("musa_device", MUSA_REDIST.device if enabled else ""),
        ("musa_gpu_architectures", ",".join(architectures)),
        ("distro_sha256", MUSA_REDIST.sha256 if enabled else ""),
        ("llvm_major", str(MUSA_REDIST.llvm_major)),
        ("mcc", MUSA_REDIST.mcc_path if enabled else "__missing_mcc__"),
        ("clang_offload_bundler", "bin/clang-offload-bundler"),
        ("lld", "bin/lld"),
        ("llvm_readobj", "bin/llvm-readobj"),
        ("libclang_cpp", "lib/libclang-cpp.so.{}".format(MUSA_REDIST.llvm_major)),
        ("libdevice", "mtgpu/bitcode/libdevice.bc"),
    ]
    repository_ctx.file(
        "musa/toolchain_identity.txt",
        "".join(["{}={}\n".format(name, value) for name, value in fields]),
    )

def _create_dummy_repository(repository_ctx):
    repository_ctx.file("musa/empty/.keep", "")
    stub = {
        "%{musa_root}": "empty",
        "%{musa_gpu_architectures}": "[]",
        "%{musa_version}": "0",
        "%{musa_version_number}": "0",
        "%{mcc_path}": "__missing_mcc__",
        "%{musa_path}": "empty",
        "%{musa_library_paths}": "[]",
    }
    _tpl(repository_ctx, "musa:BUILD", stub)
    _write_toolchain_identity(repository_ctx, False, "empty")
    _tpl(repository_ctx, "musa:build_defs.bzl", stub)

def _setup_musa_repository(repository_ctx):
    musa_toolkit_path = _setup_musa_distro(repository_ctx)
    validate_musa_layout(repository_ctx, musa_toolkit_path)

    musa_root = _remove_root_dir(musa_toolkit_path, "musa")

    repository_dict = {
        "%{musa_root}": musa_root,
        "%{musa_gpu_architectures}": str(_split_archs(repository_ctx)),
        "%{musa_version}": MUSA_REDIST.version,
        "%{musa_version_number}": str(MUSA_REDIST.version_number),
        "%{mcc_path}": MUSA_REDIST.mcc_path,
        "%{musa_path}": musa_root,
        "%{musa_library_paths}": str(MUSA_REDIST.library_paths),
    }
    _tpl(repository_ctx, "musa:BUILD", repository_dict)
    _write_toolchain_identity(repository_ctx, True, musa_root)
    _tpl(repository_ctx, "musa:build_defs.bzl", repository_dict)

def _musa_autoconf_impl(repository_ctx):
    if not _enable_musa(repository_ctx):
        _create_dummy_repository(repository_ctx)
    else:
        _setup_musa_repository(repository_ctx)

musa_configure = repository_rule(
    implementation = _musa_autoconf_impl,
    environ = [
        _TF_NEED_MUSA,
        _HERMETIC_MUSA_VERSION,
        _HERMETIC_MUSA_GPU_ARCHS,
    ],
)
