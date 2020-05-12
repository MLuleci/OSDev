#include <string.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    // Default parameters
    int nblock = 1;
    int nsize = 512;
    char val = 0;
    char *fname = "out.bin";

    // Parse arguments
    for (int i = 1; i < argc; ++i) {
        if (argv[i][0] == '-') { // Argument is a flag
            switch (argv[i][1]) {
                case 'c':
                    nblock = atoi(argv[++i]);
                    break;
                case 's':
                    nsize = atoi(argv[++i]);
                    break;
                case 'h':
                    printf("Usage: %s [-cs] [filename]\n" \
                           "Default filename is \"out.bin\"\n" \
                           "\t-c\t# of blocks to output (default 1)\n" \
                           "\t-s\tbytes per block (default 512)\n", argv[0]);
                    return 0;
                default:
                    fprintf(stderr, "Unrecognized flag \"%s\" ignored\n", argv[i]);
                    break;
            }
        } else { // Not a flag (and not skipped), assume filename
            fname = argv[i];
        }
    }

    // Create file
    FILE *ofd = fopen(fname, "w");
    if (!ofd) {
        fprintf(stderr, "Unable to open \"%s\"\n", fname);
        return 1;
    }

    // Create buffer
    char *buff = (char*) malloc(nsize);
    if (!buff) {
        fprintf(stderr, "Not enough memory\n");
        fclose(ofd);
        return 1;
    }

    for (int i = 0; i < nblock; ++i) {
        memset(buff, val, nsize);
        fwrite(buff, 1, nsize, ofd);
        val++;
    }

    free(buff);
    fclose(ofd);
    return 0;
}