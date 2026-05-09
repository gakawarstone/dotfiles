import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

const MAX_UNTRACKED_FILE_BYTES = 50_000;
const MAX_DIFF_BYTES = 150_000;

type ExecResult = {
	stdout: string;
	stderr: string;
	code: number;
	killed?: boolean;
};

async function execOrThrow(pi: ExtensionAPI, command: string, args: string[], cwd: string) {
	const result = (await pi.exec(command, args, { cwd })) as ExecResult;
	if (result.code !== 0) {
		throw new Error(result.stderr || `${command} ${args.join(" ")} failed`);
	}
	return result.stdout;
}

function parseLines(text: string) {
	return text
		.split("\n")
		.map((line) => line.trim())
		.filter(Boolean);
}

function truncate(text: string, maxBytes: number) {
	if (Buffer.byteLength(text, "utf8") <= maxBytes) {
		return text;
	}

	let output = text;
	while (Buffer.byteLength(output, "utf8") > maxBytes) {
		output = output.slice(0, Math.max(1, Math.floor(output.length * 0.9)));
	}
	return `${output}\n\n[truncated]`;
}

async function getUntrackedFileBlock(cwd: string, relativePath: string) {
	const absolutePath = join(cwd, relativePath);
	const content = await readFile(absolutePath, "utf8");
	const body = truncate(content, MAX_UNTRACKED_FILE_BYTES);
	return [
		`### ${relativePath}`,
		"```",
		body,
		"```",
	].join("\n");
}

export default function reviewExtension(pi: ExtensionAPI) {
	pi.registerCommand("review", {
		description: "Review current unstaged changes and score them from 1 to 5",
		handler: async (_args, ctx) => {
			await ctx.waitForIdle();

			let repoRoot: string;
			try {
				repoRoot = (await execOrThrow(pi, "git", ["rev-parse", "--show-toplevel"], ctx.cwd)).trim();
			} catch {
				ctx.ui.notify("Not inside a git repository", "error");
				return;
			}

			const trackedFiles = parseLines(
				await execOrThrow(pi, "git", ["diff", "--name-only", "--"], repoRoot),
			);
			const untrackedFiles = parseLines(
				await execOrThrow(pi, "git", ["ls-files", "--others", "--exclude-standard"], repoRoot),
			);

			if (trackedFiles.length === 0 && untrackedFiles.length === 0) {
				ctx.ui.notify("No unstaged or untracked files to review", "info");
				return;
			}

			const trackedDiffRaw = await execOrThrow(pi, "git", ["diff", "--no-ext-diff", "--"], repoRoot);
			const trackedDiff = truncate(trackedDiffRaw, MAX_DIFF_BYTES);

			const untrackedBlocks = await Promise.all(
				untrackedFiles.map(async (file) => {
					try {
						return await getUntrackedFileBlock(repoRoot, file);
					} catch (error) {
						const message = error instanceof Error ? error.message : String(error);
						return `### ${file}\n\nCould not read file: ${message}`;
					}
				}),
			);

			const prompt = [
				"Review the current unstaged git changes in this repository.",
				"",
				"Score each file from 1 to 5:",
				"- 1 = very poor / risky",
				"- 2 = weak",
				"- 3 = acceptable",
				"- 4 = good",
				"- 5 = excellent",
				"",
				"Be critical but concise.",
				"For each file, mention the strongest part, the main issue, and one concrete improvement.",
				"Then give a short overall verdict and overall score.",
				"Prefer a compact markdown table for the per-file review.",
				"",
				"## Tracked unstaged files",
				trackedFiles.length > 0 ? trackedFiles.map((file) => `- ${file}`).join("\n") : "(none)",
				"",
				"## Untracked files",
				untrackedFiles.length > 0 ? untrackedFiles.map((file) => `- ${file}`).join("\n") : "(none)",
				"",
				"## Tracked unstaged diff",
				"```diff",
				trackedDiff || "(no diff)",
				"```",
				"",
				"## Untracked file contents",
				untrackedBlocks.length > 0 ? untrackedBlocks.join("\n\n") : "(none)",
			].join("\n");

			pi.sendUserMessage(prompt);
		},
	});
}
