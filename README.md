![sway](assets/S.png)

This is my personal repo for my Arch linux configurations.

# Dependencies

| Type            | Package(s)                                           |
| --------------- | ---------------------------------------------------- |
| WM              | `swayfx`                                             |
| Bar             | `waybar`                                             |
| Launcher        | `rofi`                                               |
| Notifications   | `ags`                                                |
| Terminal        | `alacritty`                                          |
| GTK             | `Collaid Gruvbox`                                    |
| Icons           | `Flat-remix-orange-dark`                             |
| Cursor          | `bibata`                                             |
| File manager    | `thunar`                                             |
| Screenshot tool | `flameshot`                                          |
| Polkit manager  | `lxsession`                                          |
| Fonts           | `ttf-iosevka-nerd ttf-jetbrains-mono monaspace Neon` |
| Editor          | `neovim`                                             |

You can also use `yay -S --needed - < pkgs` to install all dependencies.

# Installation

Incomplete but should get you most things.

```bash
# clone repository
git clone https://github.com/saveside/dots.git
# install required packages (requires root)
pacman -S --needed $(cat dots/pkgs)
# copy repository contents to HOME
cp -r dots/.* $HOME
# restart system
reboot
```

# Some shortcuts

| Shortcut               | Action                             |
| ---------------------- | ---------------------------------- |
| Super + Return (enter) | Launch terminal (`alacritty`)      |
| Super + W              | Launch file manager (`thunar`)     |
| Super + Q              | Launch web browser (`brave`)       |
| Super + Shift + C      | Close focused application          |
| Super + Shift + R      | Restart window manager             |
| Super + Shift + Q      | Quit window manager                |
| Super + R              | Start program launcher (`rofi`)    |
| Super + 1-9            | Switch workspaces from 1 to 9      |

## Screenshots

![sway](assets/gruvbox_stackedd.png)
