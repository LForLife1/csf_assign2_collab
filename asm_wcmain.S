/*
 * Assembly language main function implementation
 */

#define MAX_WORDLEN 63

	.section .text

	.globl main
main:
	subq $8, %rsp
	pushq %r10				/* total words count */
	pushq %r11				/* unique words count */
	pushq %r12				/* best word pointer */
	pushq %r13				/* best word count */
	pushq %r14				/* file pointer */
	pushq %r15				/* words hashtable */

	cmpq $2, %rdi			/* if two arguements */
	je .LopenFileNormal

	.LopenFileNormal:
	movq $16, %rdi					/* malloc 16 bytes (8 -> r, 8 -> NUL */
	call malloc
	leaq (%rsi, $1, $8) %rdi		/* load pointer to second element in argv */
	movq $114, (%rax)				/* set "r" for reading*/
	incq %rax
	movq $0, (%rax)
	movq %rax, %rsi					/* store new pointer of str literal as 2nd arg */
	call fopen
	

	ret

/*
vim:ft=gas:
*/
