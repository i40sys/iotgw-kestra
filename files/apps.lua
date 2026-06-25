module("luci.controller.apps", package.seeall)

function index()
    local page

    page = entry({"admin", "apps"}, firstchild(), _("Apps"), 60)
    page.dependent = false

    entry({"admin", "apps", "uptime-kuma"}, call("serve_js_redirect", "http", "3003"), _("Uptime Kuma"), 10).leaf = true
    entry({"admin", "apps", "nodered"}, call("serve_js_redirect", "http", "1880"), _("NodeRED"), 20).leaf = true
    entry({"admin", "apps", "dockge"}, call("serve_js_redirect", "http", "5001"), _("Dockge"), 30).leaf = true
    entry({"admin", "apps", "duplicati"}, call("serve_js_redirect", "http", "8200"), _("Duplicati"), 40).leaf = true
    entry({"admin", "apps", "vscode"}, call("serve_js_redirect", "http", "8443"), _("VS Code"), 50).leaf = true
    entry({"admin", "apps", "alloy"}, call("serve_js_redirect", "http", "12345 "), _("Alloy"), 60).leaf = true
    entry({"admin", "apps", "glpi-agent"}, call("serve_js_redirect", "http", "62354 "), _("GLPI Agent"), 70).leaf = true
    entry({"admin", "apps", "ttyd"}, call("serve_js_redirect", "http", "7681 "), _("Web Terminal"), 70).leaf = true
end

function serve_js_redirect(protocol, port)
    local ip = luci.http.getenv("SERVER_ADDR")
    local url = protocol .. "://" .. ip .. ":" .. port
    luci.http.prepare_content("text/html; charset=utf-8")
    
    local html_content = [[
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Redirecting...</title>
    <script type='text/javascript'>
        window.onload = function() {
            var referrer = document.referrer;
            console.log("Referrer page is: ", referrer);
            
            var newWindow = window.open(']] .. url .. [[', '_blank');
            console.log("Attempted to open a new window to: ", ']] .. url .. [[');
            
            if (newWindow && !newWindow.closed && typeof newWindow.closed != 'undefined') {
                console.log("New window opened successfully. Redirecting back to referrer immediately.");
                // If the new window opened successfully, go back to referrer immediately
                if (referrer) {
                    window.location.href = referrer;
                } else {
                    console.log("Referrer is empty or unavailable; not redirecting.");
                }
            } else {
                console.log("New window could not be opened. Showing manual link and starting countdown.");
                // If the new window could not be opened, show the manual link and start a countdown
                document.getElementById('manualLink').style.display = 'block';
                var countdown = 60; // 60 seconds countdown
                var countdownElement = document.getElementById('countdown');
                countdownElement.textContent = countdown;

                var interval = setInterval(function() {
                    countdown--;
                    countdownElement.textContent = countdown;
                    console.log("Countdown: ", countdown, " seconds remaining.");
                    if (countdown <= 0) {
                        clearInterval(interval);
                        console.log("Countdown finished. Redirecting back to referrer.");
                        if (referrer) {
                            window.location.href = referrer;
                        } else {
                            console.log("Referrer is empty or unavailable; not redirecting.");
                        }
                    }
                }, 1000); // Update countdown every second
            }
        };
    </script>
</head>
<body>
    <p id='manualLink' style='display: none;'>
        The window didn't open automatically. <a href=']] .. url .. [[' target='_blank'>Click here</a> to open it manually.
        <br>
        You will be redirected back to the previous page in <span id='countdown'>60</span> seconds.
    </p>
</body>
</html>
]]
    
    luci.http.write(html_content)
end
