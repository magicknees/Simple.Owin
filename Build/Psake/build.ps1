# Psake (https://github.com/psake/psake) build script

framework 4.0x86

properties {	
	$script:sourcePath = $psake.build_script_dir + "\..\..\Source\"
	$script:toolsPath = $psake.build_script_dir + "\..\..\Tools\"
	$script:nuget = $toolsPath + "\NuGet\NuGet.exe";
	$script:xunit = $toolsPath + "\XUnit\xunit.console.clr4.exe";
	$script:xunit_x86 = $toolsPath + "\XUnit\xunit.console.clr4.x86.exe";
	$script:test_x86 = (!($(gwmi win32_processor | select description) -match "x86"));
	$script:newPackagesPath = $psake.build_script_dir + '\Artifacts\Packages';
}

task default -depends Release # ?

task ? -Description "Helper to display task info" {
	'Supported tasks are: PackageRestore, Clean, Build, Rebuild, Test, Package, and Release'
}

task PackageRestore {
	Write-Host '>>> Restoring packages';
		
	Get-ChildItem ($sourcePath) -Recurse | 
		Where-Object { (!$_.PsIsContainer) } |
		Where-Object { ($_.Name -eq "packages.config") } | 
		ForEach-Object { 
			Write-Host "> " $_.FullName
			exec { & $nuget install $_.FullName -Verbosity detailed -NonInteractive }
		}
}

task Clean {
	Write-Host '>>> Cleaning bin and obj directories';

	Get-ChildItem ($sourcePath) -Recurse | 
		Where-Object { ($_.PsIsContainer) } |
		Where-Object { ($_.Name -eq "obj") -or ($_.Name -eq "bin") } | 
		ForEach-Object { 
			Write-Host "> " $_.FullName
			Remove-Item -LiteralPath $_.FullName -Recurse -Force
		}
}

task Build -depends PackageRestore {
	Write-Host '>>> Building assemblies';

	Get-ChildItem ($sourcePath) -Recurse | 
		Where-Object { (!$_.PsIsContainer) } |
		Where-Object { ($_.Name -like "*.csproj") } | 
		ForEach-Object { 
			Write-Host "> " $_.FullName
			exec { msbuild /nologo /v:m /p:Configuration=Release /t:Build $_.FullName }
		}
}

task Rebuild -depends Clean, Build

task Test -depends Build { 
	Write-Host '>>> Running tests';
	
	Get-ChildItem ($sourcePath) -Recurse | 
		Where-Object { (!$_.PsIsContainer) } |
		Where-Object { ($_.FullName -like "*\bin\Release\*.Tests.dll") } | 
		ForEach-Object { 
			Write-Host "> " $_.FullName
			exec { & $xunit $_.FullName /silent }
			if ($test_x86) {
				exec { & $xunit_x86 $_.FullName /silent }
			}
		}
}

task Package -depends Build {
	Write-Host '>>> Building packages';

	if (!(Test-Path $newPackagesPath)) { mkdir $newPackagesPath }
	
	Get-ChildItem ($sourcePath) -Recurse | 
		Where-Object { (!$_.PsIsContainer) } |
		Where-Object { ($_.Name -like "*.nuspec") } | 
		ForEach-Object { 
			Write-Host "> " $_.FullName
			exec { & $nuget pack ($_.FullName) -OutputDirectory $newPackagesPath -Verbosity detailed -NonInteractive }
		}
}

task Release -depends Clean, Test, Package
