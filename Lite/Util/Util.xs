
/*
 * Copyright 2006, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _CYGWIN
#include <windows.h>
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*	needed for testing with 'printf'
#include <stdio.h>
 */

#ifdef _CYGWIN
#include <Win32-Extensions.h>
#endif

#include "localconf.h"

#ifdef __cplusplus
}
#endif

/*	workaround for OS's without inet_aton			*/
#include "xs_include/inet_aton.c"

/* if kernel threading is in use, provide mutex locks for global variables */
#ifdef LOCAL_USE_THREADS
lcl_mutx_init m_lock = DEFAULT_MUTEX_INIT;
#endif

typedef union
{
  u_int32_t     u[4];
  unsigned char c[16];
} n128;

n128 c128, a128;

char errorbuffer[256], *eb = errorbuffer;	/* error buff	*/

u_int32_t wa[4], wb[4];		/*	working registers	*/

struct
{		/*	character array of 40 bytes		*/
  char		txt[20];	/*	20 bytes		*/
  u_int32_t	bcd[5];		/*	20 bytes, 40 digits	*/
} n;

#define zero ('0' & 0x7f)

void
extendipv4(void * aa)
{
  register u_int32_t * a = wa;
  *a++ = 0;
  *a++ = 0;
  *a++ = 0;
  *a = *((u_int32_t *)aa);
}

void
extendmask4(void *aa)
{
  register u_int32_t * a = wa;
  *a++ = 0xffffffff;
  *a++ = 0xffffffff;
  *a++ = 0xffffffff;
  *a = *((u_int32_t *)aa);
}

void
fastcomp128(void * aa)
{
  register u_int32_t * a;
  a = aa;

  *a++ ^= 0xffffffff;
  *a++ ^= 0xffffffff;
  *a++ ^= 0xffffffff;
  *a++ ^= 0xffffffff;
}

/*	add two 128 bit numbers
	return the carry
 */

int
adder128(void * aa, void * bb, int carry)
{
  int i;
  register u_int32_t a, b, r;

  for (i=3; i >= 0; i--) {
    a = *((u_int32_t *)aa + i);
    b = *((u_int32_t *)bb + i);
    r = a + b;
    a = 0;			/*	ripple carry forward	*/
    if ( r < a || r < b)	/*	if overflow		*/
      a = 1;

    b = r + carry;		/*	carry propagate	in	*/
    if (b < r)			/*	ripple carry forward	*/
      carry = 1;		/*	if overflow		*/
    else
      carry = a;

    *((u_int32_t *)a128.u + i) = b;
  }
  return carry;
}

int
addercon(void * aa, int32_t con)
{
  register u_int32_t tmp = 0x80000000;

  if (con & tmp)
    tmp = 0xffffffff;
  else
    tmp = 0;

  wb[0] = tmp;
  wb[1] = tmp;
  wb[2] = tmp;
  wb[3] = (u_int32_t)con;
  return adder128(aa,wb,0);
}

int
have128(void * bp)
{
  register u_int32_t * p = bp;

  if (*p++ || *p++ || *p++ || *p++)
    return 1;
  return 0;
}

int
_isipv4(void * bp)
{
  register u_int32_t * p = bp;

  if (*p++ || *p++ || *p++)
    return 0;
  return 1;
}

/*	network byte swap and copy	*/
void
netswap_copy(void * dest, void * src, int len)
{
  register u_int32_t * d = dest, * s = src;

  for (/* -- */;len>0;len--) {
#ifdef host_is_LITTLE_ENDIAN
    *d++ =  (((*s & 0xff000000) >> 24) | ((*s & 0x00ff0000) >>  8) | \
	     ((*s & 0x0000ff00) <<  8) | ((*s & 0x000000ff) << 24));
#else
# ifdef host_is_BIG_ENDIAN
    *d++ = *s;
# else
# error ENDIANness not defined
# endif
#endif
    s++;
  }
}

/*	do ntohl / htonl changes as necessary for this OS
 */
void
netswap(void * ap, int len)
{
#ifdef host_is_LITTLE_ENDIAN
  register u_int32_t * a = ap;
  for (/* -- */;len >0;len--) {
    *a++ =  (((*a & 0xff000000) >> 24) | ((*a & 0x00ff0000) >>  8) | \
	     ((*a & 0x0000ff00) <<  8) | ((*a & 0x000000ff) << 24));
  }
#endif
}

/*	shift right to purge '0's,
	return mask bit count and remainder value,
	left fill with ones
 */
unsigned char
_countbits(void *ap)
{
  register u_int32_t * p0 = (u_int32_t *)ap, * p1 = p0 +1, * p2 = p1 +1, * p3 = p2 +1;
  unsigned char count = 128;

  fastcomp128(ap);

  do {
    if (!(*p3 & 1))
      break;
    count--;
    *p3 >>= 1;
    if (*p2 & 1)
      *p3 |= 0x80000000;
    *p2 >>= 1;
    if (*p1 & 1)
      *p2 |= 0x80000000;
    *p1 >>= 1;
    if (*p0 & 1)
      *p1 |= 0x80000000;
    *p0 >>= 1;
  } while (count > 0);
  return count;
}

/*	multiply 128 bit number x 2
 */
void
_128x2(void * ap)
{
  register u_int32_t * p = (u_int32_t *)ap +3, tmpc, carry = 0;

  do {
    tmpc = *p & 0x80000000;	/*	propagate hi bit to next word	*/
    *p <<= 1;
    if (carry)
      *p += 1;
    carry = tmpc;
  } while (p-- > (u_int32_t *)ap);
/* printf("2o %04X:%04X:%04X:%04X\n",*((u_int32_t *)ap),*((u_int32_t *)ap +1),*((u_int32_t *)ap +2),*((u_int32_t *)ap +3)); */
}

/*	multiply 128 bit number X10
 */
int
_128x10(void * ap, void * tp)
{
  _128x2(ap);					/*	multiply by two		*/
  *(u_int32_t *)tp	= *(u_int32_t *)ap;	/*	temp save		*/
  *((u_int32_t *)tp +1)	= *((u_int32_t *)ap +1);
  *((u_int32_t *)tp +2)	= *((u_int32_t *)ap +2);
  *((u_int32_t *)tp +3)	= *((u_int32_t *)ap +3);
  _128x2(ap);
  _128x2(ap);					/*	times 8			*/
  (void) adder128(ap,tp,0);
/* printf("x  %04X:%04X:%04X:%04X\n",*((u_int32_t *)ap),*((u_int32_t *)ap +1),*((u_int32_t *)ap +2),*((u_int32_t *)ap +3)); */
}

/*	multiply 128 bit number by 10, add bcd digit to result
 */
void  
_128x10plusbcd(void * ap, void * tp, char digit)
{
/* printf("digit %X + %X = ",digit,*((u_int32_t *)ap +3)); */
  _128x10(ap,tp);
  *(u_int32_t *)tp		= 0;
  *((u_int32_t *)tp + 1)	= 0;
  *((u_int32_t *)tp + 2)	= 0;
  *((u_int32_t *)tp + 3)	= digit;
  (void) adder128(ap,tp,0);
/* printf("%d %04X:%04X:%04X:%04X\n",digit,*((u_int32_t *)ap),*((u_int32_t *)ap +1),*((u_int32_t *)ap +2),*((u_int32_t *)ap +3)); */
}

char
_simple_pack(void * str,int len)
{
  int i = len -1, j=19, lo=1;
  register unsigned char c, * bcdn = (unsigned char *)n.bcd, * sp = (unsigned char *) str;

  if (len > 40)
    return '*';				/*	error, input string too long	*/

  memset (n.bcd, 0, 20);

  do {
    c = *(sp + i) & 0x7f;
    if (c < zero || c > (zero + 9))
      return c;				/*	error, out of range	*/

    if (lo) {			/*	lo byte ?		*/
      *(bcdn + j) = c & 0xF;
      lo = 0;
    }
    else {
      c <<= 4;
      *(bcdn + j) |= c;
      lo = 1;			/*	lo byte next		*/
      j--;
    }
  } while (i-- > 0);
  return 0;
}

/*	convert a packed bcd string to 128 bit binary string
 */
void
_bcdn2bin(void * bp, int len)
{
  int i = 0, hasdigits = 0, lo;
  register unsigned char c, * cp = (unsigned char *)bp;

  memset(a128.c, 0, 16);
  memset(c128.c, 0, 16);

  while (i < len ) {
    c = *cp++;
    for (lo=0;lo<2;lo+=1) {
      if (lo) {
	if (hasdigits)			/*	suppress leading zero multiplications	*/
	  _128x10plusbcd(a128.u,c128.u, c & 0xF);
	else {
	  if (c & 0xF) {
	    hasdigits = 1;
	    a128.u[3] = c & 0xF;
	  }
	}
      }
      else {
	if (hasdigits)			/*	suppress leading zero multiplications	*/
	  _128x10plusbcd(a128.u,c128.u, c >> 4);
	else {
	  if (c & 0XF0) {
	    hasdigits = 1;
	    a128.u[3] = c >> 4;
	  }
	}
      }
      i++;
      if (i >= len)
	break;
    }
  }
}

/*	convert a 128 bit number string to a bcd number string
	returns the length of the bcd string === 20
 */
int
_bin2bcd (unsigned char * binary)
{
  register u_int32_t tmp, add3, msk8, bcd8, carry;
  u_int32_t word;
  unsigned char binmsk = 0;
  int c = 0,i, j, p;
  
  memset (n.bcd, 0, 20);

  for (p=0;p<128;p++) {			/*	bit pointer	*/
    if (! binmsk) {
      word = *((unsigned char *)binary + c);
      binmsk = 0x80;
      c++;
    }
    carry = word & binmsk;		/*	bit to convert	*/
    binmsk >>= 1;
    for (i=4;i>=0;i--) {
      bcd8 = n.bcd[i];
      if (carry | bcd8) {		/* if something to do		*/
	add3 = 3;
	msk8 = 8;
	
	for (j=0;j<8;j++) {		/*	prep bcd digits for X2	*/
	  tmp = bcd8 + add3;
	  if (tmp & msk8)
	    bcd8 = tmp;
	  add3 <<= 4;
	  msk8 <<= 4;
	}
	tmp = bcd8 & 0x80000000;	/*	propagated carry	*/
	bcd8 <<= 1;			/*	x 2			*/
	if (carry)
	  bcd8 += 1;
	n.bcd[i] = bcd8;
	carry = tmp;
      }
    }
  }
  netswap(n.bcd,5);
  return 20;
}

/*	convert a bcd number string to a bcd text string
	returns the number of digits
 */
int
_bcd2txt(unsigned char * bcd2p)
{
  register unsigned char bcd, dchar;
  int	i, j = 0;

  for (i=0;i<20;i++) {
    dchar = *(bcd2p + i);
    bcd = dchar >> 4;
    if (j || bcd) {
      n.txt[j] = bcd + zero;
      j++;
    }
    bcd = dchar & 0xF;
    if (j || bcd || i == 19) {		/* must be at least one digit	*/
      n.txt[j] = bcd + zero;
      j++;
    }
  }
  n.txt[j] = 0;				/* string terminator	*/
  return j;
}

MODULE = NetAddr::IP::Util    PACKAGE = NetAddr::IP::Util

PROTOTYPES: ENABLE

INCLUDE: xs_include/miniSocket.inc

void
comp128(s,...)
	SV * s
ALIAS:
	NetAddr::IP::Util::ipv6to4 = 2
	NetAddr::IP::Util::shiftleft = 1
PREINIT:
	unsigned char * ap;
	STRLEN len;
	int i;
PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);
#endif
	ap = (unsigned char *) SvPV(s,len);
	if (len != 16) {
	  if (ix == 2)
	    strcpy(eb,"ipv6to4");
	  else if (ix == 1)
	    strcpy(eb,"shiftleft");
	  else
	    strcpy(eb,"comp128");
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad arg length for %s%s, length is %d, should be %d",
		"NetAddr::IP::Util::",eb,len *8,128);
	}
	if (ix == 2) {
	  XPUSHs(sv_2mortal(newSVpvn((char *)(ap +12),4)));
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  XSRETURN(1);
	}
	else if (ix == 1) {
	  if (items < 2) {
	    memcpy(wa,ap,16);
	  }
	  else if ((i = SvIV(ST(1))) == 0) {
	    memcpy(wa,ap,16);
	  }
	  else if (i < 0 || i > 128) {
#ifdef LOCAL_USE_THREADS
	    lcl_mutx_ulck(&m_lock);
#endif
	    croak("Bad arg value for %s, is %d, should be 0 thru 128",
		"NetAddr::IP::Util::shiftleft",i);
	  }
	  else {
	    netswap_copy(wa,ap,4);
	    do {
		_128x2(wa);
		i--;
	    } while (i > 0);
	    netswap(wa,4);
	  }
	}
	else {
	  memcpy(wa,ap,16);
	  fastcomp128(wa);
	}
	XPUSHs(sv_2mortal(newSVpvn((char *)wa,16)));
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

void
add128(as,bs)
	SV * as
	SV * bs
ALIAS:
	NetAddr::IP::Util::sub128 = 1
PREINIT:
	unsigned char * ap, *bp;
	STRLEN len;
PPCODE:
#ifdef LOCAL_USE_THREADS   
	lcl_mutx_lck(&m_lock);    
#endif   
	ap = (unsigned char *) SvPV(as,len);
	if (len != 16) {
    Bail:
	  if (ix == 1)
	    strcpy(eb,"sub128");
	  else
	    strcpy(eb,"add128");
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad arg length for %s%s, length is %d, should be %d",
		"NetAddr::IP::Util::",eb,len *8,128);
	}

	bp = (unsigned char *) SvPV(bs,len);
	if (len != 16) {
	  goto Bail;
	}
	netswap_copy(wa,ap,4);
	netswap_copy(wb,bp,4);
	if (ix == 1) {
	  fastcomp128(wb);
	  XPUSHs(sv_2mortal(newSViv((I32)adder128(wa,wb,1))));
	}
	else {
	  XPUSHs(sv_2mortal(newSViv((I32)adder128(wa,wb,0))));
	}
	if (GIMME_V == G_ARRAY) {
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  XSRETURN(2);
	}
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

void
addconst(s,cnst)
	SV * s
	I32 cnst
PREINIT:
	unsigned char * ap;
	STRLEN len;
PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);   
#endif   
	ap = (unsigned char *) SvPV(s,len);
	if (len != 16) {
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad arg length for %s, length is %d, should be %d",
		"NetAddr::IP::Util::addconst",len *8,128);
	}
	netswap_copy(wa,ap,4);
	XPUSHs(sv_2mortal(newSViv((I32)addercon(wa,cnst))));
	if (GIMME_V == G_ARRAY) {
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  XSRETURN(2);
	}
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

int
hasbits(s)
	SV * s
ALIAS:
	NetAddr::IP::Util::isIPv4 = 1
PREINIT:
	unsigned char * bp;
	STRLEN len;
CODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);   
#endif   
	bp = (unsigned char *) SvPV(s,len);
	if (len != 16) {
	  if (ix == 1)
	    strcpy(eb,"isIPv4");
	  else
	    strcpy(eb,"hasbits");
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);  
#endif
	  croak("Bad arg length for %s%s, length is %d, should be %d",
		"NetAddr::IP::Util::",eb,len *8,128);
	}
	if (ix == 1) {
	  RETVAL = _isipv4(bp);
	}
	else {
	  RETVAL = have128(bp);
	}
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);  
#endif
OUTPUT:
	RETVAL

void
bin2bcd(s)
	SV * s
ALIAS:
	NetAddr::IP::Util::bcdn2txt = 2
	NetAddr::IP::Util::bin2bcdn = 1
PREINIT:
	unsigned char * cp;
	STRLEN	len;
PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);
#endif   
	cp = (unsigned char *) SvPV(s,len);
	if (ix == 0) {
	  if (len != 16) {
#ifdef LOCAL_USE_THREADS
	    lcl_mutx_ulck(&m_lock);
#endif
	    croak("Bad arg length for %s, length is %d, should be %d",
		"NetAddr::IP::Util::bin2bcd",len *8,128);
	  }
	  (void) _bin2bcd(cp);
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.txt,_bcd2txt((unsigned char *)n.bcd))));
	}
	else if (ix == 1) {
	  if (len != 16) {
#ifdef LOCAL_USE_THREADS
	    lcl_mutx_ulck(&m_lock);
#endif
	    croak("Bad arg length for %s, length is %d, should be %d",
		"NetAddr::IP::Util::bin2bcdn",len *8,128);
	  }
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.bcd,_bin2bcd(cp))));
	}
	else {
	  if (len > 20) {
#ifdef LOCAL_USE_THREADS
	    lcl_mutx_ulck(&m_lock);
#endif
	    croak("Bad arg length for %s, length is %d, should %d digits or less",
		"NetAddr::IP::Util::bcdn2txt",len *2,40);
	  }
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.txt,_bcd2txt(cp))));
	}
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

#*
#* the second argument 'len' is the number of bcd digits for 
#* the bcdn2bin conversion. Pack looses track of the number
#* digits so this is needed to do the "right thing".
#* NOTE: that simple_pack always returns 40 digits
#*
void
bcd2bin(s,...)
	SV * s
ALIAS:
	NetAddr::IP::Util::bcdn2bin = 2
	NetAddr::IP::Util::simple_pack = 1
PREINIT:
	unsigned char * cp, badc;
	STRLEN len;
PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);
#endif   
	cp = (unsigned char *) SvPV(s,len);
	if (len > 40) {
	  if (ix == 0)
	    strcpy(eb,"bcd2bin");
	  else if (ix ==1)
	    strcpy(eb,"simple_pack");
    Badigits:
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad arg length for %s%s, length is %d, should be %d digits or less",
		"NetAddr::IP::Util::",eb,len,40);
	}
	if (ix == 2) {
	  if (len > 20) {
	    len <<= 1;		/*	times 2	*/
	    strcpy(eb,"bcdn2bin");
	    goto Badigits;
	  }
	  if (items < 2) {
#ifdef LOCAL_USE_THREADS
	    lcl_mutx_ulck(&m_lock);
#endif
	    croak("Bad usage, should have %s('packedbcd,length)",
		"NetAddr::IP::Util::bcdn2bin");
	  }
	  len = SvIV(ST(1));
	  _bcdn2bin(cp,(int)len);
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  XSRETURN(1);
	}
	badc = _simple_pack(cp,(int)len);
	if (badc) {
	  if (ix == 1)
	    strcpy(eb,"simple_pack");
	  else
	    strcpy(eb,"bcd2bin");
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad char in string for %s%s, character is '%c', allowed are 0-9",
		"NetAddr::IP::Util::",eb,badc);
	}
	if (ix == 0) {
	  _bcdn2bin(n.bcd,40);
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
	}
	else {	/*	ix == 1	*/
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.bcd,20)));
	}
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

void
notcontiguous(s)
	SV * s
PREINIT:
	unsigned char * ap, count;
	STRLEN len;
PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);  
#endif
	ap = (unsigned char *) SvPV(s,len);
	if (len != 16) {
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad arg length for %s, length is %d, should be %d",
		"NetAddr::IP::Util::countbits",len *8,128);
	}
	netswap_copy(wa,ap,4);
	count = _countbits(wa);
	XPUSHs(sv_2mortal(newSViv((I32)have128(wa))));
	if (GIMME_V == G_ARRAY) {
	  XPUSHs(sv_2mortal(newSViv((I32)count)));
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  XSRETURN(2);
	}
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

void
ipv4to6(s)
	SV * s
ALIAS:
	NetAddr::IP::Util::mask4to6 = 1
PREINIT:
	unsigned char * ip;
	STRLEN len;
PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);
#endif
	ip = (unsigned char *) SvPV(s,len);
	if (len != 4) {
	  if (ix == 1)
	    strcpy(eb,"mask4to6");
	  else
	    strcpy(eb,"ipv4to6");
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad arg length for %s%s, length is %d, should be 32",
		"NetAddr::IP::Util::",eb,len *8);
	}
	if (ix == 0)
	  extendipv4(ip);
	else
	  extendmask4(ip);
	XPUSHs(sv_2mortal(newSVpvn((char *)wa,16)));
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

void
ipanyto6(s)
	SV * s
ALIAS:
	NetAddr::IP::Util::maskanyto6 = 1
PREINIT:
	unsigned char * ip;
	STRLEN len;
PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);
#endif
	ip = (unsigned char *) SvPV(s,len);
	if (len == 16)		/* if already 128 bits, return input	*/
	  XPUSHs(sv_2mortal(newSVpvn((char *)ip,16)));
	else if (len == 4) {
	  if (ix == 0)
	    extendipv4(ip);
	  else
	    extendmask4(ip);
	  XPUSHs(sv_2mortal(newSVpvn((char *)wa,16)));
	}
	else {
	  if (ix == 1)
	    strcpy(eb,"maskanyto6");
	  else
	    strcpy(eb,"ipanyto6");
#ifdef LOCAL_USE_THREADS
	  lcl_mutx_ulck(&m_lock);
#endif
	  croak("Bad arg length for %s%s, length is %d, should be 32 or 128",
		"NetAddr::IP::Util::",eb,len *8);
	}
#ifdef LOCAL_USE_THREADS
	lcl_mutx_ulck(&m_lock);
#endif
	XSRETURN(1);

void
threads()
    PPCODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_lck(&m_lock);
# ifdef HAVE_PTHREAD_H
	strcpy(eb,"HAVE_PTHREAD_H");
# else
#   ifdef HAVE_THREAD_H
	strcpy(eb,"HAVE_THREAD_H");	/* gotta have one of them	*/
#   else
#	strcpy(eb,"thread error, look at code");
#   endif
# endif
# ifdef xLOCAL_PERL_WANTS_PTHREAD_H
	strcat(eb,",LOCAL_PERL_WANTS_PTHREAD_H");
# endif
# ifdef xLOCAL_PERL_USE_THREADS
	strcat(eb,",LOCAL_PERL_USE_THREADS");
# endif
# ifdef xLOCAL_PERL_USE_I_THREADS
	strcat(eb,",LOCAL_PERL_USE_I_THREADS");
# endif
# ifdef xLOCAL_PERL_USE_5005_THREADS
	strcat(eb,",LOCAL_PERL_USE_5005_THREADS");
# endif
	XPUSHs(sv_2mortal(newSVpv(eb,0)));
	lcl_mutx_ulck(&m_lock);
#else
	XPUSHs(sv_2mortal(newSVpv("",0)));
#endif
	XSRETURN(1);

void
DESTROY()
  CODE:
#ifdef LOCAL_USE_THREADS
	lcl_mutx_dsty(&m_lock);
#endif
