// The MIT License (MIT)
//
// Copyright (c) 2017 Joao Pimentel <joaofelipenp at gmail dot com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h> // stat
#include <errno.h> 

#define MIN(x, y) (((x) < (y)) ? (x) : (y))

#if defined(__unix__) || defined(__APPLE__)         

#define OS_SEP_CH '/'
#define OS_SEP "/"
#define OTHER_OS_SEP_CH '\\'

#elif defined(_WIN32) || defined(WIN32) 

#define OS_SEP_CH '\\'
#define OS_SEP "\\"
#define OTHER_OS_SEP_CH '/'

#include <direct.h>   // _mkdir

#endif

typedef struct Archived {
    char *name;
    int name_length;
    int size;
    int offset;
    int key;
    unsigned char *content;
} Archived;

typedef struct List {
    Archived *item;
    struct List *next;
} List;


int isDirExist(const char *path) {
    #if defined(_WIN32)
        struct _stat info;
        if (_stat(path, &info) != 0) {
            return 0;
        }
        return (info.st_mode & _S_IFDIR) != 0;
    #else 
        struct stat info;
        if (stat(path, &info) != 0) {
            return 0;
        }
        return (info.st_mode & S_IFDIR) != 0;
    #endif
}

int get_path(const char *path, char *result) {
    char *pos = strrchr(path, '/');
    if (pos == NULL)
        #if defined(_WIN32)
            pos = strrchr(path, '\\');
            if (pos == NULL)
        #endif
        {
            result[0] = '.';
            result[1] = '\n';
            return 0;
        }
    strncpy(result, path, pos - path);
    result[pos - path] = '\0';
    return 1;
}

int makePath(const char *path) {
    #if defined(_WIN32)
        int ret = _mkdir(path);
    #else
        mode_t mode = 0755;
        int ret = mkdir(path, mode);
    #endif
    if (ret == 0)
        return 1;
    switch (errno)
    {
    case ENOENT:
        // parent didn't exist, try to create it
        {
            char new_path[1024];
            if (!get_path(path, new_path)) {
                return 0;
            }
            if (!makePath(new_path))
                return 0;
        }
        // now, try to create again
        #if defined(_WIN32)
            return 0 == _mkdir(path);
        #else 
            return 0 == mkdir(path, mode);
        #endif
    case EEXIST:
        // done!
        return isDirExist(path);

    default:
        return 0;
    }
}

int readline(FILE *f, char *buffer, size_t len) {
    char c; 
    int i;

    memset(buffer, 0, len);

    for (i = 0; i < len; i++) {   
        int c = fgetc(f); 

        if (!feof(f))  {   
            if (c == '\r') {
                buffer[i] = 0;
            } else if (c == '\n') {   
                buffer[i] = 0;
                return i + 1;
            } else {
                buffer[i] = c; 
            }
        } else {   
            return -1; 
        }
    }   
    return -1; 
}

void upstr(char * temp) {
    char *s = temp;
    for(; *s; s++) {
        *s = toupper((unsigned char) *s);
    }
}

void filename(char *original, char *result) {
    char *s = original;
    int index = 0;
    for(; *s; s++) {
        if ((*s == '/') || (*s == '\\')) {
            index = -1;
        } else {
            result[index] = *s;
        }
        index++;
    }
    result[index] = '\0';
}

void replace_sep(char *path) {
    char *s = path;
    for(; *s; s++) {
        if (*s == OTHER_OS_SEP_CH) {
            *s = OS_SEP_CH; 
        }
    }
}

int invalid_header(FILE *rgssad) {
    char header[8];
    fseek(rgssad, 0, SEEK_SET);
    fread(header, sizeof(char), 8, rgssad);
    if (header[0] != 'R') return 1;
    if (header[1] != 'G') return 1;
    if (header[2] != 'S') return 1;
    if (header[3] != 'S') return 1;
    if (header[4] != 'A') return 1;
    if (header[5] != 'D') return 1;
    if (header[6] != 0) return 1;
    if (header[7] != 1) return 1;
    return 0;
}

void write_header(FILE *rgssad) {
    fputc('R', rgssad);
    fputc('G', rgssad);
    fputc('S', rgssad);
    fputc('S', rgssad);
    fputc('A', rgssad);
    fputc('D', rgssad);
    fputc(0, rgssad);
    fputc(1, rgssad);
}

int read_little_endian(FILE *rgssad) {
    unsigned char bytes[4];
    fread(bytes, 4, 1, rgssad);
    return bytes[0] | (bytes[1]<<8) | (bytes[2]<<16) | ((unsigned) bytes[3]<<24);
}

int read_int(FILE *rgssad, int *key) {
    int value = read_little_endian(rgssad); // Force little endian
    int result = value ^ *key;
    *key *= 7;
    *key += 3;
    return result;
}

void write_int(FILE *rgssad, int *key, int value) {
    value = value ^ *key;
    *key *= 7;
    *key += 3;
    unsigned char bytes[4];
    bytes[0] = (value >> 0) & 0xFF;
    bytes[1] = (value >> 8) & 0xFF;
    bytes[2] = (value >> 16) & 0xFF;
    bytes[3] = (value >> 24) & 0xFF;
    fwrite(bytes, sizeof(unsigned char), 4, rgssad);
}

void read_str(FILE *rgssad, int *key, int length, char *result) {
    int i = 0;
    for (;i < length; i++) {
        char letter;
        fread(&letter, 1, 1, rgssad);
        result[i] = letter ^ (*key & 0xFF);
        *key *= 7;
        *key += 3;
    }
}

void write_str(FILE *rgssad, int *key, int length, char *text) {
    int i = 0;
    for (;i < length; i++) {
        char letter = text[i] ^ (*key & 0xFF);
        fwrite(&letter, 1, 1, rgssad);
        *key *= 7;
        *key += 3;
    }
}

void read_content(FILE *rgssad, int size, unsigned char *content) {
    int index = 0;
    while (index < size) {
        int count = MIN(256, size - index);
        int result = fread(content + index, 1, count, rgssad);
        index += count;
    }
}

Archived *read_archived(FILE *rgssad, int *key) {
    Archived *result = (Archived *) malloc(sizeof(Archived));
    result->name_length = read_int(rgssad, key);
    result->name = (char *) malloc(sizeof(char) * (result->name_length + 1));
    result->name[result->name_length] = '\0';
    read_str(rgssad, key, result->name_length, result->name);
    result->size = read_int(rgssad, key);
    result->offset = ftell(rgssad);
    result->key = *key;
    result->content = (unsigned char *) malloc(sizeof(unsigned char) * result->size);
    read_content(rgssad, result->size, result->content);
    return result;
}

void free_archived(Archived *arc) {
    if (arc != NULL) {
        free(arc->name);
        free(arc->content);
        free(arc);
    }
}

List *new_item(Archived *item, List *next) {
    List *result = (List *) malloc(sizeof(List));
    result->item = item;
    result->next = next;
    return result;
}

void free_list(List *list){
    if (list != NULL){
        free_list(list->next);
        free_archived(list->item);
        free(list);
    }
}

List *read_rgssad(char *input) {
    FILE *rgssad = fopen(input, "rb");
    if (rgssad == NULL) {
        printf("Error! Could not open file '%s'\n", input);
        return NULL;
    }
    fseek(rgssad, 0L, SEEK_END);
    size_t file_size = ftell(rgssad);
    if (invalid_header(rgssad)) {
        printf("Error! Invalid rgssad file '%s'\n", input);
        fclose(rgssad);
        return NULL;
    }
    
    int key = 0xDEADCAFE;
    List *list = new_item(NULL, NULL);
    List *last = list;

    while (ftell(rgssad) != file_size) {
        last->next = new_item(read_archived(rgssad, &key), NULL);
        last = last->next;
    }
    fclose(rgssad);
    return list;
}

int crypt(int key, int size, unsigned char *content, FILE *outcontent) {
    unsigned char key_bytes[4];
    key_bytes[0] = (key >> 0) & 0xFF;
    key_bytes[1] = (key >> 8) & 0xFF;
    key_bytes[2] = (key >> 16) & 0xFF;
    key_bytes[3] = (key >> 24) & 0xFF;

    int j = 0, i = 0;
    unsigned char letter = '\0';
    for(;i < size; i++) {
        letter = content[i];
        if (j == 4) {
            j = 0;
            key *= 7;
            key += 3;
            key_bytes[0] = (key >> 0) & 0xFF;
            key_bytes[1] = (key >> 8) & 0xFF;
            key_bytes[2] = (key >> 16) & 0xFF;
            key_bytes[3] = (key >> 24) & 0xFF;
        }
        fputc(letter ^ key_bytes[j], outcontent);
        j += 1;
    }
}

int copy_content(int size, unsigned char *content, FILE *outcontent) {
    int i = 0;
    for(;i < size; i++) {
        fputc(content[i], outcontent);
    }
}

int write_file_archive(FILE *rgssad, int *key, char *name, char *path, size_t check_size) {
    FILE *arc = fopen(path, "rb");
    if (arc == NULL) {
        return 1;
    }
    fseek(arc, 0L, SEEK_END);
    size_t file_size = ftell(arc);
    fseek(arc, 0L, SEEK_SET);
    if ((check_size > 0) && (check_size != file_size)) {
        fclose(arc);
        return 2;
    }

    unsigned char *content = (unsigned char *) malloc(sizeof(unsigned char) * file_size);
    read_content(arc, file_size, content);

    int name_size = strlen(name);

    write_int(rgssad, key, name_size);
    write_str(rgssad, key, name_size, name);
    write_int(rgssad, key, file_size);
    crypt(*key, file_size, content, rgssad);
    
    fclose(arc);
    free(content);

    return 0;
}

int patch(char *patchdir, char *input, char *output) {
    printf("Applying Patch:\n");
    printf("  Patch: %s\n", patchdir);
    printf("  Input: %s\n", input);
    printf("  Output: %s\n", output);
    
    List *list = read_rgssad(input);
    if (list == NULL) return 1;

    char path[1024];
    char dir[1024];

    get_path(output, dir);
    makePath(dir);
    FILE *rgssad = fopen(output, "wb");
    if (rgssad == NULL) {
        printf("Error! Could not open file '%s'\n", output);
        free_list(list);
        return 1;
    }
    
    int key = 0xDEADCAFE;
    int fast_patch = 1;
    write_header(rgssad);

    List *current = list->next;
    
    for (;current != NULL; current = current->next){
        strcpy(path, patchdir);
        strcat(path, OS_SEP);
        strcat(path, current->item->name);
        replace_sep(path);
        if (fast_patch) {
            int status = write_file_archive(rgssad, &key, current->item->name, path, current->item->size);
            if (status == 2) {
                printf("Warning: Fast patch failed for file '%s'\n", path);
                printf("  File should have size %d\n", current->item->size);
                printf("  Applying full patch\n");
                fast_patch = 0;
                write_file_archive(rgssad, &key, current->item->name, path, -1);
            } else if (status == 1) {
                write_int(rgssad, &key, current->item->name_length);
                write_str(rgssad, &key, current->item->name_length, current->item->name);
                write_int(rgssad, &key, current->item->size);
                copy_content(current->item->size, current->item->content, rgssad);
            } else {
                printf("Patching file '%s'\n", path);
            }
        } else {
            int status = write_file_archive(rgssad, &key, current->item->name, path, -1);
            if (status == 1) {
                FILE *arc = fopen("tempunpack.bin", "wb");
                if (arc == NULL) {
                    printf("Error! Could not open file '%s'\n", "tempunpack.bin");
                    fast_patch = 2;
                    break;
                } 
                crypt(current->item->key, current->item->size, current->item->content, arc);
                fclose(arc);
                write_file_archive(rgssad, &key, current->item->name, "tempunpack.bin", -1);
                remove("tempunpack.bin");
            } else {
                printf("Patching file '%s'\n", path);
            }
        }
    }
    fclose(rgssad);
    free_list(list);

    if (fast_patch == 0) {
        printf("Warning! Due to full patch, the resulting file may be very different from the original.\n");
    } else if (fast_patch == 2) {
        printf("Error! Could not open temporary file during full patch.\n");
        return 1;
    }
    return 0;
}

int enc(char *input, char *output) {
    printf("Encrypting directory:\n");
    printf("  Input: %s\n", input);
    printf("  Output: %s\n", output);
    char line[1024];
    char path[1024];
    char dir[1024];

    strcpy(path, input);
    strcat(path, OS_SEP);
    strcat(path, "order.txt");
    replace_sep(path);
    FILE *namelist = fopen(path, "r");
    if (namelist == NULL) {
        printf("Error! Could not open file '%s'\n", path);
        return 1;
    }

    get_path(output, dir);
    makePath(dir);
    FILE *rgssad = fopen(output, "wb");
    if (rgssad == NULL) {
        printf("Error! Could not open file '%s'\n", output);
        fclose(namelist);
        return 1;
    }

    int key = 0xDEADCAFE;
    write_header(rgssad);

    int failed = 0;
    while (readline(namelist, line, 1024) != -1) {
        strcpy(path, input);
        strcat(path, OS_SEP);
        strcat(path, line);
        replace_sep(path);
        printf("Reading file %s\n", path);
        if (write_file_archive(rgssad, &key, line, path, -1) != 0){
            printf("Error! Could not open file '%s'\n", path);
            failed = 1;
            break;
        }
    }

    fclose(rgssad);
    fclose(namelist);

    if (failed) {
        return 1;
    }

    return 0;
}

int dec(char *input, char *output) {
    printf("Decrypting file:\n");
    printf("  Input: %s\n", input);
    printf("  Output: %s\n", output);

    List *list = read_rgssad(input);
    if (list == NULL) return 1;

    List *current = list->next;
    
    char path[1024];
    char dir[1024];
    strcpy(path, output);
    strcat(path, OS_SEP);
    strcat(path, "order.txt");
    replace_sep(path);
    get_path(path, dir);
    makePath(dir);
    FILE *namelist = fopen(path, "w");
    if (namelist == NULL) {
        printf("Error! Could not open file '%s'\n", path);
        free_list(list);
        return 1;
    }

    int incomplete = 0;
    for (;current != NULL; current = current->next){
        strcpy(path, output);
        strcat(path, OS_SEP);
        strcat(path, current->item->name);
        replace_sep(path);
        get_path(path, dir);
        makePath(dir);
        printf("Writting file: %s\n", path);
        FILE *arc = fopen(path, "wb");
        if (arc == NULL) {
            printf("Warning! Could not open file '%s'. Skipping\n", path);
            incomplete = 1;
        } else {
            crypt(current->item->key, current->item->size, current->item->content, arc);
            fclose(arc);
        }
        fprintf(namelist, "%s\n", current->item->name);
    }
    fclose(namelist);

    free_list(list);

    if (incomplete) {
        printf("Warning! Some files could not be decrypted!\n");
        return 1;
    }
    
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc == 1) {
        return patch(".", "Engine.rgssad", "Engine.rgssad");
    }
    upstr(argv[1]);
    if (strcmp(argv[1], "PATCH") == 0) {
        char *patchdir = (argc < 3) ? "." : argv[2];
        char *input = (argc < 4) ? "Engine.rgssad" : argv[3];
        char *output = (argc < 5) ? input : argv[4];
        return patch(patchdir, input, output);
    } else if (strcmp(argv[1], "ENC") == 0) {
        char *input = (argc < 3) ? "." : argv[2];
        char *output = (argc < 4) ? "Engine.rgssad" : argv[3];
        return enc(input, output);
    } else if (strcmp(argv[1], "DEC") == 0) {
        char *input = (argc < 3) ? "Engine.rgssad" : argv[2];
        char *output = (argc < 4) ? "." : argv[3];
        return dec(input, output);
    } else if ((strcmp(argv[1], "HELP") == 0) || (strcmp(argv[1], "-H") == 0)
               || (strcmp(argv[1], "\\H") == 0)) {
        filename(argv[0], argv[0]);
        printf("Patch\\Decrypt\\Encrypt *.rgssad from RMXP\n");
        printf("usage:\n\n");
        printf("For patching:\n");
        printf("%s patch [PATCH_DIR] [SOURCE_FILE] [TARGET_FILE]\n", argv[0]);
        printf("  default:\n");
        printf("    PATCH_DIR: '.'\n");
        printf("    SOURCE_FILE: 'Engine.rgssad'\n");
        printf("    TARGET_FILE: SOURCE_FILE\n");
        printf("\n");
        printf("For encrypting:\n");
        printf("%s enc [SOURCE_DIR] [TARGET_FILE]\n", argv[0]);
        printf("  default:\n");
        printf("    SOURCE_DIR: '.'\n");
        printf("    TARGET_FILE: 'Engine.rgssad'\n");
        printf("\n");
        printf("For decrypting:\n");
        printf("%s dec [SOURCE_FILE] [TARGET_DIR]\n", argv[0]);
        printf("  default:\n");
        printf("    SOURCE_FILE: 'Engine.rgssad'\n");
        printf("    TARGET_DIR: '.'\n");

    }
    return 0;
}