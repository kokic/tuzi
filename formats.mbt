///|
let image_formats : ReadOnlyArray[String] = [
  "jpg", "jpeg", "jpe", "jfif", "png", "gif", "bmp", "dib", "tif", "tiff", "webp",
  "avif", "heic", "heif", "svg", "svgz", "ico", "cur", "psd", "psb", "ai", "eps",
  "xcf", "sketch", "fig", "raw", "arw", "cr2", "cr3", "nef", "nrw", "orf", "rw2",
  "raf", "pef", "dng", "sr2", "srf", "3fr", "fff", "iiq", "mos", "mrw", "erf", "kdc",
  "x3f", "rwl", "srw", "mef", "mdc", "cap", "dcr", "jp2", "j2k", "jpf", "jpx", "jpm",
  "mj2", "pbm", "pgm", "ppm", "pnm", "pfm", "pam", "exr", "hdr", "rgbe", "pic", "tga",
  "icns", "wbmp", "xbm", "xpm", "dds", "ktx", "ktx2", "basis", "astc", "pvr", "emf",
  "wmf", "cgm", "fits", "fit", "fts", "qoi", "flif", "bpg", "apng", "mng", "jng",
]

///|
let video_formats : ReadOnlyArray[String] = [
  "mp4", "avi", "mkv", "mov", "wmv", "flv", "f4v", "webm", "m4v", "mpg", "mpeg",
  "mpeg1", "mpeg2", "mpeg4", "vob", "rm", "rmvb", "3gp", "3g2", "asf", "ogv", "mts",
  "m2ts", "divx", "xvid", "amv", "dav", "fli", "flc", "dv", "hdv", "mxf", "r3d",
  "braw", "ari", "dng", "yuv", "rgb", "raw", "m3u8", "mpd", "gif", "apng", "swf",
  "qt", "viv", "nsv", "roq", "smk", "bik", "cam", "mpv", "m1v", "m2v",
]

///|
let font_formats : ReadOnlyArray[String] = [
  "ttf", "otf", "ttc", "otc", "woff", "woff2", "eot", "pfb", "pfm", "pfa", "afm",
  "fon", "fnt", "bdf", "pcf", "snf", "dfont", "suit", "sfd", "ufo", "glyphs", "vfb",
  "vfj", "gxf", "pm", "acfm", "amfm", "cff", "cid", "fot", "pfr", "pt3", "t42", "tte",
]

///|
let moonbit_formats : ReadOnlyArray[String] = ["mbt", "mbti", "mbtx", "mbtp"]

///|
let shell_formats : ReadOnlyArray[String] = [
  "sh", "bash", "zsh", "fish", "csh", "tcsh", "bat", "cmd", "ps1",
]

///|
let audio_formats : ReadOnlyArray[String] = [
  "mp3", "wav", "flac", "aac", "m4a", "ogg", "oga", "opus", "wma", "aiff", "aif",
  "alac", "mid", "midi",
]

///|
let archive_formats : ReadOnlyArray[String] = [
  "zip", "tar", "gz", "tgz", "bz2", "tbz", "xz", "txz", "lz", "tlz", "lzo", "zst",
  "7z", "rar", "cab", "jar", "war", "ear", "apk", "ipa", "deb", "rpm", "ar", "z",
  "lz4", "br", "ace", "arc", "lha", "lzh", "zoo", "sit", "tbz2", "lzma", "tzst",
  "cpio", "sitx",
]
