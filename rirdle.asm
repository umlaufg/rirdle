### TODO: Consider saving past attempts in memory so we can print them for every new result; Basic refactoring ###

.global _main # Entry point
.text
_main:
    j _rirdle
        
# _rirdle()
# Initializes and runs the game
_rirdle:
    call _format_answer # Ensure the answer is suitable before the game begins
    
    # while s0 < 7:
    li s0, 1
    li s1, 7
    
    _rirdle_loop:
        # Prologue (aligned)
        addi sp, sp, -16
        sw s0, 12(sp)
        sw s1, 8(sp)
        
        mv a0, s0                # Pass the attempt number for use during the prompt
        call _new_attempt        # Begin a new attempt
        
        # Epilogue
        lw s1, 8(sp)
        lw s0, 12(sp)
        addi sp, sp, 16
        
        addi s0, s0, 1           # s0++
        blt s0, s1, _rirdle_loop # Iterate
        
        j _game_over

# _new_attempt(.byte attempt_num)
# Prompts the player to guess the answer another time
_new_attempt:
    # Prologue (aligned)
    addi sp, sp, -16
    sw ra, 12(sp)
    sw a0, 8(sp)        # We need the attempt number for _prompt, so we'll save it here
    
    call _letter_counts # Re-count the number of each letter in the answer
    
    lw a0, 8(sp)        # Load the attempt number and pass as argument
    call _prompt        # Print the attempt number and the incorrect letters the player tried;
                        # get the user's input and format it
    
    call _compare_guess # Compare the guess to this game's answer;
                        # returns number of letters in the correct position
    call _result        # Output the result
    
    # Epilogue
    lw ra, 12(sp)
    addi sp, sp, 16
    
    ret

# _format_answer()
# Passes the answer to _format_word and handles error codes if invalid
_format_answer:
    la a0, str_answer
    
    # Prologue (aligned)
    addi sp, sp, -16
    sw ra, 12(sp)
    
    call _format_word             # Format str_answer
    
    li t0, 1                      # Answer is not 5 chars long
    beq a0, t0, _err_answer_len   # Branch to handler
    
    li t0, 2                      # Answer is not alphabetic
    beq a0, t0, _err_answer_alpha # Branch to handler
    
    # Epilogue
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# _format_guess()
# Passes user's guess to _format_word and handles error codes if invalid
_format_guess:
    la a0, buf_guess
    
    # Prologue (aligned)
    addi sp, sp, -16
    sw ra, 12(sp)
    
    call _format_word
    
    li t0, 1                     # Guess is not 5 chars long
    beq a0, t0, _err_guess_len   # Branch to handler
    
    li t0, 2                     # Guess is not alphabetic
    beq a0, t0, _err_guess_alpha # Branch to handler
    
    # Epilogue
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
    
# _format_word(.asciz string)
#
_format_word:
    # Preserve string
    mv s0, a0
    
    # Prologue (aligned)
    addi sp, sp, -16
    sw ra, 12(sp)
    
    mv a0, s0                        # _get_length(string)
    call _get_length
    li t0, 5                         # Ensure string is 5 chars long
    bne a0, t0, _format_word_err_len # If it is not, throw an error
    
    mv a0, s0                        # _is_alpha(string)
    call _is_alpha                   # Check to see if the string is wholly alphabetic
    beqz a0, _format_word_err_alpha  # If it is not, throw an error
    
    mv a0, s0                        # _to_uppercase(string)
    call _to_uppercase               # Ensure string is all uppercase for comparison later
    
    # string formatted without error
    li a0, 0
    j _format_word_epilogue
    
    _format_word_err_len:
        li a0, 1
        j _format_word_epilogue
        
    _format_word_err_alpha:
        li a0, 2
        j _format_word_epilogue
        
    # Epilogue
    _format_word_epilogue:
        lw ra, 12(sp)
        addi sp, sp, 16
        ret
    
# _get_length(.asciz string)
# Returns the length of the provided string
_get_length:
    # while string[t0] != [null]:
    li t0, 0
    
    _get_length_loop:
        # Get the current char : t2 = string[t0]
    	add t1, a0, t0
    	lbu t2, 0(t1)
    	
    	beqz t2, _get_length_ret # If this char is [null], return the length we've counted
    	
    	addi t0, t0, 1           # t0++
    	j _get_length_loop       # Iterate

    _get_length_ret:
        mv a0, t0
        ret

# _is_alpha(.asciz string)
# Checks all the chars of a string and returns false if they aren't all alphabetic
_is_alpha:
    # while t0 < 5:
    li t0, 0
    li t1, 5
    
    _is_alpha_loop:
        # Get the current char : t3 = string[t0]
        add t2, a0, t0
        lbu t3, 0(t2)
        
        li t4, 'A'
        blt t3, t4, _ret_false         # This char (and thus the string) is not alphabetic, return false
        li t4, 'Z'
        ble t3, t4, _is_alpha_loop_inc # This char is alphabetic
        li t4, 'a'
        blt t3, t4, _ret_false         # ...not alphabetic, return false
        li t4, 'z'
        bgt t3, t4, _ret_false         # ...not alphabetic, return false
        
    _is_alpha_loop_inc:
        addi t0, t0, 1                 # t0++
        blt t0, t1, _is_alpha_loop     # Iterate
        j _ret_true
        
# _to_uppercase(.asciz string)
# Checks all the letters of a string and converts them to uppercase if they aren't already
# *Assumes all the chars are alphabetic (check with _is_alpha)
_to_uppercase:
    # while t0 < 5:
    li t0, 0
    li t1, 5
    
    _to_uppercase_loop:
        # Get the current letter : t3 = string[t0]
        add t2, a0, t0
        lbu t3, 0(t2)
        
        li t4, 'a'                    # This means the letter is lowercase
        bge t3, t4, _make_upper       # If this letter is lowercase, convert it
        
        j _to_uppercase_loop_inc
    
    _make_upper:
        addi t3, t3, -32              # The uppercase version of a lowercase letter may be found by subtracting 32 from its ASCII code
        sb t3, 0(t2)                  # Overwrite the lowercase letter in the string buffer
        
    _to_uppercase_loop_inc:
        addi t0, t0, 1                # t0++
        blt t0, t1 _to_uppercase_loop # Iterate
        ret

# _ret_false()
# Returns false
# *Useful for conditional returns
_ret_false:
    li a0, 0
    ret

# _ret_true()
# Returns true
# *Useful for conditional returns
_ret_true:
    li a0, 1
    ret

# _letter_counts()
# Writes the number of times each letter in the answer word occurs to buf_counts
# For example, if str_answer is ROBOT, buf_counts will be 0x01000000000000200101000000
_letter_counts:
    # while t0 < 26:
    li t0, 0
    li t1, 26
    
    _letter_counts_init_loop:
        # Get the current byte in the counts buffer : t3 = buf_counts[t0]
        la t2, buf_counts
        add t2, t2, t0
        li t3, 0
        sb t3, 0(t2)                         # Zero it so the letter occurences can be counted again
        
        addi t0, t0, 1                       # t0++
        blt t0, t1, _letter_counts_init_loop # Iterate

    # while t0 < 5:
    li t0, 0
    li t1, 5
    
    _letter_counts_loop:
        # Get the current letter of the answer : t3 = str_answer[t0]
        la t2, str_answer
        add t2, t2, t0
        lbu t3, 0(t2)
        
        addi t3, t3, -65                # Get this letter's position in the alphabet (starting with A == 0)
        la t2, buf_counts
        add t2, t2, t3
        lbu t4, 0(t2)                   # t4 = buf_counts[t3]
        addi t4, t4, 1                  # Increment the number of times this letter occurs
        sb t4, 0(t2)                    # Write to the buffer
        
        addi t0, t0, 1                  # t0++
        blt t0, t1, _letter_counts_loop # Iterate
        ret

# _prompt(.byte attempt_num)
# Writes the attempt number and letters not present in the word
_prompt:
    mv t0, a0 # Preserve attempt_number so a0 can be used for ecalls
    
    # "Guess #"
    li a7, 4
    la a0, str_prompt1
    ecall
    
    # "{attempt_num}"
    li a7, 1
    mv a0, t0
    ecall
    
    li a7, 11
    li a0, '\n'
    ecall
    
_prompt_failed_letters:
    # "Failed letters: "
    li a7, 4
    la a0, str_prompt2
    ecall
    
    # while s0 < 26:
    li s0, 0
    li s1, 26
    la s2, buf_letter_guess_states
    
    _prompt_failed_letters_loop:
        # Get the current letter in the alphabet : s3 = buf_not_present[t0]
        add t0, s0, s2
        lbu s3, 0(t0)
        
        li t1, 1
        beq s3, t1, _prompt_failed_letters_found # This letter has been tried before by the player and is not present in the answer (1)
        j _prompt_failed_letters_inc             # This letter is either present in the answer (2) or hasn't been tried yet (0)
        
    _prompt_failed_letters_found:
        # Print this letter to the console so the player knows not to use it again
        li a7, 11
        addi a0, s0, 65
        ecall
        
        # Spacing for next letter (if any)
        li a0, ' '
        ecall
        
    _prompt_failed_letters_inc:
        addi s0, s0, 1                           # s0++
        blt s0, s1, _prompt_failed_letters_loop  # Iterate
    
        li a7, 11
        li a0, '\n'
        ecall
    
_prompt_input:
    # Allow the user to input their guess;
    # we don't want to cut the user off right after typing in the 5th character, so the input buffer is larger than needed
    # (the length we actually want will be checked later)
    li a7, 8
    la a0, buf_guess
    li a1, 32
    ecall
    
    # while buf_guess[s0] != '\n'
    li s0, 0
    la s1, buf_guess
    li s2, '\n'
    
    _prompt_input_loop:
        # Get the current char in the guess : s4 = buf_guess[s0]
        add s3, s0, s1
        lbu s4, 0(s3)
        beq s4, s2, _prompt_input_truncate # If this char is a newline, break the loop and zero it
        
        addi s0, s0, 1                     # s0++
        j _prompt_input_loop               # Iterate
        
    _prompt_input_truncate:
        li s4, 0
        sb s4, 0(s3)
    
    j _format_guess # Check the player's guess for errors, and clean it up for comparison

# _compare_guess()
# Compares the player's guess to the answer and writes the result to buf_result;
# returns the number of letters in the correct position
_compare_guess:
    # Begin by clearing the result buffer so we can write to it cleanly again
    # while s0 < 5:
    li s0, 0
    li s1, 5
    la s2, buf_result
    li a0, 0
    
    _compare_guess_init_loop:
        # Get the current byte in buf_result : t0 = buf_result[s0]
        add t0, s0, s2
        sb zero, 0(t0)                       # Zero it
        
        addi s0, s0, 1                       # s0++
        blt s0, s1, _compare_guess_init_loop # Iterate
        
_compare_guess_correct:
    # while s0 < 5:
    li s0, 0
    li s1, 5
    
    _compare_guess_loop_correct:
        # Get the current letter from the player's guess... : s2 = buf_guess[s0]
        la t0, buf_guess
        add t1, s0, t0
        lbu s2, 0(t1)
        
        # ...and the current letter from the answer : s3 = str_answer[s0]
        la t0, str_answer
        add t1, s0, t0
        lbu s3, 0(t1)
        
        beq s2, s3, _compare_guess_correct_pos  # If both letters are the same, write this in the result buffer
        j _compare_guess_loop_correct_inc       # Otherwise, increment
        
    _compare_guess_correct_pos:
        # Get the current byte in buf_result : t1 = &buf_result[s0]
        la t0, buf_result
        add t1, s0, t0
        li t2, 2                                # The current letter from the guess is in the correct position
        sb t2, 0(t1)
        
        addi a0, a0, 1                          # Increment the number of letters in the correct position from the guess
        
        # Get the number of occurences of this letter in the answer : t3 = buf_counts[s2 - 65]
        la t0, buf_counts
        addi t1, s2, -65                        # (A == 0)
        add t2, t0, t1
        lbu t3, 0(t2)
        addi t3, t3, -1                         # Decrement the number of times this letter can be in the guess and still be valid,
                                                # respective to the number of times it occurs in the answer
        sb t3, 0(t2)
        
        # Get the position of this letter in buf_letter_guess_states : t2 = &buf_letter_guess_states[t1]
        la t0, buf_letter_guess_states
        add t2, t0, t1
        li t3, 2                                # This number has been used before and is in the answer
        sb t3, 0(t2)
            
        j _compare_guess_loop_correct_inc
        
    _compare_guess_loop_correct_inc:
        addi s0, s0, 1                          # s0++
        blt s0, s1, _compare_guess_loop_correct # Iterate
        
_compare_guess_incorrect:
    # while s0 < 5:
    li s0, 0
    li s1, 5
        
    _compare_guess_loop_incorrect:
        # Get the current byte in the result buffer : t2 = buf_result[s0]
        la t0, buf_result
        add t1, s0, t0
        lbu t2, 0(t1)
        
        li t3, 2                                      # This means this letter has been marked as correct from the first pass
        beq t2, t3, _compare_guess_loop_incorrect_inc # If so, skip to the next letter as there is nothing to do here
        
        # Get the current letter from the guess buffer : s2 = buf_guess[s0]
        la t0, buf_guess
        add t1, s0, t0
        lbu s2, 0(t1)
        
        # Get the appropriate byte from the letter counts buffer : s3 = buf_counts[s2 - 65]
        la t0, buf_counts
        addi t1, s2, -65                              # (A == 0)
        add t2, t0, t1
        lbu s3, 0(t2)
        
        bnez s3, _compare_guess_incorrect_pos         # If this letter is contained within the answer, it must be in the wrong position;
                                                      # write this in the result buffer
        
        # Get the state of this letter : s3 = buf_letter_guess_states[t1]
        la t0, buf_letter_guess_states
        add t2, t0, t1
        lbu s3, 0(t2)
        beqz s3, _compare_guess_not_present           # If '0' (meaning the letter has not been used in a guess before), the letter is not in the answer at all;
                                                      # write this in the result buffer
        
        j _compare_guess_loop_incorrect_inc
          
    _compare_guess_incorrect_pos:
        addi s3, s3, -1                               # Decrement the number of times this letter can be in the guess and still be valid,
                                                      # with respect to the number of times it occurs in the answer
        sb s3, 0(t2)
        
        # Get the position of this letter in buf_letter_guess_states : t2 = &buf_letter_guess_states[t1]
        la t0, buf_letter_guess_states
        addi t1, s2, -65                              # (A == 0)
        add t2, t0, t1
        li t3, 2                                      # This number has been used before and is in the answer
        sb t3, 0(t2)
        
        # Get the current byte in buf_result : t1 = &buf_result[s0]
        la t0, buf_result
        add t1, s0, t0
        li t2, 1                                      # The current letter is in the answer but in the wrong position
        sb t2, 0(t1)
        
        j _compare_guess_loop_incorrect_inc
        
    _compare_guess_not_present:
        # Get the position of this letter in buf_letter_guess_states : t2 = &buf_letter_states[t1]
        la t0, buf_letter_guess_states
        addi t1, s2, -65                              # (A == 0)
        add t2, t0, t1
        li t3, 1                                      # The current letter from the guess is not in the answer
        sb t3, 0(t2)
        
        j _compare_guess_loop_incorrect_inc
        
    _compare_guess_loop_incorrect_inc:
        addi s0, s0, 1                                # s0++
        blt s0, s1, _compare_guess_loop_incorrect     # Iterate
        
        ret
    
# _result(.byte correct_letters)
# Prints the result stored in buf_result relative to each letter in the player's guess;
# checks to see if all letters are in the correct position (win condition)
_result:
    mv s0, a0 # Save the number of correct letters for comparison later
    
    li a7, 11
    li a0, '\n'
    ecall
    
    # while s1 < 5:
    li s1, 0
    li s2, 5
    
    _result_loop:
        # Get the current letter of the guess...
        la t0, buf_guess
        add t1, s1, t0
        lbu s3, 0(t1)
        
        # ...and the current byte of the result buffer
        la t0, buf_result
        add t1, s1, t0
        lbu s4, 0(t1)
        
        beqz s4, _result_not_present      # The letter is not present in the word (0)
        li t2, 1
        beq s4, t2, _result_incorrect_pos # The letter is present in the word but in the wrong position (1)
        li t2, 2
        beq s4, t2, _result_correct_pos   # The letter is in the correct position (2)
        
    _result_not_present:
        # Prints " A "
        
        li a7, 11
        li a0, ' '
        ecall
        
        mv a0, s3
        ecall
        
        li a0, ' '
        ecall
        
        j _result_loop_inc
        
    _result_incorrect_pos:
        # Prints "(A)"
        
        li a7, 11
        li a0, '('
        ecall
        
        mv a0, s3
        ecall
        
        li a0, ')'
        ecall
        
        j _result_loop_inc
        
    _result_correct_pos:
        # Prints "[A]"
        
        li a7, 11
        li a0, '['
        ecall
        
        mv a0, s3
        ecall
        
        li a0, ']'
        ecall
        
        j _result_loop_inc
        
    _result_loop_inc:
        addi s1, s1, 1           # s1++
        blt s1, s2, _result_loop # Iterate
        
        li a7, 11
        li a0, '\n'
        ecall
        
        li t0, 5               # If the player got all 5 letters in the correct position,
        beq s0, t0, _guess_win # they've won- so we can congratulate them and terminate the program
        
        ret

# _guess_win()
# Prints a message congratulating the player and terminates the program
_guess_win:
    li a7, 4
    la a0, str_win
    ecall
    
    li a0, 0
    j _exit

# _game_over()
# Prints a "game over" message along with the correct answer;
# terminates the program (0)
_game_over:
    li a7, 4
    la a0, str_lose
    ecall
    
    la a0, str_answer
    ecall
    
    li a7, 11
    li a0, '\n'
    ecall
    
    li a0, 0
    j _exit

# _err_answer_len()
# Prints an error as the game's answer is not 5 characters long;
# terminates the program (2)
_err_answer_len:
    li a7, 4
    la a0, str_err_answer_len
    ecall
    
    li a0, 2
    j _exit

# _err_answer_alpha()
# Prints and error as the game's answer is not alphabetic;
# terminates the program (2)
_err_answer_alpha:
    li a7, 4
    la a0, str_err_answer_alpha
    ecall
    
    li a0, 2
    j _exit

# _err_guess_len()
# Tells the player their answer is not 5 characters long;
# allows the user to input another string
_err_guess_len:
    li a7, 4
    la a0, str_exc_guess_len
    ecall
    
    # Since we branch to this as a part of the _prompt procedure, we do not return to _new_attempt;
    # this allows us to get the user's input directly after instead of needing to prompt them again
    j _prompt_input

# _err_guess_alpha()
# Tells the player their answer is not alphabetic;
# allows the user to input another string
_err_guess_alpha:
    li a7, 4
    la a0, str_exc_guess_alpha
    ecall
    
    # (Refer to _err_guess_len)
    j _prompt_input
  
# _exit(.byte exit_code)
# Calls the kernel to terminate the program with the appropriate exit code
 _exit:
    li a7, 93
    ecall
    
.data
str_answer:
    .asciz "Beers"
buf_counts:
    .space 26

str_prompt1:
    .asciz "Guess #"
str_prompt2:
    .asciz "Failed letters: "
    
buf_guess:
    .space 32
    
# The result calculated with _compare_guess;
# each byte represents the value a particular letter in the player's guess has with respect to str_answer;
# 0 : Letter is not present in the answer (gray in Wordle)
# 1 : Letter is present in the answer, but not in the correct position (yellow in Wordle)
# 2 : Letter is present in the answer and in the correct position (green in Wordle)
buf_result:
    .space 5
    
# The state of each letter in the alphabet with respect to the player's guesses;
# modified with _compare_guess;
# 0 : The player has not yet used this letter in a guess
# 1 : The player has used this letter in a guess, and it isn't present in the answer
# 2 : The player has used this letter in a guess, and it is present in the answer
# Needed for the "Failed Letters: " given to the player at the beginning of each attempt
buf_letter_guess_states:
    .space 26
    
str_err_answer_len:
    .asciz "FATAL: Your answer can only have a length of 5 letters\n"
str_err_answer_alpha:
    .asciz "FATAL: The answer must only contain letters\n"
    
str_exc_guess_len:
    .asciz "Your guess must be 5 letters!\n"
str_exc_guess_alpha:
    .asciz "Your guess must only contain letters!\n"

str_win:
    .asciz "You guessed the word!\n"
str_lose:
    .asciz "Game over! The word was: "
