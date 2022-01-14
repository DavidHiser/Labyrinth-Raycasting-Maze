.include "projectfunctions.asm"

.text
.globl	main
main:
	#allocate space for the memory mapped bitmap display
	allocate_heap(32768)
	
	#allocate space for the ZBuffer; SCREEN_WIDTH*8(width of double) = 1024
	allocate_heap(1024)
	sw	$v0, ZBuffer

	open_file(mapfile)
	blt	$v0, $zero, exit
	move	$s6, $v0
	
	read_file($s6, map, 256)
	blez	$v0, exit
	
	#process map
	li	$t0, 0
	li	$t1, 256
	la	$t3, map
	processloop:
	lbu	$t4, ($t3)
	subi	$t4, $t4, 48
	sb	$t4, ($t3)
	addi	$t3, $t3, 1
	addi	$t0, $t0, 1
	bne	$t0, $t1, processloop
	
	close_file($s6)

	#display main menu
	li	$a0, 0
	li	$a1, 0
	la	$v0, mainmenu
	li	$a2, 64
	li	$a3, 128
	jal	draw_texture
	
menuloop:
	lw 	$t0, 0xffff0000		#holds if input available
    	beq 	$t0, 0, menuloop	#If no input, keep displaying
	lw 	$s1, 0xffff0004
	beq	$s1, 32, exit		# input space
	beq	$s1, 119, start		# input w
	j	menuloop

	start:
	li	$t8, 1
gamemainloop:
	
	ldc1	$f0, posX
	ldc1	$f2, posY
	cvt.w.d	$f0, $f0
	cvt.w.d	$f2, $f2
	mfc1	$t2, $f0	# map X
	mfc1	$t3, $f2	# map Y
	mul	$t3, $t3, MAP_WIDTH
	add	$t3, $t3, $t2
	la	$t4, map
	add	$t4, $t4, $t3
	lb	$t2, ($t4)
	beq	$t2, 2, gameover
	
	lw 	$t0, 0xffff0000		#holds if input available
    	beq 	$t0, 0, afterinput	#If no input, keep looping
	
	# process input
	lw 	$s1, 0xffff0004
	beq	$s1, 32, exit		# input space
	beq	$s1, 119, forward	# input w
	beq	$s1, 115, back		# input s
	beq	$s1, 97, left		# input a
	beq	$s1, 100, right		# input d
	j	afterinput		# invalid input, ignore
	
	forward:
	li	$t8, 1
	li	$t2, 2
	mtc1	$t2, $f20
	cvt.d.w	$f20, $f20
	ldc1	$f0, posX
	ldc1	$f2, posY
	ldc1	$f4, dirX
	ldc1	$f6, dirY
	div.d	$f4, $f4, $f20
	div.d	$f6, $f6, $f20
	add.d	$f0, $f0, $f4
	add.d	$f2, $f2, $f6
	
	ldc1	$f10, posX
	ldc1	$f12, posY
	ldc1	$f14, posX
	ldc1	$f16, posY
	sdc1	$f0, posX
	sdc1	$f2, posY
	
	cvt.w.d	$f0, $f0
	cvt.w.d	$f2, $f2
	mfc1	$t2, $f0	# map X
	mfc1	$t3, $f2	# map Y
	mul	$t3, $t3, MAP_WIDTH
	add	$t3, $t3, $t2
	la	$t4, map
	add	$t4, $t4, $t3
	lb	$t2, ($t4)
	bne	$t2, 1, fnotblocked
	sdc1	$f14, posX
	sdc1	$f16, posY
	fnotblocked:
	
	j	afterinput
	
	back:
	li	$t8, 1
	li	$t2, 2
	mtc1	$t2, $f20
	cvt.d.w	$f20, $f20
	ldc1	$f0, posX
	ldc1	$f2, posY
	ldc1	$f4, dirX
	ldc1	$f6, dirY
	div.d	$f4, $f4, $f20
	div.d	$f6, $f6, $f20
	sub.d	$f0, $f0, $f4
	sub.d	$f2, $f2, $f6
	
	ldc1	$f10, posX
	ldc1	$f12, posY
	ldc1	$f14, posX
	ldc1	$f16, posY
	sdc1	$f0, posX
	sdc1	$f2, posY
	
	cvt.w.d	$f0, $f0
	cvt.w.d	$f2, $f2
	mfc1	$t2, $f0	# map X
	mfc1	$t3, $f2	# map Y
	mul	$t3, $t3, MAP_WIDTH
	add	$t3, $t3, $t2
	la	$t4, map
	add	$t4, $t4, $t3
	lb	$t2, ($t4)
	bne	$t2, 1, bnotblocked
	sdc1	$f14, posX
	sdc1	$f16, posY
	bnotblocked:
	
	j	afterinput
	
	left:
	li	$t8, 1
	ldc1	$f0, dirX
	ldc1	$f8, dirX
	ldc1	$f2, dirY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	mul.d	$f0, $f0, $f4
	mul.d	$f2, $f2, $f6
	sub.d	$f0, $f0, $f2
	sdc1	$f0, dirX
	
	mov.d	$f0, $f8
	ldc1	$f2, dirY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	mul.d	$f0, $f0, $f6
	mul.d	$f2, $f2, $f4
	add.d	$f2, $f2, $f0
	sdc1	$f2, dirY
	
	ldc1	$f0, planeX
	ldc1	$f8, planeX
	ldc1	$f2, planeY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	mul.d	$f0, $f0, $f4
	mul.d	$f2, $f2, $f6
	sub.d	$f0, $f0, $f2
	sdc1	$f0, planeX
	
	mov.d	$f0, $f8
	ldc1	$f2, planeY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	mul.d	$f0, $f0, $f6
	mul.d	$f2, $f2, $f4
	add.d	$f2, $f2, $f0
	sdc1	$f2, planeY
	j	afterinput
	
	right:
	li	$t8, 1
	ldc1	$f0, dirX
	ldc1	$f8, dirX
	ldc1	$f2, dirY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	neg.d	$f6, $f6
	mul.d	$f0, $f0, $f4
	mul.d	$f2, $f2, $f6
	sub.d	$f0, $f0, $f2
	sdc1	$f0, dirX
	
	mov.d	$f0, $f8
	ldc1	$f2, dirY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	neg.d	$f6, $f6
	mul.d	$f0, $f0, $f6
	mul.d	$f2, $f2, $f4
	add.d	$f2, $f2, $f0
	sdc1	$f2, dirY
	
	ldc1	$f0, planeX
	ldc1	$f8, planeX
	ldc1	$f2, planeY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	neg.d	$f6, $f6
	mul.d	$f0, $f0, $f4
	mul.d	$f2, $f2, $f6
	sub.d	$f0, $f0, $f2
	sdc1	$f0, planeX
	
	mov.d	$f0, $f8
	ldc1	$f2, planeY
	ldc1	$f4, cos15
	ldc1	$f6, sin15
	neg.d	$f6, $f6
	mul.d	$f0, $f0, $f6
	mul.d	$f2, $f2, $f4
	add.d	$f2, $f2, $f0
	sdc1	$f2, planeY
	j	afterinput
	
	afterinput:
	
	
	# Begin Rendering
	beq	$t8, $zero, skipdraw
	
	li	$s0, SCREEN_HEIGHT
	sra	$s0, $s0, 1
	li	$s1, SCREEN_HEIGHT
	floorloopY:
	li	$t7, 2
	mtc1	$t7, $f0
	mtc1	$s1, $f2
	mtc1	$s0, $f4
	cvt.d.w	$f0, $f0
	cvt.d.w	$f2, $f2
	cvt.d.w	$f4, $f4
	div.d	$f0, $f2, $f0
	sub.d	$f6, $f4, $f0
	cvt.w.d	$f6, $f6
	cvt.d.w	$f6, $f6
	div.d	$f28, $f0, $f6
	li	$a2, CEILINGCOLOR
	mov.d	$f12, $f28
	jal	divide_color
	li	$t3, 0
	li	$t4, SCREEN_WIDTH
	floorloopX:
	move	$a0, $t3
	move	$a1, $s0
	jal	draw_pixel
	move	$a1, $s1
	sub	$a1, $a1, $s0
	subi	$a1, $a1, 1
	jal	draw_pixel
	addi	$t3, $t3, 1
	bne	$t3, $t4, floorloopX
	addi	$s0, $s0, 1
	bne	$s0, $s1, floorloopY
	
	li	$s0, 0
	li	$s1, SCREEN_WIDTH
	
	wallrenderloop:
	# the following dense code section assigns $f2 - $f26.
	# These varibales are to be kept until the end of the wall render loop.
	# $f0 = temporary values
	# $f2 = pixel X coordinate
	# $f4 = Screen width
	# $f6 = X coordinate in camera space
	# $f8 = ray X direction
	# $f10 = ray Y direction
	# $f12 = X position of current box
	# $f14 = Y position of current box
	# $f16 = length of ray from origin to next X side
	# $f18 = length of ray from origin to next Y side
	# $f20 = length of ray from one X side to next X side
	# $f22 = length of ray from one Y side to next Y side
	# $f24 = X step direction
	# $f26 = Y step direction
	# $f28 = perpendicular wall distance
	# $f30 = temporary values
	li	$t2, 2
	mtc1	$t2, $f0
	mtc1	$s0, $f2
	mtc1	$s1, $f4
	cvt.d.w	$f0, $f0
	cvt.d.w	$f2, $f2
	cvt.d.w	$f4, $f4
	mul.d	$f6, $f2, $f0
	div.d	$f6, $f6, $f4
	li	$t2, 1
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	sub.d 	$f6, $f6, $f0
	ldc1	$f0, planeX
	mul.d 	$f8, $f6, $f0
	ldc1	$f0, dirX
	add.d	$f8, $f8, $f0
	ldc1	$f0, planeY
	mul.d	$f10, $f6, $f0
	ldc1	$f0, dirY
	add.d	$f10, $f10, $f0
	ldc1	$f12, posX
	ldc1	$f14, posY
	cvt.w.d	$f12, $f12
	cvt.w.d	$f14, $f14
	cvt.d.w	$f12, $f12
	cvt.d.w	$f14, $f14
	li	$t2, 1
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	div.d 	$f20, $f0, $f8
	abs.d	$f20, $f20
	div.d 	$f22, $f0, $f10
	abs.d	$f22, $f22
	li	$t2, 0
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	c.lt.d	$f8, $f0
	bc1f	else1
	li	$t2, -1
	mtc1	$t2, $f24
	cvt.d.w	$f24, $f24
	ldc1	$f16, posX
	sub.d	$f16, $f16, $f12
	mul.d	$f16, $f16, $f20
	j	endif1
	else1:
	li	$t2, 1
	mtc1	$t2, $f24
	cvt.d.w	$f24, $f24
	ldc1	$f28, posX	#temporary variable
	add.d	$f16, $f12, $f24
	sub.d	$f16, $f16, $f28
	mul.d	$f16, $f16, $f20
	endif1:
	
	c.lt.d	$f10, $f0
	bc1f	else2
	li	$t2, -1
	mtc1	$t2, $f26
	cvt.d.w	$f26, $f26
	ldc1	$f18, posY
	sub.d	$f18, $f18, $f14
	mul.d	$f18, $f18, $f22
	j	endif2
	else2:
	li	$t2, 1
	mtc1	$t2, $f26
	cvt.d.w	$f26, $f26
	ldc1	$f28, posY	#temporary variable
	add.d	$f18, $f14, $f26
	sub.d	$f18, $f18, $f28
	mul.d	$f18, $f18, $f22
	endif2:
	
	DDAloop:
	c.lt.d	$f16, $f18
	bc1f	DDAelse
	add.d	$f16, $f16, $f20
	add.d	$f12, $f12, $f24
	li	$t8, 0	# side flag
	j	DDAendif
	DDAelse:
	add.d	$f18, $f18, $f22
	add.d	$f14, $f14, $f26
	li	$t8, 1 # side flag
	DDAendif:
	
	cvt.w.d	$f12, $f12
	cvt.w.d	$f14, $f14
	mfc1	$t2, $f12	# map X
	mfc1	$t3, $f14	# map Y
	cvt.d.w	$f12, $f12
	cvt.d.w	$f14, $f14
	mul	$t3, $t3, MAP_WIDTH
	add	$t3, $t3, $t2
	# $t3 is now the array position of the byte in the map
	la	$t4, map
	add	$t4, $t4, $t3
	lb	$t2, ($t4)
	# $t2 is now the value of the box at the map position
	bne 	$t2, 1, DDAloop
	
	bne	$t8, $zero, Yside
	# wall distance = (mapY - posY + (1 - stepY) / 2 ) / rayDirY
	# $f28 = Wall distance
	ldc1	$f0, posX
	sub.d	$f28, $f12, $f0
	li	$t7, 1
	mtc1	$t7, $f0
	cvt.d.w	$f0, $f0
	sub.d	$f30, $f0, $f24	#temporary
	li	$t7, 2
	mtc1	$t7, $f0
	cvt.d.w	$f0, $f0
	div.d	$f30, $f30, $f0
	add.d	$f28, $f28, $f30
	div.d	$f28, $f28, $f8
	j	endcalc
	Yside:
	# (mapX - posX + (1 - stepX) / 2 ) / rayDirX
	# $f28 = Wall distance
	ldc1	$f0, posY
	sub.d	$f28, $f14, $f0
	li	$t7, 1
	mtc1	$t7, $f0
	cvt.d.w	$f0, $f0
	sub.d	$f30, $f0, $f26	#temporary
	li	$t7, 2
	mtc1	$t7, $f0
	cvt.d.w	$f0, $f0
	div.d	$f30, $f30, $f0
	add.d	$f28, $f28, $f30
	div.d	$f28, $f28, $f10
	endcalc:
	
	li	$t7, SCREEN_HEIGHT
	mtc1	$t7, $f0
	cvt.d.w	$f0, $f0
	div.d	$f0, $f0, $f28	# line height
	cvt.w.d	$f0, $f0
	mfc1	$t2, $f0
	
	# t3 = draw start
	sub	$t3, $zero, $t2
	li	$t6, 2		# temporary
	div	$t3, $t3, $t6
	div	$t5, $t7, $t6	# temporary
	add	$t3, $t3, $t5
	bge	$t3, $zero, notlbound
	li	$t3, 0
	notlbound:
	# t4 = draw end
	div	$t4, $t2, $t6
	div	$t5, $t7, $t6	# temporary
	add	$t4, $t4, $t5
	blt	$t4, $t7, nottbound
	subi	$t4, $t7, 1
	nottbound:
	
	li	$a2, WALLCOLOR
	beq	$t8, $zero, lighting
	ldc1	$f12, walllight
	jal	divide_color
	lighting:
	mov.d	$f12, $f28
	jal	divide_color
	
	drawloop:
	move	$a0, $s0	# x pixel
	move	$a1, $t3	# y pixel
	jal draw_pixel
	addi	$t3, $t3, 1
	blt	$t3, $t4, drawloop
	
	lw	$t2, ZBuffer
	li	$t3, 8
	mul	$t3, $t3, $s0
	add	$t2, $t2, $t3
	sdc1	$f28, ($t2)
	
	addi	$s0, $s0, 1
	bne 	$s0, $s1, wallrenderloop
	
	# Render portal sprite:
	# $f0 = temporary values
	# $f2 = posX
	# $f4 = posY
	# $f6 = sprite X position
	# $f8 = sprite Y position
	# $f10 = sprite X position relative to camera
	# $f12 = sprite Y position relative to camera
	# $f14 = planeX
	# $f16 = planeY
	# $f18 = dirX
	# $f20 = dirY
	# $f22 = inverse determinate
	# $f24 = transformX
	# $f26 = transformY
	# $f28 = sprite screen X
	# $f30 = temporary values
	ldc1	$f2, posX
	ldc1	$f4, posY
	ldc1	$f6, spriteX
	ldc1	$f8, spriteY
	ldc1	$f14, planeX
	ldc1	$f16, planeY
	ldc1	$f18, dirX
	ldc1	$f20, dirY
	li	$t2, SCREEN_WIDTH
	mtc1	$t2, $f28
	cvt.d.w	$f28, $f28
	
	#sprite positions relative to camera; sprite coordinate - camera position
	sub.d	$f10, $f6, $f2
	sub.d	$f12, $f8, $f4
	
	#inverse camera matrix determinate
	mul.d	$f0, $f14, $f20
	mul.d	$f30, $f16, $f18
	sub.d	$f22, $f0, $f30
	li	$t2, 1
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	div.d	$f22, $f0, $f22
	
	#transformed X calculation
	mul.d	$f0, $f20, $f10
	mul.d	$f30, $f18, $f12
	sub.d	$f24, $f0, $f30
	mul.d	$f24, $f24, $f22
	
	#transformed Y calculation (depth)
	li	$t2, 0
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	sub.d	$f0, $f0, $f16
	mul.d	$f0, $f0, $f10
	mul.d	$f30, $f14, $f12
	add.d	$f26, $f0, $f30
	mul.d	$f26, $f26, $f22
	
	#calculate X value of sprite on screen; stored in $s0
	li	$t2, SCREEN_WIDTH
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	li	$t2, 2
	mtc1	$t2, $f30
	cvt.d.w	$f30, $f30
	div.d	$f0, $f0, $f30
	li	$t2, 1
	mtc1	$t2, $f30
	cvt.d.w	$f30, $f30
	div.d	$f28, $f24, $f26
	add.d	$f28, $f28, $f30
	mul.d	$f28, $f28, $f0
	cvt.w.d	$f28, $f28
	mfc1	$s0, $f28
	
	#calculate height of sprite on screen; stored in $s1
	li	$t2, SCREEN_HEIGHT
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	div.d	$f0, $f0, $f26
	abs.d	$f0, $f0
	cvt.w.d	$f0, $f0
	mfc1	$s1, $f0
	
	#calculate draw vertical start and end; stored in $s2 and $s3
	sub	$s2, $zero, $s1 
	div	$s2, $s2, 2
	li	$t0, SCREEN_HEIGHT
	div	$t1, $t0, 2
	add	$s2, $s2, $t1
	bge	$s2, 0, YstartnotOoB
	li	$s2, 0
	YstartnotOoB:
	div	$s3, $s1, 2
	add	$s3, $s3, $t1
	subi	$t0, $t0, 1
	blt	$s3, $t0, YendnotOoB
	move	$s3, $t0
	YendnotOoB:
	
	#calculate draw horzontal start and end; stored in $s5 and $s6
	sub	$s5, $zero, $s1
	div	$s5, $s5, 2
	add	$s5, $s5, $s0
	bge	$s5, 0, XstartnotOoB
	li	$s5, 0
	XstartnotOoB:
	div	$s6, $s1, 2
	add	$s6, $s6, $s0
	li	$t0, SCREEN_WIDTH
	subi	$t0, $t0, 1
	blt	$s6, $t0, XendnotOoB
	move	$s6, $t0
	XendnotOoB:
	
	#draw portal
	move	$t0, $s5
	drawportal:
	#if vertical is out of bounds, dont draw the vertical
	ble	$t0, $zero, portalverticalnodraw
	bge	$t0, SCREEN_WIDTH, portalverticalnodraw
	#if it is behind the camera plane, dont draw the vertical
	li	$t2, 0
	mtc1	$t2, $f0
	cvt.d.w	$f0, $f0
	c.lt.d	$f0, $f26
	bc1f	portalverticalnodraw
	#if it is not in front of a wall, dont draw the vertical
	lw	$t2, ZBuffer
	mul	$t3, $t0, 8
	add	$t2, $t2, $t3
	ldc1	$f0, ($t2)
	c.lt.d	$f26, $f0
	bc1f	portalverticalnodraw
	# $t2 = texture X coordinate
	li	$t3, 2
	sub	$t2, $zero, $s1
	div	$t2, $t2, $t3
	add	$t2, $t2, $s0
	sub	$t2, $t0, $t2
	mul	$t2, $t2, PORTAL_TEXTURE_SIZE
	div	$t2, $t2, $s1
	move	$t3, $s2
	drawportalvertical:
	# $t4 = texture Y coordinate
	li	$t4, 256
	mul	$t4, $t4, $t3
	li	$t5, 128
	mul	$t5, $t5, SCREEN_HEIGHT
	sub	$t4, $t4, $t5
	li	$t5, 128
	mul	$t5, $t5, $s1
	add	$t4, $t4, $t5
	mul	$t4, $t4, PORTAL_TEXTURE_SIZE
	div	$t4, $t4, $s1
	div	$t4, $t4, 256
	# $t5 = address of texture pixel color
	move	$t5, $t4
	mul	$t5, $t5, PORTAL_TEXTURE_SIZE
	add	$t5, $t5, $t2
	mul	$t5, $t5, 4
	la	$t6, portal
	add	$t5, $t5, $t6
	lw	$a2, ($t5)
	
	beq	$a2, $zero, translucentportalpixel
	move	$a0, $t0
	move	$a1, $t3
	jal	draw_pixel
	translucentportalpixel:
	addi	$t3, $t3, 1
	blt	$t3, $s3, drawportalvertical
	
	portalverticalnodraw:
	addi	$t0, $t0, 1
	blt	$t0, $s6, drawportal
	
	
	# draw_texture call for torch
	li	$a0, 112
	li	$a1, 48
	la	$v0, torch
	li	$a2, 16
	li	$a3, 16
	jal	draw_texture
	
	
	skipdraw:
	li	$t8, 0
	j	gamemainloop

	
gameover:
	#display main menu
	li	$a0, 0
	li	$a1, 0
	la	$v0, exitmenu
	li	$a2, 64
	li	$a3, 128
	jal	draw_texture
	
	gameoverloop:
	lw 	$t0, 0xffff0000		#holds if input available
    	beq 	$t0, 0, gameoverloop	#If no input, keep displaying
	lw 	$s1, 0xffff0004
	beq	$s1, 32, exit		# input space
	j	gameoverloop
	
exit:	li	$v0, 10
	syscall
