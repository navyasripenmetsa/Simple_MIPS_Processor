# and_or_compute.asm
# temp = A & B
# result = temp | C
# store result at 112
# Expected: M[112] = 11 (0x0B)

        .text
        .globl main

main:
    # initialize inputs
    addi $t0, $zero, 15
    sw   $t0, 100($zero)    # M[100] = A = 0x0F
    addi $t0, $zero, 3
    sw   $t0, 104($zero)    # M[104] = B = 0x03
    addi $t0, $zero, 8
    sw   $t0, 108($zero)    # M[108] = C = 0x08

    # load
    lw   $t1, 100($zero)    # t1 = A
    lw   $t2, 104($zero)    # t2 = B
    lw   $t3, 108($zero)    # t3 = C

    # nops for pipeline safety if required
    sll  $zero, $zero, 0
    sll  $zero, $zero, 0

    # temp = A & B
    and  $t4, $t1, $t2      # t4 = 0x03

    # result = temp | C
    or   $t5, $t4, $t3      # t5 = 0x0B

    # store result
    sw   $t5, 112($zero)    # M[112] = result

# infinite halt
halt:
    beq  $zero, $zero, halt
