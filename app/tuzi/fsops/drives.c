#include <moonbit.h>
#ifdef _WIN32
#include <windows.h>

// Drive letters occupy the low 26 bits; negative values carry Win32 errors.
MOONBIT_FFI_EXPORT int32_t tuzi_logical_drives(void) {
  DWORD drives = GetLogicalDrives();
  return drives ? (int32_t)drives : -(int32_t)GetLastError();
}
#elif defined(__APPLE__)
#include <errno.h>
#include <string.h>
#include <sys/param.h>
#include <sys/mount.h>

static int browsable_mount(const struct statfs *mount) {
  return !(mount->f_flags & MNT_DONTBROWSE) &&
         strcmp(mount->f_fstypename, "devfs") != 0 &&
         strcmp(mount->f_fstypename, "autofs") != 0;
}

// Copy the borrowed getmntinfo snapshot into a MoonBit FixedArray[Bytes].
MOONBIT_FFI_EXPORT void **tuzi_mount_points(int32_t *error) {
  struct statfs *mounts;
  *error = 0;
  int count = getmntinfo(&mounts, MNT_NOWAIT);
  if (count == 0) {
    *error = errno ? errno : EIO;
    return moonbit_make_ref_array(0, NULL);
  }
  int visible = 0;
  for (int i = 0; i < count; ++i)
    visible += browsable_mount(&mounts[i]);
  void **result = moonbit_make_ref_array(visible, NULL);
  for (int i = 0, next = 0; i < count; ++i) {
    if (!browsable_mount(&mounts[i]))
      continue;
    size_t length = strlen(mounts[i].f_mntonname);
    moonbit_bytes_t path = moonbit_make_bytes((int32_t)length, 0);
    memcpy(path, mounts[i].f_mntonname, length);
    result[next++] = path;
  }
  return result;
}
#elif defined(__linux__)
#include <stdlib.h>

// The shared Unix FFI must link on Linux; only the MacOS branch calls it.
MOONBIT_FFI_EXPORT void **tuzi_mount_points(int32_t *error) {
  (void)error;
  abort();
}
#endif
