// Create Uptime Kuma's first admin user, so the stack needs no prepared DB.
//
// Run inside the kuma container (it ships socket.io-client) with:
//   docker compose exec -T -w /app kuma node - < contrib/bootstrap-admin.js
// The credentials come from the container's env (.env): the same account
// AutoKuma logs in with and Grafana Alloy scrapes /metrics with. Idempotent:
// on an initialised instance it only checks that the account can log in.
const { io } = require("socket.io-client");

const username = process.env.AUTOKUMA__KUMA__USERNAME;
const password = process.env.AUTOKUMA__KUMA__PASSWORD;
const port = process.env.UPTIME_KUMA_PORT || "3001";
if (!username || !password) {
  console.error("AUTOKUMA__KUMA__USERNAME / AUTOKUMA__KUMA__PASSWORD are not set");
  process.exit(2);
}

const socket = io(`http://127.0.0.1:${port}`, { transports: ["websocket"], reconnection: false, timeout: 10000 });
const finish = (code, msg) => {
  (code === 0 ? console.log : console.error)(msg);
  socket.close();
  process.exit(code);
};
setTimeout(() => finish(1, "timed out talking to Uptime Kuma"), 30000);
socket.on("connect_error", (e) => finish(1, `cannot connect to Uptime Kuma: ${e.message}`));

const login = () =>
  socket.emit("login", { username, password, token: "" }, (r) =>
    r.ok ? finish(0, "admin present, login OK") : finish(1, `admin exists but login failed: ${r.msg}`));

socket.on("connect", () =>
  socket.emit("needSetup", (needSetup) => {
    if (!needSetup) return login();
    socket.emit("setup", username, password, (r) =>
      r.ok ? (console.log("admin created"), login()) : finish(1, `setup failed: ${r.msg}`));
  }));
