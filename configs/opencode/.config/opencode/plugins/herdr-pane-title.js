import { execFile, spawn } from "node:child_process";

const source = "herdr:opencode-title";
const paneId = process.env.HERDR_PANE_ID;
const herdrEnabled = process.env.HERDR_ENV === "1" && paneId;

let lastTitle;
let seq = Date.now() * 1000;

function nextSeq() {
  seq += 1;
  return String(seq);
}

function asTitle(value) {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

function sessionTitleFrom(value) {
  if (!value || typeof value !== "object") return undefined;

  const obj = value;
  return (
    asTitle(obj.title) ??
    asTitle(obj.session?.title) ??
    asTitle(obj.info?.title) ??
    asTitle(obj.properties?.title) ??
    asTitle(obj.properties?.session?.title) ??
    asTitle(obj.properties?.info?.title)
  );
}

function sessionIdFrom(value) {
  if (!value || typeof value !== "object") return undefined;

  const obj = value;
  return (
    asTitle(obj.id) ??
    asTitle(obj.sessionID) ??
    asTitle(obj.session?.id) ??
    asTitle(obj.info?.id) ??
    asTitle(obj.properties?.id) ??
    asTitle(obj.properties?.sessionID) ??
    asTitle(obj.properties?.session?.id) ??
    asTitle(obj.properties?.info?.id)
  );
}

async function sessionTitleFromClient(client, sessionId) {
  if (!client || !sessionId) return undefined;

  try {
    const response = await client.session.get({ path: { id: sessionId } });
    return sessionTitleFrom(response?.data ?? response);
  } catch {
    return undefined;
  }
}

function runHerdr(args) {
  const child = spawn("herdr", args, { stdio: "ignore" });
  child.unref();
}

function getTabId() {
  return new Promise((resolve) => {
    execFile("herdr", ["pane", "get", paneId], { timeout: 1000 }, (error, stdout) => {
      if (error) {
        resolve(undefined);
        return;
      }

      try {
        const response = JSON.parse(stdout);
        const tabId = response?.result?.pane?.tab_id;
        resolve(typeof tabId === "string" && tabId.length > 0 ? tabId : undefined);
      } catch {
        resolve(undefined);
      }
    });
  });
}

async function reportTitle(title) {
  if (!herdrEnabled || title === lastTitle) return;

  lastTitle = title;
  runHerdr(["pane", "rename", paneId, title]);
  runHerdr([
    "pane",
    "report-metadata",
    paneId,
    "--source",
    source,
    "--title",
    title,
    "--seq",
    nextSeq(),
  ]);

  const tabId = await getTabId();
  if (tabId) {
    runHerdr(["tab", "rename", tabId, title]);
  }
}

export const HerdrPaneTitle = async ({ client } = {}) => {
  if (!herdrEnabled) return {};

  return {
    event: async (input) => {
      const event = input?.event;
      if (event?.type !== "session.created" && event?.type !== "session.updated") return;

      const title =
        sessionTitleFrom(event) ??
        (await sessionTitleFromClient(client, sessionIdFrom(event)));
      if (title) await reportTitle(title);
    },
  };
};
