# **Godots**

**Godots** is a lightweight desktop app for managing your Godot Engine versions and projects.
Everything you need is in one place — downloading editors, keeping multiple versions, and organizing your projects — all in an interface that looks and feels just like the built-in Godot Project Manager.

<p align="center">
<img width="812" src="https://github.com/MakovWait/godots/assets/39778897/607ce24b-2c39-4ede-8810-f7c528a496d2">
</p>

## **Installation**

### **Windows**
- Download the ZIP, extract it, and run the executable.
- No additional setup required.

### **Linux**
- Unzip and launch the binary directly.

Alternatively:
- Install from Flathub (**community maintained**):
<div align="start">
<a href='https://flathub.org/apps/details/io.github.MakovWait.Godots'><img width="250" alt='Download on Flathub' src='https://raw.githubusercontent.com/flxzt/rnote/main/misc/assets/flathub-badge.svg'/></a>
</div>

- Arch Linux users can install via AUR (**community maintained**):  
  - [`godots-bin`](https://aur.archlinux.org/packages/godots-bin)  
  - [`godots-git`](https://aur.archlinux.org/packages/godots-git)

### **macOS**
- Unzip and run **Godots.app**.
- macOS may require removing the quarantine flag:
  ```sh
  sudo xattr -r -d com.apple.quarantine /Applications/Godots.app
  ```

Download any build directly from:  
👉 **[Latest Releases](https://github.com/MakovWait/godots/releases)**

---

## **Features**

### **Download & manage any Godot version**
- Fetch any official release from GitHub.
- Keep multiple versions side-by-side.
- Add custom local Godot binaries.

### **Full project manager**
- Add, import, organize, and launch projects.
- Bind specific engine versions to individual projects.
- Launch/edit projects directly with their assigned version.
- Drag & drop `project.godot` or entire project folders.

### **HiDPI / Retina support**
- Sharp, crisp UI on high-resolution displays.

### **Theming**
- Supports custom themes compatible with Godot’s own theming system.
- Guide: 👉 **[Theming Documentation](.github/assets/THEMING.md)**
![image](https://github.com/MakovWait/godots/blob/main/.github/assets/screenshot3.png)

### **CLI interface**
- Manage projects and versions through the command line.  
  Details: 👉 **[CLI Features](.github/assets/FEATURES.md#cli)**

---

## **License**
MIT License — see `LICENSE.md`.
