# Orange Pi RV2 NixOS Installer

This repository contains a Nix flake for building an SD card image that can be used to install NixOS on an Orange Pi RV2 board.

## Prerequisites

- Nix with flakes enabled
- A host with enough resources to build an SD card image (either x86_64-linux or riscv64-linux)

## Building the Installer

To build the installer SD card image, run:

```bash
nix flake build .#installer
```

This will create a result symlink to the built SD card image.

## Cross-Building

The flake supports cross-compilation from an x86_64-linux system to build images for the riscv64-linux Orange Pi RV2. This happens automatically when building on an x86_64-linux system.

## Writing the Image to an SD Card

After building the installer, you can write the image to an SD card using:

```bash
# Replace /dev/sdX with your SD card device
sudo dd if=./result/sd-image/*.img of=/dev/sdX bs=4M status=progress conv=fsync
```

## About this Flake

This flake is based on the work from the [hydra-riscv64](https://gitlab.com/misuzu/hydra-riscv64) project and provides:

- A custom kernel for the Orange Pi RV2 board
- Required firmware for Wi-Fi (ap6256)
- ESOS firmware for proper system operation
- NixOS installer configuration

## Custom Components

- **Custom Linux Kernel**: Based on the orangepi-xunlong kernel with patches for the Orange Pi RV2
- **Firmware**: Includes both ESOS firmware and WiFi firmware
- **Installer Configuration**: Specifically tailored for the Orange Pi RV2 board

## License

The code in this repository is provided under the MIT License. Note that some included firmware files are proprietary and redistributed under their respective licenses.