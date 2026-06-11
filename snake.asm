; snake game
; assembly 8086
; written by Leonardo Ono (ono.leo@gmail.com)
;
; target OS: DOS (.COM file extension)
; use: nasm snake.asm -o snake.com -f bin

; NOTE
; Hàng số 0 chiếm 80 ô nhớ đầu tiên (từ ô 0 đến ô 79).
; Hàng số 1 chiếm 80 ô nhớ tiếp theo (từ ô 80 đến ô 159).
; Hàng số 2 chiếm 80 ô nhớ tiếp nữa (từ ô 160 đến ô 239).
;... Cứ thế xếp nối đuôi nhau cho đến hết hàng số 24.

; Hàng (Y) = Vị trí / 80 (lấy phần nguyên)
; Cột (X) = Vị trí mod 80 (lấy phần dư)
; Vị trí = (Y × 80) + X

		bits 16
		org 100h

section .text
        call hide_cursor
	start:
            call show_title
            call start_playing
            call show_game_over
            jmp start

	sleep:
            mov ah, 0
            int 1ah ; dx = current time in ticks (1 tick = 1/18.2 second) vây 18.2 tick sẽ bằng 1 giây.
            mov bx, dx ; lưu thời điểm bắt đầu vào bx
        .wait:
            mov ah, 0 
            int 1ah
            sub dx, bx ; tính thời gian đã trôi qua
            cmp dx, si ; so sánh với thời gian mong muốn (được truyền vào si)
            jl .wait ; nếu thời gian chưa đủ thì tiếp tục chờ
            ret

	hide_cursor: ; trick ẩn con trỏ chuột
            mov ah, 02h ; Trong ngắt INT 10h, hàm 02h là hàm dùng để Đặt vị trí con trỏ (Set Cursor Position).
            mov bh, 0 ; Page number (trang hiển thị, thường là 0)
            mov dh, 25 ; Row (hàng) - đặt con trỏ ở hàng 25. Màn hình DOS tiêu chuẩn có kích thước 80 cột $\times$ 25 hàng
            mov dl, 0 ; Column (cột) - đặt con trỏ ở cột 0 (bên trái màn hình)
            int 10h 
            ret

	clear_keyboard_buffer:
			mov ah, 1 ; 1 kiểm tra xem có phím nào đã được nhấn không 
			int 16h ; zf = 1 nếu chưa có phím nào được nhấn, nếu zf = 0 thì có phím đã được nhấn
			jz .end
			mov ah, 0h ; 0 Lấy phím từ bộ đệm bàn phím nếu có người nhấn phím
			int 16h ; INT 16h dùng để Lấy phím từ bộ đệm bàn phím (Get Keystroke).
			jmp clear_keyboard_buffer
		.end:
			ret

	exit_process:
			mov ah, 4ch ; hàm 4Ch của INT 21h dùng để kết thúc chương trình
			int 21h ; gọi ngắt 21h để thực hiện hàm kết thúc chương trình

	buffer_clear: ; Lấp đầy 2000 ô nhớ của biến buffer bằng các ký tự khoảng trắng
			mov bx, 0
		.next:	
			mov byte [buffer + bx], ' '
			inc bx
			cmp bx, 2000
			jnz .next
			ret
		
	buffer_write: ; cl = X, dl = Y, bl = giá trị cần gán vào ô nhớ tương ứng với vị trí (X, Y)
            mov di, buffer ; gán địa chỉ ô nhớ đầu tiên của buffer vào di
            ; Vị trí = (Y × 80) + X = (dl × 80) + cl
            mov al, 80
            mul dl
            add ax, cx
            add di, ax ; di = di + (dl × 80) + cl, di sẽ trỏ đến ô nhớ tương ứng với vị trí (X, Y) trên màn hình
            mov byte [di], bl ; cập nhật giá trị tại địa chỉ di
            ret
	
	buffer_read: ; cl = X, dl = Y
            mov di, buffer ; lấy địa chỉ ô đầu tiên của buffer
            ; Vị trí = (Y × 80) + X
            mov al, 80
            mul dl
            add ax, cx
            add di, ax
            mov bl, [di] ; nạp giá trị tại vị trí (X, Y) vào bl 
            ret
	
	buffer_print_string:
		.next:
			mov al, [si] ; lấy ký tự từ chuỗi tại vị trí si
			cmp al, 0 ; nếu là ký tự null (kết thúc chuỗi) thì dừng lại
			jz .end 
			mov byte [buffer + di], al ; ghi ký tự vào buffer tại vị trí di
			inc di ; di tăng lên 1 để chuyển sang vị trí tiếp theo trong buffer
			inc si ; si tăng lên 1 để chuyển sang ký tự tiếp theo trong chuỗi
			jmp .next 
		.end:
			ret
		
	buffer_render:
			mov ax, 0b800h ; giá trị điều khiển toàn bộ màn hình văn bản
			mov es, ax ; es không tự nạp được giá trị phải trung gian ax
			mov di, buffer
			mov si, 0
		.next:
			mov bl, [di] ; nạp giá trị tại vị trí di vào bl để kiểm tra xem đó là ký tự gì
			cmp bl, 8 ; nếu bl = 8 thì có nghĩa là vị trí đó đang chứa phần thân rắn, sẽ được hiển thị bằng ký tự 219
			jz .is_snake
			cmp bl, 4 ; nếu bl = 4 thì có nghĩa là vị trí đó đang chứa phần thân rắn, sẽ được hiển thị bằng ký tự 219
			jz .is_snake 
			cmp bl, 2 ; nếu bl = 2 thì có nghĩa là vị trí đó đang chứa phần thân rắn, sẽ được hiển thị bằng ký tự 219
			jz .is_snake
			cmp bl, 1 ; nếu bl = 1 thì có nghĩa là vị trí đó đang chứa phần thân rắn, sẽ được hiển thị bằng ký tự 219
			jz .is_snake
			jmp .write
		.is_snake:
			mov bl, 219
		.write:
            ; 2 byte cho 1 ô, byte đầu tiên là ký tự, byte thứ 2 là màu sắc
			mov byte [es:si], bl ; ký tự cần hiển thị
			mov byte [es:si + 1], 1Fh ; màu trắng trên nền xanh dương (màu của kí tự bl)
			inc di ; tăng lên 1 để duyệt sang ô tiếp theo của buffer
			add si, 2 ; tăng lên 2 vì mỗi ô chiếm 2 byte
			cmp si, 4000 ; 2000 ô × 2 byte mỗi ô = 4000 byte
			jnz .next
			ret

	show_title:
			call buffer_clear
			call buffer_render
			mov si, 18 ; đợi 18 tick (khoảng 1 giây)
			call sleep
			mov si, 0 ; reset si
		.next:
			mov bx, [.title + si] ; nếu si = 0 thì [.title + si] = 0342
			mov byte [buffer + bx], 219 ; 219 asscii code
			push si ; lưu lại giá trị si hiện tại để sau này còn so sánh với 274
			call buffer_render ; render lại màn hình để hiển thị từng ký tự của title
			mov si, 1 ; đợi 1 tick (khoảng 1/18.2 giây)
			call sleep
			pop si ; lấy lại giá trị si đã lưu trước đó
			add si, 2 ; tăng si lên 2 để lấy ký tự tiếp theo của title (1 lần 2 byte vì mỗi ký tự chiếm 2 byte trong title)
			cmp si, 274 ; 274 chính là tổng số bytes của mảng dữ liệu .title dùng để vẽ chữ "SNAKE".
			jl .next
			mov si, .text_1 ; gán địa chỉ của chuỗi "DEVELOPED BY O.L. (C) 2017" vào si
			mov di, 1626 ; gán vị trí 1626 vào di, vị trí này tương ứng với cột 26 hàng 20 trên màn hình (26 + 80*20 = 1626)
			call buffer_print_string
			mov si, .text_2 ; cũng như .text_1 nhưng là chuỗi "WRITTEN IN ASSEMBLY 8086 LANGUAGE :)"
			mov di, 1781 ; vị trí này tương ứng với cột 21 hàng 22 trên màn hình (21 + 80*22 = 1781)
			call buffer_print_string
			call clear_keyboard_buffer ; xóa bộ đệm bàn phím để tránh việc người dùng đã nhấn phím trước đó
		.wait_for_key:
			mov si, .text_4 ; cũng tương tự như .text_1 và .text_2 nhưng là chuỗi trắng tạo hiệu ứng nhấp nháy cho dòng "PRESS ANY KEY TO START"
			mov di, 1388 ; vị trí này tương ứng với cột 28 hàng 17 trên màn hình (28 + 80*17 = 1388)
			call buffer_print_string ;
			call buffer_render
			mov si, 5 ; đợi 5 tick (khoảng 0.27 giây)
			call sleep 
			mov ah, 1 ; kiểm tra xem có phím nào đã được nhấn không 
			int 16h ; INT 16h dùng để Kiểm tra trạng thái bộ đệm bàn phím (Keystroke Status).
			jnz .continue ; nếu có phím đã được nhấn thì nhảy đến .continue để bắt đầu trò chơi
			mov si, .text_3 ; gán địa chỉ của chuỗi "PRESS ANY KEY TO START" vào si
			mov di, 1388 ; vị trí này tương ứng với cột 28 hàng 17 trên màn hình (28 + 80*17 = 1388)
			call buffer_print_string ; in ra dòng "PRESS ANY KEY TO START"
			call buffer_render ; render lại màn hình để hiển thị dòng "PRESS ANY KEY TO START"
			mov si, 10 ; đợi 10 tick (khoảng 0.55 giây)
			call sleep
			mov ah, 1 ; kiểm tra xem có phím nào đã được nhấn không
			int 16h 
			jz .wait_for_key ; nếu chưa có phím nào được nhấn thì quay lại .wait_for_key để tiếp tục hiển thị dòng "PRESS ANY KEY TO START" với hiệu ứng nhấp nháy
		.continue:
			mov ah, 0 ; Lấy phím từ bộ đệm bàn phím nếu có người nhấn phím
			int 16h ; Lấy phím đã nhấn và xóa nó khỏi bộ đệm bàn phím, tránh việc phím đó ảnh hưởng đến trò chơi sau này
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
			db "DEVELOPED BY O.L. (C) 2017", 0
		.text_2:
			db "WRITTEN IN ASSEMBLY 8086 LANGUAGE :)", 0
		.text_3:
			db "PRESS ANY KEY TO START", 0
		.text_4:
			db "                      ", 0

	print_score:
			mov si, .text ; gán địa chỉ của chuỗi " SCORE: 000000" vào si
			mov di, 0 ; gán vị trí 0 vào di, vị trí này tương ứng với cột 0 hàng
			call buffer_print_string ; in ra dòng " SCORE: 000000" ở góc trên bên trái màn hình
			mov ax, [score] ; lấy điểm số hiện tại vào ax
			mov di, 13 ; gán vị trí 13 vào di, vị trí này tương ứng với cột 13 hàng 0
		.next_digit: ; vòng lặp in từng kí tự số của điểm số, in từ phải sang trái
			xor dx, dx ; xóa dx để chuẩn bị cho phép chia, vì lệnh div sẽ chia ax cho giá trị trong bx và lưu phần dư vào dx
			mov bx, 10 ; chia ax cho 10 để lấy chữ số cuối cùng của điểm số
			div bx ; ax = ax / 10, dx = ax % 10 = chữ số cuối cùng của điểm số
			push ax ; lưu lại ax để sau này còn lấy chữ số tiếp theo
			mov al, dl ; lưu trong dx số nhỏ [0-255] nên dl = dx
			add al, 48 ; chuyển số thành ký tự ASCII (0-9 tương ứng với 48-57 trong bảng ASCII)
			mov byte [buffer + di], al ; ghi ký tự số vào buffer tại vị trí di
			pop ax ; lấy lại ax để tiếp tục lấy chữ số tiếp theo
			dec di ; di giảm đi 1 để chuyển sang vị trí trước đó trong chuỗi điểm số
			cmp ax, 0
			jnz .next_digit
			ret
		.text:
			db " SCORE: 000000", 0

	update_snake_direction:
			mov ah, 1 ; kiểm tra xem có phím nào đã được nhấn không
			int 16h ; zf = 1 nếu chưa có phím nào được nhấn, nếu zf = 0 thì có phím đã được nhấn
			jz .end
			mov ah, 0h ; lấy phím từ bộ đệm bàn phím nếu có người nhấn phím
			int 16h ; ax sẽ chứa mã phím đã được nhấn, trong đó ah là mã phím mở rộng (extended key code) và al là mã ASCII của phím đó
			cmp al, 27 ; nếu phím ESC được nhấn thì thoát trò chơi
			jz exit_process 
			cmp ah, 48h ; nếu phím mũi tên lên được nhấn thì ah sẽ bằng 48h
			jz .up
			cmp ah, 50h ; nếu phím mũi tên xuống được nhấn thì ah sẽ bằng 50h
			jz .down
			cmp ah, 4bh ; nếu phím mũi tên trái được nhấn thì ah sẽ bằng 4bh
			jz .left
			cmp ah, 4dh ; nếu phím mũi tên phải được nhấn thì ah sẽ bằng 4dh
			jz .right
			jmp update_snake_direction

        ; 8 = Up, 4 = Down, 2 = Left, 1 = Right
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
			mov al, [snake_head_y] ; lấy vị trí y hiện tại của đầu rắn vào al
			mov byte [snake_head_previous_y], al ; cập nhật vị trí y trước đó của đầu rắn bằng giá trị hiện tại
			mov al, [snake_head_x] ; lấy vị trí x hiện tại của đầu rắn vào al
			mov byte [snake_head_previous_x], al ; cập nhật vị trí x trước đó của đầu rắn bằng giá trị hiện tại
			mov ah, [snake_direction] ; lấy hướng di chuyển hiện tại của rắn vào ah
			cmp ah, 8 ; nếu hướng là lên thì ah sẽ bằng 8
			jz .up
			cmp ah, 4 ; nếu hướng là xuống thì ah sẽ bằng 4
			jz .down 
			cmp ah, 2 ; nếu hướng là trái thì ah sẽ bằng 2
			jz .left
			cmp ah, 1 ; nếu hướng là phải thì ah sẽ bằng 1
			jz .right
		.up:
			dec word [snake_head_y] ; di chuyển đầu rắn lên bằng cách giảm giá trị y đi 1
			jmp .end
		.down:
			inc word [snake_head_y] ; di chuyển đầu rắn xuống bằng cách tăng giá trị y lên 1
			jmp .end
		.left:
			dec word [snake_head_x] ; di chuyển đầu rắn sang trái bằng cách giảm giá trị x đi 1
			jmp .end
		.right:
			inc word [snake_head_x] ; di chuyển đầu rắn sang phải bằng cách tăng giá trị x lên 1
		.end:
			mov bl, [snake_direction] ; nạp hướng di chuyển của rắn vào bl
			mov cl, [snake_head_previous_x] ; nạp vị trí x trước đó của đầu rắn vào cl
			mov dl, [snake_head_previous_y] ; nạp vị trí y trước đó của đầu rắn vào dl
			call buffer_write
			ret

	check_snake_new_position:
			mov cl, [snake_head_x] ; lưu giá trị x mới của đầu rắn vào cl
			mov dh, 0
			mov dl, [snake_head_y] ; lưu giá trị y mới của đầu rắn vào dl
			call buffer_read
			cmp bl, 8
			jle .set_game_over ; nếu bl <= 8 thì có nghĩa là vị trí thân rắn [1, 2, 4, 8]
			cmp bl, '*'
			je .food ; nếu bl = '*' thì có nghĩa là vị trí mới của đầu rắn đang đâm vào thức ăn
			cmp bl, ' '
			je .empty_space ; nếu bl = ' ' thì có nghĩa là vị trí mới của đầu rắn đang đâm vào khoảng trống, tức là di chuyển bình thường
            ; nếu cả 3 điều kiện trên đều không thỏa mãn thì có nghĩa là vị trí mới của đầu rắn đang đâm vào viền
		.set_game_over:
			cmp al, 1
			mov byte [is_game_over], al ; đặt cờ game over thành 1 để báo hiệu trò chơi đã kết thúc
		.write_new_head:
			mov bl, 1
			mov cl, [snake_head_x]
			mov dl, [snake_head_y]
			call buffer_write ; cập nhật vị trí mới của đầu rắn vào buffer để tí dùng buffer_render
			ret
		.food:
			inc dword [score] ; tăng điểm số lên 1 khi rắn ăn được thức ăn
			call .write_new_head
			call create_food
			jmp .end
		.empty_space:
			call update_snake_tail
			call .write_new_head
		.end:
			ret

	update_snake_tail:
			mov al, [snake_tail_y] ; lấy vị trí y hiện tại của đuôi rắn vào al
			mov byte [snake_tail_previous_y], al ; cập nhật vị trí y trước đó của đuôi rắn bằng giá trị hiện tại
			mov al, [snake_tail_x] ; lấy vị trí x hiện tại của đuôi rắn vào al
			mov byte [snake_tail_previous_x], al ; cập nhật vị trí x trước đó của đuôi rắn bằng giá trị hiện tại
			mov ch, 0
			mov cl, [snake_tail_x]
			mov dh, 0
			mov dl, [snake_tail_y]
			call buffer_read ; bl sẽ chứa giá trị tại vị trí hiện tại của đuôi rắn
			cmp bl, 8 ; nếu bl = 8 thì có nghĩa là đuôi rắn đang ở vị trí của đầu rắn
			jz .up 
			cmp bl, 4
			jz .down
			cmp bl, 2
			jz .left
			cmp bl, 1
			jz .right
			jmp exit_process
		.up:
			dec word [snake_tail_y] ; di chuyển đuôi rắn lên bằng cách giảm giá trị y đi 1
			jmp .end
		.down:
			inc word [snake_tail_y] ; di chuyển đuôi rắn xuống bằng cách tăng giá trị y lên 1
			jmp .end
		.left:
			dec word [snake_tail_x] ; di chuyển đuôi rắn sang trái bằng cách giảm giá trị x đi 1
			jmp .end
		.right:
			inc word [snake_tail_x] ; di chuyển đuôi rắn sang phải bằng cách tăng giá trị x lên 1
		.end:
			mov bl, ' ' ; khoảng trống sẽ được ghi vào vị trí cũ của đuôi rắn để xóa phần đuôi rắn đã di chuyển đi
			mov cl, [snake_tail_previous_x]
			mov dl, [snake_tail_previous_y]
			call buffer_write
		ret

	create_initial_foods: ; tạo 10 thức ăn ban đầu cho rắn, mỗi thức ăn sẽ được tạo ở một vị trí ngẫu nhiên
			mov cx, 10 ; số lượng thức ăn cần tạo
		.again:
			push cx ; lưu lại giá trị cx hiện tại
			call create_food
			pop cx ; lấy lại giá trị cx để tiếp tục tạo thức ăn cho đến khi đủ 10 cái
			loop .again ; mỗi lần chạy cx - 1, cx = 0 dừng
            ret

	create_food:
		.try_again:
			mov ah, 0 ; lấy thời gian hiện tại vào dx để tạo số ngẫu nhiên
			int 1ah ; trả về ticks lưu vào dx, max ticks là 1573040 tương đương 24h (24h * 60p * 60s * 18.2 tick/s = 1573040 tick)
            ; dx = ticks mod 2^16
            ; cx = ticks / 2^16

			mov ax, dx ; lưu thời gian hiện tại vào ax để tạo số ngẫu nhiên
			and ax, 0fffh ; đưa 4 byte cuối của ax về 0 để chỉ lấy 12 bit cuối của ax
            ; ax      [X X X X] [X X X X  X X X X  X X X X]
            ; 0fffh   [0 0 0 0] [1 1 1 1  1 1 1 1  1 1 1 1]

			mul dx 
            ; max(ax) = 2^12 và max(dx) = 2^16 nên max(ax * dx) = 2^28
            ; ax = ax * dx, kết quả có thể lên đến 28 bit nhưng nhưng chỉ lấy 16 bit thấp nhất của ax để tạo số ngẫu nhiên
			
            mov cx, 2000 ; số lượng ô nhớ trong buffer, tương đương với số ô trên
			xor dx, dx
			div cx ; ax = ax / 2000, dx = ax % 2000, kết quả trong dx sẽ là một số ngẫu nhiên từ 0 đến 1999 tương ứng với một vị trí ngẫu nhiên trên
			mov bx, dx ; lưu vị trí ngẫu nhiên vào bx để sau này kiểm tra xem vị trí đó có phải là khoảng trống hay không
			mov di, buffer ; gán địa chỉ ô đầu tiên của buffer
			mov al, [di + bx] ; địa chỉ của ô ngẫu nhiên trong buffer
			cmp al, ' ' ; kiểm tra xem ô đó có phải là khoảng trống hay không
			jnz .try_again ; nếu không phải là khoảng trống thì thử tạo số ngẫu nhiên khác để tìm vị trí khác
			mov byte [di + bx], '*' ; nếu là khoảng trống thì đặt thức ăn (ký tự '*') vào vị trí đó làm thức ăn cho rắn
			ret

	reset:
			mov ax, 0
			mov word [score], ax ; reset điểm số về 0
			mov byte [is_game_over], al ; reset cờ game over về 0 (chưa kết thúc)
			mov al, 8 ; mặc định hướng ban đầu của rắn là lên
			mov byte [snake_direction], al ; 8 = Up, 4 = Down, 2 = Left, 1 = Right, 0 = None

            ; mặc định vị trí ban đầu của rắn là ở giữa màn hình, cột 40 hàng 15
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

    ; lúc này màn hình hiển thị title, người chơi nhấn phím bất kỳ để bắt đầu trò chơi
    ; khi vào hàm start_playing thì sẽ thiết lập (viền) và (thức ăn)
    ; khi vào main_loop thiếp (rắn) và (điểm số) sẽ được hiển thị lên màn hình khi call buffer_render
    ; loop main_loop sẽ tiếp tục in (rắn) và (điểm số) cho đến khi game over 
	start_playing:
			call reset		
			call buffer_clear
			call draw_border
			call create_initial_foods
		.main_loop:
            mov ax, [score] ; Bốc điểm số hiện tại vào AX
            cmp ax, 10 ; Nếu điểm < 10: Rắn bò tốc độ bình thường
            jl .speed_normal
            cmp ax, 20 ; Nếu điểm từ 10 đến 19: Rắn bò tốc độ nhanh
            jl .speed_fast
            mov si, 1 ; Nếu điểm >= 20: Ép tốc độ cao (1 tick (~0.055 giây))
            jmp .start_sleep

        .speed_normal:
            mov si, 3 ; 3 tick (~0.16 giây)
            jmp .start_sleep
        .speed_fast:
            mov si, 2 ; 2 tick (~0.11 giây)
        .start_sleep:
            call sleep
            call update_snake_direction
            call update_snake_head
            call check_snake_new_position
            call print_score
            call buffer_render
            mov al, [is_game_over]
            cmp al, 0 ; nếu is_game_over = 0 thì trò chơi vẫn tiếp tục, nếu is_game_over = 1 thì kết thúc start_playing
            jz .main_loop
            ret

	draw_border:
			mov di, 0
		.next_x: ; in hàng 0, 1, 24
			mov byte [buffer + di], 255 ; in hàng 0, cột di
			mov byte [buffer + 80 + di], 196 ; in hàng 1, cột di
			mov byte [buffer + 1920 + di], 196 ; in hàng 24, cột di 
			inc di ; di tăng lên 1 để chuyển sang cột tiếp theo
			cmp di, 80 ; kiểm tra xem in đủ 80 cột chưa
			jnz .next_x
			mov di, 0
		.next_y: ; in cột 0, 79
			mov byte [buffer + 80 + di], 179 ; in cột 0, hàng di
			mov byte [buffer + 159 + di], 179 ; in cột 79, hàng di
			add di, 80 ; di tăng lên 80 để chuyển sang hàng tiếp theo
			cmp di, 2000 ; kiểm tra xem in đủ 25 hàng chưa (25 hàng × 80 cột = 2000 ô)
			jnz .next_y
		.corners:
			mov byte [buffer + 80], 218 ; góc trên bên trái, hàng 1 cột 0
			mov byte [buffer + 159], 191 ; góc trên bên phải, hàng 1 cột 79
			mov byte [buffer + 1920], 192 ; góc dưới bên trái, hàng 24 cột 0
			mov byte [buffer + 1999], 217 ; góc dưới bên phải, hàng 24 cột 79
			ret
		
	show_game_over:
			mov si, .text_1 ; gán địa chỉ của chuỗi "               " vào si để tạo hiệu ứng nhấp nháy cho dòng "GAME OVER"
			mov di, 880 + 32 ; vị trí này tương ứng với cột 0 hàng 11
			call buffer_print_string
			mov si, .text_2
			mov di, 960 + 32 ; vị trí này tương ứng với cột 0 hàng 12
			call buffer_print_string
			mov si, .text_1
			mov di, 1040 + 32 ; vị trí này tương ứng với cột 0 hàng 13
			call buffer_print_string
			call buffer_render
			mov si, 48 ; đợi 48 tick (khoảng 2.6 giây) để người chơi có thời gian nhìn
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

		snake_direction resb 1 ; 8 = Up, 4 = Down, 2 = Left, 1 = Right

		snake_head_x resb 1
		snake_head_y resb 1
		snake_head_previous_x resb 1
		snake_head_previous_y resb 1
		snake_tail_x resb 1
		snake_tail_y resb 1
		snake_tail_previous_x resb 1
		snake_tail_previous_y resb 1

		buffer resb 2000 ; 80 cột × 25 hàng = 2000 ô
