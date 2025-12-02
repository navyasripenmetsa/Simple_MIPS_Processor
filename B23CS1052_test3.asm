        .text
        .globl main

main:
    # Initialize test values
    addi $t0, $zero, 5      # A = 5
    addi $t1, $zero, 5      # B = 5
    addi $t2, $zero, 0      # clear t2

    # if (A == B) branch to skip the next addi
    beq  $t0, $t1, equal_case

    # this runs only if not equal
    addi $t2, $zero, 9
    sw   $t2, 200($zero)    # M[200] = 9  (not equal case)

equal_case:
    addi $t2, $zero, 1
    sw   $t2, 204($zero)    # M[204] = 1  (equal case)

halt:
    beq  $zero, $zero, halt

