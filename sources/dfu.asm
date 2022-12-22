	.include	"f320.inc"
	.area	DSEG
	.ds	4	; r0..r3
usb_cfg:	.ds	1	; r4
usb_buf:	.ds	8
bmReqType	= usb_buf + 0	; r5
bRequest	= usb_buf + 1	; r6
wValue.l	= usb_buf + 2	; r7
wValue.h	= usb_buf + 3
wIndex.l	= usb_buf + 4
wIndex.h	= usb_buf + 5
wLength.l	= usb_buf + 6
wLength.h	= usb_buf + 7

	.area	CSEG
dsc_dev::
	.db	0x12	; bLength
	.db	0x01	; bDescriptorType
	.dw	0x0002	; bcdUSB
	.db	0x00	; bDeviceClass
	.db	0x00	; bDeviceSubClass
	.db	0x00	; bDeviceProtocol
	.db	0x40	; bMaxPacketSize0
	.dw	0xc410	; idVendor
	.dw	0x61ea	; idProduct
	.dw	0x0001	; bcdDevice
	.db	0x00	; iManufacturer
	.db	0x01	; iProduct
	.db	0x00	; iSerialNumber
	.db	0x01	; bNumConfigurations
dsc_cfg::
	.db	0x09	; bLength
	.db	0x02	; bDescriptorType
	.dw	0x1b00	; wTotalLength
	.db	0x01	; bNumInterfaces
	.db	0x01	; bConfigurationValue
	.db	0x00	; iConfiguration
	.db	0x80	; bmAttributes
	.db	0x32	; bMaxPower
dsc_if::
	.db	0x09	; bLength
	.db	0x04	; bDescriptorType
	.db	0x00	; bInterfaceNumber
	.db	0x00	; bAlternateSetting
	.db	0x00	; bNumEndpoints
	.db	0xfe	; bInterfaceClass
	.db	0x01	; bInterfaceSubClass
	.db	0x02	; bInterfaceProtocol
	.db	0x01	; iInterface
dsc_dfu::
	.db	0x09	; bLength
	.db	0x21	; bDescriptorType
	.db	0x01 	; bmAttributes
	.dw	0xff00	; wDetachTimeOut
	.dw	0x4000	; wTransferSize
	.dw	0x1001 	; bcdDFUVersion
dsc_str2::
	.db	0x12	; bLength
	.db	0x03	; bDescriptorType
	.db	'M', 0x00	; Signature
	.db	'S', 0x00
	.db	'F', 0x00
	.db	'T', 0x00
	.db	'1', 0x00
	.db	'0', 0x00
	.db	'0', 0x00
	.db	0x10,0x00	; Vendor Code

	.if	0
	.macro	PUTC char
	mov	a,char
	acall	putc
	.endm
	.macro	PUTS str
	acall	puts
	.strz	str
	.endm
	.macro	PUTH hex
	mov	a,hex
	acall	puth
	.endm
putc:	; Put char (speed: 1.5MHz / 3 = 0.5Mbit)
	mov	P2MDOUT,#0x80
	clr	p2.7
	.rept	8
	rrc	a	; 1
	mov	p2.7,c	; 2
	.endm
	rrc	a
	setb	p2.7
	ret
puts:	; Put string
	pop	dph
	pop	dpl
1$:	clr	a
	movc	a,@a+dptr
	inc	dptr
	jnz	2$
	push	dpl
	push	dph
	ret
2$:	acall	putc
	ajmp	1$
puth:	; Put HEX
	push	a
	push	a
	swap	a
	acall	1$
	pop	a
	acall	1$
	pop	a
	ret
1$:	anl	a,#0x0f
	add	a,#-10
	jnc	2$
	add	a,#0x07
2$:	add	a,#0x3a
	ajmp	putc
	.else
	.macro	PUTC char
	.endm
	.macro	PUTS str
	.endm
	.macro	PUTH hex
	.endm
	.endif

	.macro	USB_WR addr, dat
	mov	dptr,#(addr << 8) | dat
	acall	usb_wr_reg
	.endm

	.macro	USB_RD addr
	mov	a,#addr | 0x80
	acall	usb_rd_reg
	.endm

start::
	jb	p3.0,start_app
;	jnb	p3.0,start_app
1$:	mov	CLKMUL,#0x80
	mov	PCA0MD,#0
	mov	SP,#-32
	mov	CLKMUL,#0xC0
2$:	mov	a,CLKMUL
	jnb	a.5,2$
	PUTS	"\n\n\n\033[36mBootloader\033[0m"
	USB_WR	POWER, 0x08
	mov	USB0XCN,#0xe0
	USB_WR	CLKREC,0x89
	USB_WR	POWER, 0x01
	USB_WR	INDEX, 0
	mov	r1,#2	; dfu_state = dfuIDLE
loop:
	acall	usb
	cjne	r1,#0xff,loop
	djnz	r1,.
	mov	USB0XCN,r1
	PUTS	"\nDownload_done\n"

start_app:
	ajmp	START

; USB Handler
usb:
	USB_RD	CMINT
	;jnb	b.2,1$	; RSTINT
	;PUTS	"\nUSB_Reset"
1$:	USB_RD	IN1INT
	jnb	b.0,2$
	USB_RD	E0CSR
	jnb	b.2,3$	; EP0 STSTL
	PUTS	"\nstall"
	USB_WR	E0CSR, 0x00
2$:	ret
3$:	jnb	b.0,2$	; EP0 OPRDY
	PUTS	"\nep0:"
	mov	r0,#usb_buf
	USB_RD	E0CNT	; usb_rd_fifo
	mov	dph,#0xc0 | FIFO_EP0
	acall	usb_set_addr
4$:	acall	usb_wait
	mov	@r0,USB0DAT
	PUTH	@r0
	jnb	f0,6$	; Flash erase & programming
	mov	dpl,r2
	mov	dph,r3
	cjne	r2,#0,5$
	mov	a,r3
	jb	a.0,5$
	mov	a,#3
	acall	flash_wr
5$:	mov	a,#1
	acall	flash_wr
	inc	dptr
	mov	r2,dpl
	mov	r3,dph
6$:	inc	r0
	djnz	b,4$
	PUTC	#32
	acall	usb_soprdy
	jbc	f0,2$
	mov	a,r5
	jnb	a.5,std

dfu:	; DFU Class Requests Handler
	mov	a,r6
	jz	6$	; DFU_DETACH
	dec	a
	jnz	2$	; DFU_DNLOAD
	PUTS	"dfu_load"
	mov	a,r7	; wValue.l
	orl	a,wValue.h
	jnz	0$
	mov	r2,a
	mov	r3,#>START
0$:	mov	a,wLength.l
	mov	r1,a
	jz	1$
	mov	r1,#5	; dfu_state = dfuDNLOAD-IDLE
	setb	f0
1$:	ret
2$:	dec	a
	dec	a
	jnz	3$	; DFU_GETSTATUS
	PUTS	"dfu_stat"
	acall	usb_wr_fifo
	clr	a	; bStatus = 0
	acall	usb_wr_dat
	mov	a,#30	; bwPollTimeout
	acall	usb_wr_dat
	acall	usb_wr_2z
	mov	a,r1	; bState = dfu_state
	jnz	.+3
	dec	r1
	acall	usb_wr_dat
	clr	a	; iString
	acall	usb_wr_dat
	ajmp	usb_send_fifo
3$:	dec	a
	jz	6$	; DFU_CLRSTATUS
4$:	dec	a
	jnz	5$	; DFU_GETSTATE
	PUTS	"dfu_state"
	mov	a,r1
	mov	r0,a
	ajmp	usb_send_one
5$:	dec	a
	jnz	stall	; DFU_ABORT
6$:	PUTS	"dfu_clr"	; detach clrstate abort
	mov	r1,#2	; dfu_state = dfuIDLE
	ajmp	usb_send_zero
stall:
	ajmp	usb_stall

std:	; Standard Requests Handler
	mov	a,r6
	jnz	1$
	PUTS	"gSTA:"	; GET_STATUS
	ajmp	5$
1$:	cjne	a,#5,2$	; SET_ADDRESS
	PUTS	"sADR:"
	PUTH	wValue.l
	mov	dph,#FADDR
	mov	dpl,r7	; wValue.l
	orl	dpl,#0x80
	acall	usb_wr_reg
	ajmp	usb_send_zero
2$:	cjne	a,#9,3$	; SET_CONFIGURATION
	PUTS	"sCFG:"
	PUTH	wValue.l
	mov	usb_cfg,r7; wValue.l
	ajmp	usb_send_zero
3$:	cjne	a,#8,4$	; GET_CONFIGURATION
	PUTS	"gGFG:"
	PUTH	usb_cfg
	mov	r0,usb_cfg
	ajmp	usb_send_one
4$:	cjne	a,#6,stall; GET_DESCRIPTOR
	PUTS	"gDSC:"
5$:	mov	a,r7	; wValue.l
	anl	a,#0x03
	add	a,wValue.h
	mov	r0,a
	mov	dptr,#dsc_size
	movc	a,@a+dptr
	xch	a,r0
	mov	dptr,#dsc_addr
	movc	a,@a+dptr
	mov	dpl,a
usb_send_packet:
	mov	a,r0
	clr	c
	subb	a,wLength.l
	jc	1$
	mov	r0,wLength.l
1$:	acall	usb_wait
	mov	USB0ADR,#FIFO_EP0
2$:	clr	a
	movc	a,@a+dptr
	PUTH	acc
	acall	usb_wr_dat
	inc	dptr
	djnz	r0,2$
	ajmp	usb_send_fifo
