# Publishing to winget

Scrcpy GUI is distributed on the Windows Package Manager (winget) so users can install it with:

```
winget install GeorgeEnglezos.ScrcpyGUI
```

Releases are kept up to date automatically by the `publish-winget` job in
`.github/workflows/build.yml`. That job only runs the **update** path, so the
package must be created once by hand first.

## One-time setup

### 1. Cut a clean release
winget rejects non-semver versions. Tag a real release like `v1.7.3`
(not `v1.7.3-Test-Builds`). The release must contain
`scrcpy-gui-setup-v<version>.exe`.

### 2. Create a Personal Access Token (PAT)
winget submissions are pull requests to the public `microsoft/winget-pkgs`
repo, so the token only needs public-repo access.

- GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)
- Scope: `public_repo`
- Copy the token.

### 3. Add the token as a repo secret
- Repo -> Settings -> Secrets and variables -> Actions -> New repository secret
- Name: `WINGET_TOKEN`
- Value: the PAT from step 2

### 4. First submission (manual, run on Windows)
This creates the package in winget. Done once.

```
winget install wingetcreate
wingetcreate new https://github.com/GeorgeEnglezos/Scrcpy-GUI/releases/download/v1.7.3/scrcpy-gui-setup-v1.7.3.exe
```

`wingetcreate` auto-detects the Inno installer and computes the hash. Fill in
the metadata when prompted:

| Field             | Value                                                          |
| ----------------- | -------------------------------------------------------------- |
| PackageIdentifier | `GeorgeEnglezos.ScrcpyGUI`                                      |
| PackageName       | `Scrcpy GUI`                                                   |
| Publisher         | `George Englezos`                                              |
| License           | `AGPL-3.0`                                                     |
| ShortDescription  | `An unofficial beginner-friendly user interface for the Scrcpy Project` |
| Moniker           | `scrcpy-gui`                                                   |
| PackageUrl        | `https://github.com/GeorgeEnglezos/Scrcpy-GUI`                |

Then submit the pull request:

```
wingetcreate submit --token <YOUR_PAT>
```

Microsoft's bot validates it (installs the exe in a sandbox). Once a moderator
merges the PR, `winget install GeorgeEnglezos.ScrcpyGUI` works.

## After that: fully automatic
Every time you push a clean `vX.Y.Z` tag, the `publish-winget` CI job runs
`wingetcreate update` and opens a new winget PR pointing at that release's
installer. No manual steps needed for future versions.
