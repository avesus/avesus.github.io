param([Parameter(Mandatory=$true)][string]$Vivado)
$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$project=Join-Path $root 'wifi_e310_link'
$output=Join-Path $project 'build/release-compactmul'
if (-not (Test-Path -LiteralPath $Vivado -PathType Leaf)) { throw 'Supply the installed vivado.bat path.' }
New-Item -ItemType Directory -Force -Path $output | Out-Null
# Preserve the exact accepted generics. Separate Vivado invocations avoid
# carrying synthesis process state into implementation in Vivado 2026.1.
foreach ($phase in @('synth','route')) {
 $resume=if ($phase -eq 'route') {'1'} else {'0'}
 $args=@('-mode','batch','-nojournal','-log',"$output/$phase.log",'-source',"$project/tools/build_minimal_vivado.tcl",'-tclargs',
   $project,'xc7z020clg484-3',$output,$phase,'1',$resume,'-','Pullnone',
   '1','1','1','1','1','1','1','1','1','0','1','0','1')
 & $Vivado @args
 if ($LASTEXITCODE -ne 0) { throw "Vivado $phase failed: inspect $output/$phase.log" }
}
Write-Output "Build complete: $output/gf_e310_minimal.bit. Nothing was loaded onto hardware."
