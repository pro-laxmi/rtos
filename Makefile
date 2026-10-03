CC = i686-elf-gcc
AS = i686-elf-as

SRC_DIR = src
BUILD_DIR = build
ISO_DIR = isodir

.PHONY: all clean run

all: myos.iso
all: $(BUILD_DIR)/myos.iso

boot.o: boot.s
	$(AS) boot.s -o boot.o
$(BUILD_DIR)/boot.o: $(SRC_DIR)/boot.s
	@mkdir -p $(BUILD_DIR)
	$(AS) $< -o $@

kernel.o: kernel.c
	$(CC) -std=gnu99 -ffreestanding -O2 -Wall -Wextra -c kernel.c -o kernel.o
$(BUILD_DIR)/kernel.o: $(SRC_DIR)/kernel.c
	@mkdir -p $(BUILD_DIR)
	$(CC) -std=gnu99 -ffreestanding -O2 -Wall -Wextra -c $< -o $@

myos.bin: boot.o kernel.o
	$(CC) -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc
$(BUILD_DIR)/myos.bin: $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o $(SRC_DIR)/linker.ld
	$(CC) -T $(SRC_DIR)/linker.ld -o $@ -ffreestanding -O2 -nostdlib $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o -lgcc

myos.iso: myos.bin grub.cfg
	mkdir -p isodir/boot/grub
	cp myos.bin isodir/boot/myos.bin
	cp grub.cfg isodir/boot/grub/grub.cfg
	grub2-mkrescue -o myos.iso isodir
$(BUILD_DIR)/myos.iso: $(BUILD_DIR)/myos.bin $(SRC_DIR)/grub.cfg
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(BUILD_DIR)/myos.bin $(ISO_DIR)/boot/myos.bin
	cp $(SRC_DIR)/grub.cfg $(ISO_DIR)/boot/grub/grub.cfg
	grub2-mkrescue -o $@ $(ISO_DIR)

run: myos.iso
	qemu-system-i386 -cdrom myos.iso
run: $(BUILD_DIR)/myos.iso
	qemu-system-i386 -cdrom $<

clean:
	rm -f boot.o kernel.o myos.bin myos.iso
	rm -rf isodir
	rm -rf $(BUILD_DIR) $(ISO_DIR)
