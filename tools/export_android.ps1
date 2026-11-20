param(
    [string]$GodotPath,
    [string]$JavaSdk=$env:JAVA_HOME,
    [string]$AndroidSdk=$env:ANDROID_HOME,
    [string]$OutputPath
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$localTools=Join-Path $env:LOCALAPPDATA 'HunterLifeBuild'
if(-not $GodotPath){
    $candidate=Join-Path (Split-Path $projectRoot -Parent) 'Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
    if(Test-Path -LiteralPath $candidate){$GodotPath=$candidate}else{throw 'Informe -GodotPath com o executável Godot 4.7.2.'}
}
if(-not $JavaSdk){$JavaSdk=Get-ChildItem (Join-Path $localTools 'java') -Directory -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName}
if(-not $AndroidSdk){$AndroidSdk=Join-Path $localTools 'sdk'}
if(-not(Test-Path -LiteralPath (Join-Path $JavaSdk 'bin\java.exe'))){throw 'Defina JAVA_HOME ou informe -JavaSdk (JDK 17).'}
if(-not(Test-Path -LiteralPath (Join-Path $AndroidSdk 'build-tools\36.0.0\apksigner.bat'))){throw 'Instale Android SDK Build-Tools 36.0.0 e Platform 36; informe -AndroidSdk.'}
$env:JAVA_HOME=$JavaSdk
$env:ANDROID_HOME=$AndroidSdk
$env:PATH=(Join-Path $JavaSdk 'bin')+';'+$env:PATH
$output=if($OutputPath){[IO.Path]::GetFullPath($OutputPath)}else{Join-Path $projectRoot 'builds\android\Hunter-Life-0.1.2-test.apk'}
New-Item -ItemType Directory -Force -Path (Split-Path $output -Parent) | Out-Null
& $GodotPath --headless --path $env:TEMP --script (Join-Path $PSScriptRoot 'configure_android.gd')
if($LASTEXITCODE -ne 0){throw 'Falha ao configurar caminhos Android no editor.'}
& $GodotPath --headless --editor --path $projectRoot --import
if($LASTEXITCODE -ne 0){throw 'Falha na importação.'}
& $GodotPath --headless --path $projectRoot --export-debug 'Android Test' $output
if($LASTEXITCODE -ne 0){throw 'Falha ao exportar. Confira templates Android 4.7.2 e o log do Godot.'}
& (Join-Path $AndroidSdk 'build-tools\36.0.0\apksigner.bat') verify --verbose $output
if($LASTEXITCODE -ne 0){throw 'Assinatura inválida.'}
& (Join-Path $AndroidSdk 'build-tools\36.0.0\zipalign.exe') -c -P 16 -v 4 $output | Select-Object -Last 1
if($LASTEXITCODE -ne 0){throw 'Alinhamento inválido.'}
$hash=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $([IO.Path]::GetFileName($output))" | Set-Content -LiteralPath ($output+'.sha256')
Write-Output "APK de teste: $output"
Write-Output "SHA256: $hash"
