export KBUILD_OUTPUT := build_4b
export ARCH := arm64
export LLVM := -17

# 检查是否支持 Rust
.PHONY: rustavailable
rustavailable:
	@$(MAKE) -C linux_raspberrypi ARCH=$(ARCH) O=$(KBUILD_OUTPUT) LLVM=$(LLVM) rustavailable
	@echo "Rust is available!"

# 下载树莓派操作系统镜像
# [destinyfvcker] xz -d 解压缩，这里 - 在普通的情况下就代表标准输入，但是在这里因为使用了管道，
# 所以表示 xz 命令应该从 curl 命令的输出之中读取数据
2024-03-12-raspios-bookworm-arm64-lite.img:
	@curl -sfL https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-13/$@.xz | xz -d - > $@
	qemu-img resize $@ 4G

# 配置并构建内核
linux_raspberrypi/$(KBUILD_OUTPUT)/arch/$(ARCH)/boot/Image:
	@$(MAKE) -C linux_raspberrypi ARCH=$(ARCH) O=$(KBUILD_OUTPUT) LLVM=$(LLVM) bcm2711_rust_defconfig
	@$(MAKE) -C linux_raspberrypi ARCH=$(ARCH) O=$(KBUILD_OUTPUT) LLVM=$(LLVM) -j$$(nproc)

# 构建目标
.PHONY: build
build: linux_raspberrypi/$(KBUILD_OUTPUT)/arch/$(ARCH)/boot/Image

# 使用 QEMU 运行
.PHONY: run
run: build 2024-03-12-raspios-bookworm-arm64-lite.img
	@qemu-system-aarch64 \
		-machine type=raspi3b \
		-m 1024 \
		-k en-us \
		-dtb linux_raspberrypi/$(KBUILD_OUTPUT)/arch/$(ARCH)/boot/dts/broadcom/bcm2710-rpi-3-b-plus.dtb \
		-kernel linux_raspberrypi/$(KBUILD_OUTPUT)/arch/$(ARCH)/boot/Image \
		-drive id=hd-root,format=raw,file=2024-03-12-raspios-bookworm-arm64-lite.img \
		-append "rw earlycon=pl011,0x3f201000 console=ttyAMA0 loglevel=8 root=/dev/mmcblk0p2 \
		fsck.repair=yes net.ifnames=0 rootwait memtest=1 dwc_otg.fiq_fsm_enable=1" \
		-serial stdio \
		-usb -device usb-kbd \
		-device usb-tablet -device usb-net