// Important: do not add any additional #include directives!
// The only C library functions that may be used are
//
// - fgetc
// - malloc
// - free

#include <stdlib.h>
#include "wcfuncs.h"

// Compute a hash code for the given NUL-terminated
// character string.
//
// The hash algorithm should be implemented as follows:
//
// uint32_t hash_code = 5381
// for each character c of w in order {
//   hash_code = hash_code * 33 + c
// }
//
// Note that the character values should be treated as
// being unsigned (in the range 0..255)
uint32_t wc_hash(const unsigned char *w)
{
  uint32_t hash_code = 5381;
  while (*w != '\0')
  {
    hash_code = hash_code * 33 + *w;
    w++;
  }
  return hash_code;
}

// Compare two strings lexicographically. Return
//
// - a negative value if lhs string is less than rhs string
// - 0 if lhs string is identical to rhs string
// - a positive value if lhs string is greater than rhs string
//
// Lexicographical comparison is a generalization of alphabetical
// order, but using character codes. If one string is a prefix
// of the other, it is considered as "less than". E.g.,
// "hi" would compare as less than "high".
int wc_str_compare(const unsigned char *lhs, const unsigned char *rhs)
{
  unsigned char cLHS, cRHS;
  do
  {
    cLHS = (unsigned char)*lhs++;
    cRHS = (unsigned char)*rhs++;
    if (cLHS == '\0')
    {
      return cLHS - cRHS;
    } // if there is no next char to be read in lhs
  } while (cLHS == cRHS);

  return cLHS - cRHS;
}

// Copy NUL-terminated source string to the destination buffer.
void wc_str_copy(unsigned char *dest, const unsigned char *source)
{
  if (source == NULL) { return; }
  int numCopied = 0;
  while (*source != '\0' && numCopied < MAX_WORDLEN)
  {
    *dest = *source;
    source++;
    dest++;
    numCopied++;
  }
  *dest = '\0';
}

// Return 1 if the character code in c is a whitespace character,
// false otherwise.
//
// For the purposes of this function, a whitespace character is one of
//
//   ' '
//   '\t'
//   '\r'
//   '\n'
//   '\f'
//   '\v'
int wc_isspace(unsigned char c)
{
  return (c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\f' || c == '\v');
}

// Return 1 if the character code in c is an alphabetic character
// ('A' through 'Z' or 'a' through 'z'), 0 otherwise.
int wc_isalpha(unsigned char c)
{
  return ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'));
}

// Read the next word from given input stream, storing
// the word in the array pointed-to by w. (This array should be
// assumed to be MAX_WORDLEN+1 elements in size.) Return 1
// if a word is read successfully, 0 otherwise.
//
// For the purposes of this function, a word is a sequence of
// 1 or more non-whitespace characters.
//
// If a sequence of non-whitespace characters has more than
// MAX_WORDLEN characters, then only the first MAX_WORDLEN
// characters in the sequence should be stored in the array.
int wc_readnext(FILE *in, unsigned char *w)
{
  int numChars = 0; //make sure stay under MAX_WORDLEN
  int c; //used to check if EOF
  while ((c = fgetc(in)) != EOF)
  {
    if (wc_isspace(c) == 0) //is not whitespace
    {
      if (numChars < MAX_WORDLEN) //is within MAX_WORDLEN
      {
        w[numChars] = (unsigned char) c;
        numChars++;
      }
    }
    else //is whitespace, either continue to first non-whitespace or end if it is last
    {
      if (numChars > 0)
      {
        w[numChars] = '\0';
        return 1;
      }
    }
  }

  if (numChars > 0) //check if word was read
  {
    w[numChars] = '\0';
    return 1;
  }

  return 0; //didn't read
}

// Convert the NUL-terminated character string in the array
// pointed-to by w so that every letter is lower-case.
void wc_tolower(unsigned char *w)
{
  if (w == NULL) { return; }
  while (*w != '\0') // null terminated
  { 
    if (wc_isalpha(*w) && (*w >= 'A' && *w <= 'Z'))
    {
      *w = *w + 32; // add 32 to make lowercase
    }
    w++; // next character in string
  }
}

// Remove any non-alphaabetic characters from the end of the
// NUL-terminated character string pointed-to by w.
void wc_trim_non_alpha(unsigned char *w)
{
  if (w == NULL || *w == '\0')
  {
    return;
  }
  unsigned char *end = w;
  while (*end != '\0')
  {
    end++;
  } // at this point w points to null character, backtrack to first alpha
  while (w < end && !wc_isalpha(*end))
  {
    end--;
  }
  if (wc_isalpha(*end))
  {
    *(end + 1) = '\0';
  } else {
    *end = '\0';
  }
}

// Search the specified linked list of WordEntry objects for an object
// containing the specified string.
//
// If a matching object is found, set the int variable pointed-to by
// inserted to 0 and return a pointer to the matching object.
//
// If a matching object is not found, allocate a new WordEntry object,
// set its next pointer to point to what head points to (i.e., so the
// new object is at the head of the list), set the variable pointed-to
// by inserted to 1, and return a pointer to the new node. Note that
// the new node should have its count value set to 0. (It is the caller's
// job to update the count.)
struct WordEntry *wc_find_or_insert(struct WordEntry *head, const unsigned char *s, int *inserted)
{
  if (s == NULL) { return NULL; } // make sure we are inserting something

  struct WordEntry *current = head;

  // find if already in list
  while (current != NULL)
  {
    if (wc_str_compare(current->word, (const unsigned char *)s) == 0)
    {
      *inserted = 0;
      return current;
    }
    current = current->next;
  }

  // append if not
  struct WordEntry *newEntry = malloc(sizeof(struct WordEntry));

  wc_str_copy((unsigned char *)newEntry->word, (const unsigned char *)s);
  newEntry->word[MAX_WORDLEN] = '\0'; // guarentee that string ends with null terminator
  newEntry->count = 0;

  newEntry->next = head;
  head = newEntry;

  *inserted = 1;
  return newEntry;
}

// Find or insert the WordEntry object for the given string (s), returning
// a pointer to it. The head of the linked list which contains (or should
// contain) the entry for s is the element of buckets whose index is the
// hash code of s mod num_buckets.
//
// Returns a pointer to the WordEntry object in the appropriate linked list
// which represents s.
struct WordEntry *wc_dict_find_or_insert(struct WordEntry *buckets[], unsigned num_buckets, const unsigned char *s)
{
  if (buckets == NULL) { return NULL; }

  uint32_t index = wc_hash(s) % num_buckets;

  int inserted;
  struct WordEntry *word = wc_find_or_insert(buckets[index], s, &inserted);
      
  // If a new node was inserted, update the buckets array element
  if (inserted) {
    buckets[index] = word;
  }

  return word;
}

// Free all of the nodes in given linked list of WordEntry objects.
void wc_free_chain(struct WordEntry *p)
{
  while (p != NULL)
  {
    struct WordEntry *next = p->next; // create pointer to next
    free(p); // free current node
    p = next; //go to next node
  }
}
