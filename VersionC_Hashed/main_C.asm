# main_C.asm  (Version C - Hashed secret only)

# In this version, only a 32-bit hash value of the password is
# stored in the binary. The actual password never appears anywhere
# in plaintext form.

# A simple hash function is used (djb2-like):
# hash = 5381
# for each character: hash = hash * 33 + char

# The same hashing function is applied to the user input at runtime,
# and the resulting hash is compared with the stored target value.

# This prevents the attacker from directly reading the password;
# they must either brute-force the input or patch the control flow.

        .data
prompt_msg_C:   .asciiz "Enter password (Version C): "
success_msg_C:  .asciiz "\nACCESS GRANTED (C)\n"
fail_msg_C:     .asciiz "\nACCESS DENIED (C)\n"

# Initial hash value and target hash
hash_init:      .word   5381
target_hash:    .word   0x5211FF21    # djb2("secret123")



# Buffer for user input (max 63 chars + null terminator)
input_buf_C:    .space  64

        .text
        .globl main

main:
        # Print password prompt
        la      $a0, prompt_msg_C
        li      $v0, 4
        syscall

        # Read input string from user
        la      $a0, input_buf_C
        li      $a1, 63
        li      $v0, 8
        syscall

        # Load initial hash value (5381)
        la      $t0, hash_init
        lw      $s0, 0($t0)      # s0 = hash accumulator

        # s1 = pointer to input buffer
        la      $s1, input_buf_C

        li      $t2, 10          # ASCII linefeed '\n'

hash_loop:
        lbu     $t1, 0($s1)      # t1 = current input character

        # Stop if null/newline reached
        beq     $t1, $zero, end_hash
        beq     $t1, $t2, end_hash

        # hash = (hash * 33) + character
        # 33 = 32 + 1 => (hash << 5) + hash

        sll     $t3, $s0, 5      # t3 = hash * 32
        addu    $t3, $t3, $s0    # t3 = hash * 33
        addu    $s0, $t3, $t1    # s0 = t3 + current character

        addi    $s1, $s1, 1      # move to next character
        j       hash_loop

end_hash:
        # Compare computed hash with stored target hash
        la      $t4, target_hash
        lw      $t5, 0($t4)      # t5 = stored hash value

        beq     $s0, $t5, success_C
        j       fail_C

success_C:
        la      $a0, success_msg_C
        li      $v0, 4
        syscall
        j       exit_program

fail_C:
        la      $a0, fail_msg_C
        li      $v0, 4
        syscall
        j       exit_program

exit_program:
        li      $v0, 10
        syscall