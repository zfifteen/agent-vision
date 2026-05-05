# Install Codex Vision

Codex Vision requires macOS, Swift, and Xcode command line tools.

```bash
git clone https://github.com/zfifteen/codex-vision.git
cd codex-vision
scripts/install-local.sh
```

The installer builds `CodexVision.app`, stages the plugin under `~/plugins/codex-vision`, updates `~/.agents/plugins/marketplace.json`, and registers the local marketplace plus `codex-vision@local` in `~/.codex/config.toml`.

## First Use

Ask Codex:

```text
/codex-vision snapshot
```

macOS will ask for camera permission for `CodexVision.app` the first time the capture session starts.

Streaming mode commands:

```text
/codex-vision streaming
```

## Uninstall

Remove the staged plugin directory:

```bash
rm -rf ~/plugins/codex-vision
```

Then remove the `codex-vision` entry from `~/.agents/plugins/marketplace.json` and the `codex-vision@local` plugin entry from `~/.codex/config.toml`.
