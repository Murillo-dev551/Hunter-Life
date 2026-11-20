param([string]$ApkPath)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if(-not $ApkPath){$ApkPath=Join-Path $projectRoot 'builds\android\Hunter-Life-0.1.2-test.apk'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($ApkPath)
$checks=0
function Check([bool]$ok,[string]$message){$script:checks++;if(-not $ok){throw $message}}
function Read-Entry([string]$name){
    $entry=$zip.GetEntry($name)
    if(-not $entry){throw "Recurso ausente: $name"}
    $reader=New-Object IO.StreamReader($entry.Open())
    try{return $reader.ReadToEnd()}finally{$reader.Dispose()}
}
try{
    $events=Read-Entry 'assets/data/events.json'
    Check (($events | ConvertFrom-Json).Count -eq 92) 'Catálogo original deve manter seus 92 acontecimentos.'
    Check ($events -ceq [IO.File]::ReadAllText((Join-Path $projectRoot 'data\events.json'))) 'Catálogo exportado difere do projeto.'
    $journeys=Read-Entry 'assets/data/journeys_011.json'
    Check ((($journeys | ConvertFrom-Json).Count+($events | ConvertFrom-Json).Count) -eq 174) 'Expansão deve totalizar 174 acontecimentos.'
    $encounters=Read-Entry 'assets/data/encounters_012.json'
    Check ((($encounters | ConvertFrom-Json).Count+($journeys | ConvertFrom-Json).Count+($events | ConvertFrom-Json).Count) -eq 182) 'Catálogo atual deve totalizar 182 acontecimentos.'
    foreach($catalog in @('journeys_011.json','revisions_011.json','encounters_012.json','scenery.json','scenery_assignments.json','editorial_names.json')){
        Check ((Read-Entry ('assets/data/'+$catalog)) -ceq [IO.File]::ReadAllText((Join-Path $projectRoot ('data\'+$catalog)))) "Catálogo exportado incorreto: $catalog"
    }
    Check ($null -ne $zip.GetEntry('lib/arm64-v8a/libgodot_android.so')) 'Biblioteca ARM64 ausente.'
    Check (@($zip.Entries | Where-Object {$_.FullName -match '^lib/' -and $_.FullName -notmatch '^lib/arm64-v8a/'}).Count -eq 0) 'Arquiteturas não solicitadas.'
    Check (@($zip.Entries | Where-Object {$_.FullName -match '^assets/(tests|tools|builds)/'}).Count -eq 0) 'Testes ou ferramentas incluídos no APK.'
    Check ($null -ne $zip.GetEntry('assets/assets/ASSET_LICENSES.md')) 'Licenças ausentes.'
    Check ((Read-Entry 'assets/_cl_').Contains('--fullscreen')) 'Argumento de tela cheia ausente.'
    $scrollRemap=Read-Entry 'assets/scripts/ui/touch_scroll.gd.remap'
    $scrollPath=[regex]::Match($scrollRemap,'path="res://([^"]+)"')
    Check ($scrollPath.Success -and $null -ne $zip.GetEntry('assets/'+$scrollPath.Groups[1].Value)) 'Componente de rolagem compilado ausente.'
    foreach($script in @('missions','catalog','game_state','storage','ui/creation_view','scenery','ui/scenery_view','exam_journal','ui/document_style','ui/notebook','ui/masthead','ui/editorial_rule')){
        $remap=Read-Entry ('assets/scripts/'+$script+'.gd.remap')
        $compiled=[regex]::Match($remap,'path="res://([^"]+)"')
        Check ($compiled.Success -and $null -ne $zip.GetEntry('assets/'+$compiled.Groups[1].Value)) "Script compilado da atualização ausente: $script"
    }
    foreach($license in @('assets/fonts/source_sans3/OFL.txt','assets/fonts/barlow_condensed/OFL.txt','assets/fonts/source_serif/OFL.txt','assets/scenery/SOURCES.md')){
        Check ((Read-Entry ('assets/'+$license)).Length -gt 1000) "Origem ou licença ausente: $license"
        Check ((Read-Entry ('assets/'+$license)) -ceq [IO.File]::ReadAllText((Join-Path $projectRoot $license))) "Origem ou licença desatualizada: $license"
    }
    foreach($relative in @('scenery/city.webp','scenery/forest.webp','scenery/road.webp','scenery/inn.webp','scenery/port.webp','scenery/ruins.webp','scenery/office.webp','scenery/market.webp','fonts/source_sans3/SourceSans3.ttf','fonts/source_sans3/SourceSans3-Bold.ttf','fonts/source_serif/SourceSerif4-Semibold.otf','fonts/source_serif/SourceSerif4-It.otf','fonts/barlow_condensed/BarlowCondensed-SemiBold.ttf','fonts/barlow_condensed/BarlowCondensed-BoldItalic.ttf','icons/choice_accept.svg','icons/choice_talk.svg','icons/choice_back.svg')){
        $import=Read-Entry ('assets/assets/'+$relative+'.import')
        $dependency=[regex]::Match($import,'path="res://([^"]+)"')
        Check ($dependency.Success -and $null -ne $zip.GetEntry('assets/'+$dependency.Groups[1].Value)) "Arte ou fonte importada ausente: $relative"
    }
    foreach($relative in @('audio/music/field_notes.wav','audio/sfx/click.wav','audio/sfx/select.wav','audio/sfx/tab.wav','audio/sfx/back.wav','audio/sfx/success.wav','audio/sfx/failure.wav','audio/sfx/reward.wav','audio/sfx/level.wav','icons/adventure.svg','icons/character.svg','icons/inventory.svg','icons/record.svg','icons/settings.svg','icons/saves.svg','icons/attack.svg','icons/defend.svg','icons/nen.svg','icons/other.svg','icons/emblem.svg')){
        $import=Read-Entry ('assets/assets/'+$relative+'.import')
        $match=[regex]::Match($import,'path="res://([^"]+)"')
        Check ($match.Success -and $null -ne $zip.GetEntry('assets/'+$match.Groups[1].Value)) "Dependência importada ausente: $relative"
    }
    Write-Output "Integridade APK: $checks verificações, 0 falhas"
}finally{$zip.Dispose()}
