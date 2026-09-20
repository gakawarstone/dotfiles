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
  const data = obj.data && typeof obj.data === "object" ? obj.data : undefined;
  return (
    asTitle(data?.title) ??
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
  const data = obj.data && typeof obj.data === "object" ? obj.data : undefined;
  return (
    asTitle(data?.sessionID) ??
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

async function sessionTitleFromClient(ctx, sessionID) {
  if (!ctx || !sessionID) return undefined;

  try {
    const session = await ctx.session.get({ sessionID });
    return sessionTitleFrom(session ?? undefined);
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

export default {
  id: "herdr.pane-title",
  setup(ctx) {
    if (!herdrEnabled) return;

    const controller = new AbortController();
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event?.type !== "session.created" && event?.type !== "session.renamed") continue;

        const title =
          sessionTitleFrom(event) ?? (await sessionTitleFromClient(ctx, sessionIdFrom(event)));
        if (title) await reportTitle(title);
      }
    })();

    return () => controller.abort();
  },
};
