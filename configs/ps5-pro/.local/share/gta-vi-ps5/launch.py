# /// script
# dependencies = ["PSNAWP==3.0.3"]
# ///
"""Launch a game on the paired PS5 Pro and connect with Chiaki-ng."""

import argparse
import fcntl
from functools import partial
import os
from pathlib import Path
import subprocess
import sys

from cloud import CloudAuthorizationError, CloudError, SonyConsoleService
from psnawp_api import PSNAWP

GAMES = {
    "gta-vi": ("GTA VI", "PPSA01547", "gws"),
    "fc-27": ("EA SPORTS FC 27", "PPSA34015", "gws"),
    "god-of-war-ragnarok": ("God of War Ragnarök", "PPSA08330", "gws"),
    "astros-playroom": ("Astro's Playroom", "PPSA01325", "gws"),
}
CONSOLE = "PS5-035"
HOST = "192.168.178.60"
CHIAKI = Path.home() / ".local/bin/chiaki-ng-framegen"


def show_status(game, desktop_id, stage, message):
    print(message, file=sys.stderr, flush=True)
    try:
        result = subprocess.run(
            [
                "/usr/bin/quickshell", "ipc", "call", "ps5-launch", "gameStatus",
                game, desktop_id, stage, message,
            ],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
        if result.returncode != 0:
            print("Quickshell launch window unavailable.", file=sys.stderr)
    except (OSError, subprocess.TimeoutExpired):
        print("Quickshell launch window unavailable.", file=sys.stderr)


def launch(game, title_id, profile, report):
    if not os.access(CHIAKI, os.X_OK):
        report("error", "Сборка Chiaki-ng с генерацией кадров недоступна.")
        return 1

    token = subprocess.run(
        ["/usr/bin/secret-tool", "lookup", "application", "gta-vi-ps5", "credential", "npsso"],
        capture_output=True,
        text=True,
        timeout=20,
    ).stdout.strip()
    if not token:
        report("error", "Разблокируй связку ключей или обнови авторизацию PSN.")
        return 1

    sony = SonyConsoleService(PSNAWP(token).authenticator)
    consoles = sony.consoles(include_inventory=True)
    matches = [
        console for console in consoles
        if ((console.get("device") or {}).get("name") or "").casefold() == CONSOLE.casefold()
    ]
    if len(matches) != 1:
        report("error", "PSN не смогла однозначно найти зарегистрированную PS5 Pro.")
        return 1

    console = matches[0]
    inventory = (console.get("systemData") or {}).get("installedTitles") or {}
    titles = inventory.get("titles")
    if titles is not None and not any(
        str(row.get("npTitleId", "")).upper().removesuffix("_00") == title_id
        for row in titles
    ):
        report("error", f"В списке установленных игр PS5 Pro нет {game}.")
        return 1

    sony.launch(
        title_id,
        console["duid"],
        timeout=65,
        on_accepted=lambda: report(
            "waiting", "PSN приняла команду. Жду подтверждения от консоли."
        ),
    )
    report("connecting", "Подключаю Chiaki. Жду изображение с PS5 Pro.")
    print(f"PSN confirmed {game} launch. Opening Chiaki-ng with profile {profile or 'Default'}.", flush=True)
    result = subprocess.run(
        [
            str(CHIAKI),
            f"--profile={profile}",
            "--fullscreen",
            "--exit-app-on-stream-exit",
            "stream", CONSOLE, HOST,
        ],
        check=False,
    )
    if result.returncode != 0:
        report("error", "Chiaki завершился с ошибкой подключения.")
    return result.returncode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("game", nargs="?", choices=GAMES, default="gta-vi")
    game_key = parser.parse_args().game
    game, title_id, profile = GAMES[game_key]
    report = partial(show_status, game, f"{game_key}-ps5")
    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}")
    with (runtime_dir / "gta-vi-ps5.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            report("busy", "Уже открыт сеанс PS5 из игрового ярлыка.")
            return 1
        try:
            report("checking", "Проверяю авторизацию и установленную игру.")
            return launch(game, title_id, profile, report)
        except CloudAuthorizationError:
            report("error", "PSN отклонила авторизацию. Обнови вход для игровых ярлыков.")
        except CloudError as exc:
            report("error", f"PSN не подтвердила запуск {game}. {exc}")
        except Exception as exc:
            report("error", f"Не удалось запустить {game}. {type(exc).__name__}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
