///|
#cfg(platform="windows")
async fn link_powershell(
  script : String,
  paths : Map[String, String],
) -> String {
  link_command(
    "powershell.exe",
    ["-NoProfile", "-NonInteractive", "-Command", script],
    extra_env=paths,
  )
}

///|
#cfg(platform="windows")
async fn read_link_text(path : Path) -> String {
  let output = link_powershell(
    (
      #|$ErrorActionPreference = 'Stop'
      #|[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
      #|try {
      #|  $item = Get-Item -LiteralPath $env:TUZI_LINK_SOURCE -Force
      #|  if ($item.LinkType -notin @('Junction', 'SymbolicLink')) { throw 'Not a supported link' }
      #|  ConvertTo-Json -InputObject ([string]$item.Target[0]) -Compress
      #|} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
    ),
    { "TUZI_LINK_SOURCE": path.to_native() },
  )
  @json.from_json(@json.parse(output))
}

///|
#cfg(platform="windows")
async fn create_link_like(
  source : Path,
  destination : Path,
  target : Path,
) -> Unit {
  ignore(
    link_powershell(
      (
        #|$ErrorActionPreference = 'Stop'
        #|[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
        #|try {
        #|  $item = Get-Item -LiteralPath $env:TUZI_LINK_SOURCE -Force
        #|  if ($item.LinkType -notin @('Junction', 'SymbolicLink')) { throw 'Not a supported link' }
        #|  $target = [System.Management.Automation.WildcardPattern]::Escape($env:TUZI_LINK_TARGET)
        #|  New-Item -ItemType $item.LinkType -Path $env:TUZI_LINK_DESTINATION -Target $target | Out-Null
        #|} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
      ),
      {
        "TUZI_LINK_SOURCE": source.to_native(),
        "TUZI_LINK_DESTINATION": destination.to_native(),
        "TUZI_LINK_TARGET": target.to_native(),
      },
    ),
  )
}

///|
/// FileInfo/DirectoryInfo.MoveTo moves the link entry without opening its target.
#cfg(platform="windows")
async fn relocate_link(source : Path, destination : Path) -> Unit {
  ignore(
    link_powershell(
      (
        #|$ErrorActionPreference = 'Stop'
        #|[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
        #|try {
        #|  $item = Get-Item -LiteralPath $env:TUZI_LINK_SOURCE -Force
        #|  if ($item.LinkType -notin @('Junction', 'SymbolicLink')) { throw 'Not a supported link' }
        #|  $item.MoveTo($env:TUZI_LINK_DESTINATION)
        #|} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
      ),
      {
        "TUZI_LINK_SOURCE": source.to_native(),
        "TUZI_LINK_DESTINATION": destination.to_native(),
      },
    ),
  )
}
