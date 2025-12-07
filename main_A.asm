# main_A.asm  (Version A - Plaintext secret)

# The password is stored as a plaintext ASCII string in the .data section.
# The program prompts the user to enter a password.
# The input is compared to the stored password byte by byte.
# If they match exactly, it prints "ACCESS GRANTED", otherwise "ACCESS DENIED".

# From an attackers point of view, this is the weakest design,
# because the password can be read directly from the binary in Ghidra

        .data
prompt_msg:     .asciiz "Enter password: "
success_msg:    .asciiz "\nACCESS GRANTED\n"
fail_msg:       .asciiz "\nACCESS DENIED\n"

stored_pwd:     .asciiz "secret123"

# Buffer for user input
input_buf:      .space  33

        .text
        .globl main

main:
        # Print password prompt
        la      $a0, prompt_msg    # $a0 = address of prompt_msg
        li      $v0, 4             # 4 = print_string
        syscall

        # Read string from user
        la      $a0, input_buf     # $a0 = buffer address
        li      $a1, 32            # $a1 = maximum length (32)
        li      $v0, 8             # 8 = read_string syscall
        syscall
        # User input is stored in input_buf, potentially ending with '\n' and/or '\0'

        # Remove newline character from input (if present)
        la      $t0, input_buf     # $t0 = pointer to input buffer
remove_newline:
        lb      $t1, 0($t0)        # $t1 = current character
        beq     $t1, $zero, setup_compare  # if null terminator, done
        li      $t2, 10            # $t2 = ASCII newline '\n'
        beq     $t1, $t2, found_newline
        addi    $t0, $t0, 1        # move to next character
        j       remove_newline
found_newline:
        sb      $zero, 0($t0)      # replace newline with null terminator

        # Set up pointers for comparison
setup_compare:
        la      $s0, input_buf 
        la      $s1, stored_pwd

compare_loop:
        lb      $t0, 0($s0)        # $t0 = input_buf[i]
        lb      $t1, 0($s1)        # $t1 = stored_pwd[i]

        # If both null: exact match found
        beq     $t0, $zero, check_end_of_stored

        # If input ended but stored continues, or vice versa, or chars differ: fail
        beq     $t1, $zero, fail
        bne     $t0, $t1, fail

        # Both equal and not null; go next char
        addi    $s0, $s0, 1
        addi    $s1, $s1, 1
        j       compare_loop

check_end_of_stored:
        # Null Found. If stored = null: match, else failure.
        beq     $t1, $zero, success
        j       fail

success:
        la      $a0, success_msg
        li      $v0, 4
        syscall
        j       exit_program

fail:
        la      $a0, fail_msg
        li      $v0, 4
        syscall
        j       exit_program

exit_program:
        li      $v0, 10            # 10 = exit
        syscall
