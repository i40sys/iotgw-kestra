// Node-RED settings for the IoT gateway — deployed by tasks/nodered.yaml.
// Vendored in iotgw-ng v0.7.1: without it the image writes its stock
// settings.js, whose adminAuth is commented out, so the editor on :1880 (host
// network, the whole LAN) had NO login although .env carried the admin user.
// Everything comes from the container env (.env, rendered from env.j2) or from
// files tasks/nodered.yaml keeps under /data on the gateway.
//
// The editor/runtime options below are the ones the original v3 stack
// (iotgw_nodered) customized, checked against Node-RED 5.0.9; see README.md
// "Settings ported from the v3 stack".
const fs = require("fs");
const path = require("path");

// Flow-credential encryption key: generated ONCE per gateway by
// tasks/nodered.yaml (never in git, never in .env) and kept next to this file,
// so flows_cred.json still decrypts after the container is recreated or the
// stack is re-provisioned. The v3 stack had a fixed key committed in its repo.
function credentialSecret() {
  try {
    const key = fs.readFileSync(path.join(__dirname, ".iotgw-credential-secret"), "utf8").trim();
    return key || undefined;
  } catch (err) {
    return undefined; // Node-RED falls back to its system-generated key
  }
}

const hostname = process.env.IOTGW_HOSTNAME || process.env.HOSTNAME || "gateway";

module.exports = {
  flowFile: "flows.json",
  flowFilePretty: true,
  credentialSecret: credentialSecret(),
  uiPort: process.env.PORT || 1880,
  lang: "en",

  adminAuth: {
    type: "credentials",
    users: [
      {
        username: process.env.NODE_RED_USER,
        // bcrypt hash, made on the gateway by tasks/nodered.yaml
        password: process.env.NODE_RED_PASSWORD,
        permissions: "*",
      },
    ],
  },

  // No consent prompt / update check (Node-RED 4.1+): keeps the v3 behaviour.
  telemetry: { enabled: false },
  diagnostics: { enabled: true, ui: true },
  runtimeState: { enabled: false, ui: false },

  logging: {
    console: { level: "info", metrics: false, audit: false },
  },

  // Do not list the global-context keys in the editor's context sidebar.
  exportGlobalContextKeys: false,

  editorTheme: {
    page: { title: `NodeRED: ${hostname}` },
    header: { title: `NodeRED: ${hostname}`, image: null },
    tours: false,
    // Projects mode only with the optional flows repo (`nodered_flows_repo`);
    // otherwise the flows live in /data/flows.json. The active project is set
    // in /data/.config.projects.json by tasks/nodered.yaml; the git committer
    // comes from /data/.gitconfig (GIT_CONFIG_GLOBAL in .env).
    projects: {
      enabled: process.env.NODE_RED_PROJECTS === "true",
      workflow: { mode: "manual" },
    },
    codeEditor: { lib: "monaco" },
    markdownEditor: { mermaid: { enabled: true } },
  },

  // Function nodes may `require` npm modules (installed by Node-RED into
  // /data/externalModules on deploy; needs internet from the gateway).
  functionExternalModules: true,
  functionTimeout: 0,
  debugMaxLength: 1000,
  mqttReconnectTime: 15000,
  serialReconnectTime: 15000,
};
