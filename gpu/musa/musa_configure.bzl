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
load(
    "//common:common.bzl",
    "err_out",
    "execute",
    "get_python_bin",
)
load("//gpu/musa:musa_redist.bzl", "MUSA_REDIST")

_DISTRIBUTION_PATH = "musa/musa_dist"
_TF_NEED_MUSA = "TF_NEED_MUSA"
_MUSA_PATH = "MUSA_PATH"
_MUSA_HOME = "MUSA_HOME"
_MUSA_VERSION = "MUSA_VERSION"
_MUSA_DEVICE = "MUSA_DEVICE"
_MUSA_DISTRO_URL = "MUSA_DISTRO_URL"
_MUSA_DISTRO_HASH = "MUSA_DISTRO_HASH"
_MUSA_DISTRO_STRIP_PREFIX = "MUSA_DISTRO_STRIP_PREFIX"
_MUSA_DISTRO_ROOT = "MUSA_DISTRO_ROOT"
_MUSA_GPU_ARCHS = "MUSA_GPU_ARCHS"

def auto_configure_fail(msg):
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("\n%sMUSA Configuration Error:%s %s\n" % (red, no_color, msg))

def auto_configure_warning(msg):
    yellow = "\033[1;33m"
    no_color = "\033[0m"
    print("\n%sAuto-Configuration Warning:%s %s\n" % (yellow, no_color, msg))

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

def _canonical_path(p):
    parts = [x for x in p.split("/") if x != ""]
    return paths.join(*parts)

def _remove_root_dir(path, root_dir):
    if path.startswith(root_dir + "/"):
        return path[len(root_dir) + 1:]
    return path

def _split_archs(repository_ctx):
    archs = repository_ctx.os.environ.get(_MUSA_GPU_ARCHS, "")
    return [a.strip() for a in archs.split(",") if a.strip()]

def _find_musa_config(repository_ctx, musa_path):
    python_bin = get_python_bin(repository_ctx)
    result = execute(
        repository_ctx,
        [python_bin, repository_ctx.attr._find_musa_config, musa_path],
        allow_failure = True,
        env_vars = {
            _MUSA_PATH: musa_path,
            _MUSA_DEVICE: repository_ctx.os.environ.get(_MUSA_DEVICE, ""),
            _MUSA_VERSION: repository_ctx.os.environ.get(_MUSA_VERSION, ""),
        },
    )
    if result.return_code:
        auto_configure_fail("Failed to inspect MUSA toolkit: %s" % err_out(result))
    return dict([tuple(x.split(": ", 1)) for x in result.stdout.splitlines()])

def _download_musa_archive(repository_ctx, url, sha256, strip_prefix = ""):
    if not sha256:
        auto_configure_fail("{} is required when {} is set".format(_MUSA_DISTRO_HASH, _MUSA_DISTRO_URL))
    repository_ctx.report_progress("Downloading and extracting MUSA toolkit from {}".format(url))
    kwargs = {
        "url": url,
        "output": _DISTRIBUTION_PATH,
        "sha256": sha256,
    }
    if strip_prefix:
        kwargs["stripPrefix"] = strip_prefix
    repository_ctx.download_and_extract(**kwargs)

def _setup_musa_distro(repository_ctx):
    version = repository_ctx.os.environ.get(_MUSA_VERSION, "")
    if version and version != MUSA_REDIST.version:
        auto_configure_fail("Only MUSA SDK {} is qualified; requested {}".format(MUSA_REDIST.version, version))
    device = repository_ctx.os.environ.get(_MUSA_DEVICE, "")
    if device and device not in ["S4000", "MTT S4000"]:
        auto_configure_fail("Only S4000 is qualified; requested {}".format(device))

    distro_url = repository_ctx.os.environ.get(_MUSA_DISTRO_URL, "")
    local_path = repository_ctx.os.environ.get(_MUSA_PATH, "") or repository_ctx.os.environ.get(_MUSA_HOME, "")
    if not distro_url and local_path:
        if not repository_ctx.path(local_path).exists:
            auto_configure_fail("MUSA toolkit path does not exist: {}".format(local_path))
        auto_configure_warning("Using non-hermetic MUSA from {}".format(local_path))
        repository_ctx.symlink(local_path, _DISTRIBUTION_PATH)
        return _DISTRIBUTION_PATH, ""

    if distro_url:
        sha256 = repository_ctx.os.environ.get(_MUSA_DISTRO_HASH, "")
        root = repository_ctx.os.environ.get(_MUSA_DISTRO_ROOT, ".")
        strip_prefix = repository_ctx.os.environ.get(_MUSA_DISTRO_STRIP_PREFIX, "")
    else:
        distro_url = MUSA_REDIST.url
        sha256 = MUSA_REDIST.sha256
        root = MUSA_REDIST.root
        strip_prefix = ""
    _download_musa_archive(repository_ctx, distro_url, sha256, strip_prefix)
    toolkit_path = _DISTRIBUTION_PATH if root in ["", "."] else _canonical_path("{}/{}".format(_DISTRIBUTION_PATH, root))
    return toolkit_path, sha256

def _write_toolchain_identity(repository_ctx, enabled, musa_root, config, distro_sha256 = ""):
    """Writes the canonical, path-free identity inputs for bridge hashing."""
    architectures = _split_archs(repository_ctx) if enabled else []
    fields = [
        ("schema", "xla-musa-toolchain-v1"),
        ("enabled", "1" if enabled else "0"),
        ("musa_root", musa_root),
        ("musa_version", config.get("musa_version", "0")),
        ("musa_version_number", config.get("musa_version_number", "0")),
        ("musa_device", repository_ctx.os.environ.get(_MUSA_DEVICE, "") if enabled else ""),
        ("musa_gpu_architectures", ",".join(architectures)),
        ("distro_sha256", distro_sha256),
        ("llvm_major", "14"),
        ("mcc", config.get("mcc_path", "__missing_mcc__")),
        ("clang_offload_bundler", "bin/clang-offload-bundler"),
        ("lld", "bin/lld"),
        ("llvm_readobj", "bin/llvm-readobj"),
        ("libclang_cpp", "lib/libclang-cpp.so.14"),
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
    _write_toolchain_identity(repository_ctx, False, "empty", {})
    _tpl(repository_ctx, "musa:build_defs.bzl", stub)

def _setup_musa_repository(repository_ctx):
    musa_toolkit_path, distro_sha256 = _setup_musa_distro(repository_ctx)
    config = _find_musa_config(repository_ctx, musa_toolkit_path)

    if musa_toolkit_path == _DISTRIBUTION_PATH:
        musa_root = "musa_dist"
    else:
        musa_root = _remove_root_dir(musa_toolkit_path, "musa")

    repository_dict = {
        "%{musa_root}": musa_root,
        "%{musa_gpu_architectures}": str(_split_archs(repository_ctx)),
        "%{musa_version}": config.get("musa_version", ""),
        "%{musa_version_number}": config.get("musa_version_number", "0"),
        "%{mcc_path}": config.get("mcc_path", "bin/mcc"),
        "%{musa_path}": "musa_dist" if musa_root == "musa_dist" else musa_root,
        "%{musa_library_paths}": config.get("library_paths", "[]"),
    }
    _tpl(repository_ctx, "musa:BUILD", repository_dict)
    _write_toolchain_identity(repository_ctx, True, musa_root, config, distro_sha256)
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
        _MUSA_PATH,
        _MUSA_HOME,
        _MUSA_VERSION,
        _MUSA_DEVICE,
        _MUSA_DISTRO_URL,
        _MUSA_DISTRO_HASH,
        _MUSA_DISTRO_STRIP_PREFIX,
        _MUSA_DISTRO_ROOT,
        _MUSA_GPU_ARCHS,
    ],
    attrs = {
        "_find_musa_config": attr.label(
            default = Label("//gpu/musa:find_musa_config.py"),
        ),
    },
)
