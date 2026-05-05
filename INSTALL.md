# Install Codex Vision

Codex Vision requires macOS, Swift, and Xcode command line tools.

```bash
git clone https://github.com/zfifteen/codex-vision.git
cd codex-vision
scripts/install-local.sh
```

The installer builds `CodexVision.app`, stages the plugin under `~/plugins/codex-vision`, and updates `~/.agents/plugins/marketplace.json`.

After installation, restart Codex and enable the plugin if prompted.

## First Use

Ask Codex:

```text
Use Codex Vision to start the camera and inspect the latest frame.
```

macOS will ask for camera permission for `CodexVision.app` the first time the capture session starts.

## Uninstall

Remove the staged plugin directory:

```bash
rm -rf ~/plugins/codex-vision
```

Then remove the `codex-vision` entry from `~/.agents/plugins/marketplace.json`.
