import type { ExtensionAPI, Theme } from "@mariozechner/pi-coding-agent";
import { VERSION } from "@mariozechner/pi-coding-agent";

const ART = [
	"██████  ███████",
	"██   ██   ███  ",
	"██   ██   ███  ",
	"██████    ███  ",
	"██        ███  ",
	"██        ███  ",
	"██      ███████",
];

function renderGreeting(theme: Theme): string[] {
	const title = theme.fg("accent", "PI");
	const subtitle = theme.fg("muted", `coding agent v${VERSION}`);
	const art = ART.map((line) => theme.fg("accent", `  ${line}`));

	return ["", ...art, "", `  ${title} ${subtitle}`, ""];
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;

		ctx.ui.setHeader((_tui, theme) => ({
			render: () => renderGreeting(theme),
			invalidate() {},
		}));
	});
}
