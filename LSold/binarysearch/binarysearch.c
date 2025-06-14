#include <stdio.h>          //file://C:/users/kris/desktop/binarysearch/mingw32/?/stdio.h
#include <string.h>         //file://C:/users/kris/desktop/binarysearch/mingw32/?/string.h
#include <stdlib.h>         //file://C:/users/kris/desktop/binarysearch/mingw32/?/stdlib.h
#include <time.h>           //file://C:/users/kris/desktop/binarysearch/mingw32/?/time.h
#include <unistd.h>         //file://C:/users/kris/desktop/binarysearch/mingw32/?/unistd.h
                               
//#include "C:\Users\kris\Desktop\binarysearch\_11010_11010.c"   //file://C:/Users/kris/Desktop/binarysearch/_11010_11010.c
//#include "C:\Users\kris\Desktop\binarysearch\_12825_12825.c"   //file://C:/Users/kris/Desktop/binarysearch/_12825_12825.c
//#include "C:\Users\kris\Desktop\binarysearch\_15070_15070.c"   //file://C:/Users/kris/Desktop/binarysearch/_15070_15070.c
//#include "C:\Users\kris\Desktop\binarysearch\_15712_15712.c"   //file://C:/Users/kris/Desktop/binarysearch/_15712_15712.c
//#include "C:\Users\kris\Desktop\binarysearch\_20482_20482.c"   //file://C:/Users/kris/Desktop/binarysearch/_20482_20482.c
//#include "C:\Users\kris\Desktop\binarysearch\_20952_20952.c"   //file://C:/Users/kris/Desktop/binarysearch/_20952_20952.c
//#include "C:\Users\kris\Desktop\binarysearch\_24246_24246.c"   //file://C:/Users/kris/Desktop/binarysearch/_24246_24246.c
//#include "C:\Users\kris\Desktop\binarysearch\_24866_24866.c"   //file://C:/Users/kris/Desktop/binarysearch/_24866_24866.c
//#include "C:\Users\kris\Desktop\binarysearch\_25269_25269.c"   //file://C:/Users/kris/Desktop/binarysearch/_25269_25269.c
//#include "C:\Users\kris\Desktop\binarysearch\_2555_2555.c"     //file://C:/Users/kris/Desktop/binarysearch/_2555_2555.c
//#include "C:\Users\kris\Desktop\binarysearch\_26047_26047.c"   //file://C:/Users/kris/Desktop/binarysearch/_26047_26047.c
//#include "C:\Users\kris\Desktop\binarysearch\_3024_3024.c"     //file://C:/Users/kris/Desktop/binarysearch/_3024_3024.c
//#include "C:\Users\kris\Desktop\binarysearch\_3070a_3070a.c"   //file://C:/Users/kris/Desktop/binarysearch/_3070a_3070a.c
//#include "C:\Users\kris\Desktop\binarysearch\_3070b_3070b.c"   //file://C:/Users/kris/Desktop/binarysearch/_3070b_3070b.c
//#include "C:\Users\kris\Desktop\binarysearch\_32607_32607.c"   //file://C:/Users/kris/Desktop/binarysearch/_32607_32607.c
//#include "C:\Users\kris\Desktop\binarysearch\_33286_33286.c"   //file://C:/Users/kris/Desktop/binarysearch/_33286_33286.c
//#include "C:\Users\kris\Desktop\binarysearch\_33291_33291.c"   //file://C:/Users/kris/Desktop/binarysearch/_33291_33291.c
//#include "C:\Users\kris\Desktop\binarysearch\_33492_33492.c"   //file://C:/Users/kris/Desktop/binarysearch/_33492_33492.c
//#include "C:\Users\kris\Desktop\binarysearch\_35394_35394.c"   //file://C:/Users/kris/Desktop/binarysearch/_35394_35394.c
//#include "C:\Users\kris\Desktop\binarysearch\_35463_35463.c"   //file://C:/Users/kris/Desktop/binarysearch/_35463_35463.c
//#include "C:\Users\kris\Desktop\binarysearch\_3614a_3614a.c"   //file://C:/Users/kris/Desktop/binarysearch/_3614a_3614a.c
//#include "C:\Users\kris\Desktop\binarysearch\_3661_3661.c"     //file://C:/Users/kris/Desktop/binarysearch/_3661_3661.c
//#include "C:\Users\kris\Desktop\binarysearch\_38799_38799.c"   //file://C:/Users/kris/Desktop/binarysearch/_38799_38799.c
//#include "C:\Users\kris\Desktop\binarysearch\_3960_3960.c"     //file://C:/Users/kris/Desktop/binarysearch/_3960_3960.c
//#include "C:\Users\kris\Desktop\binarysearch\_39739_39739.c"   //file://C:/Users/kris/Desktop/binarysearch/_39739_39739.c
//#include "C:\Users\kris\Desktop\binarysearch\_4081a_4081a.c"   //file://C:/Users/kris/Desktop/binarysearch/_4081a_4081a.c
//#include "C:\Users\kris\Desktop\binarysearch\_4081b_4081b.c"   //file://C:/Users/kris/Desktop/binarysearch/_4081b_4081b.c
//#include "C:\Users\kris\Desktop\binarysearch\_4085a_4085a.c"   //file://C:/Users/kris/Desktop/binarysearch/_4085a_4085a.c
//#include "C:\Users\kris\Desktop\binarysearch\_4085b_4085b.c"   //file://C:/Users/kris/Desktop/binarysearch/_4085b_4085b.c
//#include "C:\Users\kris\Desktop\binarysearch\_4085c_4085c.c"   //file://C:/Users/kris/Desktop/binarysearch/_4085c_4085c.c
//#include "C:\Users\kris\Desktop\binarysearch\_43898_43898.c"   //file://C:/Users/kris/Desktop/binarysearch/_43898_43898.c
//#include "C:\Users\kris\Desktop\binarysearch\_4740_4740.c"     //file://C:/Users/kris/Desktop/binarysearch/_4740_4740.c
//#include "C:\Users\kris\Desktop\binarysearch\_49668_49668.c"   //file://C:/Users/kris/Desktop/binarysearch/_49668_49668.c
//#include "C:\Users\kris\Desktop\binarysearch\_50018e_50018e.c" //file://C:/Users/kris/Desktop/binarysearch/_50018e_50018e.c
//#include "C:\Users\kris\Desktop\binarysearch\_52494_52494.c"   //file://C:/Users/kris/Desktop/binarysearch/_52494_52494.c
//#include "C:\Users\kris\Desktop\binarysearch\_6019_6019.c"     //file://C:/Users/kris/Desktop/binarysearch/_6019_6019.c
//#include "C:\Users\kris\Desktop\binarysearch\_60897_60897.c"   //file://C:/Users/kris/Desktop/binarysearch/_60897_60897.c
//#include "C:\Users\kris\Desktop\binarysearch\_61252_61252.c"   //file://C:/Users/kris/Desktop/binarysearch/_61252_61252.c
//#include "C:\Users\kris\Desktop\binarysearch\_6141_6141.c"     //file://C:/Users/kris/Desktop/binarysearch/_6141_6141.c
//#include "C:\Users\kris\Desktop\binarysearch\_65092_65092.c"   //file://C:/Users/kris/Desktop/binarysearch/_65092_65092.c
//#include "C:\Users\kris\Desktop\binarysearch\_6942_6942.c"     //file://C:/Users/kris/Desktop/binarysearch/_6942_6942.c
//#include "C:\Users\kris\Desktop\binarysearch\_72046_72046.c"   //file://C:/Users/kris/Desktop/binarysearch/_72046_72046.c
//#include "C:\Users\kris\Desktop\binarysearch\_72078_72078.c"   //file://C:/Users/kris/Desktop/binarysearch/_72078_72078.c
//#include "C:\Users\kris\Desktop\binarysearch\_78257_78257.c"   //file://C:/Users/kris/Desktop/binarysearch/_78257_78257.c
//#include "C:\Users\kris\Desktop\binarysearch\_85861_85861.c"   //file://C:/Users/kris/Desktop/binarysearch/_85861_85861.c
//#include "C:\Users\kris\Desktop\binarysearch\_85975_85975.c"   //file://C:/Users/kris/Desktop/binarysearch/_85975_85975.c
//#include "C:\Users\kris\Desktop\binarysearch\_86996_86996.c"   //file://C:/Users/kris/Desktop/binarysearch/_86996_86996.c
//#include "C:\Users\kris\Desktop\binarysearch\_90322_90322.c"   //file://C:/Users/kris/Desktop/binarysearch/_90322_90322.c
//#include "C:\Users\kris\Desktop\binarysearch\_93794_93794.c"   //file://C:/Users/kris/Desktop/binarysearch/_93794_93794.c
//#include "C:\Users\kris\Desktop\binarysearch\_98138_98138.c"   //file://C:/Users/kris/Desktop/binarysearch/_98138_98138.c
                               
#include "token.c"          //file://C:/users/kris/desktop/binarysearch/token.c


//#define _countof(a) (sizeof(a)/sizeof(*(a)))

#define DoBenchmark

#ifdef DoBenchmark
  #define _Benchmark iCount=0; while ((abs(clock()-ttime)<CLOCKS_PER_SEC) && ++iCount)
#else
  #define _Benchmark 
#endif

typedef struct {
    int group;
    const char* rule;
    const char* ldraw_output;
} Rule;

const Rule* ruleIdx[_countof(rules)];

//comparator function for qsort
int CompareRules( const void* pA , const void* pB ) {
	return strcmp( (*((const Rule**)pA))->rule , (*((const Rule**)pB))->rule );
}
void InitRules() {
	//set ptrs for each rules element at initial index
	for (int N=0 ; N<_countof(ruleIdx) ; N++ ) { ruleIdx[N]	= &rules[N]; }		
	qsort( ruleIdx , _countof(ruleIdx) , sizeof(void*) , CompareRules );
	printf("%i rules\n",_countof(ruleIdx));
}
const Rule* FindRule( char* pzRule ) {
	int iBegin = 0 , iEnd = _countof(ruleIdx);
	while (iEnd >= iBegin) {
		//try item from middle
		int idx = (iBegin+iEnd)/2;			
		const char* pzEntry = ruleIdx[idx]->rule;
		int iResu = strcmp( pzRule , pzEntry );
		if (!iResu) { return ruleIdx[idx]; } //found
		if (iBegin == iEnd) { return NULL; } //NOT found
		//remove the wrong half of possibilities		
		if (iResu>0) { iBegin= idx+1; } else { iEnd = idx-1; }		
	}
	return NULL; //NOT found
} 

void NormalizeInput( char* pzInput ) {	
	char WasSpace=1, *pOut = pzInput, C;
	while ((C=*pzInput++)) {
		switch (C) {
		case ' ' : case '\t' : case '\r' : case '\n' : 
		  if (!WasSpace) { *pOut++ = ' '; }
			WasSpace=1; break;
		default: 
		  *pOut++ = C; WasSpace=0;
		}
	}
	while (pOut[-1]==' ') { pOut--; }
	*pOut = '\0';	
}

int main() {

    InitRules();
    
    FILE *outputFile = fopen("output.ldr", "w"); // Open the file in write

    while (!feof(stdin)) {
        char userInput[100];

        printf("Enter a string (or 'exit' to quit): ");
        fgets(userInput, 100, stdin);
        userInput[strcspn(userInput, "\n")] = '\0';
				NormalizeInput( userInput );
				printf("'%s'\n",userInput);
				

        if (strcmp(userInput, "exit") == 0) {
            break;  // Exit the loop if the user types 'exit'
        }

				#ifdef DoBenchmark
				clock_t ttime = clock();
				long long iCount = 0;
				#endif				
				
				const Rule* pFound = NULL;									
				#if 1
					_Benchmark {
						pFound = FindRule( userInput );
					}
				#else
					_Benchmark {
						for (int N=0 ; N<_countof(rules) ; N++) {
							if (!strcmp(userInput , rules[N].rule)) {
								pFound = &rules[N]; break; 
							}							
						}						
					}
				#endif
				if (pFound) {
					printf("%s\n", pFound->ldraw_output);
					fprintf(outputFile, "%s\n\n", pFound->ldraw_output);
					if ( _execl("LDCAD32.exe","ldcad32","C:\\users\\kris\\desktop\\binarysearch\\output.ldr",NULL) == -1) {
						perror("_exec");
						exit(EXIT_FAILURE);
					}
				}
				else {
					printf("No match found.\n");
				}				
				
				#ifdef DoBenchmark
				printf("took %.05fms %lli/s\n",1000.0/iCount,iCount);
				#endif
				
    }

    fclose(outputFile); // Close the file

    return 0;
		
}