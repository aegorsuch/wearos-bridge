# WearOS Bridge

A cross-platform (Windows, macOS, Ubuntu/Linux) command-line helper for pairing a Wear OS watch over Wi-Fi, connecting with Android Debug Bridge (ADB), mirroring the watch with scrcpy, and sideloading APK files.

Repository: https://git.tak.gov/aegorsuch/wearos-bridge

## Project Information

### Rights

Unlimited Rights granted to TAK Product Center.

### Point of Contact

Alex Gorsuch on chat.tak.gov or Signal.

### Repositories

TAK Forge is the canonical repository. GitHub is a secondary repository.

### Report a Bug

If the helper fails, crashes, or behaves unexpectedly, open a GitHub issue at https://github.com/aegorsuch/wearos-bridge/issues and include your operating system, the stage of the flow that failed, the exact error text, and the watch model or device state when possible. The tool's menu also includes a bug-report option to open a prefilled issue form.

## Quick Start

Download the archive for your platform from the [latest release](https://github.com/aegorsuch/wearos-bridge/releases/latest):

| Platform | Download | Launch |
|----------|----------|--------|
| Windows 10+ | `wearos-bridge-windows.zip` | Double-click `wearos-bridge.bat` |
| macOS | `wearos-bridge-macos.tar.gz` | `./wearos-bridge.sh` in Terminal |
| Ubuntu / Linux | `wearos-bridge-linux.tar.gz` | `./wearos-bridge.sh` in a terminal |

**Windows**

1. Extract the ZIP and keep the files together. Run the `.bat` file, not the `.ps1` file. The correct result is a black window showing **WEAROS BRIDGE** and a numbered menu.
2. If the `.bat` file opens as text, right-click it, choose **Open with**, and select **Windows Command Processor**. Also confirm the filename ends in `.bat`, not `.bat.txt`.
3. In the menu, select **1. Setup scrcpy System Path** before selecting any watch action.

Do not paste the scrcpy download link into the path prompt. Download and extract scrcpy first, then provide the folder that contains both `scrcpy.exe` and `adb.exe`. scrcpy can be stored anywhere. The helper remembers the folder you select. If you move or rename it later, select **1. Setup scrcpy System Path** again and choose its new location.

**macOS**

```sh
brew install --cask powershell      # PowerShell 7 (pwsh)
brew install scrcpy android-platform-tools
tar -xzf wearos-bridge-macos.tar.gz && cd wearos-bridge-macos
./wearos-bridge.sh
```

If macOS blocks the downloaded script or `pwsh` (Gatekeeper), clear the quarantine flag with `xattr -dr com.apple.quarantine wearos-bridge-macos` after confirming the download source.

**Ubuntu / Linux**

```sh
sudo snap install powershell --classic   # PowerShell 7 (pwsh); see Microsoft's docs for apt-based install
sudo apt install scrcpy adb
tar -xzf wearos-bridge-linux.tar.gz && cd wearos-bridge-linux
./wearos-bridge.sh
```

On macOS/Linux, scrcpy and adb are detected automatically from `PATH`, `ANDROID_HOME`/`ANDROID_SDK_ROOT`, Homebrew, snap, and common Android SDK locations, so menu option 1 is only needed for a scrcpy folder that is not installed through a package manager. If the script is not executable, run `chmod +x wearos-bridge.sh`. You may also run `pwsh ./wearos-bridge.ps1` directly.

Each commit pushed to the `develop` branch automatically runs the tests on Windows, Ubuntu, and macOS runners and then publishes a release with all three archives. CI uses fixture ADB only; macOS and Linux have not been verified against a physical watch.

After successful publication, automation verifies that all three release assets are uploaded and nonempty, then removes older published stable releases. Only the newest published stable release is retained; drafts, prereleases, and git tags/source history are not deleted. Failed or superseded publications do not trigger cleanup.

The canonical Forge repository is https://git.tak.gov/aegorsuch/wearos-bridge. GitHub release publication does not synchronize Forge branches. Until a CI credential is configured for Forge, update it explicitly with a non-force, fast-forward push of GitHub `develop`; a divergent Forge branch must be reconciled before pushing.

## Requirements

- A Wear OS watch and the computer on the same network, with Wireless Debugging enabled on the watch
- scrcpy and ADB: a scrcpy release containing both `scrcpy.exe` and `adb.exe` on Windows; `scrcpy` and `adb` from your package manager (or SDK platform-tools) on macOS/Linux
- Windows 10 or later: Windows PowerShell 5.1, included with Windows
- macOS or Ubuntu/Linux: PowerShell 7+ (`pwsh`)
- On Linux, a desktop session for scrcpy's window, and `xdg-open` for the bug-report link (optional; the link is printed if it cannot open)

## Getting Started

A `.bat` file is a small script that Windows runs like a program. To use this helper on Windows:

1. Double-click `wearos-bridge.bat` (or right-click it and choose **Open**) to launch it. A console window will open with a numbered menu.
2. If Windows shows a **Windows protected your PC** SmartScreen warning, click **More info**, then **Run anyway**. This warning is common for downloaded batch files; before running it, confirm you downloaded it from the expected repository or a trusted source.
3. Type the number of the menu option you want and press Enter. Follow the on-screen prompts. Close the console window to quit.
4. To type a folder or file path when asked, you can drag the file/folder from File Explorer (Windows) or your file manager (macOS/Linux, in most terminals) directly into the console window instead of typing it out.
5. Press `Ctrl+C` to cancel a running command (such as Live Watch Logs).

On macOS/Linux run `./wearos-bridge.sh` instead; everything after launch works the same.

## First Run

1. Windows: click the [scrcpy releases link](https://github.com/Genymobile/scrcpy/releases), download the latest `scrcpy-win64` zip, and extract it. scrcpy mirrors your watch screen and includes `adb.exe`, which the helper uses to connect to the watch and install APKs. macOS/Linux: install scrcpy and adb as shown in Quick Start.
2. Run the launcher and, on Windows, select **1. Setup scrcpy System Path**.
3. Drag the extracted folder containing `scrcpy.exe` and `adb.exe` into the window, or enter its path. The helper remembers this folder for future launches but does not change your permanent PATH.
4. If you move or rename the scrcpy folder later, run setup again and choose its new location.

## Enable Developer Options and Wireless Debugging

Before pairing, enable the required settings on the watch:

1. From the watch face, swipe down from the top edge of the screen to open the quick panel (the panel with quick settings such as battery, Wi-Fi, and Do Not Disturb).
2. Tap the **Settings** gear icon, then select **About Watch**.
3. Select **Software information**, then tap **Software Version** five times until the watch displays **Developer mode turned on**.
4. Return to the main Settings screen and open **Developer Options**. It is usually at the bottom of the list or just below **About Watch**.
5. Turn on **ADB Debugging**.
6. Open **Wireless Debugging** and turn it on.
7. Make sure the watch is connected to a Wi-Fi network.

## Pair the Watch

On the watch:

Before pairing, make sure the watch and the computer are connected to the same Wi-Fi network. They must be able to reach each other over that network.

The **IP address** identifies the watch on the network, for example `192.168.1.33`. Enter the IP address by itself; do not append the port. The **pairing port** is a separate number, such as `41131`, shown on the watch's pairing screen. Enter both values exactly, and do not use the connection port for pairing.

1. Open **Developer Options > Wireless Debugging**.
2. Select **Pair new device**.
3. Note the six-digit number at the top labeled **Wi-Fi pairing code**.
4. Note the IP address and pairing port shown in the pairing screen.

In the helper, select **2. Pair Watch via Wi-Fi** and enter those values when prompted. Pairing saves the watch IP and pairing port for the active profile; it does not mean the watch is currently connected.

Pairing and connection use different ports. The pairing port is shown after selecting **Pair new device**. The connection port is shown on the main **Wireless Debugging** screen. The IP address is usually the same on both screens, but for step 2 always use the IP and pairing port from the **Pair new device** screen, not the connection IP:port on the main screen. The helper repeats this reminder at the pairing prompts.

## Connect to the Watch

1. Return to the main **Wireless Debugging** screen on the watch.
2. In the helper, select **3. Connect to Watch**.
3. Enter the watch IP address and the connection port shown on the main Wireless Debugging screen. Leave the IP blank to use the saved IP. The connection port can change when Wireless Debugging restarts.

The helper saves the IP address and ports in `ip_cache.txt` and in the active profile. These are local settings and are ignored by Git.

The bridge reuses an already authorized connection, starts ADB when connecting if needed, and retries unsuccessful connections without restarting the shared server. The menu reports pairing from saved settings and connection from the live ADB device list, so a saved pairing can remain even when the watch is offline. A connected watch must be in the authorized `device` state at the exact saved endpoint.

## Screen Mirroring

After connecting, select **4. Launch Screen Mirroring**. The helper reuses the saved `IP:connection-port` if it is already connected, otherwise attempts to connect, and passes that endpoint to scrcpy. scrcpy uses the same ADB executable as the bridge.

## Sideload an APK

After connecting, select **5. Sideload an APK File**, then enter the APK file path or click and drag the APK file into the window, and press Enter. The bridge checks the connection, displays install progress, and reports ADB's install result. The APK is installed on the selected watch with replacement and runtime permissions enabled.

The install uses the saved direct ADB connection and disables streamed installation for better reliability over wireless debugging. If the watch disconnects during installation, wake it, enable Wireless Debugging, reconnect, and retry if ADB did not report `Success`.

## View Live Watch Logs

After connecting, select **6. Live Watch Logs** to stream new log lines immediately to the console while saving them to a timestamped file. Enter an optional keyword to show and save only matching lines, or press Enter to see all logs. The tool will display a message when capture is running. Keywords may contain letters, numbers, periods, underscores, and hyphens, such as `weartak` or `takserver.aftakcoe.org`.

Reproduce the issue while the stream is running, then press `Ctrl+C` to stop capture and return to the menu.

Log filenames use this format:

`ip_port_watch_log_keyword_startdatetime_enddatetime.txt`

For example: `10.0.0.169_34419_watch_log_takserver.aftakcoe.org_20260923-211500_20260923-211745.txt`.

When no keyword is supplied, the filename uses `none`.

The log is written directly to the `watch_logs` folder as it streams, using a temporary `..._inprogress.txt` name that is renamed to include the end time once capture stops. This means a capture is never stranded elsewhere if the window is closed or the batch job is terminated mid-stream.

The `watch_logs` folder is ignored by Git because logs may contain device, application, or user data. Review captures there (see Local Files for its location). Share a log only after checking it for sensitive information.

## Local Files

On Windows the helper creates these local files beside the batch file. On macOS and Linux they are stored in a per-user directory instead (`~/Library/Application Support/wearos-bridge` on macOS, `$XDG_CONFIG_HOME/wearos-bridge` or `~/.config/wearos-bridge` on Linux), created readable only by you. Set `WEAROS_BRIDGE_HOME` on any platform to choose a different folder.

- `ip_cache.txt` - saved watch IP and ports; ignored by Git
- `path_configured.txt` - local marker indicating PATH setup was completed; ignored by Git
- `watch_profiles.json` and `active_profile.txt` - saved watch profiles and the selected profile; ignored by Git
- `watch_logs/` - captured logs; ignored by Git
- `diagnostic_bundles/` - locally exported support bundles; ignored by Git

The six-digit pairing code is used only during pairing and is not saved.

## PowerShell core, profiles, and automation

The helper now ships with a PowerShell-based core and a small batch launcher for compatibility. This gives the project target-specific connection retries, structured status output, and profile support for multiple watches.

### Multi-watch profiles

Profiles are optional. If you only use one Wear OS watch, you can ignore them and keep using the default setup. The profile system is mainly a convenience for multi-watch setups, where each watch keeps its own saved IP, pairing port, and connection port.

This is useful when you have more than one Wear OS device in your setup. For example, you might keep one profile for your primary watch (`ODIN-WEARTAK`) and another for a dev device (`ODIN-WEARTAK-4`). That way each device keeps its own saved settings, and you can switch without retyping setup details each time.

If you do want to manage profiles, either use the menu flow or the command-line options:

- `--profile-list`
- `--profile-use NAME`
- `--profile-delete NAME`

The `default` profile cannot be deleted, but you can create and switch to other names like `ODIN-WEARTAK` or `ODIN-WEARTAK-4` for separate devices. For a quick menu-based removal, enter `DELETE NAME` in the profile management prompt.

### Developer Tools

Developer Tools is always available as **7. Developer Tools** on the main menu. It contains:

- **Manage Profiles** - create, switch, and delete saved watch profiles.
- **Bulk Sideload APK** - install an APK to all currently authorized ADB devices.
- **Diagnose Environment** - show ADB, scrcpy, profile, and device information.
- **Export Diagnostic Bundle** - create a local ZIP with system/tool versions and paths plus bridge status. Watch logs are excluded by default; users can opt in to up to five recent logs (5 MB each). IPs, MAC addresses, profile names, ADB serials, and user-profile paths are redacted by default. Redaction is pattern-based and may miss identifiers in free-text logs, so review the ZIP before sharing. Nothing is uploaded automatically.
- **Pair + Connect + Mirror** - run the pairing, connection, and mirroring flow.

Profiles are optional. For more than one watch, create a profile for each device (for example, `ODIN-WEARTAK` and `ODIN-WEARTAK-4`) and switch profiles before pairing or connecting. Each profile stores its own IP and ports. The `default` profile cannot be deleted.

The bulk sideload action targets every ADB device currently in the authorized `device` state. Check the listed devices before using it if more than one watch or Android device is connected.

### Structured status output

The PowerShell script exposes `--status-json` for scripts or automation. It returns installation/configuration flags, saved pairing and connection state, the active profile, profile settings, and the current ADB device summary as JSON.

### Shared ADB and connection retries

Menu and CLI operations reuse healthy connections. Failed connection or pairing attempts do not kill the shared ADB server or other ADB processes, so Android Studio's debugger and Logcat can remain attached. The connection port shown in Wireless Debugging can change, so update it when reconnecting if needed. `--recover-adb` is an explicit, opt-in server restart; it interrupts all ADB clients and should not be part of routine automation.

### One-click pair + connect + mirror

Use **7. Developer Tools > 5. Pair + Connect + Mirror** for the guided flow, or run `wearos-bridge.bat --pair-connect-mirror` (`./wearos-bridge.sh --pair-connect-mirror` on macOS/Linux) for the command-line flow. The command prompts for any values not supplied as arguments.

## Android Studio / Automation

Use the normal menu for manual setup, pairing, and troubleshooting. Scripts and agents should invoke direct commands, not navigate a special menu. Both interfaces use the same installation, connection, and mirroring functions.

Run `wearos-bridge.bat --automation-help` (or `./wearos-bridge.sh --automation-help` on macOS/Linux) to discover the automation interface. The examples use the Windows launcher and Windows paths; on macOS/Linux substitute `./wearos-bridge.sh` and POSIX paths. They assume the launcher is on PATH; otherwise use its full quoted path.

```text
wearos-bridge.bat --install "C:\project\app\build\outputs\apk\debug\app-debug.apk" --profile DEV --non-interactive --json
wearos-bridge.bat --status-json --serial 192.168.1.33:5555 --json
wearos-bridge.bat --screenshot "C:\project\watch.png" --profile DEV --json
wearos-bridge.bat --tap 180 180 --profile DEV --json
wearos-bridge.bat --swipe 180 280 180 80 300 --profile DEV --json
wearos-bridge.bat --key KEYCODE_HOME --profile DEV --json
wearos-bridge.bat --launch com.example.watch/.MainActivity --profile DEV --json
wearos-bridge.bat --force-stop com.example.watch --profile DEV --json
wearos-bridge.bat --upload-preset weartak "C:\WatchPresets\odin.json" odin-weartak --profile DEV --json
./wearos-bridge.sh --install ~/project/app/build/outputs/apk/debug/app-debug.apk --profile DEV --non-interactive --json
```

### Commands and modifiers

| Command | Arguments | Behavior |
|---|---|---|
| `--install` | APK path | Replace the app and grant runtime permissions; never automatically uninstall or erase app data |
| `--bulk-install` | APK path | Install to every authorized device; fail overall if any installation fails |
| `--connect` | IPv4 address and port | Connect directly; `--non-interactive` or `--json` prevents saving/changing profile settings |
| `--mirror` | None | Open scrcpy for the selected device; run until the window closes or the automation timeout expires |
| `--status-json` | None | Read status without connecting to a target |
| `--screenshot` | Output PNG path | Capture binary PNG data; replace the output only after successful capture and PNG signature validation |
| `--tap` | X Y | Tap nonnegative screen coordinates |
| `--swipe` | X1 Y1 X2 Y2 and optional duration in ms | Swipe using nonnegative integers; omit duration to use Android's default |
| `--key` | Numeric keycode or `KEYCODE_NAME` | Send an Android key event |
| `--launch` | `PACKAGE/ACTIVITY` | Start an explicit activity and wait for the launch result |
| `--force-stop` | Package name | Force-stop an app |
| `--upload-preset` | `weartak` or `tracker`, JSON path, preset name | Upload and read-back verify a local preset; return the direct TAK chat command to apply it |
| `--recover-adb` | None | Explicitly restart the shared ADB server; interrupts Studio and other ADB clients |

Place modifiers after the command, in any order:

- `--serial SERIAL`: target an exact ADB serial, including USB devices, emulators, or wireless `IP:port` endpoints.
- `--profile NAME`: target an existing profile's saved endpoint **for this invocation only**. It does not switch the active profile or update saved ports. Create/configure the profile using the menu first.
- `--adb PATH`: use an explicit ADB executable, preferably Android Studio's SDK `platform-tools\adb.exe`.
- `--non-interactive`: never prompt; invalid/missing arguments fail immediately. Only the commands in the table support automation modifiers. Interactive pairing, live logging, and profile management remain separate commands.
- `--json`: implies noninteractive mode and emits exactly one JSON result on stdout, including on failure.
- `--timeout SECONDS`: timeout for **each native command**, from 1 to 3600 seconds; defaults to 120. Connection retries can involve multiple native commands, so this is not an overall workflow deadline. A timed-out operation fails; an install might still have completed on the device, so inspect its state before retrying.

Use either `--serial` or `--profile`, not both. Without either, device operations use the saved active endpoint. Neither targeting option applies to `--connect`, `--bulk-install`, or `--recover-adb`. Bulk installation deliberately affects all authorized devices.

Relative input/output paths are resolved from the caller's working directory. Configuration and logs still live beside the bridge script. Screenshot directories must already exist. The bridge does not build APKs: run your Gradle build before invoking installation.

`--mirror` without automation modifiers retains its unlimited interactive lifetime. With automation modifiers it runs in the foreground with the native-command timeout; set `--timeout 3600` for a longer viewing session. It does not return a background PID.

### Share Android Studio's ADB

Select the same SDK ADB used by Studio to avoid competing bundled ADB versions:

```text
wearos-bridge.bat --install "C:\project\app-debug.apk" --profile DEV --adb "C:\Users\YOUR_USER\AppData\Local\Android\Sdk\platform-tools\adb.exe" --json
```

For a persistent selection, set the Windows user environment variable `WEAROS_BRIDGE_ADB` to the full SDK ADB path and restart Studio/the bridge to pick it up. Selection order is `--adb`, `WEAROS_BRIDGE_ADB`, configured scrcpy folder, then PATH. An invalid explicit selection fails rather than silently falling back. scrcpy receives this same executable through its `ADB` environment variable.

### WearTAK / WearTAK Tracker presets

Use **7. Developer Tools > 8. Upload WearTAK / Tracker preset**, or:

```text
wearos-bridge.bat --upload-preset weartak "C:\WatchPresets\odin.json" odin-weartak --profile DEV --json
wearos-bridge.bat --upload-preset tracker "C:\WatchPresets\odin-tracker.json" odin-tracker --serial WATCH_SERIAL --json
```

The selected app must be installed. Open it once if its external storage is not initialized. Preset names are 1-32 lowercase letters, digits or hyphens, starting with a letter or digit. The bridge stages the file, reads it back and compares SHA-256 hashes, then replaces any existing preset of that name. Failed uploads do not replace the existing preset; the bridge attempts to remove the staged file and reports cleanup failures. App settings are never changed by uploading.

Files go under `/sdcard/Android/data/com.aitech.weartak_civ/files/presets/` for WearTAK or `/sdcard/Android/data/com.tak.weartak_tracker/files/presets/` for Tracker. Android device paths use forward slashes; Windows input paths use backslashes.

A WearTAK preset can contain:

```json
{
  "profile": {
    "callsign": "ODIN-WEARTAK",
    "team": "Dark Green",
    "role": "K9",
    "height": "5'8\"",
    "weight": "150",
    "pants": "30",
    "waist": "30",
    "birthyear": "1988",
    "sex": "Male",
    "usertype": "Coalition Civilian"
  },
  "servers": [
    {
      "name": "Example TAK",
      "url": "tak.example.org",
      "port": 8089,
      "username": "YOUR_USERNAME",
      "password": "YOUR_PASSWORD"
    }
  ]
}
```

Tracker supports only `callsign`, `team` and `role` in `profile`; use a separate preset without the physiological fields. Either app accepts profile-only or servers-only presets. Profile values must be nonempty strings. Weight is in pounds; height is feet and inches; pants is pants length. Server URLs are bare hostnames or IPv4 addresses, not URLs with schemes or paths; omit `port` for the apps' default of 8089.

The bridge checks JSON structure, supported field names, server fields/ports and the 64 KiB size limit before uploading. The app remains responsible for validating actual profile values against its settings choices and ranges, and enforcing managed/locked settings. Upload verification does not mean those values will be accepted.

**To apply:** enable **Tool Preferences > Plugins > Commands** in the app, allow-list the sender's callsign, and send the returned command as a **direct TAK chat message** from that sender:

```text
#weartakcommandloadprofile name=odin-weartak
#weartaktrackercommandloadprofile name=odin-tracker
```

The watch needs an existing working TAK connection to receive the message. The bridge does not send chat or trigger application over ADB. Check the watch's chat reply for the application outcome; existing server connections are skipped, not updated. Neither the upload result nor the reply verifies successful server authentication. Callsign allow-lists do not authenticate a sender; use this feature only on trusted TAK networks.

With `--json`, `data` includes `app`, `package`, `name`, `remotePath`, `uploaded`, `verified`, `applied` (always `false`) and `applyCommand`. `success: true` means only that the preset file was uploaded and verified.

Presets contain **plaintext credentials**. Keep real files outside repositories and shared folders; protect both the PC and watch copies. A local `presets/` folder beside the bridge is Git-ignored as a convenience, not encrypted storage. File contents and credentials are not printed by this command; raw native upload diagnostics and JSON parser errors are withheld to prevent accidental disclosure. A temporary local read-back copy is deleted after verification.

### Result contract for scripts and agents

Exit code **0** means the operation succeeded; **1** means invalid arguments, timeout, or operation failure. An install requires both a zero ADB exit code and an explicit `Success` result. Bulk installations continue through all targets, then fail overall if any target failed.

With `--json`, the stable version-1 envelope is:

```json
{
  "schemaVersion": 1,
  "command": "--screenshot",
  "success": true,
  "serial": "192.168.1.33:5555",
  "data": { "path": "C:\\project\\watch.png" },
  "messages": [],
  "error": null
}
```

On failure, `success` is `false` and `error` contains the reason. `serial` is null for untargeted operations or failures before target resolution. `data` is null for install/connect/mirror/recovery, contains `path` for screenshots, contains native command `output` for screen/app controls, and contains upload metadata plus `applyCommand` for presets. Messages contain human-readable progress and native diagnostics rather than extra stdout text.

`--status-json` without `--json` retains its original bare status object. With `--json`, that object is under `data`. `watchConnected` describes the exact saved active endpoint in the authorized `device` state. When `--serial` or `--profile` is supplied, status also includes `selectedSerial` and `selectedConnected` for that per-call target; the saved active profile remains unchanged. A successful status query does not imply the watch is connected: inspect those fields.

Agents should discover commands using `--automation-help`, use `--json` and an explicit target for device actions, check both exit code and `success`, and never invoke server recovery automatically.

### Android Studio External Tools

In **Settings > Tools > External Tools**, add an install tool:

- **Program:** `C:\Windows\System32\cmd.exe`
- **Arguments:** `/d /c ""C:\tools\wearos-bridge\wearos-bridge.bat" --install "$ProjectFileDir$\app\build\outputs\apk\debug\app-debug.apk" --profile DEV --non-interactive --json"`
- **Working directory:** `$ProjectFileDir$`

Adjust the launcher path, module name, build variant, and profile for your project. Build the APK first; an External Tool invocation alone does not build it.

For a screenshot tool, use the same program/working directory and these arguments:

```text
/d /c ""C:\tools\wearos-bridge\wearos-bridge.bat" --screenshot "$ProjectFileDir$\watch.png" --profile DEV --json"
```

## Troubleshooting

### More than one ADB device

Reconnect through option 3. Mirroring and APK installation use the saved direct `IP:port` connection to select the correct watch.

### Pairing fails

Confirm that Wireless Debugging and **Pair new device** are open on the watch, then verify the pairing port and six-digit Wi-Fi pairing code.

### Connection fails

Use the port from the main Wireless Debugging screen, not the pairing port. Enter the current IP address and connection port in **3. Connect to Watch**. The connection port can change when Wireless Debugging restarts. Confirm the PC and watch are on the same network and keep the watch awake while connecting or installing.

### Watch shows "unauthorized"

If ADB reports the watch as `unauthorized`, confirm the **Allow debugging?** prompt on the watch, then connect again.

### "adb server is out of date" or devices behave inconsistently

Different bundled ADB versions can conflict on the same server port. Configure `WEAROS_BRIDGE_ADB` or `--adb` to use Studio's SDK executable, so the bridge and scrcpy use the same version. If pairing fails with a protocol-fault error, reopen **Pair new device** on the watch for a fresh code and port and retry. Only if the shared server really needs restarting, invoke `wearos-bridge.bat --recover-adb` (or `./wearos-bridge.sh --recover-adb`), understanding that this interrupts Studio's debugger, Logcat, and other ADB clients.

### Text entry through scrcpy does not save

Some watch apps require pressing their own Done, Enter, or checkmark control to commit text. If text works when entered directly on the watch but not through scrcpy, the behavior is likely specific to the app's text-field handling.
