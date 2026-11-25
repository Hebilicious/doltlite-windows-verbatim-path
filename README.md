# DoltLite on Windows: a verbatim path creates a database with no HEAD

On Windows, DoltLite cannot create a database at a verbatim path (`\\?\C:\...\x.db`). The first
open fails with `unable to open database file` and leaves a file with no `HEAD`. After that,
`dolt_hashof('HEAD')` fails with `dolt_hashof: invalid ref spec`. A plain path works.

`std::fs::canonicalize` in Rust gives verbatim paths. Found in
[Quadratique](https://github.com/Hebilicious/quadratique/pull/21).

## Versions

- DoltLite 0.51.15, the latest release (`doltlite-tools-win-x64-0.51.15.zip`).
- DoltLite `master`.
- Windows Server 2025 (GitHub `windows-latest`).

## Run

In PowerShell on Windows:

```powershell
./repro.ps1
```

The script downloads the release CLI. It creates a table at a plain path and at a verbatim path,
then reads `dolt_hashof('HEAD')` from each. Pass `-Doltlite <path to doltlite.exe>` to test another
build.

## Expected

Both paths give a commit hash, and the script exits with code 0.

## Actual

```
D:\a\...\.tmp\plain.db -> 4fec3e7013aa8024bd37b78551becac9294f9109
Error in 2nd command line argument: unable to open database file
\\?\D:\a\...\.tmp\verbatim.db -> Error in 2nd command line argument: dolt_hashof: invalid ref spec
```

The script exits with code 1.

## Cause

`src/chunk_store_lock.c` finds the folder of the database with `strrchr(path, '/')`. On Windows a
verbatim path keeps its backslashes, so the lock path becomes `.\\?\C:\...\x.db-lock`, which
Windows cannot open.

## Fix

- Issue: https://github.com/Hebilicious/doltlite/issues/1
- Pull request: https://github.com/Hebilicious/doltlite/pull/2

The [workflow](.github/workflows/repro.yml) runs `repro.ps1` on the release, and on `doltlite.exe`
built from `master` and from the fix branch. It also runs the fix branch's
`test/windows_path_smoke.sh` on both builds. The release and `master` fail. The fix branch passes.
