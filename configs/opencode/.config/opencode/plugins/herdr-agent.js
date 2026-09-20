// Local V2 port of herdr's opencode agent-state integration (v11, V1-only).
// Managed file herdr-agent-state.js is herdr's and stays untouched; this
// plugin replaces it until herdr ships V2 support. Uses only node:net.
import net from "node:net";

const SOURCE = "herdr:opencode";
const AGENT = "opencode";
let reportSeq = Date.now() * 1000;
let requestChain = Promise.resolve();
let reportedRootSessionID;

const childSessions = new Map();
const CHILD_EVENT_STATES = new Map([
  ["permission.asked", "blocked"],
  ["form.created", "blocked"],
  ["permission.replied", "working"],
  ["form.replied", "working"],
  ["form.cancelled", "working"],
]);

function nextReportSeq() {
  reportSeq += 1;
  return reportSeq;
}

function sessionIDFromEvent(event) {
  if (!event || typeof event !== "object") return undefined;
  const data = event.data && typeof event.data === "object" ? event.data : undefined;
  const form = data?.form && typeof data.form === "object" ? data.form : undefined;
  const id =
    data?.sessionID ?? form?.sessionID ?? event.properties?.sessionID ?? event.sessionID;
  return typeof id === "string" && id ? id : undefined;
}

const SESSION_STATE_BY_STATUS = new Map([
  ["idle", "idle"],
  ["active", "working"],
  ["busy", "working"],
  ["pending", "working"],
  ["retry", "working"],
  ["running", "working"],
  ["streaming", "working"],
  ["working", "working"],
]);

function stateFromSessionStatus(status) {
  const kind = typeof status === "string" ? status : status?.type;
  return typeof kind === "string" ? SESSION_STATE_BY_STATUS.get(kind.toLowerCase()) : undefined;
}

function resolveRoot(sessionID) {
  let root = sessionID;
  while (childSessions.has(root)) root = childSessions.get(root);
  return root;
}

function request(method, params) {
  const pending = requestChain.then(() => requestOnce(method, params));
  requestChain = pending.catch(() => {});
  return pending;
}

function requestOnce(method, params) {
  const paneId = process.env.HERDR_PANE_ID;
  const socketPath = process.env.HERDR_SOCKET_PATH;

  if (!paneId || !socketPath) {
    return Promise.resolve();
  }

  const socketEndpoint =
    process.platform === "win32" ? `\\\\.\\pipe\\${socketPath}` : socketPath;

  const requestId = `${SOURCE}:${Date.now()}:${Math.floor(Math.random() * 1_000_000)
    .toString()
    .padStart(6, "0")}`;
  const payload = {
    id: requestId,
    method,
    params: {
      pane_id: paneId,
      source: SOURCE,
      agent: AGENT,
      seq: nextReportSeq(),
      ...params,
    },
  };

  return new Promise((resolve) => {
    const client = net.createConnection(socketEndpoint, () => {
      client.write(`${JSON.stringify(payload)}\n`);
    });

    const finish = () => {
      client.destroy();
      resolve();
    };

    client.setTimeout(500, finish);
    client.on("data", finish);
    client.on("error", finish);
    client.on("end", finish);
    client.on("close", resolve);
  });
}

function reportSession(sessionID) {
  if (!sessionID) {
    return Promise.resolve();
  }
  return request("pane.report_agent_session", { agent_session_id: sessionID });
}

function reportState(state, sessionID) {
  const params = { state };
  if (sessionID) {
    reportedRootSessionID = sessionID;
    params.agent_session_id = sessionID;
  }
  return request("pane.report_agent", params);
}

async function handleEvent(event) {
  const type = event?.type;
  const data = event?.data && typeof event.data === "object" ? event.data : {};
  const sessionID = sessionIDFromEvent(event);

  if (type === "session.created") {
    if (data.sessionID && data.parentID) childSessions.set(data.sessionID, data.parentID);
    reportedRootSessionID = sessionID;
    return;
  }
  if (type === "session.forked") {
    if (data.sessionID && data.parentID) childSessions.set(data.sessionID, data.parentID);
    return;
  }
  if (sessionID && childSessions.has(sessionID)) {
    const state = CHILD_EVENT_STATES.get(type);
    if (state) await reportState(state, resolveRoot(sessionID));
    return;
  }

  switch (type) {
    case "session.execution.started":
      if (sessionID && sessionID !== reportedRootSessionID) {
        await reportSession(sessionID);
      }
      break;
    case "session.status": {
      const state = stateFromSessionStatus(data.status);
      if (state) {
        await reportState(state, sessionID);
      } else {
        await reportSession(sessionID);
      }
      break;
    }
    case "session.tool.called":
    case "session.tool.success":
    case "permission.replied":
    case "form.replied":
    case "form.cancelled":
    case "session.compaction.ended":
      await reportState("working", sessionID);
      break;
    case "permission.asked":
    case "form.created":
    case "session.execution.failed":
      await reportState("blocked", sessionID);
      break;
    case "session.idle":
      await reportState("idle", sessionID);
      break;
    case "session.deleted":
      break;
    default:
      break;
  }
}

export default {
  id: "herdr.agent-state",
  async setup(ctx) {
    if (
      process.env.HERDR_ENV !== "1" ||
      !process.env.HERDR_SOCKET_PATH ||
      !process.env.HERDR_PANE_ID
    ) {
      return;
    }

    const promptHook = await ctx.session.hook("prompt", async (hookEvent) => {
      const sessionID =
        typeof hookEvent?.sessionID === "string" && hookEvent.sessionID
          ? hookEvent.sessionID
          : undefined;
      if (sessionID && childSessions.has(sessionID)) return;
      await reportState("working", sessionID);
    });

    const controller = new AbortController();
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
          try {
            await handleEvent(event);
          } catch {
            // Best-effort reporting must never break the event loop
          }
        }
      } catch {
        // Subscription aborted on unload
      }
    })();

    return async () => {
      controller.abort();
      try {
        await promptHook.dispose();
      } catch {
        // Registration already disposed
      }
    };
  },
};
