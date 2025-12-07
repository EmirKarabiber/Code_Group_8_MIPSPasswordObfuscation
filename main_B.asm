# main_B.asm  (Version B - XOR-encrypted secret)

# In this version, the password is stored as XOR-encrypted bytes
# in the .data section. During execution, the program computes the
# XOR key, decrypts the encrypted bytes, and compares the result
# with the user input.

# Purpose:
# Prevent direct extraction of the plaintext password from the binary
# Force the attacker to analyze the XOR key and decryption loop

        .data
prompt_msg_B:   .asciiz "Enter password (Version B): "
success_msg_B:  .asciiz "\nACCESS GRANTED (B)\n"
fail_msg_B:     .asciiz "\nACCESS DENIED (B)\n"

# Original password is "secret123".
# XOR key: 0x37
# For each character: encrypted = original ^ 0x37

# 's' = 0x73  => 0x73 ^ 0x37 = 0x44
# 'e' = 0x65  => 0x65 ^ 0x37 = 0x52
# 'c' = 0x63  => 0x63 ^ 0x37 = 0x54
# 'r' = 0x72  => 0x72 ^ 0x37 = 0x45
# 'e' = 0x65  => 0x52
# 't' = 0x74  => 0x43
# '1' = 0x31  => 0x06
# '2' = 0x32  => 0x05
# '3' = 0x33  => 0x04

encrypted_pwd_B:
        .byte  0x44,0x52,0x54,0x45,0x52,0x43,0x06,0x05,0x04,0x00

# Buffer for decrypted password
decrypted_pwd_B:
        .space  10          # 9 characters + null terminator

# Buffer for user input
input_buf_B:
        .space  33          # max 32 characters

        .text
        .globl main

main:
        # Construct obfuscated XOR key
        # (0x37 = decimal 55)
        li      $t2, 20         # t2 = 20
        li      $t3, 35         # t3 = 35
        add     $t4, $t2, $t3   # t4 = 20 + 35 = 55 = 0x37
        move    $s2, $t4        # $s2 = xor_key (0x37)


        # Print password prompt
        la      $a0, prompt_msg_B
        li      $v0, 4
        syscall

        # Read user input string
        la      $a0, input_buf_B
        li      $a1, 32
        li      $v0, 8
        syscall
        
        # input_buf_B now contains user input

        # Remove potential newlines from input
        la      $t0, input_buf_B   # $t0 = pointer to input buffer
remove_newline_B:
        lb      $t1, 0($t0)        # $t1 = current character
        beq     $t1, $zero, decrypt_setup  # if null terminator: done
        li      $t2, 10            # $t2 = ASCII newline '\n'
        beq     $t1, $t2, found_newline_B 
        addi    $t0, $t0, 1        # move to next character
        j       remove_newline_B
found_newline_B:
        sb      $zero, 0($t0)      # replace newline with null terminator

        # Decrypt the XOR-encrypted password
decrypt_setup:
        la      $s0, encrypted_pwd_B   # source (encrypted)
        la      $s1, decrypted_pwd_B   # destination (plaintext)

decrypt_loop:
        lb      $t0, 0($s0)            # t0 = encrypted byte
        beq     $t0, $zero, end_decrypt   # if null terminator, stop

        xor     $t1, $t0, $s2          # t1 = decrypted_byte = enc ^ key
        sb      $t1, 0($s1)            # write to decrypted buffer

        addi    $s0, $s0, 1            # advance encrypted pointer
        addi    $s1, $s1, 1            # advance decrypted pointer
        j       decrypt_loop

end_decrypt:
        # Add string terminator
        sb      $zero, 0($s1)


        # Compare user input with decrypted password
        la      $s0, input_buf_B       # user input pointer
        la      $s1, decrypted_pwd_B   # decrypted password pointer

compare_loop_B:
        lb      $t0, 0($s0)
        lb      $t1, 0($s1)

        # If user input finished:
        beq     $t0, $zero, check_end_of_stored_B

        # If stored ends earlier or bytes mismatch: fail
        beq     $t1, $zero, fail_B
        bne     $t0, $t1, fail_B

        addi    $s0, $s0, 1
        addi    $s1, $s1, 1
        j       compare_loop_B

check_end_of_stored_B:
        beq     $t1, $zero, success_B
        j       fail_B

success_B:
        la      $a0, success_msg_B
        li      $v0, 4
        syscall
        j       exit_program

fail_B:
        la      $a0, fail_msg_B
        li      $v0, 4
        syscall
        j       exit_program

exit_program:
        li      $v0, 10
        syscall
