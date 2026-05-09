import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const BLOCK_REASON = "Blocked by user";
const NO_UI_REASON = "No UI available for confirmation";
const READONLY_TOOLS = new Set(["read", "grep", "find", "ls"]);
const ALLOWED_BASH_COMMANDS = new Set([
	"cat",
	"cd",
	"fd",
	"find",
	"git",
	"grep",
	"head",
	"ls",
	"pwd",
	"rg",
	"sort",
	"tail",
	"tree",
	"uniq",
	"wc",
]);
const ALLOWED_GIT_SUBCOMMANDS = new Set([
	"branch",
	"diff",
	"grep",
	"log",
	"ls-files",
	"show",
	"status",
]);
const DISALLOWED_BASH_TOKENS = [";", "<", ">", "`", "$(", "\n", "\r", "||"];

type ExtensionContext = Parameters<Parameters<ExtensionAPI["on"]>[1]>[1];

type EditInput = {
	oldText?: unknown;
	newText?: unknown;
};

function toText(value: unknown, fallback = "") {
	const text = String(value ?? fallback);
	return text || fallback;
}

function getCommandName(segment: string) {
	const [name] = segment.trim().split(/\s+/, 1);
	return name ?? "";
}

function isAllowedBashSegment(command: string) {
	const trimmed = command.trim();
	if (!trimmed) return false;

	const name = getCommandName(trimmed);
	if (!ALLOWED_BASH_COMMANDS.has(name)) return false;

	if (name === "git") {
		const subcommand = trimmed.split(/\s+/)[1] ?? "";
		return ALLOWED_GIT_SUBCOMMANDS.has(subcommand);
	}

	return true;
}

function splitBashSegments(command: string) {
	const segments: string[] = [];
	let current = "";
	let quote: "'" | '"' | undefined;

	for (let i = 0; i < command.length; i++) {
		const char = command[i];

		if (quote) {
			current += char;
			if (char === quote) quote = undefined;
			continue;
		}

		if (char === "'" || char === '"') {
			quote = char;
			current += char;
			continue;
		}

		if (char === "|") {
			segments.push(current);
			current = "";
			continue;
		}

		if (char === "&") {
			if (command[i + 1] !== "&") return undefined;
			segments.push(current);
			current = "";
			i++;
			continue;
		}

		current += char;
	}

	if (quote) return undefined;
	segments.push(current);
	return segments;
}

function isAllowedBashCommand(command: string) {
	const trimmed = command.trim();
	if (!trimmed) return false;

	if (DISALLOWED_BASH_TOKENS.some((token) => trimmed.includes(token))) {
		return false;
	}

	const segments = splitBashSegments(trimmed);
	return segments !== undefined && segments.every((segment) => isAllowedBashSegment(segment));
}

async function confirmSimple(ctx: ExtensionContext, title: string, message: string) {
	return ctx.ui.confirm(title, message);
}

async function confirmEdit(ctx: ExtensionContext, filePath: string, _edits: EditInput[]) {
	return confirmSimple(ctx, "Allow edit?", `Apply edit to ${filePath}?`);
}

export default function confirmToolsExtension(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (READONLY_TOOLS.has(event.toolName)) {
			return undefined;
		}

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
