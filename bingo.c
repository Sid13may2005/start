/**
 * @file bingo.c
 * @brief A complete, single-player command-line Bingo game in C.
 *
 * This program generates a valid 5x5 Bingo card, calls random numbers
 * from 1 to 75, automatically marks the card, and detects when a
 * "BINGO" (a full row, column, or diagonal) is achieved.
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Define constants for the Bingo card dimensions
#define ROWS 5
#define COLS 5
#define TOTAL_NUMBERS 75

// Function Prototypes
void generate_card(int card[ROWS][COLS]);
void display_card(int card[ROWS][COLS]);
int call_number(int called_numbers[TOTAL_NUMBERS + 1]);
void mark_card(int card[ROWS][COLS], int number);
int check_for_bingo(int card[ROWS][COLS]);
void clear_screen();

int main() {
    int card[ROWS][COLS] = {0};
    // Array to track called numbers. Index 0 is unused. Indices 1-75 correspond to numbers.
    int called_numbers[TOTAL_NUMBERS + 1] = {0};
    int number_of_calls = 0;
    int called_number;

    // Seed the random number generator for unique games
    srand((unsigned int)time(NULL));

    generate_card(card);

    printf("Welcome to C-BINGO!\n");
    printf("Here is your card. The center is a FREE space.\n");
    printf("Press Enter to call the next number...\n\n");
    display_card(card);
    getchar(); // Wait for user to press Enter

    // Main game loop
    while (1) {
        clear_screen();
        called_number = call_number(called_numbers);
        number_of_calls++;

        printf("Call #%d: The number is... %d!\n\n", number_of_calls, called_number);

        mark_card(card, called_number);
        display_card(card);

        if (check_for_bingo(card)) {
            printf("\n=========================================\n");
            printf(" B I N G O !!!\n");
            printf("You got Bingo in %d calls!\n", number_of_calls);
            printf("=========================================\n");
            break; // Exit the game loop
        }

        printf("\nPress Enter to continue...");
        getchar(); // Wait for user to proceed
    }

    return 0;
}

/**
 * @brief Generates a valid 5x5 Bingo card with numbers in the correct ranges.
 * B: 1-15, I: 16-30, N: 31-45, G: 46-60, O: 61-75.
 * The center space is marked as 0 (FREE).
 * @param card The 2D array representing the bingo card.
 */
void generate_card(int card[ROWS][COLS]) {
    int i, j, k;
    int used_nums[TOTAL_NUMBERS + 1] = {0};

    for (j = 0; j < COLS; j++) {
        int min = j * 15 + 1;
        int max = (j + 1) * 15;

        for (i = 0; i < ROWS; i++) {
            int num;
            do {
                num = (rand() % 15) + min;
            } while (used_nums[num]); // Keep generating until a unique number is found

            used_nums[num] = 1; // Mark this number as used
            card[i][j] = num;
        }
    }
    // Set the center square as a "FREE" space (marked as 0)
    card[2][2] = 0;
}

/**
 * @brief Displays the current state of the Bingo card.
 * Marked numbers (or the FREE space) are shown as 'XX'.
 * @param card The 2D array representing the bingo card.
 */
void display_card(int card[ROWS][COLS]) {
    printf("-------------------------------------\n");
    printf("|   B   |   I   |   N   |   G   |   O   |\n");
    printf("-------------------------------------\n");

    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < COLS; j++) {
            if (card[i][j] == 0) {
                printf("|  XX   "); // Marked number or FREE space
            } else {
                printf("| %-5d ", card[i][j]); // Use %-5d for alignment
            }
        }
        printf("|\n");
        printf("-------------------------------------\n");
    }
}

/**
 * @brief Selects a new, unique random number between 1 and 75.
 * @param called_numbers An array tracking which numbers have been called.
 * @return The newly called number.
 */
int call_number(int called_numbers[TOTAL_NUMBERS + 1]) {
    int num;
    do {
        num = (rand() % TOTAL_NUMBERS) + 1;
    } while (called_numbers[num]); // Loop until an uncalled number is found

    called_numbers[num] = 1; // Mark the number as called
    return num;
}

/**
 * @brief Marks a number on the card by setting its value to 0.
 * @param card The 2D array representing the bingo card.
 * @param number The number that was called.
 */
void mark_card(int card[ROWS][COLS], int number) {
    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < COLS; j++) {
            if (card[i][j] == number) {
                card[i][j] = 0; // Mark the number
                return; // Exit once found
            }
        }
    }
}

/**
 * @brief Checks the card for any winning patterns (row, column, or diagonal).
 * A winning pattern consists of all 5 squares being marked (value 0).
 * @param card The 2D array representing the bingo card.
 * @return 1 if a Bingo is found, 0 otherwise.
 */
int check_for_bingo(int card[ROWS][COLS]) {
    int i, j;

    // Check for horizontal (row) wins
    for (i = 0; i < ROWS; i++) {
        if (card[i][0] == 0 && card[i][1] == 0 && card[i][2] == 0 && card[i][3] == 0 && card[i][4] == 0) {
            return 1;
        }
    }

    // Check for vertical (column) wins
    for (j = 0; j < COLS; j++) {
        if (card[0][j] == 0 && card[1][j] == 0 && card[2][j] == 0 && card[3][j] == 0 && card[4][j] == 0) {
            return 1;
        }
    }

    // Check for diagonal wins
    if (card[0][0] == 0 && card[1][1] == 0 && card[2][2] == 0 && card[3][3] == 0 && card[4][4] == 0) {
        return 1;
    }
    if (card[0][4] == 0 && card[1][3] == 0 && card[2][2] == 0 && card[3][1] == 0 && card[4][0] == 0) {
        return 1;
    }

    return 0; // No bingo found
}

/**
 * @brief A simple function to clear the console screen for a cleaner display.
 * Works on both Windows and Unix-like systems.
 */
void clear_screen() {
#ifdef _WIN32
    system("cls");
#else
    system("clear");
#endif
}
