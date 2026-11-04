import QtQuick
import QtTest
import "../BarComponents.js" as BarComponents

TestCase {
    name: "BarComponents"

    function init() {
        BarComponents.hosts["test-desktop"] = { Wifi: true, NetworkSpeed: false };
        BarComponents.hosts["test-laptop"] = { LanMouse: false };
    }

    function cleanup() {
        delete BarComponents.hosts["test-desktop"];
        delete BarComponents.hosts["test-laptop"];
    }

    function test_defaults() {
        const enabledByDefault = ["Workspaces", "Media", "NetworkSpeed", "CodexUsage",
                                  "HsflVpn", "LanMouse", "Pomodoro", "Volume",
                                  "Microphone", "Bluetooth", "Battery", "KeyboardLayout",
                                  "NotificationIndicator"];
        for (const component of enabledByDefault)
            verify(BarComponents.enabled("", component), component);
        verify(BarComponents.enabled("unknown", "LanMouse"));
        verify(!BarComponents.enabled("unknown", "Wifi"));
        verify(!BarComponents.enabled("unknown", "NoSuchComponent"));
        verify(BarComponents.enabled("toString", "NetworkSpeed"));
    }

    function test_host_overrides() {
        verify(BarComponents.enabled("test-desktop", "Wifi"));
        verify(!BarComponents.enabled("test-desktop", "NetworkSpeed"));
        verify(BarComponents.enabled("test-desktop", "LanMouse"));
        verify(!BarComponents.enabled("test-laptop", "Wifi"));
        verify(BarComponents.enabled("test-laptop", "NetworkSpeed"));
        verify(!BarComponents.enabled("test-laptop", "LanMouse"));
    }
}
