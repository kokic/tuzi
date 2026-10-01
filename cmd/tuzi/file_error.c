#include <moonbit.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <errno.h>
#endif

MOONBIT_FFI_EXPORT int32_t tuzi_is_cross_device_error(int32_t code) {
#ifdef _WIN32
  return code == ERROR_NOT_SAME_DEVICE;
#else
  return code == EXDEV;
#endif
}
