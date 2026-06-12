
		bits 16
		org 100h

%define FOOD_RED     9
%define FOOD_GREEN   10
%define FOOD_YELLOW  11
%define FOOD_MAGENTA 12
%define SNAKE_HEAD   13
%define OBSTACLE     178    ; khối gạch chướng ngại vật

section .text
		call hide_cursor
	start:
		call show_title
	.menu:
		call show_menu
		cmp al, 0
		je .play
		cmp al, 1
		je .help
		jmp exit_process
	.play:
		call show_difficulty_menu      ; Gọi Menu chọn cấp độ khó
		mov [game_mode], al            ; Lưu lựa chọn (0 = Easy, 1 = Hard) vào biến
		call start_playing
		call show_game_over
		jmp .menu
	.help:
		call show_help
		jmp .menu

	; in:
	;	si = number of 55.56 ms to wait
	sleep:
			mov ah, 0
			int 1ah
			mov bx, dx
		.wait:
			mov ah, 0
			int 1ah
			sub dx, bx
			cmp dx, si
			jl .wait
			ret

	hide_cursor:
			mov ah, 02h
			mov bh, 0
			mov dh, 25
			mov dl, 0
			int 10h
			ret

	clear_keyboard_buffer:
			mov ah, 1
			int 16h
			jz .end
			mov ah, 0h ; retrieve key from buffer
			int 16h
			jmp clear_keyboard_buffer
		.end:
			ret

	exit_process:
			mov ah, 4ch
			int 21h
			ret

	buffer_clear:
			mov bx, 0
		.next:	
			mov byte [buffer + bx], ' '
			inc bx
			cmp bx, 2000
			jnz .next
			ret
		
	; in:
	;	bl = char
	;	cx = col
	;	dl = row
	buffer_write:
		mov di, buffer
		mov al, 80
		mul dl
		add ax, cx
		add di, ax
		mov byte [di], bl
		ret
	
	; in:
	;	cx = col
	;	dx = row
	; out: 
	;	bl = char
	buffer_read:
		mov di, buffer
		mov al, 80
		mul dl
		add ax, cx
		add di, ax
		mov bl, [di]
		ret
	
	; in:
	;	si = string address
	;	di = buffer destination offset
	buffer_print_string:
		.next:
			mov al, [si]
			cmp al, 0
			jz .end
			mov byte [buffer + di], al
			inc di
			inc si
			jmp .next
		.end:
			ret
		
	;   1 = snake right
	;   2 = snake left
	;   4 = snake down
	;   8 = snake up
	;  13 = snake head
	; > 8 = ASCII char
	buffer_render:
			mov ax, 0b800h
			mov es, ax
			mov di, buffer
			mov si, 0
		.next:
			mov bl, [di]
			mov bh, 7Fh
			cmp bl, SNAKE_HEAD
			jz .is_snake_head
			cmp bl, 8
			jz .is_snake_vertical
			cmp bl, 4
			jz .is_snake_vertical
			cmp bl, 2
			jz .is_snake_horizontal
			cmp bl, 1
			jz .is_snake_horizontal
			cmp bl, FOOD_RED
			jz .is_food_red
			cmp bl, FOOD_GREEN
			jz .is_food_green
			cmp bl, FOOD_YELLOW
			jz .is_food_yellow
			cmp bl, FOOD_MAGENTA
			jz .is_food_magenta
			jmp .write
		.is_snake_head:
			mov bl, 2
			mov bh, 0Bh
			jmp .write
		.is_snake_horizontal:
			mov bl, 205
			mov bh, 09h
			jmp .write
		.is_snake_vertical:
			mov bl, 186
			mov bh, 09h
			jmp .write
		.is_food_red:
			mov bl, 219
			mov bh, 0Ch
			jmp .write
		.is_food_green:
			mov bl, 219
			mov bh, 0Ah
			jmp .write
		.is_food_yellow:
			mov bl, 219
			mov bh, 0Eh
			jmp .write
		.is_food_magenta:
			mov bl, 219
			mov bh, 0Dh
		.write:
			mov byte [es:si], bl
			mov byte [es:si + 1], bh
			inc di
			add si, 2
			cmp si, 4000
			jnz .next
			ret

	show_title:
			call buffer_clear
			call buffer_render
			mov si, 18
			call sleep
			mov si, 0
		.next:
			mov bx, [.title + si]
			mov byte [buffer + bx], 219
			push si
			call buffer_render
			mov si, 1
			call sleep
			pop si
			add si, 2
			cmp si, 274
			jl .next
			mov si, .text_1
			mov di, 1626
			call buffer_print_string
			mov si, .text_2
			mov di, 1781
			call buffer_print_string
			call clear_keyboard_buffer
		.wait_for_key:
			mov si, .text_4
			mov di, 1388
			call buffer_print_string
			call buffer_render
			mov si, 5
			call sleep
			mov ah, 1
			int 16h
			jnz .continue
			mov si, .text_3
			mov di, 1388
			call buffer_print_string
			call buffer_render
			mov si, 10
			call sleep
			mov ah, 1
			int 16h
			jz .wait_for_key
		.continue:
			mov ah, 0
			int 16h
			ret
		.title:
			dw 0342, 0341, 0340, 0339, 0338, 0337, 0336, 0335, 0415, 0495
			dw 0575, 0655, 0656, 0657, 0658, 0659, 0660, 0661, 0662, 0742
			dw 0822, 0902, 0982, 0981, 0980, 0979, 0978, 0977, 0976, 0975
			dw 0985, 0905, 0825, 0745, 0665, 0585, 0505, 0425, 0345, 0426
			dw 0507, 0587, 0668, 0669, 0750, 0830, 0911, 0992, 0912, 0832
			dw 0752, 0672, 0592, 0512, 0432, 0352, 0995, 0915, 0835, 0755
			dw 0675, 0595, 0515, 0435, 0355, 0356, 0357, 0358, 0359, 0360
			dw 0361, 0362, 0442, 0522, 0602, 0682, 0762, 0842, 0922, 1002
			dw 0676, 0677, 0678, 0679, 0680, 0681, 0365, 0445, 0525, 0605
			dw 0685, 0765, 0845, 0925, 1005, 0372, 0451, 0530, 0609, 0608
			dw 0687, 0686, 0768, 0769, 0850, 0931, 1012, 0382, 0381, 0380
			dw 0379, 0378, 0377, 0376, 0375, 0455, 0535, 0615, 0695, 0775
			dw 0855, 0935, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022
			dw 0696, 0697, 0698, 0699, 0700, 0701, 0702
		.text_1:
			db "SNAKE GAME", 0
		.text_2:
			db "WRITTEN IN ASSEMBLY 8086 LANGUAGE :)", 0
		.text_3:
			db " PRESS ANY KEY FOR MENU ", 0
		.text_4:
			db "                      ", 0

	show_menu:
			mov byte [menu_selected], 0
			call clear_keyboard_buffer
		.draw:
			call buffer_clear
			mov si, .title
			mov di, 432
			call buffer_print_string
			mov si, .start_game
			mov di, 753
			call buffer_print_string
			mov si, .how_to_play
			mov di, 913
			call buffer_print_string
			mov si, .exit
			mov di, 1073
			call buffer_print_string
			mov si, .hint
			mov di, 1459
			call buffer_print_string
			mov al, [menu_selected]
			cmp al, 0
			jnz .select_help
			mov byte [buffer + 750], '>'
			jmp .render
		.select_help:
			cmp al, 1
			jnz .select_exit
			mov byte [buffer + 910], '>'
			jmp .render
		.select_exit:
			mov byte [buffer + 1070], '>'
		.render:
			call buffer_render
		.wait_key:
			mov ah, 0
			int 16h
			cmp al, 27 ; ESC
			jz .exit_selected
			cmp al, 13 ; ENTER
			jz .return_selected
			cmp ah, 48h ; up
			jz .up
			cmp ah, 50h ; down
			jz .down
			jmp .wait_key
		.up:
			mov al, [menu_selected]
			cmp al, 0
			jnz .decrease
			mov byte [menu_selected], 2
			jmp .draw
		.decrease:
			dec byte [menu_selected]
			jmp .draw
		.down:
			mov al, [menu_selected]
			cmp al, 2
			jnz .increase
			mov byte [menu_selected], 0
			jmp .draw
		.increase:
			inc byte [menu_selected]
			jmp .draw
		.return_selected:
			mov al, [menu_selected]
			ret
		.exit_selected:
			mov al, 2
			ret
		.title:
			db "SNAKE GAME MENU", 0
		.start_game:
			db "START GAME", 0
		.how_to_play:
			db "HOW TO PLAY", 0
		.exit:
			db "EXIT", 0
		.hint:
			db "UP/DOWN: SELECT  ENTER: OK  ESC: EXIT", 0

	; cấp độ khó
	show_difficulty_menu:
        mov byte [menu_selected], 0
        call clear_keyboard_buffer
    .draw:
        call buffer_clear
        
        mov si, .title
        mov di, 428
        call buffer_print_string
        
        mov si, .easy_mode
        mov di, 765
        call buffer_print_string
        
        mov si, .hard_mode
        mov di, 925
        call buffer_print_string

        mov al, [menu_selected]
        cmp al, 0
        jnz .select_hard
        mov byte [buffer + 760], '>'   ; Đặt con trỏ '>' ở dòng EASY
        jmp .render
    .select_hard:
        mov byte [buffer + 920], '>'   ; Đặt con trỏ '>' ở dòng HARD
    .render:
        call buffer_render
    .wait_key:
        mov ah, 0
        int 16h
        cmp al, 13 ; ENTER
        jz .return_selected
        cmp ah, 48h ; Mũi tên lên
        jz .toggle
        cmp ah, 50h ; Mũi tên xuống
        jz .toggle
        jmp .wait_key
    .toggle:
        xor byte [menu_selected], 1    ; Đổi qua lại giữa 0 và 1
        jmp .draw
    .return_selected:
        mov al, [menu_selected]
        ret
    .title:
        db "SELECT GAME MODE", 0
    .easy_mode:
        db "EASY MODE", 0
    .hard_mode:
        db "HARD MODE", 0

	show_help:
			call buffer_clear
			mov si, .title
			mov di, 429
			call buffer_print_string
			mov si, .line_1
			mov di, 670
			call buffer_print_string
			mov si, .line_2
			mov di, 830
			call buffer_print_string
			mov si, .line_3
			mov di, 990
			call buffer_print_string
			mov si, .line_4
			mov di, 1150
			call buffer_print_string
			mov si, .back
			mov di, 1470
			call buffer_print_string
			call buffer_render
			call clear_keyboard_buffer
			mov ah, 0
			int 16h
			ret
		.title:
			db "SNAKE GAME - HOW TO PLAY", 0
		.line_1:
			db "USE ARROW KEYS TO MOVE THE SNAKE.", 0
		.line_2:
			db "EAT COLOR BLOCKS TO GROW AND SCORE.", 0
		.line_3:
			db "AVOID WALLS AND YOUR OWN BODY.", 0
		.line_4:
			db "PRESS ESC DURING GAME TO QUIT.", 0
		.back:
			db "PRESS ANY KEY TO RETURN", 0

	print_score:
			mov si, .text
			mov di, 0
			call buffer_print_string
			mov ax, [score]
			mov di, 13
		.next_digit:
			xor dx, dx
			mov bx, 10
			div bx
			push ax
			mov al, dl
			add al, 48
			mov byte [buffer + di], al
			pop ax
			dec di
			cmp ax, 0
			jnz .next_digit
			ret
		.text:
			db " SCORE: 000000", 0

	update_snake_direction:
			mov ah, 1
			int 16h
			jz .end
			mov ah, 0h ; retrieve key from buffer
			int 16h
			cmp al, 27 ; ESC
			jz exit_process
			cmp ah, 48h ; up
			jz .up
			cmp ah, 50h ; down
			jz .down
			cmp ah, 4bh; left
			jz .left
			cmp ah, 4dh; right
			jz .right
			jmp update_snake_direction
		.up:
			mov byte [snake_direction], 8
			jmp update_snake_direction
		.down:
			mov byte [snake_direction], 4
			jmp update_snake_direction
		.left:
			mov byte [snake_direction], 2
			jmp update_snake_direction
		.right:
			mov byte [snake_direction], 1
			jmp update_snake_direction
		.end:
			ret
		
	update_snake_head:
			mov al, [snake_head_y]
			mov byte [snake_head_previous_y], al
			mov al, [snake_head_x]
			mov byte [snake_head_previous_x], al
			mov ah, [snake_direction]
			cmp ah, 8 ; up
			jz .up
			cmp ah, 4 ; down
			jz .down
			cmp ah, 2; left
			jz .left
			cmp ah, 1; right
			jz .right
		.up:
			dec word [snake_head_y]
			jmp .end
		.down:
			inc word [snake_head_y]
			jmp .end
		.left:
			dec word [snake_head_x]
			jmp .end
		.right:
			inc word [snake_head_x]
		.end:
			; update previous snake body with direction information
			mov bl, [snake_direction]
			mov ch, 0
			mov cl, [snake_head_previous_x]
			mov dl, [snake_head_previous_y]
			call buffer_write
			ret

	check_snake_new_position:
			mov ch, 0
			mov cl, [snake_head_x]
			mov dh, 0
			mov dl, [snake_head_y]
			call buffer_read
			cmp bl, SNAKE_HEAD
			je .set_game_over
			cmp bl, 8
			jle .set_game_over
			cmp bl, FOOD_RED
			je .food
			cmp bl, FOOD_GREEN
			je .food
			cmp bl, FOOD_YELLOW
			je .food
			cmp bl, FOOD_MAGENTA
			je .food
			cmp bl, ' '
			je .empty_space
		.set_game_over:
			cmp al, 1
			mov byte [is_game_over], al 
		.write_new_head:
			mov bl, SNAKE_HEAD
			mov ch, 0
			mov cl, [snake_head_x]
			mov ch, 0
			mov dl, [snake_head_y]
			call buffer_write
			ret
		.food:
			cmp byte [game_mode], 0    ; Kiểm tra chế độ chơi
            je .easy_score             ; Nếu bằng 0 -> Chạy sang chế độ EASY
			; ---- TÍNH ĐIỂM THEO MÀU CHẾ ĐỘ HARD ----
            cmp bl, FOOD_RED
            je .add_1
            cmp bl, FOOD_GREEN
            je .add_2
            cmp bl, FOOD_YELLOW
            je .add_3
            add dword [score], 5       ; Mặc định màu Tím cộng 5 điểm
            jmp .food_continue
        .add_1:
            add dword [score], 1
            jmp .food_continue
        .add_2:
            add dword [score], 2
            jmp .food_continue
        .add_3:
            add dword [score], 3
            jmp .food_continue

		.easy_score:                   ; ---- TÍNH ĐIỂM THEO CHẾ ĐỘ EASY
			inc dword [score]
			
		.food_continue:
			call .write_new_head
			call create_food
			jmp .end
		.empty_space:
			call update_snake_tail
			call .write_new_head
		.end:
			ret

	update_snake_tail:
			mov al, [snake_tail_y]
			mov byte [snake_tail_previous_y], al
			mov al, [snake_tail_x]
			mov byte [snake_tail_previous_x], al
			mov ch, 0
			mov cl, [snake_tail_x]
			mov dh, 0
			mov dl, [snake_tail_y]
			call buffer_read
			cmp bl, 8 ; up
			jz .up
			cmp bl, 4 ; down
			jz .down
			cmp bl, 2; left
			jz .left
			cmp bl, 1; right
			jz .right
			jmp exit_process
		.up:
			dec word [snake_tail_y]
			jmp .end
		.down:
			inc word [snake_tail_y]
			jmp .end
		.left:
			dec word [snake_tail_x]
			jmp .end
		.right:
			inc word [snake_tail_x]
		.end:
			mov bl, ' '
			mov ch, 0
			mov cl, [snake_tail_previous_x]
			mov ch, 0
			mov dl, [snake_tail_previous_y]
			call buffer_write
		ret

	create_initial_foods:
			mov cx, 10
		.again:
			push cx
			call create_food
			pop cx
			loop .again

	; TODO: needs to fix when there isn't more free position available
	create_food:
		.try_again:
			; ref.: http://webpages.charter.net/danrollins/techhelp/0245.HTM
			mov ah, 0
			int 1ah ; cx = hi dx = low
			mov ax, dx
			and ax, 0fffh
			mul dx
			mov dx, ax
			mov ax, dx
			mov cx, 2000
			xor dx, dx
			div cx ; dx = rest of division
			mov bx, dx
			mov di, buffer
			mov al, [di + bx]
			cmp al, ' ' ; create food just in empty position
			jnz .try_again
			; ---- BẮT ĐẦU ĐOẠN PHÂN LUỒNG CHẾ ĐỘ CHƠI (PHÚC SỬA TẠI ĐÂY) ----
            cmp byte [game_mode], 0
            je .easy_food_distribution   ; Nếu game_mode = 0 (Easy) -> Nhảy xuống xử lý 2 màu

            ; ---- CHẾ ĐỘ HARD (4 MÀU ) ----
            mov ax, dx
			xor dx, dx
            mov cx, 100         ; Chia cho 100 lấy phần dư từ 0 đến 99 để tính tỷ lệ %
            div cx
			
			cmp dx, 60          ; Tỷ lệ 60% đầu tiên (0 - 59) -> Ra màu đỏ
            jl .set_red
            cmp dx, 85          ; Tỷ lệ 25% tiếp theo (60 - 84) -> Ra màu xanh lá
            jl .set_green
            cmp dx, 97          ; Tỷ lệ 12% tiếp theo (85 - 96) -> Ra màu vàng
            jl .set_yellow
                                ; 3% còn lại (97 - 99) -> Ra màu tím (siêu hiếm)
            mov al, FOOD_MAGENTA
            jmp .write_to_buffer

			; ---- CHẾ ĐỘ EASY (2 MÀU) ----
        	.easy_food_distribution:
            mov ax, dx
            xor dx, dx
            mov cx, 2           ; Chỉ chia cho 2 để lấy phần dư là 0 hoặc 1
            div cx              ; dx = 0 hoặc 1 (tỷ lệ chia đôi 50/50)

            cmp dx, 0
            je .set_red         ; Nếu dư 0 -> Gán màu Đỏ
            jmp .set_green      ; Nếu dư 1 -> Gán màu Xanh lá

			; ---- CÁC NHÃN PHỤ TRỢ ĐỂ GÁN GIÁ TRI MÀU ----
			.set_red:
				mov al, FOOD_RED
				jmp .write_to_buffer
			.set_green:
				mov al, FOOD_GREEN
				jmp .write_to_buffer
			.set_yellow:
				mov al, FOOD_YELLOW

			.write_to_buffer:
				mov byte [di + bx], al   ; Ghi giá trị màu đã chọn vào ô nhớ trong buffer
				ret

	reset:
			mov ax, 0
			mov word [score], ax
			mov byte [is_game_over], al
			mov al, 8
			mov byte [snake_direction], al
			mov al, 40
			mov byte [snake_head_x], al
			mov byte [snake_head_previous_x], al
			mov byte [snake_tail_previous_x], al
			mov byte [snake_tail_x], al
			mov al, 15
			mov byte [snake_head_y], al
			mov byte [snake_head_previous_y], al
			mov byte [snake_tail_y], al
			mov byte [snake_tail_previous_y], al
			ret

	start_playing:
			call reset		
			call buffer_clear
			call draw_border
			call create_obstacles ;gọi hàm tạo vật cản
			call create_initial_foods
		.main_loop:
			mov si, 2
			call sleep
		
			call update_snake_direction
			call update_snake_head
			call check_snake_new_position
			call print_score
			call buffer_render
		
			mov al, [is_game_over]
			cmp al, 0
			jz .main_loop
			ret
	; Tạo chướng ngại vật
    create_obstacles:
            cmp byte [game_mode], 1     ; Kiểm tra nếu không phải HARD MODE (1) thì bỏ qua
            jne .end

            mov bl, OBSTACLE            ; Lấy ký tự vật cản gán vào bl

            ; --- Khối vật cản 1 (Thanh ngang phía trên bên trái - Dài 6 ô) ---
            mov dl, 7                   ; Dòng 7
            mov cx, 18                  ; Bắt đầu từ cột 18
            call buffer_write
            mov cx, 19
            call buffer_write
            mov cx, 20
            call buffer_write
            mov cx, 21
            call buffer_write
            mov cx, 22
            call buffer_write
            mov cx, 23                  ; Kết thúc ở cột 23
            call buffer_write

            ; --- Khối vật cản 2 (Thanh ngang phía trên bên phải - Dài 6 ô) ---
            mov dl, 7                   ; Dòng 7
            mov cx, 57                  ; Bắt đầu từ cột 57
            call buffer_write
            mov cx, 58
            call buffer_write
            mov cx, 59
            call buffer_write
            mov cx, 60
            call buffer_write
            mov cx, 61
            call buffer_write
            mov cx, 62                  ; Kết thúc ở cột 62
            call buffer_write

            ; --- Khối vật cản 3 (Thanh ngang phía dưới bên trái - Dài 6 ô) ---
            mov dl, 18                  ; Dòng 18
            mov cx, 18                  ; Bắt đầu từ cột 18
            call buffer_write
            mov cx, 19
            call buffer_write
            mov cx, 20
            call buffer_write
            mov cx, 21
            call buffer_write
            mov cx, 22
            call buffer_write
            mov cx, 23                  ; Kết thúc ở cột 23
            call buffer_write

            ; --- Khối vật cản 4 (Thanh ngang phía dưới bên phải - Dài 6 ô) ---
            mov dl, 18                  ; Dòng 18
            mov cx, 57                  ; Bắt đầu từ cột 57
            call buffer_write
            mov cx, 58
            call buffer_write
            mov cx, 59
            call buffer_write
            mov cx, 60
            call buffer_write
            mov cx, 61
            call buffer_write
            mov cx, 62                  ; Kết thúc ở cột 62
            call buffer_write
        .end:
            ret

	draw_border:
			mov di, 0
		.next_x:
			mov byte [buffer + di], 255
			mov byte [buffer + 80 + di], 196
			mov byte [buffer + 1920 + di], 196
			inc di
			cmp di, 80
			jnz .next_x
			mov di, 0
		.next_y:
			mov byte [buffer + 80 + di], 179
			mov byte [buffer + 159 + di], 179
			add di,80
			cmp di, 2000
			jnz .next_y
		.corners:
			mov byte [buffer + 80], 218
			mov byte [buffer + 159], 191
			mov byte [buffer + 1920], 192
			mov byte [buffer + 1999], 217
			ret
		
	show_game_over:
			mov si, .text_1
			mov di, 880 + 32
			call buffer_print_string
			mov si, .text_2
			mov di, 960 + 32
			call buffer_print_string
			mov si, .text_1
			mov di, 1040 + 32
			call buffer_print_string
			call buffer_render
			mov si, 48
			call sleep
			call clear_keyboard_buffer
			mov ah, 0
			int 16h
			ret
		.text_1:
			db "               ", 0
		.text_2:
			db "   GAME OVER   ", 0

section .bss
		score resw 1
		is_game_over resb 1
		menu_selected resb 1
		game_mode resb 1  ; 0 là easy, 1 là hard

		; 8 = up
		; 4 = down
		; 2 = left
		; 1 = right
		snake_direction resb 1

		snake_head_x resb 1
		snake_head_y resb 1
		snake_head_previous_x resb 1
		snake_head_previous_y resb 1
		snake_tail_x resb 1
		snake_tail_y resb 1
		snake_tail_previous_x resb 1
		snake_tail_previous_y resb 1

		buffer resb 2000

