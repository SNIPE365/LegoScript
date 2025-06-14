#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main() {
    // Disable buffering for stdout.
    setbuf(stdout, NULL);

    // Define a structure to store the data.
    struct DataEntry {
        int ID;
        char LSScript[4086];    // Adjust the size as needed.
        char LDRAWScript[4086]; // Adjust the size as needed.
    };

    // Define an array of data entries.
    struct DataEntry data[] = {
        {1,  "3024 P1 c1 = 3024 P2 s1;",       "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3024.dat\n"
                                               "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3024.dat"},
        {2,  "3024 P1 s1 = 3024 P2 c1;",       "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3024.dat\n"
                                               "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3024.dat"},
        {3,  "3024 P2 c1 = 3024 P1 s1;",       "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3024.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3024.dat"},
        {4,  "3024 P2 s1 = 3024 P1 c1;",       "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3024.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3024.dat"},
        {5,  "3023 P1 c1 = 3023 P2 s1;",       "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {6,  "3023 P1 s1 = 3024 P2 c1;",       "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {7,  "3023 P2 c1 = 3023 P1 s1;",       "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {8,  "3023 P2 s1 = 3023 P1 c1;",       "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {9,  "3023 P1 c2 = 3023 P2 s2;",       "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {10, "3023 P1 s2 = 3024 P2 c2;",       "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {11, "3023 P2 c2 = 3023 P1 s2;",       "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {12, "3023 P2 s2 = 3023 P1 c2;",       "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {13, "3023 P1 c1,c2 = 3023 P2 s1,s2;", "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {14, "3023 P1 c1,c2 = 3024 P2 s2,s1;", "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {15, "3023 P2 c2,c1 = 3023 P1 s1,s2;", "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {16, "3023 P2 c2,c1 = 3023 P1 s2,s1;", "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {17, "3023 P1 s1,s2 = 3023 P2 c1,c2;", "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {18, "3023 P1 s1,s2 = 3024 P2 c2,c1;", "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {19, "3023 P2 s2,s1 = 3023 P1 c1,c2;", "1 4 0 -8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},
        {20, "3023 P2 s2,s1 = 3023 P1 c2,c1;", "1 4 0  8 0 1 0 0 0 1 0 0 0 1 3023.dat\n"
                                               "1 2 0  0 0 1 0 0 0 1 0 0 0 1 3023.dat"},

    };

    // Determine the size of the data array.
    size_t dataCount = sizeof(data) / sizeof(data[0]);

    // Create a variable to control the loop.
    int continueFlag = 1;

    while (continueFlag) {
        // Prompt the user for an ID.
        int userInput;
        printf("Enter an ID (or 0 to exit): ");
        scanf("%d", &userInput);

        if (userInput == 0) {
            continueFlag = 0; // Exit the loop if the user enters 0.
        } else {
            // Search for the user input in the data array.
            int i;
            for (i = 0; i < dataCount; i++) {
                if (data[i].ID == userInput) {
                    // Found a match, open the output file in write mode ("w").
                    FILE *outputFile = fopen("output.txt", "w");
                    if (outputFile == NULL) {
                        perror("Error opening the output file");
                        return 1;
                    }
                    fprintf(outputFile, "%s", data[i].LDRAWScript);
                    fflush(outputFile); // Flush the output buffer.
                    fclose(outputFile);
                    system(""C:\\users\\kris\\desktop\\ldcad\\ldcad.exe" "legoscript.ldr"");
                    break; // Exit the loop after finding a match.
                }
            }

            // If no match was found.
            if (i == dataCount) {
                printf("No matching entry found.\n");
            }
        }
    }

    return 0;
}
