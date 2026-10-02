#include <moonbit.h>
#ifdef _WIN32
#include <windows.h>

// Drive letters occupy the low 26 bits; negative values carry Win32 errors.
MOONBIT_FFI_EXPORT int32_t tuzi_logical_drives(void) {
  DWORD drives = GetLogicalDrives();
  return drives ? (int32_t)drives : -(int32_t)GetLastError();
}
#endif
