param([int]$BuildNumber = 9)
cd C:\dev\kj_delivery_fresh
$defines = @()
Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*)$') {
    $val = $matches[2].Trim([char]34, [char]39)
    $defines += "--dart-define=$($matches[1])=$val"
  }
}
flutter build apk --release --target-platform android-arm64 --build-number $BuildNumber @defines
if ($LASTEXITCODE -eq 0) {
  $apk = "build\app\outputs\flutter-apk\app-release.apk"
  adb install -r -d $apk
}
