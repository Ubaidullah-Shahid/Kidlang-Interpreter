# ============================================================
# KidLang Sample Program 10
# Topic: Interactive Number Guessing Game
# ============================================================

SHOW "========================================"
SHOW "   NUMBER GUESSING GAME"
SHOW "   Powered by KidLang!"
SHOW "========================================"
SHOW ""
SHOW "I am thinking of a number between 1 and 10."
SHOW "Try to guess it!"
SHOW ""

# The secret number (in a real game, this would be random)
SET secretNumber = 7
SET maxTries = 3
SET tries = 0
SET won = FALSE

WHILE tries < maxTries AND won == FALSE DO
    SET tries = tries + 1
    
    SHOW "Try number:"
    SHOW tries
    SHOW "Enter your guess (1-10):"
    ASK guess
    
    IF guess == secretNumber THEN
        SET won = TRUE
        SHOW ""
        SHOW "CORRECT! You guessed it!"
        SHOW "The secret number was:"
        SHOW secretNumber
        SHOW ""
        SHOW "You got it in"
        SHOW tries
        SHOW "tries!"
    ELIF guess < secretNumber THEN
        SHOW "Too LOW! Try a bigger number."
        IF tries < maxTries THEN
            SET remaining = maxTries - tries
            SHOW "You have"
            SHOW remaining
            SHOW "tries left."
        END
    ELSE
        SHOW "Too HIGH! Try a smaller number."
        IF tries < maxTries THEN
            SET remaining = maxTries - tries
            SHOW "You have"
            SHOW remaining
            SHOW "tries left."
        END
    END
    
    SHOW ""
END

IF won == FALSE THEN
    SHOW "Sorry! You used all your tries."
    SHOW "The secret number was:"
    SHOW secretNumber
    SHOW ""
    SHOW "Better luck next time!"
END

SHOW ""
SHOW "Thanks for playing KidLang Guessing Game!"
SHOW ""

# ---- Score calculation ----
IF won == TRUE THEN
    SWITCH tries
        CASE 1:
            SET score = 100
            SHOW "Amazing! First try! Score: 100"
        CASE 2:
            SET score = 75
            SHOW "Great! Second try! Score: 75"
        CASE 3:
            SET score = 50
            SHOW "Good! Third try! Score: 50"
        DEFAULT:
            SET score = 0
    ENDSWITCH
ELSE
    SET score = 0
    SHOW "No score this round. Practice more!"
END

SHOW ""
SHOW "Your final score:"
SHOW score
SHOW ""
SHOW "Game Over! Goodbye!"
