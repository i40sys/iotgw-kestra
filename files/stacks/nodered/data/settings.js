// Node-RED settings for the IoT gateway — deployed by tasks/nodered.yaml.
// Vendored in iotgw-ng v0.7.1: without it the image writes its stock
// settings.js, whose adminAuth is commented out, so the editor on :1880 (host
// network, the whole LAN) had NO login although .env carried the admin user.
// Everything comes from the container env (.env, rendered from env.j2).
module.exports = {
  flowFile: "flows.json",
  uiPort: process.env.PORT || 1880,

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

  // Projects mode only with the optional flows repo (`nodered_flows_repo`);
  // otherwise the flows live in /data/flows.json.
  editorTheme: {
    projects: {
      enabled: process.env.NODE_RED_PROJECTS === "true",
    },
  },

  logging: {
    console: { level: "info", metrics: false, audit: false },
  },
};
