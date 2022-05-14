#include <stdio.h>

extern char * hello();

int main() {
	printf("%s", hello());
	
	return 0;
}