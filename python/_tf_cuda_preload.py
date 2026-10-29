"""Make pip-installed CUDA libraries (site-packages/nvidia/*/lib) visible to TensorFlow.

TensorFlow's wheel does not search those directories, so the GPU is silently skipped.
Preloading them by soname right before `import tensorflow` fixes that without
LD_LIBRARY_PATH. Local to this venv; harmless for processes that never import TensorFlow.
"""
import ctypes
import glob
import os
import sys

_ORDER = ("cuda_runtime", "cuda_nvrtc", "nvjitlink", "cublas", "cufft", "curand", "cusparse",
          "cusolver", "cudnn", "cuda_cupti", "nccl")


def _preload():
    root = next((os.path.join(p, "nvidia") for p in sys.path if os.path.isdir(os.path.join(p, "nvidia"))), None)
    if root is None:
        return
    for pkg in _ORDER:
        for lib in sorted(glob.glob(os.path.join(root, pkg, "lib", "lib*.so*"))):
            try:
                ctypes.CDLL(lib, mode=ctypes.RTLD_GLOBAL)
            except OSError:
                pass


class _Finder:
    def find_spec(self, name, path=None, target=None):
        if name == "tensorflow":
            sys.meta_path.remove(self)
            _preload()
        return None


sys.meta_path.insert(0, _Finder())
