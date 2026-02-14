.PHONY: prepare kernel bootloader image run clean
all: image

prepare:
	mkdir -p bin/tmp

kernel: prepare
	gcc -m32 -ffreestanding -fno-pic -fno-stack-protector -c src/kernel/kernel.c -o bin/tmp/kernel.o
	ld -m elf_i386 -T src/linker.ld bin/tmp/kernel.o -o bin/tmp/kernel.bin -e kernel_main -Map bin/tmp/kernel.map

bootloader: prepare kernel
	$(eval KERNEL_SIZE := $(shell stat -c%s bin/tmp/kernel.bin))
	$(eval KERNEL_SECTORS := $(shell echo $$(( ($(KERNEL_SIZE) + 511) / 512 )) ))
	$(eval BSS_START := $(shell awk '$$2 == "bss_start" {print $$1}' bin/tmp/kernel.map))
	$(eval BSS_END := $(shell awk '$$2 == "bss_end" {print $$1}' bin/tmp/kernel.map))
	nasm -f bin src/bootloader/stage_one.asm -o bin/tmp/stage_one.bin
	nasm -f bin src/bootloader/stage_two.asm -o bin/tmp/stage_two.bin -dKERNEL_SECTORS=$(KERNEL_SECTORS) -dBSS_START=$(BSS_START) -dBSS_END=$(BSS_END)

image: prepare kernel bootloader
	cat bin/tmp/stage_one.bin > bin/akeno_os.img
	cat bin/tmp/stage_two.bin >> bin/akeno_os.img
	cat bin/tmp/kernel.bin >> bin/akeno_os.img
	truncate -s 1440K bin/akeno_os.img

run: prepare kernel bootloader image
	qemu-system-x86_64 -drive file=bin/akeno_os.img,format=raw,index=0,media=disk

clean:
	rm -rf bin/