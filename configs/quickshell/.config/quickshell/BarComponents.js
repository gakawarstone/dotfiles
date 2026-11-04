// Override individual components for each hostname. See README.md.
var hosts = {
};

var defaults = {
    Workspaces: true,
    Media: true,
    NetworkSpeed: true,
    CodexUsage: true,
    Wifi: false,
    HsflVpn: true,
    LanMouse: true,
    Pomodoro: true,
    Volume: true,
    Microphone: true,
    Bluetooth: true,
    Battery: true,
    KeyboardLayout: true,
    NotificationIndicator: true
};

function enabled(hostname, component) {
    if (Object.prototype.hasOwnProperty.call(hosts, hostname)
            && Object.prototype.hasOwnProperty.call(hosts[hostname], component)) {
        return hosts[hostname][component];
    }
    return defaults[component] === true;
}
