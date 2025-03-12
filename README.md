# Rirdle
Wordle clone written in RISC-V Assembly. Written and compatible with RARS.

## Instructions
1. Download and open rirdle.asm in the [RARS simulator](https://github.com/TheThirdOne/rars).
2. In the .data section at the bottom, change str_answer to any 5-letter word.

Instead of using colors to represent the accuracy of each letter in your guess, square brackets and parentheses are used.

* Square brackets mean the letter is in the correct position (green in Wordle);
* Parentheses mean the letter is contained in the answer, but at an incorrect position (yellow in Wordle);
* If the letter has neither around it, it's not in the word (gray in Wordle)

**Screenshot:**

![image](https://github.com/umlaufg/rirdle/blob/main/docs/images/rirdle_screenshot_1.PNG?raw=true)

#
*(This project is for demonstration purposes, but will likely be improved over time.)*
