#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "wcfuncs.h"

// Suggested number of buckets for the hash table
#define HASHTABLE_SIZE 13249

// prototypes for helper functions

//One situation that could arise is that there could be multiple WordEntry objects that are tied 
//for the highest occurrence count. In this case, choose the candidate (among the words with the
// highest occurrence count) that compares as least lexicographically as the one to display when
// the summary stats are printed. You can use the wc_str_compare function to do lexicographical comparisons of strings.

//Error handling: if there is a command line argument specifying the name of an input file, but the named 
//file can’t be opened, the program should print an error message to stderr and exit with a non-zero exit code. 
//If the program executes successfully, it should exit with exit code zero.

void free_hashtable(struct WordEntry**, unsigned int);

int main(int argc, char **argv) {

  // stats (to be printed at end)
  uint32_t total_words = 0;
  uint32_t unique_words = 0;
  const unsigned char *best_word = (const unsigned char *) "";
  uint32_t best_word_count = 0;

  // get input file from argv
  if (argc != 2) { return -1; } // incorrect number of arguments

  FILE* file = fopen(argv[1], "r");

  struct WordEntry* words_hashtable[HASHTABLE_SIZE]; //hashtable of words
  unsigned char word[MAX_WORDLEN];
  
  while (wc_readnext(file, word)) { //while we successfully keep reading new words
    total_words++;                  //increment total num of words
    wc_tolower(word);               //make word lowercase
    wc_trim_non_alpha(word);        //make only alphabet characters

    struct WordEntry* entry = wc_dict_find_or_insert(words_hashtable, HASHTABLE_SIZE, word);  //find or insert word
    if (entry->count == 0) {  // if it was just created, it must be a new (unique) word
      unique_words++;
    }
    entry->count++;           //either way, increment the count of that word

    if (entry->count > best_word_count || wc_str_compare(word, best_word) < 0) //update most frequent word if necessary
    {
      best_word = word;
      best_word_count = entry->count;
    }
    
  }  

  printf("Total words read: %u\n", (unsigned int) total_words);
  printf("Unique words read: %u\n", (unsigned int) unique_words);
  printf("Most frequent word: %s (%u)\n", (const char *) best_word, best_word_count);

  fclose(file);                                     // close file
  free_hashtable(words_hashtable, HASHTABLE_SIZE);  // free memory

  return 0;
}

// definitions of helper functions

void free_hashtable(struct WordEntry** hashtable, unsigned int buckets) {
  // parent pointer is on stack like a basic array
  // each element of array is a malloc'd pointer to the head of a linked list
  // so all that needs to be done is to free each linked list in the array
  for (unsigned int i = 0; i < buckets; i++) {
    wc_free_chain(hashtable[i]);
  }
}