# works: boot from nvme (bottom slot), boot from usb (blue ones)
{ lib
, buildPackages
, buildLinux
, fetchFromGitHub
, fetchpatch
, ...
} @ args:

let
  modDirVersion = "6.6.63";
in
(buildLinux (args // {
  inherit modDirVersion;
  version = "${modDirVersion}-ky";

  src = fetchFromGitHub {
    owner = "orangepi-xunlong";
    repo = "linux-orangepi";
    rev = "ae9e974d3e19f460b6397bfe8f0f1417a073ce05";
    hash = "sha256-3mJMruK/oQNsw9VWDVln1CZ+Zv8MXQBy4gmsi7EbX+s=";
  };

  defconfig = "x1_defconfig";

  structuredExtraConfig = with lib.kernel; {
    # ttyS0
    SERIAL_8250 = lib.mkForce no;
    SERIAL_PXA_KY_X1 = yes;

    # Broken
    SPI_DESIGNWARE_EXT = no;
    TOUCHSCREEN_GT9XX = no;
    TOUCHSCREEN_GOODIX = no;
    TYPEC_HUSB239 = no;
    USB_NET_ASIX = no;
    WLAN_VENDOR_REALTEK = no;

    ETHERCAT = no;
    TOUCHSCREEN_FTS = no;

    # Make the build faster
    COMPILE_TEST = no;
    DRM_NOUVEAU = no;
    DRM_AMDGPU = no;
  };

  kernelPatches = [
    {
      patch = fetchpatch {
        url = "https://raw.githubusercontent.com/cwt-opi-rv2/linux-cwt-orangepi-ky/f52ff2db8a163c51c770fe72af6a6e5c8f315617/linux-01-enable_pxa_pwm_on_ky_x1.patch";
        hash = "sha256-nDTiRfAhgok06tP//m9NG2PoEfpKQS2Gz5mpHSHo9Pg=";
      };
    }
    {
      patch = fetchpatch {
        url = "https://raw.githubusercontent.com/cwt-opi-rv2/linux-cwt-orangepi-ky/f52ff2db8a163c51c770fe72af6a6e5c8f315617/linux-02-add_DMA_BUF_ns_import_to_amvx.patch";
        hash = "sha256-V2vWHTmai4PZapTGlAJnJUetv+P4C0xK01GgFUdcCKw=";
      };
    }
    {
      patch = ./bcmdhd-makefile-include-fix.patch;
    }
  ];

  extraMeta = {
    branch = lib.versions.major modDirVersion;
    platforms = [ "riscv64-linux" ];
  };
} // (args.argsOverride or { }))).overrideAttrs (old: {
  nativeBuildInputs = old.nativeBuildInputs or [ ] ++ (with buildPackages; [ ubootTools ]);
  env.NIX_CFLAGS_COMPILE = toString [
    "-Wno-error=incompatible-pointer-types"
    "-Wno-error=implicit-function-declaration"
    "-Wno-error=int-conversion"
  ];
})
