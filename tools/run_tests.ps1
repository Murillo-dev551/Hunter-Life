param([string]$GodotPath,[string]$RunPrefix='012')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if(-not $GodotPath){$GodotPath=Join-Path (Split-Path $projectRoot -Parent) 'Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'}
if(-not(Test-Path -LiteralPath $GodotPath)){throw 'Informe -GodotPath com o executável do Godot.'}
$previousRoot=$env:HUNTER_LIFE_DATA_ROOT
$results=@()
try{
    foreach($file in (Get-ChildItem (Join-Path $projectRoot 'tests/test_*.gd') | Sort-Object Name)){
        # Each suite owns its slots/preferences. A successful creation in one suite
        # must never make another suite's empty-slot fixture occupied.
        $env:HUNTER_LIFE_DATA_ROOT='user://regression_'+$RunPrefix+'_'+$file.BaseName+'_'+[guid]::NewGuid().ToString('N')
        $arguments=@('--path',$projectRoot,'--script',('res://tests/'+$file.Name))
        if($file.BaseName -notmatch 'visual|ui|audio_identity|player_text|polish|android|combat_menu|touch_scroll'){$arguments=@('--headless')+$arguments}
        $log=Join-Path $projectRoot ('tests/'+$RunPrefix+'_final_'+$file.BaseName+'.log')
        & $GodotPath @arguments *> $log
        $code=$LASTEXITCODE
        $lines=Get-Content -LiteralPath $log
        $summary=($lines | Select-String '\d+ verificações.*falhas' | Select-Object -Last 1).Line
        $scriptError=@($lines | Select-String 'SCRIPT ERROR|^ERROR:' | Where-Object {$_.Line -notmatch '^ERROR: \d+ resources still in use at exit'}).Count -gt 0
        if($scriptError -or -not $summary -or $summary -notmatch ', 0 falhas'){$code=1}
        $results+=@{name=$file.BaseName;code=$code;summary=$summary}
        Write-Output ($file.BaseName+' exit='+$code+' '+$summary)
    }
    $results | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $projectRoot ('tests/'+$RunPrefix+'_test_results.json'))
    if(@($results | Where-Object {$_.code -ne 0}).Count -gt 0){throw 'Falhas na regressão; consulte o consolidado e os logs em tests/.'}
    Write-Output ('Regressão concluída: '+$results.Count+' suítes aprovadas.')
}finally{
    if($null -eq $previousRoot){Remove-Item Env:HUNTER_LIFE_DATA_ROOT -ErrorAction SilentlyContinue}else{$env:HUNTER_LIFE_DATA_ROOT=$previousRoot}
}
