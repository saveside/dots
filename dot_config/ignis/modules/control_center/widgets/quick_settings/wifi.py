import asyncio
from ignis import widgets
from ignis import utils
from ...qs_button import QSButton
from ...menu import Menu
from ....shared_widgets import ToggleBox
from ignis.services.network import NetworkService, WifiAccessPoint, WifiDevice

network = NetworkService.get_default()


class WifiNetworkItem(widgets.Button):
    def __init__(self, access_point: WifiAccessPoint):
        super().__init__(
            css_classes=["network-item", "unset"],
            on_click=lambda x: asyncio.create_task(access_point.connect_to_graphical()),
            child=widgets.Box(
                child=[
                    widgets.Icon(
                        image=access_point.bind(
                            "strength", transform=lambda value: access_point.icon_name
                        ),
                    ),
                    widgets.Label(
                        label=access_point.ssid,
                        halign="start",
                    ),
                    widgets.Icon(
                        image="object-select-symbolic",
                        halign="end",
                        hexpand=True,
                        visible=access_point.bind("is_connected"),
                    ),
                ]
            ),
        )


class WifiMenu(Menu):
    def __init__(self, device: WifiDevice):
        super().__init__(
            name="wifi",
            child=[
                ToggleBox(
                    label="Wi-Fi",
                    active=network.wifi.enabled,
                    on_change=lambda x, state: network.wifi.set_enabled(state),
                    css_classes=["network-header-box"],
                ),
                widgets.Box(
                    vertical=True,
                    child=device.bind(
                        "access_points",
                        transform=lambda value: [WifiNetworkItem(i) for i in value],
                    ),
                ),
                widgets.Separator(),
                widgets.Button(
                    css_classes=["network-item", "unset"],
                    on_click=lambda x: asyncio.create_task(utils.exec_sh_async("nm-connection-editor")),
                    style="margin-bottom: 0;",
                    child=widgets.Box(
                        child=[
                            widgets.Icon(image="preferences-system-symbolic"),
                            widgets.Label(
                                label="Network Settings",
                                halign="start",
                            ),
                        ]
                    ),
                ),
            ],
        )


class WifiButton(QSButton):
    def __init__(self, device: WifiDevice):
        menu = WifiMenu(device)

        def get_label(ssid: str) -> str:
            if ssid:
                return ssid
            else:
                return "Wi-Fi"

        def get_icon(icon_name: str) -> str:
            if device.ap.is_connected:
                return icon_name
            else:
                return "network-wireless-symbolic"

        def toggle_list(x) -> None:
            asyncio.create_task(device.scan())
            menu.toggle()

        super().__init__(
            label=device.ap.bind("ssid", get_label),
            icon_name=device.ap.bind("icon-name", get_icon),
            on_activate=toggle_list,
            on_deactivate=toggle_list,
            active=network.wifi.bind("enabled"),
            menu=menu,
        )


def wifi_control() -> list[QSButton]:
    return [WifiButton(dev) for dev in network.wifi.devices]
