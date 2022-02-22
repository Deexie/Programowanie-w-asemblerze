        default rel
        global start, place, step

        section .bss
states      resq 1
difference  resq 1
fixed_temp  resq 1

width       resd 1
height      resd 1

factor      resd 1

        section .text

;;; Sets temperature of a given cell. That temperature will not be change during simulation.
;;; Assumes that r10 contains pointer to states array, r8 - to fixed_temp array,
;;; rdx - index of cell where temperature should be fixed and xmm0 - that temperature.
;;; Modifies rax register.
%macro set_fixed 0
        lea     rax, [r10 + 4 * rdx]    ; rdx-th cell of states.
        movss   [rax], xmm0             ; Sets temperature.
        lea     rax, [r8 + 4 * rdx]     ; rdx-th cell of fixed_temp.
        mov     dword [rax], 1          ; Temperature of this cell is fixed.
%endmacro

;;; Initiates simulation and sets coolers in the outer cells.
;;; Modifies rax, rcx, rdx, r8, r9, r10, r11 registers.
start:
        mov     dword [width], edi
        mov     dword [height], esi
        mov     r10, [rdx]              ; Gets the first matrix pointer.

        mov     r11d, edi
        imul    r11, rsi                ; Stores size of matrix.
        mov     qword [states], r10
        mov     rax, 8
        mov     r9, [rdx + rax]
        mov     qword [difference], r9
        mov     r8, [rdx + 2 * rax]
        mov     qword [fixed_temp], r8
        movss   [factor], xmm1

;;; Sets coolers in the first and the last row of the matrix.
        sub     r11, rdi                ; Gets index of the first element of the last row of matrix.
        mov     rcx, rdi
l1:
        mov     rdx, rcx
        dec     rdx
        set_fixed

        add     rdx, r11                ; Gets the corresponding index of the cell in the last row.
        set_fixed
        loop    l1

;;; Sets coolers in the first and the last column of the matrix.
        mov     ecx, esi
        dec     ecx                     ; First row is already set.
l2:
        mov     edx, ecx
        imul    edx, edi                ; First element of rdx-th row.
        set_fixed

        add     edx, edi
        dec     edx                     ; Last element of rdx-th row.
        set_fixed
        loop    l2
        ret

;;; Sets heaters of the given temperature in the given cells.
;;; Modifies rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11 registers and xmm0.
place:
        test    rdi, rdi
        jz      place_ret               ; Return if there is no heaters.

        mov     r11, rcx                ; Stores temp in r11.
        mov     r9, rdx                 ; Stores y in r9.
        mov     rcx, rdi
l3:
        dec     rcx                     ; Gets actual index.
        mov     r10, [states]
        mov     r8, [fixed_temp]
        lea     rax, [r11 + 4 * rcx]
        movss   xmm0, [rax]             ; Stores temp[rcx].
        lea     rax, [rsi + 4 * rcx]
        mov     edx, [rax]              ; Stores x[rcx].
        lea     rax, [r9 + 4 * rcx]
        mov     edi, [rax]              ; Stores y[rcx].
        imul    edx, [width]
        add     edx, edi                ; Sets index of a matrix.
        set_fixed
        inc     rcx
        loop    l3

place_ret:
        ret

;;; Makes one step of a simulation.
;;; Modifies rax, rcx, rdx, rdi, rsi, r8, r9, r10, r11 and xmm0, xmm1, xmm2, xmm3, xmm4.
step:
        mov     ecx, [width]            ; First row does not need to change.
        mov     r10, [states]
        mov     r9, [difference]
        mov     r8, [fixed_temp]
        mov     r11d, [height]
        dec     r11d
        imul    r11, rcx                ; Loop should stop when this value is reached.

;;; Finds the difference of temperature for the matrix.
;;; Processes 4 values at once.
l4:
        mov     rdx, rcx                ; Starts from the first cell in second row.
        lea     rax, [r10 + 4 * rdx]
        movups  xmm0, [rax]             ; Current cells temperature.

        inc     rdx
        lea     rax, [r10 + 4 * rdx]
        movups  xmm1, [rax]             ; Cells to the right.

        dec     rdx
        sub     edx, [width]
        lea     rax, [r10 + 4 * rdx]
        movups  xmm2, [rax]             ; Cells above.

        add     edx, [width]
        add     edx, [width]
        lea     rax, [r10 + 4 * rdx]
        movups  xmm3, [rax]             ; Cells below.

        sub     edx, [width]
        dec     rdx
        lea     rax, [r10 + 4 * rdx]
        movups  xmm4, [rax]             ; Cells to the left.
        inc     rdx                     ; Goes back to current cells.

;;; xmm0 = 4 * xmm0
;;; xmm1 = xmm1 + xmm2 + xmm3 + xmm4
        addps   xmm0, xmm0
        addps   xmm1, xmm2
        addps   xmm3, xmm4
        addps   xmm0, xmm0
        addps   xmm1, xmm3
d5:
        subps   xmm1, xmm0
        movss   xmm4, [factor]
        shufps  xmm4, xmm4, 0h          ; Broadcasts factor.
        mulps   xmm1, xmm4              ; Scales difference by factor.
        lea     rax, [r9 + 4 * rdx]
        movups  [rax], xmm1             ; Puts result in difference matrix.
d6:
        add     rcx, 4
        cmp     rcx, r11
        jb      l4

;;; Sets new current state.
        mov     rcx, r11                ; Index of first cell of last row.
        dec     rcx
l5:
        lea     rax, [r8 + 4 * rcx]
        mov     edx, [rax]              ; Stores value indicating if temperature is fixed for this cell.
        lea     rdi, [r9 + 4 * rcx]
        movss   xmm0, [rdi]             ; Stores difference for this cell.
        lea     rsi, [r10 + 4 * rcx]
        movss   xmm1, [rsi]             ; Stores last temperature for this cell.

        test    edx, edx
        jnz     cont_l5                 ; In this cell temperature cannot be changed.

        addps   xmm1, xmm0
        movss   [rsi], xmm1
cont_l5:
        loop    l5

        ret