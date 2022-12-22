	.include	"f320.inc"

	.area	CSEG
	ljmp	start
	ajmp	START + 3 + 8 * 0
usb_wait::
	mov	a,USB0ADR
	jb	a.7,.-2
	ret
	ajmp	START + 3 + 8 * 1
usb_set_addr::
	acall	usb_wait
	mov	USB0ADR,dph
	ret
	ajmp	START + 3 + 8 * 2
usb_wr_byte::
	acall	usb_wait
	mov	USB0DAT,dpl
	ret
	ajmp	START + 3 + 8 * 3
usb_rd_byte::
	acall	usb_wait
	mov	b,USB0DAT
	ret
	ajmp	START + 3 + 8 * 4
usb_rd_reg::
	mov	dph,a
	acall	usb_set_addr
	ajmp	usb_rd_byte
	ajmp	START + 3 + 8 * 5
usb_wr_reg::
	lcall	usb_set_addr
	ljmp	usb_wr_byte
	ajmp	START + 3 + 8 * 6
usb_soprdy::
	mov	dptr,#(E0CSR << 8) | 0x40
	ljmp	usb_wr_reg
	ajmp	START + 3 + 8 * 7
usb_send_zero::
	mov	dptr,#(E0CSR << 8) | 0x08
	ljmp	usb_wr_reg
	ajmp	START + 3 + 8 * 8
usb_send_one::
	acall	usb_wr_fifo
	mov	USB0DAT,r0
	ajmp	usb_send_fifo
	ajmp	START + 3 + 8 * 9
usb_wr_fifo::
	mov	dph,#FIFO_EP0
	ljmp	usb_set_addr
	ajmp	START + 3 + 8 * 10
usb_send_fifo::
	mov	dptr,#(E0CSR << 8) | 0x0A
	ljmp	usb_wr_reg
	ajmp	START + 3 + 8 * 11
usb_stall::
	mov	dptr,#(E0CSR << 8) | 0x20
	ljmp	usb_wr_reg
	ajmp	START + 3 + 8 * 12
dsc_size::
	.db	0x02, 0x12, 0x1b, 0x04, 0x06, 0x12
	ajmp	START + 3 + 8 * 13
dsc_addr::
	.db	<dsc_dev + 4, <dsc_dev, <dsc_cfg, <dsc_str0, <dsc_str1, <dsc_str2
	ajmp	START + 3 + 8 * 14
dsc_str0::
	.db	0x04	; bLength
	.db	0x03	; bDescriptorType
	.db	0x09, 0x04, 0, 0
	ajmp	START + 3 + 8 * 15
dsc_str1::
	.db	0x06 	; bLength
	.db	0x03	; bDescriptorType
	.db	'D',0,'F',0
	ajmp	START + 3 + 8 * 16
flash_wr::
	mov	FLKEY,#0xa5
	mov	FLKEY,#0xf1
	mov	PSCTL,a
	mov	a,@r0
	movx	@dptr,a
	mov	PSCTL,#0
	ret
	ajmp	START + 3 + 8 * 18
usb_wr_dat::
	mov	USB0DAT,a
	ljmp 	usb_wait
	nop
	ajmp	START + 3 + 8 * 19
usb_wr_2z::
	clr	a
	acall	usb_wr_dat
	clr	a
	ajmp 	usb_wr_dat
	ajmp	START + 3 + 8 * 20
