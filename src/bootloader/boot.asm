org 0x7c00
bits 16

jmp short main
nop

bdb_oem:                    db 'MSWIN4.1'
bdb_bytes_per_sector:       dw 512
bdb_sector_per_cluster:     db 1
bdb_reserved_sector:        dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880
bdb_media_descriptor_type:  db 0F0h
bdb_sectors_per_fat:        dw 9
bdb_sector_per_track:       dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 29h
ebr_volume_id:              db 12h,34h,56h,78h
ebr_volume_label:           db 'MOZITE      '
ebr_system_id:              db 'FAT12   '

main:
	xor ax, ax
	mov ss, ax
	mov ds, ax
	mov es, ax

	mov sp, 0x7c00

	mov [ebr_drive_number], dl

	mov ax, 1
	mov cl, 1
	mov bx, 0x7E00
	call disk_read

	mov si, os_boot_msg
	call print
	hlt

halt:
	jmp halt

disk_read:
	push ax
	push bx
	push cx
	push dx
	push di
	call lba_to_chs

	mov ah, 02h
	mov di, 3
retry:
	stc
	int 13h
	jnc doneRead
	call diskReset
	dec di
	test di, di
	jnz retry

failDiskRead:
	mov si, read_failure
	call print
	hlt

	jmp halt

diskReset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc failDiskRead
	popa
	ret

doneRead:
	pop di
	pop dx
	pop bx
	pop ax
	pop cx

	ret

lba_to_chs:
	push ax
	push dx
	xor dx, dx
	div word[bdb_sector_per_track]
	inc dx
	mov cx, dx
	xor dx, dx
	div word[bdb_heads]
	mov dh, dl
	mov ch, al
	shl ah, 6
	or cl, ah
	pop ax
	mov dl, al
	pop ax
	ret

print:
	push si
	push ax
	push bx

print_loop:
	lodsb
	or al, al
	jz done_print
	mov ah, 0x0e
	mov bh, 0
	int 0x10

	jmp print_loop

done_print:
	pop bx
	pop ax
	pop si
	ret

os_boot_msg: db "Hello, The OS has Booted", 0x0d, 0x0a, 0
read_failure: db "Failed to read Disk!", 0x0d, 0x0a, 0
times 510-($-$$) db 0
dw 0xaa55