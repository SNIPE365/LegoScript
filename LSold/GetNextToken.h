char *GetNextToken(char **Buffer) {
    char *token = NULL;
    while (**Buffer != '\0') {
        // Skip leading whitespace characters
        while (**Buffer == ' ' || **Buffer == '\t' || **Buffer == '\n') {
            (*Buffer)++;
        }
        if (**Buffer == '\0') {
            break;  // Reached the end of the buffer
        }

        // Calculate the length of the token
        char *start = *Buffer;
        while (**Buffer != ' ' && **Buffer != '\t' && **Buffer != '\n' && **Buffer != '\0') {
            (*Buffer)++;
        }

        // Allocate memory for the token and copy it
        int tokenLength = *Buffer - start;
        token = (char *)malloc(tokenLength + 1);
        if (token == NULL) {
            perror("Error allocating memory");
            exit(1);
        }
        strncpy(token, start, tokenLength);
        token[tokenLength] = '\0';

        // Return the token
        return token;
    }

    return NULL;  // No more tokens
}