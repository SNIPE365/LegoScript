#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#define MAX_COLORS 100 // Define the maximum number of colors

bool isWhitespaceLine(const char *line) {
    for (int i = 0; line[i] != '\0'; i++) {
        if (line[i] != ' ' && line[i] != '\t' && line[i] != '\n') {
            return false;
        }
    }
    return true;
}

bool isValidLineType0(const char *line) {
    const char *trimmedLine = line + strspn(line, " \t");
    return strncmp(trimmedLine, "0 ", 2) == 0 || strncmp(trimmedLine, "0\t", 2) == 0;
}

bool isLineType1(const char *line) {
    const char *trimmedLine = line + strspn(line, " \t");
    return strncmp(trimmedLine, "1 ", 2) == 0 || strncmp(trimmedLine, "1\t", 2) == 0;
}

int main() {
    FILE *inputFile = fopen("input.ldr", "r");
    if (inputFile == NULL) {
        printf("Error opening input file.\n");
        return 1;
    }

    FILE *outputFile = fopen("output.ls", "w");
    if (outputFile == NULL) {
        printf("Error opening output file.\n");
        fclose(inputFile);
        return 1;
    }

    // Read Colors.txt and store color IDs in an array
    FILE *colorsFile = fopen("Colors.txt", "r");
    if (colorsFile == NULL) {
        printf("Error opening Colors.txt.\n");
        fclose(inputFile);
        fclose(outputFile);
        return 1;
    }

    int colorIds[MAX_COLORS];
    int numColors = 0;

    char colorLine[256];
    while (fgets(colorLine, sizeof(colorLine), colorsFile) != NULL && numColors < MAX_COLORS) {
        if (colorLine[0] != '0' && sscanf(colorLine, "%*d %d %*s", &colorIds[numColors]) == 1) {
            numColors++;
        }
    }
    fclose(colorsFile);

    char LineType;
    char line[256];

    while (fgets(line, sizeof(line), inputFile) != NULL) {
        LineType = '\0'; // Initialize LineType within the loop.
        if (isWhitespaceLine(line)) {
            fputs(line, outputFile);
        } else if (sscanf(line, " %c", &LineType) == 1 && LineType == '0' && isValidLineType0(line)) {
            const char *trimmedLine = line + strspn(line, " \t");
            fprintf(outputFile, "// %s", trimmedLine + 2); // Skip the '0 ' characters.
        } else if (isLineType1(line)) {
            int colorId;
            if (sscanf(line, " %*d %d", &colorId) == 1) {
                bool isValidColor = false;
                for (int i = 0; i < numColors; i++) {
                    if (colorId == colorIds[i]) {
                        isValidColor = true;
                        break;
                    }
                }
                if (isValidColor) {
                    printf("Line is type 1, Color ID: %d\n", colorId);
                } else {
                    printf("Error: Color ID %d is not a valid LDRAW color ID.\n", colorId);
                }
            }
        } else if (LineType != '0') {
            printf("Line is not of type 0 or empty. Exiting program.\n");
            fclose(inputFile);
            fclose(outputFile);
            return 1;
        }
    }

    fclose(inputFile);
    fclose(outputFile);
    printf("File conversion complete.\n");

    return 0;
}
