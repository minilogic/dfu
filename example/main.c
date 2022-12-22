#include <C8051F320.h>
#include "xprintf.h"

#define T0FREQ  25
#define T0SCAL  (65536 - (250000 / T0FREQ))

void main (void)
{
  PCA0MD = 0;           // WDOG disabled
  CLKMUL = 0;
  OSCICN = 0x81;        // SYSCLK = 3MHz
  CKCON = 0x0A;         // TIM0 - irq; TIM1 - uart
  TMOD = 0x21;
  TL0 = T0SCAL & 0xFF;
  TH0 = T0SCAL >> 8;
  TL1 = TH1 = 243;      // UART = 115200
  TCON = 0x50;
  XBR0 = 0x01;
  XBR1 = 0x40;
  SCON0 = 0x10;
  IE = 0x82;
  PUTS("\n\n\033[36mC8051F320 dfu example\033[0m");
  for(char i = 0; i <= 100; i++, PCON |= 1) PRINTF("\r%u%%", i);
  PCA0MD = 0x40;        // WDOG enabled
  while(1);
}

static void tim0_isr (void) __interrupt(1)
{
  TL0 = T0SCAL & 0xFF;
  TH0 = T0SCAL >> 8;
}

int putchar (int ch)
{
  if(ch == '\n') putchar('\r');
  for(SBUF0 = ch; !TI0; );
  TI0 = 0;
  return ch;
}
