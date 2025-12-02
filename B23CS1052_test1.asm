.text
.globl main

main:
    
    # Store 10 at M[100] (0x64)
    addi $t0, $zero, 10
    sw $t0, 100($zero)

    # Store 20 at M[104] (0x68)
    addi $t0, $zero, 20
    sw $t0, 104($zero)
    
    # Store 30 at M[108] (0x6C)
    addi $t0, $zero, 30
    sw $t0, 108($zero)

    
    # Load A (10) into $s0
    lw $s0, 100($zero)
    
    # Load B (20) into $s1
    lw $s1, 104($zero)

    # Load C (30) into $s2
    lw $s2, 108($zero)

    # We must wait for the 'lw' instructions to finish
    
    sll $zero, $zero, 0   # nop
    sll $zero, $zero, 0   # nop
    sll $zero, $zero, 0   # nop 

    
    # $t1 = A + B (10 + 20)
    add $t1, $s0, $s1
    
    # $s3 = $t1 + C (30 + 30)
    add $s3, $t1, $s2       # $s3 should now be 60

    # Store 60 (0x3c) at M[112] (0x70)
    sw $s3, 112($zero)

# --- Infinite Halt ---
halt:
    beq $zero, $zero, halt