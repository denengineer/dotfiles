import { NotificationPopups } from "./notificationPopups.js";

const hyprland = await Service.import("hyprland");
const notifications = await Service.import("notifications");
const mpris = await Service.import("mpris");
const audio = await Service.import("audio");
const battery = await Service.import("battery");
const systemtray = await Service.import("systemtray");

const widgetCssBase =
  "padding: 0.3rem 0.8rem; background-color: transparent; border: none; border-radius:unset;";

const date = Variable("", {
  poll: [1000, 'date "+%^b,%e | %H:%M"'],
});

const connections = Variable("", {
  poll: [
    1000,
    "nmcli -t -f type,name connection show --active",
    (c) => {
      return c.split("\n").map((con) => {
        const values = con.split(":");
        return {
          type: values[0] === "802-11-wireless" ? "wifi" : values[0],
          name: values[1],
        };
      });
    },
  ],
});

function WorkspacesWidget() {
  const activeId = hyprland.active.workspace.bind("id");
  const label = hyprland.active.client.bind("class");

  const workspaces = hyprland.bind("workspaces").as((ws) => {
    console.log(ws);
    const mapped = [
      ...ws
        .sort((a, b) => a.name.localeCompare(b.name))
        .filter((ws) => !(ws.floating && !ws.title))
        .map((ws) =>
          Widget.Button({
            cursor: "pointer",
            css: activeId.as(
              (aId) =>
                `${widgetCssBase} ${
                  aId === ws.id
                    ? "background: @ctp-latte-lavender; color: @ctp-latte-base;"
                    : ""
                }`
            ),
            on_clicked: () =>
              hyprland.messageAsync(`dispatch workspace ${ws.id}`),
            child: Widget.Label(`${ws.name}`),
          })
        ),
      Widget.Label({
        css: `${widgetCssBase}`,
        label,
      }),
    ];
    return mapped;
  });

  return Widget.Box({
    class_name: "workspaces",
    children: workspaces,
  });
}

// we don't need dunst or any other notification daemon
// because the Notifications module is a notification daemon itself
function Notification() {
  const popups = notifications.bind("popups");
  return Widget.Box({
    class_name: "notification",
    visible: popups.as((p) => p.length > 0),
    children: [
      Widget.Icon({
        icon: "preferences-system-notifications-symbolic",
      }),
      Widget.Label({
        label: popups.as((p) => p[0]?.summary || ""),
      }),
    ],
  });
}

function Media() {
  const label = Utils.watch("", mpris, "player-changed", () => {
    if (mpris.players[0]) {
      const { track_artists, track_title } = mpris.players[0];
      return `${track_artists.join(", ")} - ${track_title}`;
    } else {
      return "Nothing is playing";
    }
  });

  return Widget.Button({
    class_name: "media",
    on_primary_click: () => mpris.getPlayer("")?.playPause(),
    on_scroll_up: () => mpris.getPlayer("")?.next(),
    on_scroll_down: () => mpris.getPlayer("")?.previous(),
    child: Widget.Label({ label }),
  });
}

function Volume() {
  const icons = {
    101: "overamplified",
    67: "high",
    34: "medium",
    1: "low",
    0: "muted",
  };

  function getIcon() {
    const icon = audio.speaker.is_muted
      ? 0
      : [101, 67, 34, 1, 0].find(
          (threshold) => threshold <= audio.speaker.volume * 100
        );

    return `audio-volume-${icons[icon]}-symbolic`;
  }

  const icon = Widget.Icon({
    icon: Utils.watch(getIcon(), audio.speaker, getIcon),
  });

  const slider = Widget.Slider({
    hexpand: true,
    draw_value: false,
    on_change: ({ value }) => (audio.speaker.volume = value),
    setup: (self) =>
      self.hook(audio.speaker, () => {
        self.value = audio.speaker.volume || 0;
      }),
  });

  return Widget.Box({
    class_name: "volume",
    css: "min-width: 180px",
    children: [icon, slider],
  });
}

function ClockWidget() {
  return Widget.Label({
    css: `${widgetCssBase}`,
    label: date.bind(),
  });
}

function getToggleIndex(arr, currentIndex = 0) {
  const nextValue = currentIndex + 1;
  return nextValue === arr.length ? 0 : nextValue;
}

function getGradient(color, percentage = 0, bgColor = "@ctp-latte-surface2") {
  return `background: linear-gradient(90deg, ${color} ${percentage}%, ${bgColor} ${percentage}%); `;
}

const batteryDisplayTypes = ["time", "perc"];
const batteryDisplayType = Variable(0);

function updateBattery(self, battery, displayType = 0) {
  const cssBase = `color: @ctp-latte-base; ${widgetCssBase}`;
  const timeLeftMin = Math.round(battery["time-remaining"] || 0) / 60;
  const percentage = battery["percent"];
  let classToSet = self.class_name;
  let labelToSet = self.label;
  let cssToSet = self.css;

  if (
    !battery.charging &&
    percentage != 100 &&
    (timeLeftMin < 20 || percentage < 20)
  ) {
    cssToSet = getGradient("@ctp-latte-red", percentage);
  } else if (
    !battery.charging &&
    percentage != 100 &&
    (timeLeftMin < 100 || percentage < 70)
  ) {
    cssToSet = getGradient("@ctp-latte-yellow", percentage);
  } else if (percentage == 100) {
    cssToSet = getGradient("@ctp-latte-surface2", percentage);
  } else {
    cssToSet = getGradient("@ctp-latte-green", percentage);
  }

  switch (batteryDisplayTypes[displayType]) {
    case "perc":
      labelToSet = `${percentage}% `;
      break;
    case "perc":
      labelToSet = `${percentage}% `;
      break;
    default:
      labelToSet = `${
        timeLeftMin < 60
          ? `${timeLeftMin.toFixed(0)} min`
          : `${Math.floor(timeLeftMin / 60)}h ${Math.round(
              timeLeftMin % 60
            )} min`
      } `;
  }

  labelToSet = `${battery.charging ? "󱐋 " : ""}${labelToSet}`;

  self.css = `${cssBase}${cssToSet}`;
  self.label = labelToSet;
  self.class_name = classToSet;
}
function BatteryWidget() {
  return Widget.Button({
    on_primary_click: (args) =>
      (batteryDisplayType.value = getToggleIndex(
        batteryDisplayTypes,
        batteryDisplayType.value
      )),
    child: Widget.Label({
      visible: battery.bind("available"),
      setup: (self) => {
        self.hook(batteryDisplayType, () =>
          updateBattery(self, battery, batteryDisplayType.value)
        );
        self.hook(battery, () =>
          updateBattery(self, battery, batteryDisplayType.value)
        );
      },
    }),
  });
}

function SysTray() {
  const items = systemtray.bind("items").as((items) =>
    items.map((item) =>
      Widget.Button({
        css: `${widgetCssBase}`,
        child: Widget.Icon({ icon: item.bind("icon") }),
        on_primary_click: (_, event) => item.activate(event),
        on_secondary_click: (_, event) => item.openMenu(event),
        tooltip_markup: item.bind("tooltip_markup"),
      })
    )
  );

  return Widget.Box({
    children: items,
  });
}

function WireguardWidget() {
  return Widget.Button({
    cursor: "pointer",
    css: connections
      .bind()
      .as(
        (c) =>
          `${widgetCssBase}${
            c?.find(({ type }) => type === "wireguard")
              ? "background: @ctp-latte-green;"
              : "background: @ctp-latte-red;"
          } color: @ctp-latte-base;`
      ),
    on_primary_click: (args) => {
      const isConnected = !!connections.value?.find(
        ({ type }) => type === "wireguard"
      );
      if (isConnected) {
        Utils.execAsync(["nmcli", "connection", "down", "Hetzner"]);
      } else {
        Utils.execAsync(["nmcli", "connection", "up", "Hetzner"]);
      }
    },
    child: Widget.Label({
      // To cmpensate for weird nerd font icons width
      css: "padding-right: 0.55rem",
      label: "󰖂",
    }),
  });
}

function WifiWidget() {
  return Widget.Button({
    css: widgetCssBase,
    cursor: "pointer",
    // on_primary_click: (args) => {
    //     const isConnected = !!connections.value?.find(({ type }) => type === 'wireguard');
    //     if (isConnected) {
    //         Utils.execAsync(['nmcli','connection', 'down', 'hetzner'])
    //     } else {
    //         Utils.execAsync(['nmcli','connection', 'up', 'hetzner'])
    //     }
    // },
    child: Widget.Label({
      label: connections
        .bind()
        .as(
          (c) => c?.find(({ type }) => type === "wifi")?.name || "disconnected"
        ),
    }),
  });
}

const dividePerc = ([total, free]) => Math.round((free / total) * 100);

const cpuPerc = Variable(0, {
  poll: [
    2000,
    "top -b -n 1",
    (out) =>
      dividePerc([
        100,
        out
          .split("\n")
          .find((line) => line.includes("Cpu(s)"))
          .split(/\s+/)[1]
          .replace(",", "."),
      ]),
  ],
});

const ramPerc = Variable(0, {
  poll: [
    2000,
    "free",
    (out) =>
      dividePerc(
        out
          .split("\n")
          .find((line) => line.includes("Mem:"))
          .split(/\s+/)
          .splice(1, 2)
      ),
  ],
});

function Ram() {
  return Widget.Label({
    class_name: "clock",
    label: ramPerc.bind(),
  });
}
function Cpu() {
  return Widget.Label({
    class_name: "clock",
    label: cpuPerc.bind(),
  });
}

// layout of the bar
function Left() {
  return Widget.Box({
    children: [WorkspacesWidget()],
  });
}

function Center() {
  return Widget.Box({
    children: [
      // Media(),
      // Notification(),
    ],
  });
}

function Right() {
  return Widget.Box({
    hpack: "end",
    children: [
      Volume(),
      // Cpu(),
      // Ram(),
      SysTray(),

      WireguardWidget(),
      WifiWidget(),
      BatteryWidget(),
      ClockWidget(),
    ],
  });
}

function Bar(monitor = 0) {
  return Widget.Window({
    name: `bar - ${monitor} `, // name has to be unique
    class_name: "bar",
    monitor,
    anchor: ["top", "left", "right"],
    exclusivity: "exclusive",
    child: Widget.CenterBox({
      start_widget: Left(),
      center_widget: Center(),
      end_widget: Right(),
    }),
  });
}

App.config({
  style: "./style.css",
  windows: [
    // Bar(0),
    Bar(2),
    NotificationPopups(),
    // you can call it, for each monitor
    // Bar(0),
    // Bar(1)
  ],
});

export { };

