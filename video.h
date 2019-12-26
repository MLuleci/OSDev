#ifndef _VIDEO_H_
#define _VIDEO_H_

/**
 * Clears the screen.
*/
void clear();

/**
 * Prints a given string.
 * @param ptr
*/
void print(const char *ptr);

/**
 * Move the cursor to given coordinates.
 * @param x
 * @param y
*/
void move(unsigned char x, unsigned char y);

#endif
