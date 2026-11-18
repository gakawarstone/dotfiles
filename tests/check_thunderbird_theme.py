#!/usr/bin/env python3
"""Install and enable the theme in an isolated, headless Thunderbird profile."""

import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import zipfile


THEME = Path(__file__).resolve().parents[1] / "configs/thunderbird/.config/thunderbird/mocha-mauve.xpi"
THEME_ID = "{47f5c9df-1d03-5424-ae9e-0613b69a9d2f}"


def check_archive():
    with zipfile.ZipFile(THEME) as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["applications"]["gecko"]["id"] == THEME_ID
        stylesheet = manifest.get("theme_experiment", {}).get("stylesheet")
        assert stylesheet is None or stylesheet in archive.namelist()
        for icon in manifest["icons"].values():
            assert archive.read(icon).startswith(b"\x89PNG\r\n\x1a\n")


def check_thunderbird(binary="thunderbird", policy=False):
    with tempfile.TemporaryDirectory(prefix="tb-theme-check-") as tmp:
        profile = Path(tmp) / "profile"
        profile.mkdir()
        with socket.socket() as port_socket:
            port_socket.bind(("127.0.0.1", 0))
            port = port_socket.getsockname()[1]
        (profile / "user.js").write_text(
            f'user_pref("marionette.port", {port});\n'
            'user_pref("app.update.auto", false);\n'
        )
        env = dict(os.environ, HOME=tmp)
        env.pop("MOZ_DISABLE_NONLOCAL_CONNECTIONS", None)
        env.pop("DBUS_SESSION_BUS_ADDRESS", None)
        if policy:
            # Simulate the existing disabled version before applying the policy.
            extensions = profile / "extensions"
            extensions.mkdir()
            with zipfile.ZipFile(THEME) as source, zipfile.ZipFile(
                extensions / f"{THEME_ID}.xpi", "w", zipfile.ZIP_DEFLATED
            ) as old:
                for name in source.namelist():
                    data = source.read(name)
                    if name == "manifest.json":
                        manifest = json.loads(data)
                        manifest["version"] = "1.0.0"
                        data = json.dumps(manifest).encode()
                    old.writestr(name, data)
            seed = subprocess.Popen(
                [shutil.which("thunderbird") or "thunderbird", "--headless", "--no-remote", "--profile", str(profile)],
                env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
            try:
                for _ in range(100):
                    try:
                        data = json.loads((profile / "extensions.json").read_text())
                        addon = next(a for a in data["addons"] if a.get("id") == THEME_ID)
                        if addon.get("version") == "1.0.0" and addon.get("userDisabled"):
                            break
                    except (OSError, ValueError, StopIteration, KeyError):
                        pass
                    time.sleep(0.1)
                else:
                    raise RuntimeError("Could not prepare disabled old theme")
            finally:
                seed.terminate()
                try:
                    seed.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    seed.kill()
                    seed.wait()
        log = (Path(tmp) / "thunderbird.log").open("w+")
        process = subprocess.Popen(
            [binary, "--headless", "--no-remote", "--marionette",
             "--remote-allow-system-access", "--profile", str(profile)],
            env=env, stdout=subprocess.DEVNULL, stderr=log,
        )
        try:
            for _ in range(100):
                try:
                    connection = socket.create_connection(("127.0.0.1", port), timeout=1)
                    break
                except OSError:
                    if process.poll() is not None:
                        raise RuntimeError("Thunderbird exited before Marionette started")
                    time.sleep(0.1)
            else:
                raise RuntimeError("Thunderbird Marionette did not start")
            with connection:
                connection.settimeout(20)

                def receive():
                    length = b""
                    while not length.endswith(b":"):
                        chunk = connection.recv(1)
                        if not chunk:
                            raise EOFError("Marionette connection closed")
                        length += chunk
                    expected = int(length[:-1])
                    data = b""
                    while len(data) < expected:
                        chunk = connection.recv(expected - len(data))
                        if not chunk:
                            raise EOFError("Marionette response truncated")
                        data += chunk
                    return json.loads(data)

                def send(number, name, params):
                    data = json.dumps([0, number, name, params]).encode()
                    connection.sendall(str(len(data)).encode() + b":" + data)
                    response = receive()
                    if response[2]:
                        raise RuntimeError(response[2])
                    return response[3]["value"]

                receive()
                # NewSession returns capabilities directly rather than a value.
                data = json.dumps([0, 1, "WebDriver:NewSession", {"capabilities": {}}]).encode()
                connection.sendall(str(len(data)).encode() + b":" + data)
                response = receive()
                if response[2]:
                    raise RuntimeError(response[2])
                send(2, "Marionette:SetContext", {"value": "chrome"})
                script = """
                  const path = arguments[0];
                  const policy = arguments[2];
                  const done = arguments[arguments.length - 1];
                  (async () => {
                    const {AddonManager} = ChromeUtils.importESModule("resource://gre/modules/AddonManager.sys.mjs");
                    const win = Services.wm.getMostRecentWindow("mail:3pane");
                    let addon;
                    if (policy) {
                      for (let attempt = 0; attempt < 100; attempt++) {
                        addon = await AddonManager.getAddonByID(arguments[1]);
                        if (addon && addon.isActive) break;
                        await new Promise(resolve => win.setTimeout(resolve, 100));
                      }
                    } else {
                      const file = Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile);
                      file.initWithPath(path);
                      const install = await AddonManager.getInstallForFile(file);
                      await install.install();
                      addon = await AddonManager.getAddonByID(arguments[1]);
                      await addon.enable();
                    }
                    if (!addon) throw new Error("Theme was not installed");
                    let windowColor = "";
                    if (win) {
                      for (let attempt = 0; attempt < 50; attempt++) {
                        windowColor = win.getComputedStyle(win.document.documentElement)
                          .getPropertyValue("--lwt-accent-color").trim();
                        if (windowColor === "rgb(30, 30, 46)") break;
                        await new Promise(resolve => win.setTimeout(resolve, 100));
                      }
                    }
                    return {id: addon.id, version: addon.version, type: addon.type,
                            active: addon.isActive, disabled: addon.appDisabled,
                            theme: Services.prefs.getStringPref("extensions.activeThemeID", ""),
                            windowColor};
                  })().then(done, e => done({error: String(e)}));
                """
                result = send(3, "WebDriver:ExecuteAsyncScript", {
                    "script": script, "args": [str(THEME), THEME_ID, policy],
                    "newSandbox": True, "sandbox": "default", "scriptTimeout": 20000,
                })
                assert result.get("id") == THEME_ID, result
                assert result["type"] == "theme" and result["active"] and not result["disabled"], result
                assert result["theme"] == THEME_ID, result
                assert result["windowColor"] == "rgb(30, 30, 46)", result
                print(f'Thunderbird enabled {result["id"]}, version {result["version"]}; '
                      f'window color: {result["windowColor"]!r}')
        except Exception:
            log.flush()
            print((Path(tmp) / "thunderbird.log").read_text()[-4000:], file=sys.stderr)
            raise
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
            log.close()


if __name__ == "__main__":
    check_archive()
    check_thunderbird(sys.argv[1], policy=True) if len(sys.argv) > 1 else check_thunderbird()
