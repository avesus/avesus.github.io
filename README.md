# avesus.github.io
Brian's website

## Local preview

This repository is a static site, so it can be previewed with Python's built-in
HTTP server before pushing changes to GitHub.

```sh
./host-locally.sh
```

Then open <http://127.0.0.1:8179/> and capture screenshots at the target browser
resolutions before deploying.

For a quick mobile homepage screenshot, run:

```sh
./screenshot-homepage.sh
```

The screenshot is written to `screenshots/homepage-mobile.png`. The
`screenshots/` directory is ignored by Git so local captures can stay inside the
repo without being committed.

Platform notes:

- macOS/Linux: run `./host-locally.sh`. If the checkout lost executable
  permissions, run `sh ./host-locally.sh`.
- Windows: run `./host-locally.sh` from Git Bash or WSL. From PowerShell with
  the default Git for Windows install, run
  `& "C:\Program Files\Git\bin\bash.exe" ./host-locally.sh`; if `bash` is on
  `PATH`, `bash ./host-locally.sh` also works.
- Use another port with `./host-locally.sh 8180` or `PORT=8180 ./host-locally.sh`
  if `8179` is already in use.

The script requires Python 3 and automatically tries `python3`, `python`, then
the Windows Python launcher `py -3`.

The screenshot script requires Node.js/npm. It uses `npx playwright screenshot`
and prefers an installed Chrome or Edge browser when one is available. You can
override the defaults with environment variables, for example:

```sh
VIEWPORT=1280,720 OUTPUT=screenshots/homepage-desktop.png ./screenshot-homepage.sh
```
