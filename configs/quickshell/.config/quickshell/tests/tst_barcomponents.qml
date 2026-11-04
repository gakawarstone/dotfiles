import QtQuick
import QtTest
import ".."

TestCase {
    name: "BarComponents"

    Component {
        id: defaults
        BarComponents {}
    }

    Component {
        id: withHosts
        BarComponents {
            id: settings
            states: [
                State {
                    name: "desktop"
                    when: settings.hostname === "test-desktop"
                    PropertyChanges { target: settings; wifi: true; networkSpeed: false }
                },
                State {
                    name: "laptop"
                    when: settings.hostname === "test-laptop"
                    PropertyChanges { target: settings; lanMouse: false }
                }
            ]
        }
    }

    function test_defaults() {
        const settings = createTemporaryObject(defaults, this);
        const enabledByDefault = ["workspaces", "media", "networkSpeed", "codexUsage",
                                  "hsflVpn", "lanMouse", "pomodoro", "volume",
                                  "microphone", "bluetooth", "battery", "keyboardLayout",
                                  "notificationIndicator"];
        for (const component of enabledByDefault)
            verify(settings[component], component);
        verify(!settings.wifi);
    }

    function test_host_states() {
        const settings = createTemporaryObject(withHosts, this);
        settings.hostname = "test-desktop";
        compare(settings.state, "desktop");
        verify(settings.wifi);
        verify(!settings.networkSpeed);
        verify(settings.lanMouse);

        settings.hostname = "test-laptop";
        compare(settings.state, "laptop");
        verify(!settings.wifi);
        verify(settings.networkSpeed);
        verify(!settings.lanMouse);

        settings.hostname = "unknown";
        compare(settings.state, "");
        verify(!settings.wifi);
        verify(settings.networkSpeed);
        verify(settings.lanMouse);
    }
}
