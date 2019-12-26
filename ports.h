#ifndef _PORTS_H_
#define _PORTS_H_

/**
 * Output data to given I/O port.
 * @param port
 * @param data
*/
void out(unsigned short port, unsigned char data);

/**
 * Input data from given I/O port.
 * @param port
 * @return data
*/
unsigned char in(unsigned short port);

#endif
