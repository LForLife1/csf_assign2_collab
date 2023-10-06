/*
 * Assembly language function implementations
 */

#define MAX_WORDLEN 63

/*
 * Offsets for the fields of the struct WordEntry data type
 * (Note that there is 4 bytes of padding between the count and next
 * fields.)
 */
#define WORDENTRY_WORD_OFFSET   (0)
#define WORDENTRY_COUNT_OFFSET  (MAX_WORDLEN+1)
#define WORDENTRY_NEXT_OFFSET   (MAX_WORDLEN+1+4+4)
#define WORDENTRY_SIZE          (WORDENTRY_NEXT_OFFSET+8)

	.section .rodata
/* Define any string constants or read-only data here */

	.section .text

/*
 * Compute a hash code for the given NUL-terminated
 * character string.
 *
 * The hash algorithm should be implemented as follows:
 *
 * uint32_t hash_code = 5381
 * for each character c of w in order {
 *   hash_code = hash_code * 33 + c
 * }
 *
 * Note that the character values should be treated as
 * being unsigned (in the range 0..255)
 *
 * C function prototype:
 *    uint32_t wc_hash(const unsigned char *w);
 */
	.globl wc_hash
wc_hash:

    subq $8, %rsp 			/*Align the stack pointer.*/
	movq $5381, %r11		/* store hash in %r11 */

	.LhashCharLoop:
		movq $0, %r10		/* reset character value */
		movb (%rdi), %r10b	/* move current character value into %r10b */
		cmpb $0, %r10b		/* if at NUL terminator */
		je .LreturnHash		/* return current hash */

		imulq $33, %r11		/* multiply hash by 33 */
		addq %r10, %r11		/* + c */
		incq %rdi			/* proceed to next letter */
		jmp .LhashCharLoop

	.LreturnHash:
		movq %r11, %rax		/* store hash in return register */
		addq $8, %rsp /*Align the stack pointer.*/
		ret

/*
 * Compare two strings lexicographically. Return
 *
 * - a negative value if lhs string is less than rhs string
 * - 0 if lhs string is identical to rhs string
 * - a positive value if lhs string is greater than rhs string
 *
 * Lexicographical comparison is a generalization of alphabetical
 * order, but using character codes. If one string is a prefix
 * of the other, it is considered as "less than". E.g.,
 * "hi" would compare as less than "high".
 *
 * C function prototype:
 *    int wc_str_compare(const unsigned char *lhs, const unsigned char *rhs);
 */
	.globl wc_str_compare
wc_str_compare:
	/* INPUT PARAMETERS:   	lhs: Pointer to the first string into %rdi
							rhs: Pointer to da second string into %rsi */
    
	pushq %r12			/* store callee-saved register */
    pushq %r13			/* store callee-saved register */
    pushq %r14			/* store callee-saved register */
	movq $0, %rax		/* clear rax */
	
	.LcharsLoop:				/* looping until finding different character */

		movb (%rdi), %r12b			/* Put character from lhs into register */
    	movb (%rsi), %r13b			/* Put character from rhs into register */

		cmpb $0, %r12b				/* Check if lhs char is null */
		je .LlhsEnded				/* If it is, jump to lhsended */

		cmpb $0, %r13b				/* Check if rhs char (value at r13) is null */
		je .LposValue				/* Since this means rhs is longer with same prefix, return positive */

		cmpb %r12b, %r13b			/* Compare the actual (value of) characters */
		jne .LcompareChars			/* If non-zero, jump to compare */

		incq %rdi					/* Since same, increment pointerval of r12 */
		incq %rsi					/* Increment pointerval of r13 */
		jmp .LcharsLoop				/* Jump back to top of loop */
	
	.LlhsEnded:						/* if lhs ends */

		cmpb $0, %r13b				/* Check if next rhs character is null */
		je .Lequalstrings			/* If it is, move to equal strings */
			
		movl $-1, %eax				/* Otherwise lhs is shorter */
		jmp .Lreturn_strcomp

	.LposValue:						/* returning positive value */
		movl $1, %eax				/* move 1 to return*/
		jmp .Lreturn_strcomp

	.LcompareChars:					/* if strings have diff chars at a place */

		subb %r13b, %r12b			/* find the chars difference */
		jns .LposValue				/* if the subtraction ticks the NEGATIVE flag then rhs > lhs */

		movl $-1, %eax				/* otherwise return negative value because less than */
		jmp .Lreturn_strcomp

	.Lequalstrings:					/* if strings are the same */
		movl $0, %eax				/* move 0 to return for equal strings*/
	
	.Lreturn_strcomp:
	    popq %r14			/* restore callee-saved register */
    	popq %r13			/* restore callee-saved register */
		popq %r12			/* restore callee-saved register */
    	ret

/*
 * Copy NUL-terminated source string to the destination buffer.
 *
 * C function prototype:
 *    void wc_str_copy(unsigned char *dest, const unsigned char *source);
 */
	.globl wc_str_copy
wc_str_copy:
    pushq %r12			/* store callee-saved register */
    pushq %r13			/* store callee-saved register */
    pushq %r14			/* store callee-saved register */

	movq %rsi, %r12 		/* set %r12 to pointer to source start (argument 1) */
	movq %rdi, %r13 		/* set %r13 to pointer to destination start (argument 2) */
	
	.LNotAtEnd:
		movb (%r12), %r14b	/* move byte from source into r14b */
		movb %r14b, (%r13)	/* move byte from r14b into destination */
		incq %r12			/* increment pointer to source */
		incq %r13			/* increment pointer to destination */
		cmpb $0, %r14b		/* check if byte is null */
		jne .LNotAtEnd		/* if not null, continue copying */

    popq %r14			/* restore callee-saved register */
    popq %r13			/* restore callee-saved register */
    popq %r12			/* restore callee-saved register */
    ret

/*
 * Return 1 if the character code in c is a whitespace character,
 * false otherwise.
 *
 * For the purposes of this function, a whitespace character is one of
 *
 *   ' '
 *   '\t'
 *   '\r'
 *   '\n'
 *   '\f'
 *   '\v'
 *
 * C function prototype:
 *    int wc_isspace(unsigned char c);
 */
	.globl wc_isspace
wc_isspace:

    subq $8, %rsp 			/*Align the stack pointer.*/

    cmpq $32, %rdi 		/* Compare c to ' ' */
    je .Lis_space 		/* Jump if equal */

    cmpq $9 , %rdi  	/* Compare c to '\t' */
    je .Lis_space  		/* Jump if equal */

    cmpq $13, %rdi  	/* Compare c to '\r' */ 
    je .Lis_space  		/* Jump if equal */

    cmpq $10, %rdi  	/* Compare c to '\n' */
    je .Lis_space  		/* Jump if equal */

    cmpq $12, %rdi  	/* Compare c to '\f' */
    je .Lis_space  		/* Jump if equal */

    cmpq $11, %rdi  	/* Compare c to '\v' */
    je .Lis_space  		/* Jump if equal */

	/* Since c is not a whitespace character... */
	movl $0, %eax  	/* move 0 value to int sized return register */
	addq $8, %rsp 			/*Align the stack pointer.*/
	ret			 	/* return */

	.Lis_space:
	/* If c is a whitespace character... */
	movl $1, %eax	/* move 1 value to int sized return register */
	addq $8, %rsp 			/*Align the stack pointer.*/
	ret			 	/* return */

/*
 * Return 1 if the character code in c is an alphabetic character
 * ('A' through 'Z' or 'a' through 'z'), 0 otherwise.
 *
 * C function prototype:
 *    int wc_isalpha(unsigned char c);
 */
	.globl wc_isalpha
wc_isalpha:
	cmpb $65, %dil 				/* compare to A */
	jl .LoutOfCapitalRange 		/* if it's greater than or equal to A... */
	cmpb $90, %dil 				/* compare to Z */
	jg .LoutOfCapitalRange		/* if it's less than or equal to Z... */
	jmp .LisValid				/* it is valid */

	.LoutOfCapitalRange:		/* if it's not between A and Z, check between a and z*/
				
	cmpb $97, %dil				/* compare to a */
	jl .LisNotValid				/* if it's greater than or equal to a... */
	cmpb $122, %dil				/* compare to z */
	jg .LisNotValid				/* if it's less than or equal to z... */
	jmp .LisValid				/* it is valid */

	.LisNotValid:				/* if not valid */

		movl $0, %eax			/* return 0 for false */
		ret

	.LisValid:					/* if is valid */

	movl $1, %eax 				/* return 1 for true */
	ret

/*
 * Read the next word from given input stream, storing
 * the word in the array pointed-to by w. (This array should be
 * assumed to be MAX_WORDLEN+1 elements in size.) Return 1
 * if a word is read successfully, 0 otherwise.
 *
 * For the purposes of this function, a word is a sequence of
 * 1 or more non-whitespace characters.
 *
 * If a sequence of non-whitespace characters has more than
 * MAX_WORDLEN characters, then only the first MAX_WORDLEN
 * characters in the sequence should be stored in the array.
 *
 * C function prototype:
 *    int wc_readnext(FILE *in, unsigned char *w);
 */
	.globl wc_readnext
wc_readnext:
	subq $8, %rsp 			/* align stack */

	/* reserve callee saved registers */
	pushq %r12 				/* save %r12 */
	pushq %r13				/* save %r13 */
	pushq %r14				/* save %r14 */
	pushq %r15				/* save %r15 */

	movq %rdi, %r12 		/* store input file <first arg> in %r12 */
	movq %rsi, %r13			/* store destination pointer <second arg> in %r13 */
	movq $0, %r14			/* store char counter in %r14 */
	
	.LloopUntilEndWord:
		movq %r12, %rdi			/* move input file to %rdi */
		call fgetc				/* call fgetc to get next character */
		movq %rax, %r15			/* store char into %r15 temporarily */

		cmpb $-1, %r15b			/* compare char to -1 (EOF) */
		je .LEndWord			/* if char is EOF, jump to end of word */

		movq %r15, %rdi			/* move char to %rdi */
		call wc_isspace			/* call wc_isspace to check if char is whitespace */
		cmpb $0, %al			/* compare result to 0 */
		jne .LcheckHasStartedWord	/* if char is whitespace, jump to check if word has started */


		/* add character to word */
		movq %r15, (%r13)		/* move char to destination pointer */
		incq %r13				/* increment destination pointer */

		cmpq $MAX_WORDLEN, %r14	/* compare char counter to MAX_WORDLEN */
		je .LEndWord			/* if char counter is equal to MAX_WORDLEN, jump to end of word */
		incq %r14				/* increment char counter */
		
		jmp .LloopUntilEndWord	/* jump to beginning of loop */

	.LcheckHasStartedWord:
		cmpq $0, %r14			/* compare char counter to 0 */
		jg .LEndWord			/* if char counter is greater than 0, jump to end of word */
		jmp .LloopUntilEndWord	/* else new word hasn't started, continue*/

	/* ON REACHED END OF WORD */
	.LEndWord:
		cmpq $0, %r14				/* compare char counter to 0 */
		je .LdidntReadWord 			/* if char counter is equal to 0, jump to didn't read word */

		movq $0, (%r13)				/* add NUL terminator */
		movq $1, %rax				/* move 1 to %rax */
		jmp .Lreturn_rn				/* jump to return */

	.LdidntReadWord:
		movq $0, %rax				/* move 0 to %rax */
									/* fall through to return */

	.Lreturn_rn:
		popq %r15					/* pop values out in reverse order cause stack */
		popq %r14
		popq %r13
		popq %r12
		addq $8, %rsp				/* add 8 to stack pointer */
		ret	

/*
 * Convert the NUL-terminated character string in the array
 * pointed-to by w so that every letter is lower-case.
 *
 * C function prototype:
 *    void wc_tolower(unsigned char *w);
 */
    .globl wc_tolower
wc_tolower:
    pushq %rbx				/* save callee-saved register */
    movq %rdi, %rbx			/* store pointer to current char in %rbx */

    .LnextCharToLower:
        movq $0, %r11		/* reset character value */
        movb (%rbx), %r11b	/* put current character into %r11b */

        cmpb $0, %r11b
        je .LallCharactersLower	/* reached end of string, jump to return */

        movq %r11, %rdi		/* set argument for function call*/
        call wc_isalpha		/* check if %r11b is a character */
        cmpb $1, %al
        jne .LcharacterIsGood	/* the character is not valid. Jump to next character */

        /* to lower... */
        cmpb $90, %r11b 	/* compare with 'Z' */
        jg .LcharacterIsGood	/* the character is lowercase already. Jump to next character */
        addq $32, (%rbx)	/* convert to lowercase */

    .LcharacterIsGood:
        incq %rbx
        jmp .LnextCharToLower	/* jump to next character */

    .LallCharactersLower:
    popq %rbx				/* restore callee-saved register */
    ret

/*
 * Remove any non-alphaabetic characters from the end of the
 * NUL-terminated character string pointed-to by w.
 *
 * C function prototype:
 *    void wc_trim_non_alpha(unsigned char *w);
 */
	.globl wc_trim_non_alpha
wc_trim_non_alpha:
    pushq %rbx				/* save callee-saved register and align stack */
    movq %rdi, %rbx			/* store pointer to current char in %rbx */

    cmpq $0, %rdi			/* check if pointer is NULL*/
    je .Lreturn_tna				/* if so exit function */

    .LfindStringEnd:
        movb (%rbx), %r11b	/* load current char into %r11 */
        cmpb $0, %r11b			/* check if current char is null character */
        je .LloopbackAlpha		/* if so jump to .LloopbackAlpha */
        incq %rbx				/* increment pointer to next char */
        jmp .LfindStringEnd		/* jump to .LfindStringEnd */

    //backtrack to first alpha
    //we should use wc_isalpha to check if current char is alpha
    .LloopbackAlpha:
        cmpq %rdi, %rbx			/* check if pointer is at beginning of string */
        je .LhaveBackTrackedChar/* if it is, we have to move back to the beginning */

        movb (%rbx), %dil		/* move current chatacter into param for is_alpha */
        call wc_isalpha			/* call wc_isalpha to check if current char is alpha */

        cmpq $1, %rax			/* check if current char is alpha */
        je .LhaveBackTrackedChar/* if it is, we found our last character */

                                /* otherwise we have to keep moving back */
        decq %rbx				/* decrement pointer to previous char */
        jmp .LloopbackAlpha		/* jump to .LloopbackAlpha */

    .LhaveBackTrackedChar:
		movb (%rbx), %dil		/* move current character into param for is_alpha */
        call wc_isalpha			/* call wc_isalpha to check if current char is alpha */

        cmpq $1, %rax			/* check if current char is alpha */
        je .LsetNullCharPlusOne	/* if it is, set the next character to null */
        movb $0, (%rbx)			/* otherwise, set the current character to null */
        jmp .Lreturn_tna		/* jump to .Lreturn */

    .LsetNullCharPlusOne:
        addq $1, %rbx			/* increment pointer to next char */
        movb $0, (%rbx)			/* set the next character to null */
	
    .Lreturn_tna:
        popq %rbx				/* restore callee-saved register and restore stack */
        ret

/*
 * Search the specified linked list of WordEntry objects for an object
 * containing the specified string.
 *
 * If a matching object is found, set the int variable pointed-to by
 * inserted to 0 and return a pointer to the matching object.
 *
 * If a matching object is not found, allocate a new WordEntry object,
 * set its next pointer to point to what head points to (i.e., so the
 * new object is at the head of the list), set the variable pointed-to
 * by inserted to 1, and return a pointer to the new node. Note that
 * the new node should have its count value set to 0. (It is the caller's
 * job to update the count.)
 *
 * C function prototype:
 *    struct WordEntry *wc_find_or_insert(struct WordEntry *head, const unsigned char *s, int *inserted);
 */
	.globl wc_find_or_insert
wc_find_or_insert:

	/* save callee-saved register and align stack */
	pushq %r12							/* store value of head while we manipulate rbx */
	pushq %r13							/* store pointer to string to be inserted */
	pushq %r14							/* save %r14 */
	pushq %r15							/* save %r15 */
    pushq %rbx							/* stores value of current WordEntry object */	

	testq %rsi, %rsi					/* check if string is non-null */
	jz .Lnullval						/* if null, return null */		

	movq %rdi, %r12						/* move pointer to head into r12 */
	movq %rsi, %r13						/* move pointer to string to be inserted into r13 */
	movq %rdx, %r14
	movq %rdi, %rbx						/* save pointer to WordEntry object in rbx */

	//check if head is null
	cmpq $0, %rbx						/* check if head is null */
	je .Linsert							/* if null, insert new entry */

	.LfindIfInList:						/* find if the entry is already in the list */
		cmpq $0, %rbx					/* check if the current entry is null */
		je .Linsert						/* if null, insert new entry */

		leaq WORDENTRY_WORD_OFFSET(%rbx), %rdi		/* move pointer to current word in entry into rdi */
		movq %r13, %rsi								/* move pointer to word to be inserted into rsi */
		call wc_str_compare				/* compare the two words */
		cmpl $0, %eax					/* check if the words are equal */
		je .LobjFound					/* if equal, return the entry */

		movq WORDENTRY_NEXT_OFFSET(%rbx), %rbx	/* move pointer to next WordEntry object into rbx */
		jmp .LfindIfInList				/* move to next WordEntry */	

	.Linsert: 							/* inserting the value because not found */
		movq $WORDENTRY_SIZE, %rdi		/* move size of WordEntry object to rdi */
		call malloc						/* allocate memory for new WordEntry object */
		movq %rax, %rbx					/* move pointer to new WordEntry object to rbx */

		leaq WORDENTRY_WORD_OFFSET(%rbx), %rdi		/* move pointer to word in new WordEntry object into rdi */
		movq %r13, %rsi					/* move pointer to string to be inserted into rsi */
		call wc_str_copy				/* copy word to be inserted into new WordEntry object */

		leaq WORDENTRY_WORD_OFFSET(%rbx), %rdi		/* move pointer to word in new WordEntry object into rdi */
		movq $MAX_WORDLEN, %rcx						/* set rcx to MAX_WORDLEN */
		movb $0, (%rdi, %rcx)	
		movq $0, WORDENTRY_COUNT_OFFSET(%rbx)		/* make count 0 */

		movq %r12, WORDENTRY_NEXT_OFFSET(%rbx)		/* set next pointer to head */
		movq %rbx, %r12					/* set head to new WordEntry object */

		movl $1, (%r14)					/* store one in inserted */
		jmp .Lreturn					/* return the entry */

	.LobjFound:
		movq %rbx, %rax					/* move pointer to WordEntry object into rax */
		movl $0, (%r14)					/* store zero in inserted */
		jmp .Lreturn					/* return the entry */

	.Lnullval:
		movl $0, (%rdx)					/* store zero in inserted */
		movq $0, %rax					/* make rax null */

	.Lreturn:
		popq %rbx						/* restore callee-saved register */
		popq %r15						/* restore callee-saved register */
		popq %r14						/* restore callee-saved register */
		popq %r13						/* restore callee-saved register */
		popq %r12						/* restore callee-saved register */
		ret

/*
 * Find or insert the WordEntry object for the given string (s), returning
 * a pointer to it. The head of the linked list which contains (or should
 * contain) the entry for s is the element of buckets whose index is the
 * hash code of s mod num_buckets.
 *
 * Returns a pointer to the WordEntry object in the appropriate linked list
 * which represents s.
 *
 * C function prototype:
 *    struct WordEntry *wc_dict_find_or_insert(struct WordEntry *buckets[], unsigned num_buckets, const unsigned char *s);
 */
	.globl wc_dict_find_or_insert
wc_dict_find_or_insert:

	pushq %rbp
	movq %rsp, %rbp
	subq $16, %rbp
	pushq %r12							/* store callee-saved register */
	pushq %r13							/* store callee-saved register */
	pushq %r14							/* store callee-saved register */
	pushq %r15							/* store callee-saved register */
	pushq %rbx							/* store callee-saved register */

	cmpq $0, %rdi						/* check if buckets is null */
	je .Lreturn_dfi						/* if null, return null */

	movq %rdi, %r12						/* move pointer to buckets into r12 */
	movq %rsi, %r13						/* move num_buckets into r13 */
	movq %rdx, %r14						/* move pointer to string into r14 */	

	movq %r14, %rdi						/* move pointer to string into rdi */
	movq $0, %rax						/* move zero to rax */
	call wc_hash						/* call wc_hash to get hash code */

	.Lmoduloloop:						/* we leave when rax holds a value smaller than num__buckets */
		cmpq %rax, %r13					/* check if num_buckets is less than hash code */
		jge .Lmodulobreak				/* if less, break out of loop */
		subq %r13, %rax					/* subtract num_buckets from hash code */
		jmp .Lmoduloloop				/* loop again */

	.Lmodulobreak:						/* index is now correct */
		movq %rax, %r13					/* move index into r13 */
		movq (%r12, %r13, 8), %r12		/* move pointer to WordEntry object into r12 */
		movq %r12, %rdi					/* move pointer to WordEntry object into rdi */
		movq %r14, %rsi					/* move pointer to string into rsi */
		//TODO: GET INSERTED AND PASS ITS ADDRESS INTO RDX FOR THIS

		leaq 8(%rbp), %rdx
		call wc_find_or_insert			/* call wc_find_or_insert to find or insert the WordEntry object */

		/*  
		// If a new node was inserted, update the buckets array element
		int* inserted;
  		if (inserted) {
    		buckets[index] = word;
 		 }
  		return word; */

	.Lreturn_dfi:
		popq %rbx						/* restore callee-saved register */
		popq %r15						/* restore callee-saved register */
		popq %r14						/* restore callee-saved register */
		popq %r13						/* restore callee-saved register */
		popq %r12						/* restore callee-saved register */
		addq $16, %rbp
		popq %rbp
		ret

/*
 * Free all of the nodes in given linked list of WordEntry objects.
 *
 * C function prototype:
 *    void wc_free_chain(struct WordEntry *p);
 */
	.globl wc_free_chain
wc_free_chain:
	
	pushq %rbx							/* save callee-saved register, align stack*/
	movq %rdi, %rbx						/* move pointer to head into r10 */

	.LfreeLoop:
		cmpq $0, %rbx					/* check if current entry is null */
		je .LfreeReturn					/* if null, end of linked list so return */

		movq %rbx, %rdi					/* move pointer to current WordEntry object into rdi */
		movq WORDENTRY_NEXT_OFFSET(%rbx), %rbx		/* move pointer to next WordEntry object into rbx */
		call free						/* free current WordEntry object */
		jmp .LfreeLoop					/* move to next WordEntry object */

	.LfreeReturn:
		popq %rbx						/* restore callee-saved register */
		ret

/*
vim:ft=gas:
*/
