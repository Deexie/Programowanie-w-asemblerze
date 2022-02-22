/* Zadanie zaliczeniowe z Programowania w Asemblerze */
/* Aleksandra Martyniuk am418415 */

.data

.balign 4
matrix_value:       .word 1
.balign 4
width_value:        .word 1
.balign 4
height_value:       .word 1
.balign 4
weight_value:       .word 1

.text

.global start
.global step

/* Loads all the data. */
.balign 4
start:
    push {r4}
    ldr r4, width
    str r0, [r4]
    ldr r4, height
    str r1, [r4]
    ldr r4, matrix
    str r2, [r4]
    ldr r4, weight
    str r3, [r4]
    pop {r4}
    bx lr

.balign 4
step:
    push {r4-r11}
    ldr r1, matrix
    ldr r1, [r1]
    ldr r2, height
    ldr r2, [r2]
    ldr r3, width
    ldr r3, [r3]
    sub r5, r3, #1              @ Number of a current column.

next_column_loop:
    eor r4, r4, r4              @ Number of a current row.

next_cell_loop:
    mla r8, r3, r4, r5          @ Index of current cell.
    mov r8, r8, ASL #2          @ Number of bytes before current cell.
    eor r7, r7, r7              @ Difference.

    @ Find the difference with cells from above.
    teq r4, #0
    beq first_row               @ First row does not have cells above.
    sub r9, r8, r3, ASL #2      @ Number of bytes before cell above.
    sub r9, r9, #4              @ Number of bytes before left cell of above cell.
    add r6, r1, r9
    ldr r10, [r6]               @ r10 and r11 contain values of above neighbours.

    ldr r6, [r1, r8]            @ Value in current cell.
    add r7, r7, r10
    add r7, r7, r11
    sub r7, r7, r6, ASL #1

first_row:
    @ Find the difference with cells from below.
    sub r11, r2, #1             @ r11 = height - 1
    teq r4, r11
    beq last_row                @ Last row does not have cells below.
    add r9, r8, r3, ASL #2      @ Number of bytes before cell below.
    sub r9, r9, #4              @ Number of bytes before left cell of below cell.
    add r6, r1, r9
    ldm r6, {r10, r11}          @ r10 and r11 contain values of below neighbours.

    ldr r6, [r1, r8]            @ Value in current cell.
    add r7, r7, r10
    add r7, r7, r11
    sub r7, r7, r6, ASL #1

last_row:
    sub r9, r8, #4              @ Number of bytes before cell to the left.
    ldr r10, [r1, r9]           @ r10 contains value of left neighbour.

    ldr r6, [r1, r8]            @ Value in current cell.
    add r7, r7, r10
    sub r7, r7, r6

    ldr r10, weight
    ldr r10, [r10]
    mul r7, r10, r7

    mov r11, r6                 @ To be used in next loop iteration.
    mov r10, #1000
    mul r6, r10, r6

    add r7, r7, r6              @ Add difference to cell value.
    str r7, [r1, r8]

    add r4, r4, #1              @ Next row.
    teq r4, r2
    bne next_cell_loop          @ Go to the next cell in current column.

    subs r5, r5, #1             @ Next column.
    bne next_column_loop

    @ Set first column.
    eor r8, r8, r8
    mov r5, r2
set_cell:
    add r6, r1, r8
    ldr r10, [r0]
    str r10, [r6]
    add r0, r0, #4
    add r8, r8, r3, ASL #2      @ Next cell of 1st column.
    subs r5, r5, #1             @ Index.
    bne set_cell

    pop {r4-r11}
    bx lr


matrix:     .word matrix_value
width:      .word width_value
height:     .word height_value
weight:     .word weight_value
