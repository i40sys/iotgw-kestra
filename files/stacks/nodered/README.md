# Node-RED stack

Node-RED (`nodered/node-red:5.0.9`, one version in `tasks/nodered.yaml`) on the
gateway, behind its admin login, deployed by `tasks/nodered.yaml` (tag `nodered`,
enable flag `nodered`). Vendored here (task-073 §7); the original v3 stack repo
(`iotgw_nodered`, Node-RED 3.1) is no longer used.

| File | Role |
|---|---|
| `compose.yaml` | the service: host network, privileged, `/dev` → `/host/dev`, `data/` → `/data`, healthcheck, Uptime Kuma label, log limits |
| `env.j2` | `.env`: version, TZ, hostname, admin user + bcrypt hash, projects on/off, `GIT_CONFIG_GLOBAL` |
| `data/settings.js` | Node-RED settings (below) |
| `data/.config.projects.json.j2` | flows repo only: the active project + its credential key |
| `data/.gitconfig.j2` | flows repo only: the editor's git committer |
| `flows-sync.sh` | flows repo only: installs the controller's checkout as the project, keeping local work |

## Deployment variables

- `nodered: true` needs `iotgw_hostname`, `nodered_user`, `nodered_password`.
- `nodered_flows_repo: true` (optional) also needs `github_org`; optional
  `nodered_flows_branch` (default: the repo's default branch) and
  `nodered_flows_token` (a read-only token, only for a private repo).
- `tasks/preflight.yaml` checks them; the UI schema is iotgw-ng
  `deployment-config.schema.json`.

## Admin login

`adminAuth` (credentials) with the single user `nodered_user`, permissions `*`.
The password is hashed with bcrypt **on the gateway** in a throw-away Node-RED
container (password in its env, task `no_log`) and lands in `.env` (root, 0640)
as `NODE_RED_PASSWORD`. The editor and the whole admin API (`/flows`,
`/settings`, `/projects`, …) answer 401 without a token. As in v3, `httpNode`
routes and the dashboard are not behind a login (v3 had no `httpNodeAuth`).

## Flow credentials

`data/.iotgw-credential-secret` (0600, uid 1000) is the flow-credential key:
made once per gateway by provisioning, never in git, never in `.env`, kept
across re-provisioning (data/ is never wiped). `settings.js` reads it as
`credentialSecret`; in projects mode it is also the project's key in
`.config.projects.json`. A gateway provisioned by v0.7.1 had Node-RED's
system-generated key in `.config.runtime.json`; that key is adopted, so its
`flows_cred.json` keeps decrypting.

Lost with the gateway's disk: credentials have to be re-entered after a
reinstall (also the encrypted `flows_cred.json` committed to a flows repo).

## Standalone (default)

Flows live in `data/flows.json`. Re-provisioning replaces the stack files but
keeps `data/`.

## Flows repo (`nodered_flows_repo: true`)

Projects mode, with `flows.<iotgw_hostname>` as the active project.

- **Clone on the controller, not the gateway.** The Kestra runner (Ansible
  controller) clones `https://github.com/<github_org>/flows.<iotgw_hostname>.git`
  into `/tmp/iotgw-nodered-<host>/` before the stack is stopped (a failed clone
  leaves Node-RED running). A public repo needs nothing. A private one takes
  `nodered_flows_token`: passed to git only as an `http.extraHeader` in the
  process environment (`GIT_CONFIG_*`), so it is not on the command line, not in
  `.git/config`, not logged (`no_log`). The gateway gets no key and no token and
  never talks to GitHub (no deploy keys: GitHub mails on each one).
- **Copy to the gateway with history.** The checkout keeps its `.git` (projects
  mode needs it) with `origin` set to the plain https URL and any
  `credential`/`http`/`url` config removed; provisioning fails if the token
  shows up anywhere in `.git`. It is copied as one tarball to
  `data/projects/.iotgw-incoming/`, owned by uid 1000, and the controller copy
  is deleted.
- **Local changes are never lost.** `flows-sync.sh` (run in a throw-away
  Node-RED container, git included, while Node-RED is stopped):
  - no project yet → install it;
  - the gateway copy has **no uncommitted change** (Node-RED's `*.backup`
    aside) and **every local branch head is in the fresh clone** (all pushed)
    → replace it with the fresh checkout;
  - otherwise → **keep the gateway copy untouched** and print
    `flows-sync: kept …` with the reason, plus a WARNING in the run. The repo's
    newer version is not applied until the operator commits + pushes (or
    discards) the change in the editor and re-provisions.
- `.config.projects.json` is rewritten on every run (the active project + the
  gateway's credential key); a key changed in the editor's project settings is
  reset by the next provisioning.
- `data/.gitconfig` (`GIT_CONFIG_GLOBAL`) sets the committer for the editor:
  `<iotgw_hostname> <<iotgw_hostname>@<local_domain>>`. Pushing from the editor
  needs credentials the operator types there; provisioning ships none.
- The project's `package.json` dependencies are **not** installed (Node-RED does
  not do it for projects either); add extra nodes via the palette manager.

## Settings ported from the v3 stack

From `iotgw_nodered` `data/settings.js` (Node-RED 3.1), checked against 5.0.9:

| v3 setting | v5 |
|---|---|
| `adminAuth` from `NODE_RED_USER`/`NODE_RED_PASSWORD` | same |
| `credentialSecret` (a fixed key committed in the repo) | per-gateway key, see above |
| `flowFile: flows.json`, `flowFilePretty`, `uiPort`, `lang: en` | same |
| `diagnostics` on, `runtimeState` off, `exportGlobalContextKeys: false` | same |
| `editorTheme.page/header.title` "NodeRED: <hostname>", no header image, `tours: false` | same |
| `editorTheme.projects` (always on, workflow manual) | on only with the flows repo; manual |
| `codeEditor: monaco`, `markdownEditor.mermaid` | same |
| `functionExternalModules`, `functionTimeout: 0`, `debugMaxLength`, `mqtt/serialReconnectTime` | same |
| — | `telemetry: {enabled: false}` (new in 4.1; keeps v3's no-prompt/no-update-check behaviour) |
| `externalModules: {}`, `palette: {}`, `functionGlobalContext: {}` | dropped (empty) |
| `.config.users.json` (editor prefs, git user with a company email, workflow `auto`) | dropped; committer from `.gitconfig`, workflow manual |
| `.config.runtime.json` / `.config.nodes.json` (runtime state) | dropped; Node-RED writes them |
| `data/projects/.sshkeys/admin_id_rsa` (a committed private key) | dropped: no key on the gateway |
| `data/package.json` | no extra palette nodes in v3; none installed |
