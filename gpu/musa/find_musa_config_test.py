"""Focused validation of the qualified MUSA SDK contract."""

import pathlib
import tempfile
import unittest
from unittest import mock

import find_musa_config


class SdkConfigTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = pathlib.Path(self.directory.name)
        for name in (
            "bin/mcc", "bin/clang-offload-bundler", "bin/lld", "bin/llvm-readobj",
            "include/musa.h", "include/llvm/Config/llvm-config.h",
            "lib/libclang-cpp.so.14", "mtgpu/bitcode/libdevice.bc",
            "lib/libmusart.so.5", "lib/libmublas.so.5",
            "lib/libmudnn.so.1", "lib/libmufft.so.1",
        ):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.touch()

    def inspect(self, output="clang version 14.0.0\nmcc version 5.1.0\n", requested=""):
        with mock.patch("subprocess.check_output", return_value=output):
            return find_musa_config.inspect_sdk(str(self.root), requested)

    def test_reads_mcc_version_instead_of_clang_version(self):
        config = self.inspect()
        self.assertEqual(config["musa_version"], "5.1.0")
        self.assertEqual(config["musa_version_number"], "50100")
        self.assertEqual(config["library_paths"], "['lib']")

    def test_environment_cannot_disguise_incompatible_sdk(self):
        with self.assertRaisesRegex(ValueError, "Expected MUSA SDK"):
            self.inspect("clang version 14.0.0\nmcc version 5.0.0\n", "5.1.0")

    def test_rejects_mismatched_requested_version(self):
        with self.assertRaisesRegex(ValueError, "does not match"):
            self.inspect(requested="5.0.0")

    def test_rejects_wrong_llvm(self):
        with self.assertRaisesRegex(ValueError, "LLVM 14"):
            self.inspect("clang version 18.0.0\nmcc version 5.1.0\n")

    def test_reports_missing_bridge_and_adapter_inputs(self):
        (self.root / "bin/lld").unlink()
        (self.root / "lib/libmufft.so.1").unlink()
        with self.assertRaisesRegex(ValueError, "bin/lld, libmufft.so"):
            self.inspect()

    def test_rejects_broken_library_symlink(self):
        library = self.root / "lib/libmudnn.so.1"
        library.unlink()
        library.symlink_to("missing.so")
        with self.assertRaisesRegex(ValueError, "libmudnn.so"):
            self.inspect()


if __name__ == "__main__":
    unittest.main()
