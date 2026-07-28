# szStart

> The project is in initial state, therefore no ready-to-go binaries, or even working builds.

<center><img src="assets/screenshot.png"></img></center>

Cross-platform Minecraft Server GUI written in Lazarus / FPC.

## Aims of this project

This application aims the easy creation of Minecraft Server on-the-fly, and managing it via GUI.

## Supported systems

Planned targets: 
- Windows 7 or newer
- Linux with Qt6 support
- macOS Big Sur or newer

## Third-party dependencies

In binary form, the program is compiled and linked as a single executable, distributed under the GPLv2-only license. The corresponding source code is available via this repository or distributed alongside the software.

### Internal packages

This project relies on the following internal packages configured in the Lazarus Project Options:

- **FPC RTL & Lazarus LCL** (FPC modified LGPL) \u2013 *The linking exception permits static compilation into our GPLv2 binary.*
- **mORMot 2** (Dual/Tri-licensed: MPL v1.1 or later / GPL v2.0 or later / LGPL v2.1 or later) \u2013 *We utilize this framework under its GPLv2-or-later option to remain compatible with our project license.*
- **SQLite3** via `mormot.db.raw.sqlite3.static` (Public Domain) \u2013 *Statically links raw, unencumbered SQLite3 object binaries.*

### External libraries

This project embeds the following external dependencies as Git submodules inside the `/libraries` directory:

- **libsodium** (ISC License) \u2013 https://github.com/jedisct1/libsodium
- **miniupnpc** (BSD 3-Clause License) \u2013 https://github.com/miniupnp/miniupnp

