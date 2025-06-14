void LoadFileContents(const char *FileName, char **DynamicBufferName) {
    FILE *file = OpenFile(FileName, "r");
    if (file == NULL) {
        perror("Error opening file");
        exit(1);
    }

    // Find the size of the file
    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    fseek(file, 0, SEEK_SET);

    // Allocate memory for the buffer
    *DynamicBufferName = (char *)malloc(file_size + 1);
    if (*DynamicBufferName == NULL) {
        perror("Error allocating memory");
        exit(1);
    }

    // Read the file into the buffer
    fread(*DynamicBufferName, sizeof(char), file_size, file);
    (*DynamicBufferName)[file_size] = '\0'; // Null-terminate the string

    // Close the file
    fclose(file);
}