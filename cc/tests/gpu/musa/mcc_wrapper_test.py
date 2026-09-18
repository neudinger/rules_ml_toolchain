"""Regression tests for hermetic dispatch and parameter-file boundaries."""

import importlib.machinery
import importlib.util
import os
import pathlib
import tempfile
import unittest
from unittest import mock


WRAPPER = pathlib.Path(__file__).resolve().parents[3] / (
    "impls/linux_x86_64_linux_x86_64_musa/wrappers/mcc_wrapper"
)
loader = importlib.machinery.SourceFileLoader("mcc_wrapper", str(WRAPPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
wrapper = importlib.util.module_from_spec(spec)
loader.exec_module(wrapper)


class WrapperTest(unittest.TestCase):
    def test_missing_configuration_does_not_use_host_tools(self):
        with mock.patch.dict(os.environ, {}, clear=True), mock.patch.object(
            wrapper.subprocess, "call"
        ) as call:
            self.assertEqual(wrapper.main(), 1)
            call.assert_not_called()

    def test_parameter_file_preserves_spaces_and_exit_status(self):
        with tempfile.TemporaryDirectory() as directory:
            params = pathlib.Path(directory) / "args"
            params.write_text("-c\n-x\nmusa\nsource with spaces.cc\n-o\nout.o\n")
            with mock.patch.dict(os.environ, {
                "GCC_PATH": "/configured/clang",
                "MCC_PATH": "/configured/mcc",
                "MUSA_PATH": "/configured/sdk",
            }), mock.patch.object(wrapper.sys, "argv", [str(WRAPPER), "@" + str(params)]), mock.patch.object(
                wrapper, "InvokeMcc", return_value=23
            ) as invoke:
                self.assertEqual(wrapper.main(), 23)
                invoke.assert_called_once_with(
                    ["-c", "source with spaces.cc", "-o", "out.o"], False
                )

    def test_host_sysroot_is_preserved(self):
        args = ["-c", "--sysroot=configured", "-isystem", "external/sysroot_usr/include",
                "--musa-path=sdk", "--offload-arch=mp_22"]
        self.assertEqual(wrapper.FilterHostFlags(args), args[:4])


if __name__ == "__main__":
    unittest.main()
