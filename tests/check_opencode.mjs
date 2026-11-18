// Check local OpenCode plugins with stubbed hooks, without sending heartbeats.
import assert from "node:assert/strict";
import path from "node:path";
import { pathToFileURL } from "node:url";

const directory = process.argv[2];
if (!directory) throw new Error("Pass the OpenCode configuration directory");

const files = [
  ["herdr-agent.js", "herdr.agent-state"],
  ["herdr-pane-title.js", "herdr.pane-title"],
  ["wakatime.js", "local.wakatime"],
];
const hooks = [];
const disposable = { dispose() {} };
const ctx = {
  location: { project: { directory: process.cwd() } },
  app: { version: "test" },
  event: { async *subscribe() {} },
  tool: { async hook(name) { hooks.push(`tool:${name}`); return disposable; } },
  session: { async hook(name) { hooks.push(`session:${name}`); return disposable; } },
};

for (const [file, expected] of files) {
  const loaded = await import(pathToFileURL(path.join(directory, "plugins", file)).href);
  assert.equal(loaded.default.id, expected);
  assert.equal(typeof loaded.default.setup, "function");
  const dispose = await loaded.default.setup(ctx);
  if (typeof dispose === "function") await dispose();
}
assert.ok(hooks.includes("tool:execute.after"));
assert.ok(hooks.includes("session:prompt"));
console.log("OpenCode plugin imports and isolated setup passed");
