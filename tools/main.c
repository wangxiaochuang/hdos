#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

uint8_t buffer[2 * 18 * 512 * 80 ] = {0};

/*
 * cylinder: [0-79]
 * head: [0-1]
 * sector: [1-18]
*/
void writeFloppy(int head, int cylinder, int sector, uint8_t *buf, int len) {
    int from = cylinder * 18 * 512 * 2 + head * (18 * 512) + (sector - 1) * 512;
    uint8_t *p = buffer + from;
    memcpy(p, buf, len);
}

void makeFloppy(char *path) {
    FILE *f = fopen(path, "w+");
    buffer[510] = 0x55;
    buffer[511] = 0xaa;
    fwrite(buffer, 1, sizeof(buffer), f);
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

    makeFloppy("./data/system.img");
}
