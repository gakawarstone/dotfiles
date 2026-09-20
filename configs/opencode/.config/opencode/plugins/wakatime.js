// Local WakaTime plugin for OpenCode V2.
// Derived from angristan/opencode-wakatime (MIT) and ported to the V2 plugin
// API: default export with id + setup, tool hooks instead of
// message.part.updated events, ctx.app.version instead of /global/health.
import { execSync, spawn } from "node:child_process";
import * as crypto from "node:crypto";
import * as fs from "node:fs";
import { createWriteStream } from "node:fs";
import * as https from "node:https";
import * as os from "node:os";
import * as path from "node:path";

const PLUGIN_VERSION = "2.0.0-local";

function getWakatimeHomeFromEnv() {
  const value = process.env.WAKATIME_HOME?.trim();
  if (!value) return undefined;
  if (value === "~") return os.homedir();
  if (value.startsWith("~/") || value.startsWith("~\\")) {
    return path.join(os.homedir(), value.slice(2));
  }
  return value;
}

function getWakatimeHomeDir() {
  return getWakatimeHomeFromEnv() ?? os.homedir();
}

function getWakatimeResourcesDir() {
  return getWakatimeHomeFromEnv() ?? path.join(os.homedir(), ".wakatime");
}

function getWakatimeConfigFilePath() {
  return path.join(getWakatimeHomeDir(), ".wakatime.cfg");
}

const LogLevel = { DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3 };
const LogLevelName = ["DEBUG", "INFO", "WARN", "ERROR"];

const logger = {
  level: LogLevel.INFO,
  setLevel(level) {
    this.level = level;
  },
  debug(msg) {
    this.log(LogLevel.DEBUG, msg);
  },
  info(msg) {
    this.log(LogLevel.INFO, msg);
  },
  warn(msg) {
    this.log(LogLevel.WARN, msg);
  },
  error(msg) {
    this.log(LogLevel.ERROR, msg);
  },
  errorException(err) {
    this.error(err instanceof Error ? err.message : String(err));
  },
  log(level, msg) {
    if (level < this.level) return;
    const line = `[${new Date().toISOString()}][${LogLevelName[level]}] ${msg}\n`;
    try {
      const logFile = path.join(getWakatimeResourcesDir(), "opencode.log");
      const dir = path.dirname(logFile);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.appendFileSync(logFile, line);
    } catch {
      // Silently ignore logging errors
    }
  },
};

let stateFile = path.join(getWakatimeResourcesDir(), "opencode.json");

function initState(projectFolder) {
  const hash = crypto.createHash("md5").update(projectFolder).digest("hex").slice(0, 8);
  stateFile = path.join(getWakatimeResourcesDir(), `opencode-${hash}.json`);
}

function readState() {
  try {
    return JSON.parse(fs.readFileSync(stateFile, "utf-8"));
  } catch {
    return {};
  }
}

function writeState(state) {
  try {
    const dir = path.dirname(stateFile);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
  } catch {
    // Silently ignore state write errors
  }
}

function timestamp() {
  return Math.floor(Date.now() / 1000);
}

function shouldSendHeartbeat(force = false) {
  if (force) return true;
  try {
    return timestamp() - (readState().lastHeartbeatAt ?? 0) >= 60;
  } catch {
    return true;
  }
}

function updateLastHeartbeat() {
  writeState({ lastHeartbeatAt: timestamp() });
}

function whichSync(cmd) {
  try {
    const result = execSync(os.platform() === "win32" ? `where ${cmd}` : `which ${cmd}`, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return result.trim().split("\n")[0] || null;
  } catch {
    return null;
  }
}

const GITHUB_RELEASES_URL = "https://api.github.com/repos/wakatime/wakatime-cli/releases/latest";
const GITHUB_DOWNLOAD_URL = "https://github.com/wakatime/wakatime-cli/releases/latest/download";
const UPDATE_CHECK_INTERVAL = 4 * 60 * 60 * 1000;

const dependencies = {
  resourcesLocation: getWakatimeResourcesDir(),
  cliLocation: undefined,
  get stateFile() {
    return path.join(this.resourcesLocation, "opencode-cli-state.json");
  },
  isWindows() {
    return os.platform() === "win32";
  },
  getOsName() {
    return os.platform() === "win32" ? "windows" : os.platform();
  },
  getArchitecture() {
    const arch = os.arch();
    if (arch === "x64") return "amd64";
    if (arch === "ia32" || arch.includes("32")) return "386";
    if (arch === "arm64") return "arm64";
    if (arch === "arm") return "arm";
    return arch;
  },
  getCliBinaryName() {
    return `wakatime-cli-${this.getOsName()}-${this.getArchitecture()}${this.isWindows() ? ".exe" : ""}`;
  },
  getCliDownloadUrl() {
    return `${GITHUB_DOWNLOAD_URL}/wakatime-cli-${this.getOsName()}-${this.getArchitecture()}.zip`;
  },
  readCliState() {
    try {
      if (fs.existsSync(this.stateFile)) return JSON.parse(fs.readFileSync(this.stateFile, "utf-8"));
    } catch {
      // Ignore errors
    }
    return {};
  },
  writeCliState(state) {
    try {
      fs.mkdirSync(path.dirname(this.stateFile), { recursive: true });
      fs.writeFileSync(this.stateFile, JSON.stringify(state, null, 2));
    } catch {
      // Ignore errors
    }
  },
  getCliLocationGlobal() {
    try {
      const globalPath = whichSync(`wakatime-cli${this.isWindows() ? ".exe" : ""}`);
      if (globalPath) {
        logger.debug(`Found global wakatime-cli: ${globalPath}`);
        return globalPath;
      }
    } catch {
      // Ignore errors
    }
    return undefined;
  },
  getCliLocation() {
    if (this.cliLocation) return this.cliLocation;
    const globalCli = this.getCliLocationGlobal();
    if (globalCli) {
      this.cliLocation = globalCli;
      return this.cliLocation;
    }
    this.cliLocation = path.join(this.resourcesLocation, this.getCliBinaryName());
    return this.cliLocation;
  },
  isCliInstalled() {
    return fs.existsSync(this.getCliLocation());
  },
  shouldCheckForUpdates() {
    if (this.getCliLocationGlobal()) return false;
    const state = this.readCliState();
    if (!state.lastChecked) return true;
    return Date.now() - state.lastChecked > UPDATE_CHECK_INTERVAL;
  },
  async checkAndInstallCli() {
    if (this.getCliLocationGlobal()) {
      logger.debug("Using global wakatime-cli, skipping installation check");
      return;
    }
    if (!this.isCliInstalled()) {
      logger.info("wakatime-cli not found, downloading...");
      await this.installCli();
      return;
    }
    if (this.shouldCheckForUpdates()) {
      logger.debug("Checking for wakatime-cli updates...");
      const latestVersion = await this.getLatestVersion();
      const state = this.readCliState();
      if (latestVersion && latestVersion !== state.version) {
        logger.info(`Updating wakatime-cli to ${latestVersion}...`);
        await this.installCli();
        this.writeCliState({ lastChecked: Date.now(), version: latestVersion });
      } else {
        this.writeCliState({ ...state, lastChecked: Date.now() });
      }
    }
  },
  getLatestVersion() {
    return new Promise((resolve) => {
      https
        .get(GITHUB_RELEASES_URL, { headers: { "User-Agent": "opencode-wakatime" } }, (res) => {
          let data = "";
          res.on("data", (chunk) => {
            data += chunk;
          });
          res.on("end", () => {
            try {
              resolve(JSON.parse(data).tag_name);
            } catch {
              resolve(undefined);
            }
          });
        })
        .on("error", () => resolve(undefined));
    });
  },
  async installCli() {
    const zipUrl = this.getCliDownloadUrl();
    const zipFile = path.join(this.resourcesLocation, `wakatime-cli-${Date.now()}.zip`);
    try {
      fs.mkdirSync(this.resourcesLocation, { recursive: true });
      logger.debug(`Downloading wakatime-cli from ${zipUrl}`);
      await this.downloadFile(zipUrl, zipFile);
      logger.debug(`Extracting wakatime-cli to ${this.resourcesLocation}`);
      await this.extractZip(zipFile, this.resourcesLocation);
      if (!this.isWindows()) {
        const cliPath = this.getCliLocation();
        if (fs.existsSync(cliPath)) {
          fs.chmodSync(cliPath, 0o755);
          logger.debug(`Set executable permission on ${cliPath}`);
        }
      }
      logger.info("wakatime-cli installed successfully");
    } catch (err) {
      logger.errorException(err);
      throw err;
    } finally {
      try {
        if (fs.existsSync(zipFile)) fs.unlinkSync(zipFile);
      } catch {
        // Ignore cleanup errors
      }
    }
  },
  downloadFile(url, dest) {
    const self = this;
    return new Promise((resolve, reject) => {
      const followRedirect = (currentUrl, redirectCount = 0) => {
        if (redirectCount > 5) {
          reject(new Error("Too many redirects"));
          return;
        }
        https
          .get(currentUrl, (res) => {
            if (res.statusCode === 301 || res.statusCode === 302) {
              if (res.headers.location) {
                followRedirect(res.headers.location, redirectCount + 1);
                return;
              }
            }
            if (res.statusCode !== 200) {
              reject(new Error(`HTTP ${res.statusCode}`));
              return;
            }
            const file = createWriteStream(dest);
            res.pipe(file);
            file.on("finish", () => {
              file.close();
              resolve();
            });
            file.on("error", (err) => {
              try {
                fs.unlinkSync(dest);
              } catch {
                // Ignore cleanup errors
              }
              reject(err);
            });
          })
          .on("error", reject);
      };
      void self;
      followRedirect(url);
    });
  },
  async extractZip(zipFile, destDir) {
    try {
      if (this.isWindows()) {
        execSync(`powershell -command "Expand-Archive -Force '${zipFile}' '${destDir}'"`, {
          windowsHide: true,
        });
      } else {
        execSync(`unzip -o "${zipFile}" -d "${destDir}"`, { stdio: "ignore" });
      }
    } catch {
      logger.warn("Native unzip failed, attempting manual extraction");
      await this.extractZipManual(zipFile, destDir);
    }
  },
  async extractZipManual(zipFile, destDir) {
    const data = fs.readFileSync(zipFile);
    let offset = 0;
    while (offset < data.length - 4) {
      if (data[offset] === 0x50 && data[offset + 1] === 0x4b && data[offset + 2] === 0x03 && data[offset + 3] === 0x04) {
        const compressedSize = data.readUInt32LE(offset + 18);
        const uncompressedSize = data.readUInt32LE(offset + 22);
        const fileNameLength = data.readUInt16LE(offset + 26);
        const extraFieldLength = data.readUInt16LE(offset + 28);
        const fileName = data.slice(offset + 30, offset + 30 + fileNameLength).toString();
        const dataStart = offset + 30 + fileNameLength + extraFieldLength;
        const compressionMethod = data.readUInt16LE(offset + 8);
        if (fileName.includes("wakatime-cli")) {
          const destPath = path.join(destDir, path.basename(fileName));
          if (compressionMethod === 0) {
            fs.writeFileSync(destPath, data.slice(dataStart, dataStart + uncompressedSize));
          } else if (compressionMethod === 8) {
            const { inflateRawSync } = await import("node:zlib");
            fs.writeFileSync(destPath, inflateRawSync(data.slice(dataStart, dataStart + compressedSize)));
          }
          logger.debug(`Extracted ${fileName} to ${destPath}`);
          return;
        }
        offset = dataStart + compressedSize;
      } else {
        offset++;
      }
    }
    throw new Error("Could not find wakatime-cli in zip file");
  },
};

async function ensureCliInstalled() {
  try {
    await dependencies.checkAndInstallCli();
    return dependencies.isCliInstalled();
  } catch (err) {
    logger.errorException(err);
    return false;
  }
}

const DEFAULT_HEARTBEAT_TIMEOUT_MS = 30_000;
const HEARTBEAT_KILL_GRACE_MS = 2_000;
const pendingHeartbeatBatches = new Set();
const activeHeartbeatProcesses = new Set();

function killActiveHeartbeats() {
  for (const child of activeHeartbeatProcesses) {
    if (child.exitCode !== null || child.signalCode !== null) continue;
    try {
      child.kill("SIGKILL");
    } catch {
      // The process may have exited between the status check and the signal.
    }
  }
}

process.once("exit", killActiveHeartbeats);

function buildExecOptions() {
  const options = { stdio: ["pipe", "ignore", "ignore"], windowsHide: true };
  if (os.platform() !== "win32" && !process.env.WAKATIME_HOME && !process.env.HOME) {
    options.env = { ...process.env, WAKATIME_HOME: os.homedir() };
  }
  return options;
}

function formatArgs(args) {
  return args
    .map((arg) => (arg.includes(" ") ? `"${arg.replace(/"/g, '\\"')}"` : arg))
    .join(" ");
}

function sendHeartbeats(params, timeoutMs = DEFAULT_HEARTBEAT_TIMEOUT_MS) {
  const heartbeatBatch = new Promise((resolve) => {
    if (params.length === 0) {
      resolve();
      return;
    }
    const cliLocation = dependencies.getCliLocation();
    if (!dependencies.isCliInstalled()) {
      logger.warn("wakatime-cli not installed, skipping heartbeat");
      resolve();
      return;
    }
    const [primary, ...extra] = params;
    const client = primary.opencodeClient || "cli";
    const opencodeVersion = primary.opencodeVersion || "unknown";
    const args = [
      "--entity",
      primary.entity,
      "--entity-type",
      "file",
      "--category",
      primary.category ?? "ai coding",
      "--plugin",
      `opencode-${client}/${opencodeVersion} opencode-wakatime/${PLUGIN_VERSION}`,
    ];
    if (primary.projectFolder) args.push("--project-folder", primary.projectFolder);
    if (primary.lineChanges !== undefined && primary.lineChanges !== 0) {
      args.push("--ai-line-changes", primary.lineChanges.toString());
    }
    if (primary.isWrite) args.push("--write");
    if (extra.length > 0) args.push("--extra-heartbeats");
    logger.debug(`Sending ${params.length} heartbeat(s): wakatime-cli ${formatArgs(args)}`);
    const child = spawn(cliLocation, args, buildExecOptions());
    activeHeartbeatProcesses.add(child);
    let resolved = false;
    let forceKillId;
    const resolveOnce = () => {
      if (!resolved) {
        resolved = true;
        activeHeartbeatProcesses.delete(child);
        clearTimeout(timeoutId);
        if (forceKillId) clearTimeout(forceKillId);
        resolve();
      }
    };
    const timeoutId = setTimeout(() => {
      logger.warn(`Heartbeat batch timed out after ${timeoutMs}ms, terminating wakatime-cli`);
      try {
        child.kill("SIGTERM");
      } catch (error) {
        logger.error(`Failed to terminate wakatime-cli: ${error}`);
      }
      forceKillId = setTimeout(() => {
        if (child.exitCode !== null || child.signalCode !== null) return;
        logger.warn("wakatime-cli did not exit after SIGTERM, sending SIGKILL");
        try {
          child.kill("SIGKILL");
        } catch (error) {
          logger.error(`Failed to kill wakatime-cli: ${error}`);
        }
      }, HEARTBEAT_KILL_GRACE_MS);
    }, timeoutMs);
    child.once("error", (error) => {
      logger.error(`wakatime-cli spawn error: ${error.message}`);
      resolveOnce();
    });
    child.once("close", (code, signal) => {
      if (code !== null && code !== 0) logger.warn(`wakatime-cli exited with code ${code}`);
      else if (signal) logger.debug(`wakatime-cli terminated by signal ${signal}`);
      resolveOnce();
    });
    const extraHeartbeats = extra.map((heartbeat) => ({
      ai_line_changes:
        heartbeat.lineChanges !== undefined && heartbeat.lineChanges !== 0
          ? heartbeat.lineChanges
          : undefined,
      category: heartbeat.category ?? "ai coding",
      entity: heartbeat.entity,
      entity_type: "file",
      is_write: heartbeat.isWrite || undefined,
      time: Date.now() / 1000,
    }));
    child.stdin?.on("error", (error) => {
      logger.error(`wakatime-cli stdin error: ${error.message}`);
    });
    child.stdin?.end(extraHeartbeats.length > 0 ? `${JSON.stringify(extraHeartbeats)}\n` : undefined);
  });
  if (params.length > 0) {
    pendingHeartbeatBatches.add(heartbeatBatch);
    void heartbeatBatch.then(
      () => pendingHeartbeatBatches.delete(heartbeatBatch),
      () => pendingHeartbeatBatches.delete(heartbeatBatch),
    );
  }
  return heartbeatBatch;
}

async function flushHeartbeats() {
  while (pendingHeartbeatBatches.size > 0) {
    await Promise.all(pendingHeartbeatBatches);
  }
}

const processedToolCalls = new Set();
const fileChanges = new Map();

function asFile(value) {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

function inputFile(input) {
  if (!input || typeof input !== "object") return undefined;
  return (
    asFile(input.filePath) ?? asFile(input.filepath) ?? asFile(input.path) ?? asFile(input.file)
  );
}

function textFromContent(content) {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .map((part) => (part && part.type === "text" && typeof part.text === "string" ? part.text : ""))
    .join("\n");
}

// Normalize the many shapes a completed tool result can take in V2
// (execute.after result vs. message part state) into one state object.
function normalizeToolState(event) {
  const result = event.status === "completed" ? event.result : undefined;
  let resultContent;
  let resultMetadata;
  let resultText;
  if (Array.isArray(result)) {
    resultContent = result;
  } else if (typeof result === "string") {
    resultText = result;
  } else if (result && typeof result === "object") {
    if (Array.isArray(result.content)) resultContent = result.content;
    if (result.metadata && typeof result.metadata === "object") resultMetadata = result.metadata;
    if (typeof result.output === "string") resultText = result.output;
    if (typeof result.text === "string") resultText = result.text;
  }
  return {
    input: event.input && typeof event.input === "object" ? event.input : {},
    metadata: resultMetadata,
    outputText: resultText ?? textFromContent(resultContent),
  };
}

function extractFileChanges(tool, { input, metadata, outputText }) {
  const changes = [];
  if (tool === "read") {
    const file = inputFile(input);
    if (file) changes.push({ file, info: { additions: 0, deletions: 0, isWrite: false } });
    return changes;
  }
  if (!metadata) {
    if (tool === "edit" || tool === "write") {
      const file = inputFile(input);
      if (file) changes.push({ file, info: { additions: 0, deletions: 0, isWrite: tool === "write" } });
    }
    return changes;
  }
  switch (tool) {
    case "edit": {
      const filediff = metadata.filediff;
      if (filediff?.file) {
        changes.push({
          file: filediff.file,
          info: {
            additions: filediff.additions ?? 0,
            deletions: filediff.deletions ?? 0,
            isWrite: false,
          },
        });
      } else {
        const file = asFile(metadata.filePath) ?? inputFile(input);
        if (file) changes.push({ file, info: { additions: 0, deletions: 0, isWrite: false } });
      }
      break;
    }
    case "write": {
      const file = asFile(metadata.filepath) ?? inputFile(input);
      if (file) {
        changes.push({
          file,
          info: { additions: 0, deletions: 0, isWrite: !metadata.exists },
        });
      }
      break;
    }
    case "patch": {
      const diff = metadata.diff;
      const files = [];
      for (const line of outputText.split("\n")) {
        if (line.startsWith("  ") && !line.startsWith("   ")) {
          const file = line.trim();
          if (file && !file.includes(" ")) files.push(file);
        }
      }
      const perFileDiff = files.length > 0 ? Math.round((diff ?? 0) / files.length) : 0;
      for (const file of files) {
        changes.push({
          file,
          info: {
            additions: perFileDiff > 0 ? perFileDiff : 0,
            deletions: perFileDiff < 0 ? Math.abs(perFileDiff) : 0,
            isWrite: false,
          },
        });
      }
      break;
    }
    case "multiedit": {
      const results = metadata.results;
      if (results) {
        for (const result of results) {
          if (result.filediff?.file) {
            changes.push({
              file: result.filediff.file,
              info: {
                additions: result.filediff.additions ?? 0,
                deletions: result.filediff.deletions ?? 0,
                isWrite: false,
              },
            });
          }
        }
      }
      break;
    }
    default:
      break;
  }
  return changes;
}

async function processHeartbeat(projectFolder, opencodeVersion, opencodeClient, force = false) {
  if (!shouldSendHeartbeat(force) && !force) {
    logger.debug("Skipping heartbeat (rate limited)");
    return;
  }
  if (fileChanges.size === 0) {
    logger.debug("No file changes to report");
    if (force) await flushHeartbeats();
    return;
  }
  const heartbeats = [];
  for (const [file, info] of fileChanges.entries()) {
    heartbeats.push({
      entity: file,
      projectFolder,
      lineChanges: info.additions - info.deletions,
      category: "ai coding",
      isWrite: info.isWrite,
      opencodeVersion,
      opencodeClient,
    });
    logger.debug(`Sent heartbeat for ${file}: +${info.additions}/-${info.deletions} lines`);
  }
  fileChanges.clear();
  updateLastHeartbeat();
  void sendHeartbeats(heartbeats);
  if (force) {
    logger.debug(`Waiting for ${heartbeats.length} heartbeats to complete...`);
    await flushHeartbeats();
    logger.debug("All heartbeat batches completed");
  }
}

function trackFileChange(file, info) {
  const existing = fileChanges.get(file) ?? {
    additions: 0,
    deletions: 0,
    lastModified: Date.now(),
    isWrite: false,
  };
  fileChanges.set(file, {
    additions: existing.additions + (info.additions ?? 0),
    deletions: existing.deletions + (info.deletions ?? 0),
    lastModified: Date.now(),
    isWrite: existing.isWrite || (info.isWrite ?? false),
  });
}

function findToolPart(messages, messageID, callID) {
  const list = Array.isArray(messages) ? messages : messages?.data ?? messages?.messages ?? [];
  const message = list.find((m) => m?.id === messageID && m?.type === "assistant");
  const part = message?.content?.find((p) => p?.type === "tool" && (p?.id === callID || p?.callID === callID));
  return part?.state && typeof part.state === "object" ? part.state : undefined;
}

export default {
  id: "local.wakatime",
  async setup(ctx) {
    try {
      const cfg = fs.readFileSync(getWakatimeConfigFilePath(), "utf-8");
      if (/^\s*debug\s*=\s*true\s*$/m.test(cfg)) logger.level = LogLevel.DEBUG;
    } catch {
      // Config file doesn't exist or can't be read, keep default INFO level
    }

    const projectFolder =
      ctx.location?.project?.directory ?? ctx.location?.directory ?? process.cwd();
    const projectName = path.basename(projectFolder);
    const rawClient = process.env.OPENCODE_CLIENT || "cli";
    const opencodeClient = rawClient === "app" ? "web" : rawClient;
    const opencodeVersion = ctx.app?.version ?? "unknown";
    logger.debug(`OpenCode client: ${opencodeClient}, version: ${opencodeVersion}`);

    initState(projectFolder);
    const cliInstalled = await ensureCliInstalled();
    if (!cliInstalled) {
      logger.warn("WakaTime CLI could not be installed. Please install it manually: https://wakatime.com/terminal");
    } else {
      logger.info(`OpenCode WakaTime plugin initialized for project: ${projectName}`);
    }

    const toolHook = await ctx.tool.hook("execute.after", async (event) => {
      try {
        if (event?.status !== "completed") return;
        const tool = event.tool;
        if (tool !== "edit" && tool !== "write" && tool !== "patch" && tool !== "multiedit" && tool !== "read") {
          return;
        }
        const callKey = `${event.messageID}:${event.id}`;
        if (processedToolCalls.has(callKey)) return;
        processedToolCalls.add(callKey);
        if (processedToolCalls.size > 1000) {
          for (const key of processedToolCalls) {
            processedToolCalls.delete(key);
            if (processedToolCalls.size <= 500) break;
          }
        }

        let state = normalizeToolState(event);
        if (tool !== "read") {
          try {
            const messages = await ctx.session.context({ sessionID: event.sessionID });
            const partState = findToolPart(messages, event.messageID, event.id);
            if (partState) {
              state = {
                input:
                  partState.input && typeof partState.input === "object"
                    ? partState.input
                    : state.input,
                metadata:
                  partState.metadata && typeof partState.metadata === "object"
                    ? partState.metadata
                    : state.metadata,
                outputText: textFromContent(partState.content) || state.outputText,
              };
            }
          } catch {
            // Fall back to hook input/result when context lookup fails
          }
        }

        logger.debug(`Tool executed: ${tool}`);
        const changes = extractFileChanges(tool, state);
        for (const change of changes) {
          try {
            if (fs.statSync(change.file).isDirectory()) {
              logger.debug(`Skipping directory: ${change.file}`);
              continue;
            }
          } catch {
            // File may not exist (deleted/temp) — still track it
          }
          trackFileChange(change.file, change.info);
          logger.debug(`Tracked: ${change.file} (+${change.info.additions ?? 0}/-${change.info.deletions ?? 0})`);
        }
        if (changes.length > 0) {
          await processHeartbeat(projectFolder, opencodeVersion, opencodeClient);
        }
      } catch (err) {
        logger.debug(`WakaTime tool hook error: ${err instanceof Error ? err.message : String(err)}`);
      }
    });

    const promptHook = await ctx.session.hook("prompt", async () => {
      try {
        logger.debug("Chat message received");
        if (fileChanges.size > 0) {
          await processHeartbeat(projectFolder, opencodeVersion, opencodeClient);
        }
      } catch (err) {
        logger.debug(`WakaTime prompt hook error: ${err instanceof Error ? err.message : String(err)}`);
      }
    });

    const controller = new AbortController();
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          if (event?.type !== "session.deleted" && event?.type !== "session.idle") continue;
          try {
            logger.debug(`Session event: ${event.type} - sending final heartbeat`);
            await processHeartbeat(projectFolder, opencodeVersion, opencodeClient, true);
          } catch (err) {
            logger.debug(`WakaTime event error: ${err instanceof Error ? err.message : String(err)}`);
          }
        }
      } catch {
        // Subscription aborted on unload
      }
    })();

    return async () => {
      controller.abort();
      try {
        await toolHook.dispose();
      } catch {
        // Registration already disposed
      }
      try {
        await promptHook.dispose();
      } catch {
        // Registration already disposed
      }
      await flushHeartbeats();
    };
  },
};
