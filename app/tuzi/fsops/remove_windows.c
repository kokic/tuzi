#include <moonbit.h>

#ifdef _WIN32
#include <windows.h>

MOONBIT_FFI_EXPORT int32_t tuzi_clear_readonly(moonbit_string_t path) {
  DWORD attrs = GetFileAttributesW((LPCWSTR)path);
  if (attrs == INVALID_FILE_ATTRIBUTES)
    return -(int32_t)GetLastError();
  // Never change the target of a link, nor attributes on directories.
  if ((attrs & (FILE_ATTRIBUTE_REPARSE_POINT | FILE_ATTRIBUTE_DIRECTORY)) ||
      !(attrs & FILE_ATTRIBUTE_READONLY))
    return 0;
  DWORD writable = attrs & ~FILE_ATTRIBUTE_READONLY;
  if (!SetFileAttributesW((LPCWSTR)path,
                         writable ? writable : FILE_ATTRIBUTE_NORMAL))
    return -(int32_t)GetLastError();
  return 1;
}
#endif
