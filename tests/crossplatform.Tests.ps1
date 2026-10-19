BeforeDiscovery {
    $onWindows = ($env:OS -eq 'Windows_NT')
    $onMac = (-not $onWindows) -and [bool](Get-Variable -Name IsMacOS -ValueOnly -ErrorAction SilentlyContinue)
}

BeforeAll {
    . (Join-Path (Join-Path $PSScriptRoot '..') 'wearos-bridge.ps1')
}

Describe 'Platform-aware state directory' {
    BeforeEach {
        $script:savedEnv = @{
            WEAROS_BRIDGE_HOME = $env:WEAROS_BRIDGE_HOME
            XDG_CONFIG_HOME = $env:XDG_CONFIG_HOME
        }
    }
    AfterEach {
        $env:WEAROS_BRIDGE_HOME = $script:savedEnv.WEAROS_BRIDGE_HOME
        $env:XDG_CONFIG_HOME = $script:savedEnv.XDG_CONFIG_HOME
    }

    It 'honors WEAROS_BRIDGE_HOME on every platform' {
        $env:WEAROS_BRIDGE_HOME = Join-Path $TestDrive 'custom-state'
        Get-StateDirectory | Should -Be (Join-Path $TestDrive 'custom-state')
    }

    It 'keeps Windows settings beside the script' -Skip:(-not $onWindows) {
        $env:WEAROS_BRIDGE_HOME = $null
        Get-StateDirectory | Should -Be $ScriptDir
    }

    It 'uses XDG config on Linux' -Skip:($onWindows -or $onMac) {
        $env:WEAROS_BRIDGE_HOME = $null
        $env:XDG_CONFIG_HOME = Join-Path $TestDrive 'xdg'
        Get-StateDirectory | Should -Be (Join-Path (Join-Path $TestDrive 'xdg') 'wearos-bridge')
    }

    It 'uses Application Support on macOS' -Skip:(-not $onMac) {
        $env:WEAROS_BRIDGE_HOME = $null
        Get-StateDirectory | Should -BeLike '*/Library/Application Support/wearos-bridge'
    }
}

Describe 'Tool discovery' {
    BeforeEach {
        $script:savedPath = $env:PATH
        $script:savedAdb = $env:WEAROS_BRIDGE_ADB
        $script:savedOverride = $script:AdbOverride
        $script:toolDir = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        New-Item -Path $script:toolDir -ItemType Directory | Out-Null
    }
    AfterEach {
        $env:PATH = $script:savedPath
        $env:WEAROS_BRIDGE_ADB = $script:savedAdb
        $script:AdbOverride = $script:savedOverride
    }

    It 'uses the platform executable names' {
        if ($script:IsWindowsHost) {
            $script:AdbName | Should -Be 'adb.exe'
            $script:ScrcpyName | Should -Be 'scrcpy.exe'
        }
        else {
            $script:AdbName | Should -Be 'adb'
            $script:ScrcpyName | Should -Be 'scrcpy'
        }
    }

    It 'finds adb and scrcpy on PATH' {
        $adb = Join-Path $script:toolDir $script:AdbName
        $scrcpy = Join-Path $script:toolDir $script:ScrcpyName
        Set-Content -Path $adb -Value 'x'
        Set-Content -Path $scrcpy -Value 'x'
        if (-not $script:IsWindowsHost) { & chmod +x $adb $scrcpy }
        $env:WEAROS_BRIDGE_ADB = $null
        $script:AdbOverride = $null
        $env:PATH = $script:toolDir + [System.IO.Path]::PathSeparator + $env:PATH
        Mock Get-ConfiguredScrcpyFolder { $null }
        (Get-AdbExecutable) | Should -Be $adb
        (Get-ScrcpyExecutable) | Should -Be $scrcpy
    }

    It 'checks common install locations when PATH is minimal' -Skip:$onWindows {
        $sdk = Join-Path $script:toolDir 'sdk'
        New-Item -Path (Join-Path $sdk 'platform-tools') -ItemType Directory -Force | Out-Null
        $adb = Join-Path (Join-Path $sdk 'platform-tools') 'adb'
        Set-Content -Path $adb -Value 'x'
        $savedHome = $env:ANDROID_HOME
        try {
            $env:ANDROID_HOME = $sdk
            Find-ToolExecutable -Name 'adb' | Should -Be $adb
        }
        finally { $env:ANDROID_HOME = $savedHome }
    }
}

Describe 'Native runner' {
    It 'passes arguments containing spaces and quotes and captures output, stderr, and exit status' {
        $script = Join-Path $TestDrive 'echo.ps1'
        Set-Content -Path $script -Value 'param($Value) [Console]::WriteLine($Value); [Console]::Error.WriteLine(''diagnostic''); exit 7'
        $shell = (Get-Process -Id $PID).Path
        $result = Invoke-NativeTool -Executable $shell -Arguments @('-NoProfile', '-File', $script, 'a "quoted" path with spaces')
        $result.exitCode | Should -Be 7
        $result.output | Should -Match 'a "quoted" path with spaces'
        $result.output | Should -Match 'diagnostic'
    }
}

Describe 'POSIX launcher' -Skip:$onWindows {
    BeforeAll {
        $launcher = Join-Path (Join-Path $PSScriptRoot '..') 'wearos-bridge.sh'
        $fakeAdb = Join-Path $TestDrive 'fake adb'
        $fakeScript = @'
#!/bin/sh
dir=$(dirname "$0")
preset="$dir/uploaded-preset.json"
if [ "$#" -eq 1 ] && [ "$1" = devices ]; then
    printf 'List of devices attached\nfixture-device\tdevice\n'; exit 0
fi
if [ "$1" != -s ] || [ "$2" != fixture-device ]; then echo 'Unexpected target' >&2; exit 2; fi
case "$3" in
    shell)
        if [ "$4" = pm ] && [ "$5" = path ]; then echo 'package:/data/app/fixture/base.apk'; exit 0; fi
        if [ "$4" = mkdir ]; then exit 0; fi
        if [ "$4" = mv ]; then rm -f "$preset"; exit 0; fi
        ;;
    push) cp "$4" "$preset"; exit 0 ;;
    exec-out) if [ "$4" = cat ]; then cat "$preset"; exit 0; fi ;;
esac
echo 'Unexpected operation' >&2; exit 3
'@
        [System.IO.File]::WriteAllText($fakeAdb, $fakeScript.Replace("`r`n", "`n"))
        & chmod +x $fakeAdb $launcher
        $env:WEAROS_BRIDGE_HOME = Join-Path $TestDrive 'state'
    }

    It 'uploads a preset through wearos-bridge.sh with parseable JSON' {
        $preset = Join-Path $TestDrive 'launcher preset.json'
        [System.IO.File]::WriteAllText($preset, '{"profile":{"callsign":"ODIN"}}')
        $output = & $launcher --upload-preset weartak $preset odin --serial fixture-device --adb $fakeAdb --json
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        $result = ($output -join "`n") | ConvertFrom-Json
        $result.success | Should -BeTrue
        $result.data.verified | Should -BeTrue
    }

    It 'returns parseable error JSON and exit code 1' {
        $output = & $launcher --install --json
        $LASTEXITCODE | Should -Be 1
        (($output -join "`n") | ConvertFrom-Json).success | Should -BeFalse
    }
}
