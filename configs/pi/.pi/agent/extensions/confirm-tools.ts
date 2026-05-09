import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const BLOCK_REASON = "Blocked by user";
const NO_UI_REASON = "No UI available for confirmation";
const ALLOWED_BASH_PREFIXES = ["cd", "find", "rg", "git diff", "git status"];
const DISALLOWED_BASH_TOKENS = [";", "|", "<", ">", "`", "$(", "\n", "\r", "||"];

type EditInput = {
	oldText?: unknown;
	newText?: unknown;
};

function toText(value: unknown, fallback = "") {
	const text = String(value ?? fallback);
	return text || fallback;
}

function isAllowedBashSegment(command: string) {
	const trimmed = command.trim();
	return ALLOWED_BASH_PREFIXES.some(
		(prefix) => trimmed === prefix || trimmed.startsWith(`${prefix} `),
	);
}

function isAllowedBashCommand(command: string) {
	const trimmed = command.trim();
	if (!trimmed) return false;

	if (DISALLOWED_BASH_TOKENS.some((token) => trimmed.includes(token))) {
		return false;
	}

	if (trimmed.replaceAll("&&", "").includes("&")) {
		return false;
	}

	return trimmed.split("&&").every((segment) => isAllowedBashSegment(segment));
}

function formatDiffLines(prefix: "-" | "+", text: string) {
	return text.split("\n").map((line) => `${prefix} ${line}`);
}

function buildEditDiff(edits: EditInput[]) {
	return edits
		.map((edit, index) => {
			const oldText = toText(edit.oldText, "(empty)");
			const newText = toText(edit.newText, "(empty)");

			return [
				`## Edit ${index + 1}`,
				"```diff",
				...formatDiffLines("-", oldText),
				...formatDiffLines("+", newText),
				"```",
			].join("\n");
		})
		.join("\n\n");
}

async function confirmSimple(
	ctx: Parameters<Parameters<ExtensionAPI["on"]>[1]>[1],
	title: string,
	message: string,
) {
	return ctx.ui.confirm(title, message);
}

async function confirmEdit(
	ctx: Parameters<Parameters<ExtensionAPI["on"]>[1]>[1],
	path: string,
	edits: EditInput[],
) {
	const diff = buildEditDiff(edits);
	const [{ getMarkdownTheme }, { Box, Container, Key, Markdown, Spacer, Text, matchesKey }] =
		await Promise.all([
			import("@mariozechner/pi-coding-agent"),
			import("@mariozechner/pi-tui"),
		]);
	const markdownTheme = getMarkdownTheme();

	return ctx.ui.custom<boolean>(
		(_tui, theme, _kb, done) => {
			const content = new Container();
			content.addChild(new Text(theme.fg("accent", theme.bold("Allow edit?")), 0, 0));
			content.addChild(new Spacer(1));
			content.addChild(new Markdown(`**File:** \`${path}\``, 0, 0, markdownTheme));
			content.addChild(new Spacer(1));
			content.addChild(new Markdown(diff || "*(no diff provided)*", 0, 0, markdownTheme));
			content.addChild(new Spacer(1));
			content.addChild(new Text(theme.fg("dim", "Enter = allow, Esc = block"), 0, 0));

			const box = new Box(1, 1, (text) => theme.bg("customMessageBg", text));
			box.addChild(content);

			return {
				render(width: number) {
					return box.render(width);
				},
				invalidate() {
					box.invalidate();
				},
				handleInput(data: string) {
					if (matchesKey(data, Key.enter)) {
						done(true);
						return;
					}

					if (matchesKey(data, Key.escape)) {
						done(false);
					}
				},
			};
		},
		{ overlay: true },
	);
}

export default function confirmToolsExtension(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName === "bash") {
			const command = toText(event.input.command);
			if (isAllowedBashCommand(command)) {
				return undefined;
			}

			if (!ctx.hasUI) {
				return { block: true, reason: NO_UI_REASON };
			}

			const confirmed = await confirmSimple(
				ctx,
				"Allow bash command?",
				command || "(empty command)",
			);
			if (!confirmed) return { block: true, reason: BLOCK_REASON };
		}

		if (!ctx.hasUI) {
			return { block: true, reason: NO_UI_REASON };
		}

		if (event.toolName === "write") {
			const path = toText(event.input.path);
			const confirmed = await confirmSimple(ctx, "Allow write?", `Write file: ${path}`);
			if (!confirmed) return { block: true, reason: BLOCK_REASON };
		}

		if (event.toolName === "edit") {
			const path = toText(event.input.path);
			const edits = Array.isArray(event.input.edits) ? (event.input.edits as EditInput[]) : [];
			const confirmed = await confirmEdit(ctx, path, edits);
			if (!confirmed) return { block: true, reason: BLOCK_REASON };
		}

		return undefined;
	});
}
