# Install Codex Vision

Codex Vision requires macOS, Swift, and Xcode command line tools.

```bash
git clone https://github.com/zfifteen/codex-vision.git
cd codex-vision
scripts/install-local.sh
```

The installer builds `CodexVision.app`, stages the plugin under `~/plugins/codex-vision`, updates `~/.agents/plugins/marketplace.json`, and registers the local marketplace plus `codex-vision@local` in `~/.codex/config.toml`.

## First Use

Codex Vision installs one slash command with two public modes:

```text
/codex-vision snapshot
/codex-vision streaming
```

`/codex-vision snapshot` starts the camera, returns one JPEG frame into the chat, and stops the camera.

`/codex-vision streaming` starts streaming mode. While streaming is active, the Mac camera indicator should stay on and Codex can call `codex_vision_frame` when visual context would help.

To stop streaming, ask Codex to stop camera use:

```text
Codex Vision streaming off
```

There is no public `/codex-vision frame` or `/codex-vision stop` slash mode in version 1.0. Those are MCP tool actions Codex performs from the installed skill.

macOS will ask for camera permission for `CodexVision.app` the first time the capture session starts. Repeated prompts usually mean the app identity changed and the local installer should be rerun.

## Uninstall

Remove the staged plugin directory:

```bash
rm -rf ~/plugins/codex-vision
```

Then remove the `codex-vision` entry from `~/.agents/plugins/marketplace.json` and the `codex-vision@local` plugin entry from `~/.codex/config.toml`.
