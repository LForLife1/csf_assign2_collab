#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "wcfuncs.h"

// Suggested number of buckets for the hash table
#define HASHTABLE_SIZE 13249

// prototypes for helper functions

void free_hashtable(struct WordEntry**, unsigned int);

int main(int argc, char **argv) {
  // stats (to be printed at end)
  uint32_t total_words = 0;
  uint32_t unique_words = 0;
  const unsigned char *best_word = (const unsigned char *) "";
  uint32_t best_word_count = 0;

  // get input file from argv
  if (argc != 2) { // one for default running program, another for text file name
    return -1; // incorrect number of elements
  }
  FILE* file = fopen(argv[1], "r");

  struct WordEntry* words_hashtable[HASHTABLE_SIZE];
  unsigned char word[MAX_WORDLEN];// = malloc(MAX_WORDLEN);
  
  // read every word of the file
  while (wc_readnext(file, word)) {
    total_words++;
    wc_tolower(word);
    wc_trim_non_alpha(word);

    struct WordEntry* entry = wc_dict_find_or_insert(words_hashtable, HASHTABLE_SIZE, word);
    if (entry->count == 0) {
      // if it was just created, it must be a new (unique) word
      unique_words++;
    }
    entry->count++;
  }  

  printf("Total words read: %u\n", (unsigned int) total_words);
  printf("Unique words read: %u\n", (unsigned int) unique_words);
  printf("Most frequent word: %s (%u)\n", (const char *) best_word, best_word_count);

  fclose(file); // close file
  free_hashtable(words_hashtable, HASHTABLE_SIZE); // free memory

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