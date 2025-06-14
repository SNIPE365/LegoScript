#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char partID[26];  // 25 characters + '\0'
    char partINST[4]; // Up to 3 uppercase letters
    char primID[8];   // Up to 3 lowercase letters + Up to 4 digits
} ParsedInput;

int myfunction(const char* format, ParsedInput* result) {
    int count = sscanf(format, "%25[0-9A-Za-z_-] %3[A-Z] %3[a-z] = %25[0-9A-Za-z_-] %3[A-Z] %3[a-z] ;",
        result->partID, result->partINST, result->primID,
        result->partID + 25, result->partINST + 3, result->primID + 7);

    // Check if sscanf successfully parsed all expected values
    if (count != 6) {
        // If the count is not 6, the format was not as expected
        fprintf(stderr, "Error: Invalid format\n");
        return 0;
    }

    // Check for uniqueness of partINST and primID
    if (strcmp(result->partINST, result->partINST + 3) == 0 || strcmp(result->primID, result->primID + 7) == 0) {
        fprintf(stderr, "Error: Duplicate values found\n");
        return 0;
    }

    return 1; // Success
}

int main() {
    const char* input = "3024 P1 s1 = 3024 P2 c1;";
    ParsedInput result;

    if (myfunction(input, &result)) {
        printf("partID_1: %s\npartINST1: %s\nprimID1: %s\n\n", result.partID, result->partINST, result->primID);
        printf("partID_2: %s\npartINST2: %s\nprimID2: %s\n", result.partID + 25, result->partINST + 3, result->primID + 7);
    }

    return 0;
}
