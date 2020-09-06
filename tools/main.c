#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

uint8_t buffer[2][80][18][512];

/*
 * cylinder: [0-79]
 * head: [0-1]
 * sector: [1-18]
*/
void writeFloppy(int head, int cylinder, int sector, uint8_t *buf, int len) {
    sector = sector - 1;
    int count = 0;
    while (len > 0) {
        memcpy((void *)buffer[head][cylinder][sector], buf + 512 * count, len >= 512 ? 512 : len);
        count++;
        sector++;
        if (sector >= 17) {
            sector = 0;
            cylinder++;
        }
        if (cylinder >= 79) {
            cylinder = 0;
            head++;
        }
        if (head >= 2 && len > 0) {
            printf("insufficent disk");
            exit(0);
        }
        len -= 512;
    }
}

void makeFloppy(char *path, int isboot) {
    FILE *f = fopen(path, "w+");
    if (isboot) {
        buffer[0][0][0][510] = 0x55;
        buffer[0][0][0][511] = 0xaa;
    }
    int cylinder = 0;
    int head = 0;
    int sector = 0;
    for (cylinder = 0; cylinder < 80; cylinder++) {
        for (head = 0; head < 2; head++) {
            for (sector = 0; sector < 18; sector++) {
                fwrite(buffer[head][cylinder][sector], 1, 512, f);
            }
        }
    }
    fclose(f);
}

void loadData(char *path, void **p, int *plen) {
    FILE *f = fopen(path, "r");
    fseek(f, 0L, SEEK_END);
    *plen = ftell(f);
    *p = malloc(*plen);
    fseek(f, 0L, SEEK_SET);
    fread(*p, 1, *plen, f);
    fclose(f);
}

int main(int argc, char **argv) {
    void *buf = NULL;
    int len = 0;

    // write boot bin
    char *boot = "./data/boot.bin";
    loadData(boot, &buf, &len);
    writeFloppy(0, 0, 1, buf, len);

    // write kernel bin
    char *kernel = "./data/kernel.bin";
    loadData(kernel, &buf, &len);

    writeFloppy(0, 1, 2, buf, len);

    printf("kernel len: %d\n", len);
    printf("kernel section: %d\n", len / 512);

    makeFloppy("./data/system.img", 1);
}
