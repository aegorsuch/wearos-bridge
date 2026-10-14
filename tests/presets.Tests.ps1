BeforeAll {
    . (Join-Path $PSScriptRoot '..\wearos-windows-bridge.ps1')
}

Describe 'WearTAK preset uploads' {
    BeforeEach {
        $presetPath = Join-Path $TestDrive 'my preset.json'
        $script:presetFixture = '{"profile":{"callsign":"ODIN","team":"Dark Green","role":"K9"},"servers":[{"name":"Example","url":"tak.example.org","port":8089,"username":"fixture-user","password":"fixture-password"}]}'
        [System.IO.File]::WriteAllText($presetPath, $script:presetFixture)
        $script:readbackPath = $null
        Mock Get-AdbExecutable { 'adb.exe' }
        Mock Ensure-OperationTarget {}
        Mock Invoke-NativeTool {
            if ($Arguments[2] -eq 'exec-out') {
                $script:readbackPath = $OutputPath
                [System.IO.File]::WriteAllText($OutputPath, $script:presetFixture)
            }
            [pscustomobject]@{ exitCode = 0; output = 'package:/data/app/fixture/base.apk' }
        }
    }

    It 'uploads, verifies and returns the app-specific chat command without applying settings' -ForEach @(
        @{ App = 'weartak'; Package = 'com.aitech.weartak_civ'; Prefix = '#weartakcommand' }
        @{ App = 'tracker'; Package = 'com.tak.weartak_tracker'; Prefix = '#weartaktrackercommand' }
    ) {
        $response = (Invoke-AutomationCommand @('--upload-preset', $App, $presetPath, 'odin', '--serial', 'fixture-device', '--json') | Out-String)
        $result = $response | ConvertFrom-Json
        $result.success | Should -BeTrue
        $result.serial | Should -Be 'fixture-device'
        $result.data.remotePath | Should -Be "/sdcard/Android/data/$Package/files/presets/odin.json"
        $result.data.applyCommand | Should -Be "${Prefix}loadprofile name=odin"
        $result.data.verified | Should -BeTrue
        $result.data.applied | Should -BeFalse
        $response | Should -Not -Match 'fixture-user|fixture-password'
        Test-Path -LiteralPath $script:readbackPath | Should -BeFalse
        Should -Invoke Ensure-OperationTarget -Times 1 -ParameterFilter { $Serial -eq 'fixture-device' }
        Should -Invoke Invoke-NativeTool -Times 1 -ParameterFilter {
            $Arguments[0] -eq '-s' -and $Arguments[1] -eq 'fixture-device' -and $Arguments[2] -eq 'push' -and $Arguments[3] -eq $presetPath
        }
        Should -Invoke Invoke-NativeTool -Times 1 -ParameterFilter { $Arguments[3] -eq 'mv' -and $Arguments[-1] -eq "/sdcard/Android/data/$Package/files/presets/odin.json" }
        Should -Invoke Invoke-NativeTool -Times 0 -ParameterFilter { $Arguments[3] -eq 'rm' }
    }

    It 'rejects invalid preset arguments' -ForEach @(
        @{ Values = @('unknown', 'file.json', 'odin') }
        @{ Values = @('weartak', 'file.json', '../odin') }
        @{ Values = @('tracker', 'file.json', 'ODIN') }
        @{ Values = @('tracker', 'file.json', "odin`n") }
        @{ Values = @('tracker', 'file.json', ('x' * 33)) }
        @{ Values = @('tracker', 'file.json') }
    ) {
        { Read-AutomationArguments (@('--upload-preset') + $Values) } | Should -Throw
        Should -Invoke Invoke-NativeTool -Times 0
    }

    It 'validates schema before contacting the device and never echoes credentials' -ForEach @(
        @{ Json = '{"profile":'; App = 'weartak' }
        @{ Json = '[]'; App = 'weartak' }
        @{ Json = '{}'; App = 'weartak' }
        @{ Json = '{"profile":{"height":"5-8"}}'; App = 'tracker' }
        @{ Json = '{"profile":{"weight":150}}'; App = 'weartak' }
        @{ Json = '{"servers":{}}'; App = 'weartak' }
        @{ Json = '{"servers":[null]}'; App = 'weartak' }
        @{ Json = '{"profile":{"callsign":""}}'; App = 'weartak' }
        @{ Json = '{"password":"fixture-password"}'; App = 'weartak' }
        @{ Json = '{"servers":[{"name":"X","url":"https://host","username":"fixture-user","password":"fixture-password"}]}'; App = 'weartak' }
        @{ Json = '{"servers":[{"name":"X","url":"host","port":65536,"username":"fixture-user","password":"fixture-password"}]}'; App = 'weartak' }
        @{ Json = '{"servers":[{"name":"X","url":"host","port":8089.5,"username":"fixture-user","password":"fixture-password"}]}'; App = 'weartak' }
        @{ Json = '{"servers":[{"name":"X","url":"host","username":"fixture-user"}]}'; App = 'weartak' }
    ) {
        [System.IO.File]::WriteAllText($presetPath, $Json)
        $response = (Invoke-AutomationCommand @('--upload-preset', $App, $presetPath, 'odin', '--serial', 'fixture-device', '--json') | Out-String)
        ($response | ConvertFrom-Json).success | Should -BeFalse
        $response | Should -Not -Match 'fixture-user|fixture-password'
        Should -Invoke Ensure-OperationTarget -Times 0
        Should -Invoke Invoke-NativeTool -Times 0
    }

    It 'accepts servers-only presets with the default port' {
        [System.IO.File]::WriteAllText($presetPath, '{"servers":[{"name":"Example","url":"host","username":"user","password":"password"}]}')
        Read-WearTakPreset -Path $presetPath -App tracker | Should -Be $presetPath
    }

    It 'enforces the exact byte limit' {
        $base = '{"profile":{"callsign":"ODIN"}}'
        [System.IO.File]::WriteAllText($presetPath, $base.PadRight(65536))
        Read-WearTakPreset -Path $presetPath -App weartak | Should -Be $presetPath
        [System.IO.File]::WriteAllText($presetPath, $base.PadRight(65537))
        { Read-WearTakPreset -Path $presetPath -App weartak } | Should -Throw '*65536*'
        Should -Invoke Invoke-NativeTool -Times 0
    }

    It 'preserves the existing preset on upload failure or read-back mismatch' -ForEach @(
        @{ Failure = 'push' }
        @{ Failure = 'readback' }
        @{ Failure = 'mismatch' }
        @{ Failure = 'missing-app' }
    ) {
        Mock Invoke-NativeTool {
            if ($Failure -eq 'missing-app') { return [pscustomobject]@{ exitCode = 0; output = '' } }
            if ($Arguments[2] -eq 'push' -and $Failure -eq 'push') {
                return [pscustomobject]@{ exitCode = 1; output = 'fixture-password' }
            }
            if ($Arguments[2] -eq 'exec-out') {
                $script:readbackPath = $OutputPath
                [System.IO.File]::WriteAllText($OutputPath, 'fixture-password')
                if ($Failure -eq 'readback') { return [pscustomobject]@{ exitCode = 1; output = 'fixture-password' } }
            }
            [pscustomobject]@{ exitCode = 0; output = 'package:/data/app/fixture/base.apk' }
        }
        $response = (Invoke-AutomationCommand @('--upload-preset', 'weartak', $presetPath, 'odin', '--serial', 'fixture-device', '--json') | Out-String)
        ($response | ConvertFrom-Json).success | Should -BeFalse
        $response | Should -Not -Match 'fixture-password'
        Should -Invoke Invoke-NativeTool -Times 0 -ParameterFilter { $Arguments[3] -eq 'mv' }
        if ($Failure -ne 'missing-app') {
            Should -Invoke Invoke-NativeTool -Times 1 -ParameterFilter { $Arguments[3] -eq 'rm' -and $Arguments[-1] -like '*.upload' }
        }
        if ($script:readbackPath) { Test-Path -LiteralPath $script:readbackPath | Should -BeFalse }
    }
}
