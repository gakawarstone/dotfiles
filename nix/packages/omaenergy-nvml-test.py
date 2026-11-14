"""Exercise the patched backend without loading NVML or reading hardware."""

import ctypes
import runpy
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock, patch


backend = runpy.run_path(sys.argv.pop(1), run_name="omaenergy_test")
GpuSensor = backend["GpuSensor"]


def write_pointer(pointer, value):
    pointer._obj.value = value


def nvml_library(*, count=1, init_result=0, count_result=0,
                 handle_result=0, power_result=0, limit_result=0):
    def get_count(pointer):
        write_pointer(pointer, count)
        return count_result

    def get_handle(index, pointer):
        write_pointer(pointer, index + 1)
        return handle_result

    def get_power(device, pointer):
        write_pointer(pointer, device.value * 25000)
        return power_result

    def get_limit(device, pointer):
        if limit_result == 0:
            write_pointer(pointer, device.value * 100000)
        return limit_result

    return Mock(
        nvmlInit_v2=Mock(return_value=init_result),
        nvmlDeviceGetCount_v2=Mock(side_effect=get_count),
        nvmlDeviceGetHandleByIndex_v2=Mock(side_effect=get_handle),
        nvmlDeviceGetPowerUsage=Mock(side_effect=get_power),
        nvmlDeviceGetPowerManagementLimit=Mock(side_effect=get_limit),
        nvmlShutdown=Mock(return_value=0),
    )


class NvmlLifecycleTest(unittest.TestCase):
    def setUp(self):
        # Empty hwmon discovery makes these tests independent of the build host.
        self.hwmon = patch.object(Path, "glob", return_value=[])
        self.hwmon.start()
        self.addCleanup(self.hwmon.stop)
        self.loader = patch.object(ctypes, "CDLL")
        self.cdll = self.loader.start()
        self.addCleanup(self.loader.stop)
        self.registration = patch("atexit.register")
        self.register = self.registration.start()
        self.addCleanup(self.registration.stop)

    def test_repeated_unsuccessful_probes_release_each_initialization(self):
        for case in ({"count": 0}, {"count_result": 1},
                     {"handle_result": 1}, {"power_result": 1}):
            with self.subTest(case=case):
                nvml = nvml_library(**case)
                self.cdll.return_value = nvml
                for _ in range(3):
                    self.assertFalse(GpuSensor({"gpu_source": "auto"}).available)
                self.assertEqual(nvml.nvmlInit_v2.call_count, 3)
                self.assertEqual(nvml.nvmlShutdown.call_count, 3)
                self.register.assert_not_called()

    def test_uninitialized_library_needs_no_shutdown(self):
        nvml = nvml_library(init_result=1)
        self.cdll.return_value = nvml
        self.assertFalse(GpuSensor({}).available)
        nvml.nvmlShutdown.assert_not_called()
        nvml.nvmlDeviceGetCount_v2.assert_not_called()
        self.register.assert_not_called()

    def test_missing_library_or_symbol(self):
        self.cdll.side_effect = OSError("library unavailable")
        self.assertFalse(GpuSensor({}).available)
        self.cdll.side_effect = None
        nvml = nvml_library()
        del nvml.nvmlDeviceGetPowerUsage
        self.cdll.return_value = nvml
        self.assertFalse(GpuSensor({}).available)
        nvml.nvmlInit_v2.assert_not_called()
        nvml.nvmlShutdown.assert_not_called()
        self.register.assert_not_called()

    def test_exception_after_initialization_releases_library(self):
        for error in (OSError("device lost"), AttributeError("unavailable"),
                      RuntimeError("unexpected failure")):
            with self.subTest(error=error):
                nvml = nvml_library()
                nvml.nvmlDeviceGetCount_v2.side_effect = error
                self.cdll.return_value = nvml
                if isinstance(error, RuntimeError):
                    with self.assertRaises(RuntimeError):
                        GpuSensor({})
                else:
                    self.assertFalse(GpuSensor({}).available)
                nvml.nvmlShutdown.assert_called_once_with()
                self.register.assert_not_called()

    def test_recovery_keeps_library_until_one_exit_cleanup(self):
        nvml = nvml_library(count=0)
        self.cdll.return_value = nvml
        self.assertFalse(GpuSensor({}).available)
        self.assertFalse(GpuSensor({}).available)
        self.register.assert_not_called()
        def get_two_devices(pointer):
            write_pointer(pointer, 2)
            return 0

        nvml.nvmlDeviceGetCount_v2.side_effect = get_two_devices

        sensor = GpuSensor({})
        self.assertTrue(sensor.available)
        self.assertEqual(str(sensor.path), "nvml:1")
        self.assertEqual(sensor.cap_w, 200.0)
        self.assertEqual(sensor.watts(), 50.0)
        self.assertEqual(nvml.nvmlShutdown.call_count, 2)
        self.register.assert_called_once_with(nvml.nvmlShutdown)
        callback = self.register.call_args.args[0]
        callback()
        self.assertEqual(nvml.nvmlInit_v2.call_count, 3)
        self.assertEqual(nvml.nvmlShutdown.call_count, 3)

    def test_power_limit_is_optional_and_read_failure_returns_zero(self):
        nvml = nvml_library(limit_result=1)
        self.cdll.return_value = nvml
        sensor = GpuSensor({})
        self.assertTrue(sensor.available)
        self.assertEqual(sensor.cap_w, 0.0)
        nvml.nvmlDeviceGetPowerUsage.side_effect = None
        nvml.nvmlDeviceGetPowerUsage.return_value = 1
        self.assertEqual(sensor.watts(), 0.0)
        nvml.nvmlShutdown.assert_not_called()
        self.register.assert_called_once_with(nvml.nvmlShutdown)

    def test_disabled_gpu_does_not_load_nvml(self):
        self.assertFalse(GpuSensor({"gpu_source": "off"}).available)
        self.cdll.assert_not_called()
        self.register.assert_not_called()


if __name__ == "__main__":
    unittest.main()
