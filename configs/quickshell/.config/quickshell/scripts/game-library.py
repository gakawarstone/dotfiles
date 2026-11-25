"""List installed Steam games and artwork already cached by Steam."""

import json
import os
from pathlib import Path
import re


def vdf_values(path):
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    return [
        (key.lower(), re.sub(r'\\(["\\])', r"\1", value))
        for key, value in re.findall(r'^\s*"([^"]+)"[ \t]+"((?:[^"\\]|\\.)*)"', text, re.M)
    ]


def steam_games():
    home = Path.home()
    data = Path(os.environ.get("XDG_DATA_HOME") or home / ".local/share")
    roots = (
        home / ".steam/root",
        data / "Steam",
        home / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
    )
    games = {}
    for root in dict.fromkeys(path.resolve() for path in roots if path.is_dir()):
        folders = [Path(value) for key, value in vdf_values(root / "steamapps/libraryfolders.vdf") if key == "path"]
        for folder in dict.fromkeys([root, *folders]):
            apps = folder / "steamapps"
            for manifest in apps.glob("appmanifest_*.acf"):
                values = dict(vdf_values(manifest))
                app_id = values.get("appid", "")
                name = values.get("name", "").strip()
                flags = values.get("stateflags", "")
                if not app_id.isdecimal() or not name or not flags.isdecimal() or not int(flags) & 4:
                    continue
                if name.startswith(("Proton ", "Steam Linux Runtime", "Steamworks Common Redistributables")):
                    continue
                if not values.get("installdir") or not (apps / "common" / values["installdir"]).is_dir():
                    continue
                cache = root / "appcache/librarycache"
                art_dir = cache / app_id
                artwork = next((path.as_uri() for path in (
                    art_dir / "library_hero.jpg",
                    *sorted(art_dir.glob("*/library_hero.jpg")),
                    cache / f"{app_id}_library_hero.jpg",
                    art_dir / "header.jpg",
                    *sorted(art_dir.glob("*/library_header.jpg")),
                    cache / f"{app_id}_header.jpg",
                ) if path.is_file()), "")
                last_played = values.get("lastplayed", "")
                steam = ["flatpak", "run", "com.valvesoftware.Steam"] if ".var" in root.parts else ["steam"]
                games[app_id] = {
                    "id": f"steam:{app_id}",
                    "steamAppId": app_id,
                    "name": name,
                    "source": "Steam",
                    "artwork": artwork,
                    "lastPlayed": int(last_played) * 1000 if last_played.isdecimal() else 0,
                    "command": [*steam, "-silent", f"steam://rungameid/{app_id}"],
                }
    return list(games.values())


if __name__ == "__main__":
    state_dir = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    state_dir.mkdir(parents=True, exist_ok=True)
    print(json.dumps(steam_games()))
