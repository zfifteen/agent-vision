# Install Codex Vision

Codex Vision requires macOS, Swift, and Xcode command line tools.

```bash
git clone https://github.com/zfifteen/codex-vision.git
cd codex-vision
scripts/install-local.sh
```

The installer builds `CodexVision.app`, stages the plugin under `~/plugins/codex-vision`, updates `~/.agents/plugins/marketplace.json`, and registers the local marketplace plus `codex-vision@local` in `~/.codex/config.toml`.

## First Use

Codex Vision installs one slash command with three public arguments:

```text
/codex-vision snapshot
/codex-vision streaming
/codex-vision roast
```

`/codex-vision snapshot` starts the camera, waits for a usable JPEG frame, returns it into the chat, and stops the camera. If the camera returns a black warm-up frame, Codex Vision keeps the camera on, waits 5 seconds, and tries again up to 3 total attempts.

`/codex-vision streaming` starts streaming mode. While streaming is active, the Mac camera indicator should stay on and Codex can call `codex_vision_frame` when visual context would help.

`/codex-vision roast` starts the camera, waits for a usable JPEG frame, returns it into the chat, stops the camera, and asks Codex to write one opt-in playful roast of 400 characters or fewer from visible non-sensitive details.

To stop streaming, ask Codex to stop camera use:

```text
Codex Vision streaming off
```

You can also say `stop streaming` or `turn off the camera`. Codex maps those requests to `codex_vision_stop`.

macOS will ask for camera permission for `CodexVision.app` the first time the capture session starts. Repeated prompts usually mean the app identity changed and the local installer should be rerun.

## Uninstall

Remove the staged plugin directory:

```bash
rm -rf ~/plugins/codex-vision
```

Then remove the `codex-vision` entry from `~/.agents/plugins/marketplace.json` and the `codex-vision@local` plugin entry from `~/.codex/config.toml`.
