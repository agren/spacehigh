// Patch Space Invaders rom invaders.f using intel hex file spacehigh.ihx
// Mikael Ågren, 2011

#include <stdio.h>

int main(void) {
	const unsigned int romoffset=0x1000;
	unsigned int linelength;
	unsigned int lineoffset;
	unsigned int bytebuf;
	FILE *from;
	FILE *fpatch;
	fpatch = fopen("spacehigh.ihx", "r");
	from = fopen("invaders.f", "r+");

	int i;
	while(!feof(fpatch)) {
		fscanf(fpatch, ":%2x%4x00", &linelength, &lineoffset);
		if(linelength == 0) {
			break;
		}
		fseek(from, lineoffset-romoffset, SEEK_SET);
		for(i=0; i<linelength; i++) {
			fscanf(fpatch, "%2x", &bytebuf);
			fwrite(&bytebuf, 1, 1, from);
		}
		fscanf(fpatch, "%*s\n");

		printf("l %x, %x", linelength, lineoffset);
		printf("\n");
	}

	printf("\n");

	fclose(fpatch);
	fclose(from);
	return 0;
}
