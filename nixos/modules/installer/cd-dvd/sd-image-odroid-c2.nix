# To build, use:
# nix-build nixos -I nixos-config=nixos/modules/installer/cd-dvd/sd-image-odroid-c2.nix -A config.system.build.sdImage
{ config, lib, pkgs, ... }:

let
  extlinux-conf-builder =
    import ../../system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix {
      inherit pkgs;
    };
in
{
  imports = [
    ./sd-image-aarch64.nix
  ];

  boot.kernelParams = ["console=ttyAML0,115200n8" "earlycon" "console=tty0"];

  sdImage = {
    imageBaseName = "nixos-odroidc2";
    populateBootCommands = ''
      # Ref: http://git.denx.de/?p=u-boot.git;a=blob_plain;f=board/amlogic/odroid-c2/README;hb=HEAD
      export HKDIR=${pkgs.fip_create.src}

      echo "Creating FIP"
      ${pkgs.fip_create}/bin/fip_create \
        --bl30  $HKDIR/fip/gxb/bl30.bin \
        --bl301 $HKDIR/fip/gxb/bl301.bin \
        --bl31  $HKDIR/fip/gxb/bl31.bin \
        --bl33  ${pkgs.ubootOdroidC2}/u-boot.bin \
        --dump \
        fip.bin

      echo "Inserting bl2"
      cat $HKDIR/fip/gxb/bl2.package fip.bin > boot_new.bin

      echo "Wrapping u-boot"
      ${pkgs.meson-tools}/bin/amlbootsig boot_new.bin u-boot.img
      # Write bootloaders to sd image
      echo "Flashing bootloader"
      dd if=${pkgs.bl1-odroid-c2.default} of=$img conv=notrunc bs=1 count=442
      dd if=${pkgs.bl1-odroid-c2.default} of=$img conv=notrunc bs=512 skip=1 seek=1
      dd if=u-boot.img of=$img conv=notrunc bs=512 skip=96 seek=97

      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./boot
    '';
    # populateBootCommands = ''
    #   cp ${pkgs.ubootOdroidC2}/u-boot.bin boot/u-boot.bin

    #   # Ref: http://git.denx.de/?p=u-boot.git;a=blob_plain;f=board/amlogic/odroid-c2/README;hb=HEAD
    #   export HKDIR=${pkgs.fip_create.src}

    #   echo "Creating FIP"
    #   ${pkgs.fip_create}/bin/fip_create \
    #     --bl30  $HKDIR/fip/gxb/bl30.bin \
    #     --bl301 $HKDIR/fip/gxb/bl301.bin \
    #     --bl31  $HKDIR/fip/gxb/bl31.bin \
    #     --bl33  ${pkgs.ubootOdroidC2}/u-boot.bin \
    #     --dump \
    #     fip.bin

    #   echo "Inserting bl2"
    #   cat $HKDIR/fip/gxb/bl2.package fip.bin > boot_new.bin

    #   echo "Wrapping u-boot"
    #   ${pkgs.fip_create}/bin/aml_encrypt_gxb --bootsig \
    #                                          --input boot_new.bin \
    #                                          --output u-boot.img
    #   dd if=u-boot.img of=u-boot.gxbb bs=512 skip=96

    #   # Write bootloaders to sd image
    #   echo "Flashing bootloader"
    #   dd if=${pkgs.bl1-odroid-c2.default} of=$img conv=fsync bs=1 count=442
    #   dd if=${pkgs.bl1-odroid-c2.default} of=$img conv=fsync bs=512 skip=1 seek=1
    #   dd if=u-boot.gxbb of=$img conv=fsync bs=512 skip=96 seek=97

    #   ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./boot
    # '';
  };
}
