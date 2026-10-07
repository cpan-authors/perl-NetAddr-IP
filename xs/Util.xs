
/*
 * Copyright 2006 - 2012, Michael Robinton <michael@bizsystems.com>
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
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "localconf.h"

#ifdef __cplusplus
}
#endif

/*	workaround for OS's without inet_aton			*/
/*	#include "xs_include/inet_aton.c"	removed 10-12-11 */

typedef union
{
  U32     u[4];
  unsigned char c[16];
} n128;

static const char * is_ipv6to4 = "ipv6to4", * is_shiftleft = "shiftleft", * is_comp128 = "comp128";
static const char * is_sub128 = "sub128", * is_add128 = "add128";
static const char * is_hasbits = "hasbits";
/* , * is_isIPv4 = "isIPv4"; */
static const char * is_bcd2bin = "bcd2bin", * is_simple_pack = "simple_pack", * is_bcdn2bin = "bcdn2bin";
static const char * is_mask4to6 = "mask4to6", * is_ipv4to6 = "ipv4to6";
static const char * is_maskanyto6 = "maskanyto6", * is_ipanyto6 = "ipanyto6";

typedef struct bcdstuff
{		/*	character array of 40 bytes			*/
  char		txt[41];	/*	40 digits + string terminator	*/
  U32	bcd[5];		/*	20 bytes, 40 digits		*/
} BCD;

#define zero ('0' & 0x7f)

static void
extendipv4(void * aa, void * ux)
{
  U32 * a = ux;
  *a++ = 0;
  *a++ = 0;
  *a++ = 0;
  memcpy(a, aa, sizeof(*a));	/*	aa may be an unaligned Perl buffer	*/
}

static void
extendmask4(void * aa, void * ux)
{
  U32 * a = ux;
  *a++ = 0xffffffff;
  *a++ = 0xffffffff;
  *a++ = 0xffffffff;
  memcpy(a, aa, sizeof(*a));	/*	aa may be an unaligned Perl buffer	*/
}

static void
fastcomp128(void * aa)
{
  U32 * a = aa;

  *a++ ^= 0xffffffff;
  *a++ ^= 0xffffffff;
  *a++ ^= 0xffffffff;
  *a++ ^= 0xffffffff;
}

/*	add two 128 bit numbers
	return the carry
	*/

static int
adder128(void * aa, void * bb, n128 * ap128, int carry)
{
  int i;
  U32 a, b, r;

  for (i=3; i >= 0; i--) {
    a = *((U32 *)aa + i);
    b = *((U32 *)bb + i);
    r = a + b;
    a = 0;			/*	ripple carry forward	*/
    if ( r < a || r < b)	/*	if overflow		*/
      a = 1;

    b = r + carry;		/*	carry propagate	in	*/
    if (b < r)			/*	ripple carry forward	*/
      carry = 1;		/*	if overflow		*/
    else
      carry = a;

    *((U32 *)(ap128->u) + i) = b;
  }
  return carry;
}

static int
addercon(void * aa, U32 * bb, n128 * ap128, I32 con)
{
  U32 tmp = 0x80000000;

  if (con & tmp)
    tmp = 0xffffffff;
  else
    tmp = 0;

  bb[0] = tmp;
  bb[1] = tmp;
  bb[2] = tmp;
  bb[3] = (U32)con;
  return adder128(aa,bb,ap128,0);
}

static int
_num_arg(SV * sv, NV * nvp)
{
  SvGETMAGIC(sv);
  if (!SvOK(sv) || (SvPOKp(sv) && SvCUR(sv) == 0))
    return 0;
  if (SvROK(sv)) {
    if (!SvAMAGIC(sv) || !(sv = AMG_CALLunary(sv, numer_amg)) || SvROK(sv))
      return -1;
  }
  if (SvPOKp(sv)) {
    STRLEN l;
    const char * p = SvPV_nomg(sv, l);
    if (!grok_number(p, l, NULL))
      return -1;
  }
  else if (!(SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK)))
    return -1;
  *nvp = SvNV_nomg(sv);
  return 1;
}

static int
have128(void * bp)
{
  U32 w[4];

  memcpy(w, bp, sizeof(w));	/*	bp may be an unaligned Perl buffer	*/
  if (w[0] || w[1] || w[2] || w[3])
    return 1;
  return 0;
}

/*	network byte swap and copy	*/
static void
netswap_copy(void * dest, void * src, int len)
{
  U32 * d = dest;
  unsigned char * s = src;
  U32 w;

  for (/* -- */;len>0;len--) {
    memcpy(&w, s, sizeof(w));	/*	src may be an unaligned Perl buffer	*/
#ifdef host_is_LITTLE_ENDIAN
    *d++ =  (((w & 0xff000000) >> 24) | ((w & 0x00ff0000) >>  8) | \
	     ((w & 0x0000ff00) <<  8) | ((w & 0x000000ff) << 24));
#else
# ifdef host_is_BIG_ENDIAN
    *d++ = w;
# else
# error ENDIANness not defined
# endif
#endif
    s += sizeof(w);
  }
}

/*	do ntohl / htonl changes as necessary for this OS
 */
static void
netswap(void * ap, int len)
{
#ifdef host_is_LITTLE_ENDIAN
  U32 * a = ap;
  for (/* -- */;len >0;len--) {
    *a =  (((*a & 0xff000000) >> 24) | ((*a & 0x00ff0000) >>  8) | \
	     ((*a & 0x0000ff00) <<  8) | ((*a & 0x000000ff) << 24));
    a++;
  }
#endif
}

/*	shift right to purge '0's,
	return mask bit count and remainder value,
	left fill with ones
 */
static unsigned char
_countbits(void *ap)
{
  U32 * p0 = (U32 *)ap, * p1 = p0 +1, * p2 = p1 +1, * p3 = p2 +1;
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
	returns non-zero if the result overflowed 128 bits
 */
static int
_128x2(U32 * ap)
{
  U32 * p = ap +3, tmpc, carry = 0;

  do {
    tmpc = *p & 0x80000000;	/*	propagate hi bit to next word	*/
    *p <<= 1;
    if (carry)
      *p += 1;
    carry = tmpc;
  } while (p-- > ap);
  return carry ? 1 : 0;		/*	bit shifted out the top	*/
/* printf("2o %04X:%04X:%04X:%04X\n",*(ap),*(ap +1),*(ap +2),*(ap +3)); */
}

/*	multiply 128 bit number X10
	returns non-zero if the result overflowed 128 bits
 */
static int
_128x10(n128 * ap128, n128 * tp128)
{
  U32 * ap = ap128->u, * tp = tp128->u;
  int overflow;
  overflow = _128x2(ap);					/*	multiply by two		*/
  *tp		= *ap;				/*	temp save		*/
  *(tp +1)	= *(ap +1);
  *(tp +2)	= *(ap +2);
  *(tp +3)	= *(ap +3);
  overflow |= _128x2(ap);
  overflow |= _128x2(ap);					/*	times 8			*/
  overflow |= adder128(ap,tp,ap128,0);
  return overflow;
/* printf("x  %04X:%04X:%04X:%04X\n",*((U32 *)ap),*((U32 *)ap +1),*((U32 *)ap +2),*((U32 *)ap +3)); */
}

/*	multiply 128 bit number by 10, add bcd digit to result
	returns non-zero if the result overflowed 128 bits
 */
static int
_128x10plusbcd(n128 * ap128, n128 * tp128, char digit)
{
  U32 * ap = ap128->u, * tp = tp128->u;
  int overflow;
/* printf("digit %X + %X = ",digit,*(ap +3)); */
  overflow = _128x10(ap128,tp128);
  *tp		= 0;
  *(tp + 1)	= 0;
  *(tp + 2)	= 0;
  *(tp + 3)	= digit;
  overflow |= adder128(ap,tp,ap128,0);
  return overflow;
/* printf("%d %04X:%04X:%04X:%04X\n",digit,*((U32 *)ap),*((U32 *)ap +1),*((U32 *)ap +2),*((U32 *)ap +3)); */
}

/*	packs 1 to 40 digits into 20 bytes of bcd, right aligned; returns 1 with
	*bad set to the first byte outside 0-9, else 0	*/
static int
_simple_pack(const unsigned char * sp, int len, BCD * n, unsigned char * bad)
{
  int i, j = 19, lo = 1;
  unsigned char * bcdn = (unsigned char *)(n->bcd);

  if (len < 1 || len > 40)
    return 1;
  for (i = 0; i < len; i++) {
    if (sp[i] < '0' || sp[i] > '9') {
      *bad = sp[i];
      return 1;
    }
  }
  memset(bcdn, 0, 20);
  for (i = len - 1; i >= 0; i--) {
    unsigned char c = (unsigned char)(sp[i] - '0');
    if (lo) {
      bcdn[j] = c;
      lo = 0;
    }
    else {
      bcdn[j] |= (unsigned char)(c << 4);
      lo = 1;
      j--;
    }
  }
  return 0;
}

/*	convert a packed bcd string to 128 bit binary string
	returns non-zero if the value does not fit in 128 bits
 */
static int
_bcdn2bin(void * bp, n128 * ap128, n128 * cp128, int len)
{
  int i = 0, hasdigits = 0, lo, overflow = 0;
  unsigned char c, * cp = (unsigned char *)bp;

  memset(ap128->c, 0, 16);
  memset(cp128->c, 0, 16);

  while (i < len ) {
    c = *cp++;
    for (lo=0;lo<2;lo+=1) {
      if (lo) {
	if (hasdigits)			/*	suppress leading zero multiplications	*/
	  overflow |= _128x10plusbcd(ap128, cp128, c & 0xF);
	else {
	  if (c & 0xF) {
	    hasdigits = 1;
	    ap128->u[3] = c & 0xF;
	  }
	}
      }
      else {
	if (hasdigits)			/*	suppress leading zero multiplications	*/
	  overflow |= _128x10plusbcd(ap128, cp128, c >> 4);
	else {
	  if (c & 0XF0) {
	    hasdigits = 1;
	    ap128->u[3] = c >> 4;
	  }
	}
      }
      i++;
      if (i >= len)
	break;
    }
  }
  return overflow;
}

/*	convert a 128 bit number string to a bcd number string
	returns the length of the bcd string === 20
 */
int
_bin2bcd (unsigned char * binary, BCD * n)
{
   register U32 tmp, add3, msk8, bcd8, carry = 0;
  U32 word;
  unsigned char binmsk = 0;
  int c = 0,i, j, p;

  memset (n->bcd, 0, 20);

  for (p=0;p<128;p++) {			/*	bit pointer	*/
    if (! binmsk) {
      word = *((unsigned char *)binary + c);
      binmsk = 0x80;
      c++;
    }
    carry = word & binmsk;		/*	bit to convert	*/
    binmsk >>= 1;
    for (i=4;i>=0;i--) {
      bcd8 = n->bcd[i];
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
	n->bcd[i] = bcd8;
	carry = tmp;
      }
    }
  }
  netswap(n->bcd,5);
  return 20;
}

/*	convert a bcd number string to a bcd text string
	returns the number of digits
 */
static int
_bcd2txt(unsigned char * bcd2p, BCD * n)
{
  unsigned char bcd, dchar;
  int	i, j = 0;

  for (i=0;i<20;i++) {
    dchar = *(bcd2p + i);
    bcd = dchar >> 4;
    if (j || bcd) {
      n->txt[j] = bcd + zero;
      j++;
    }
    bcd = dchar & 0xF;
    if (j || bcd || i == 19) {		/* must be at least one digit	*/
      n->txt[j] = bcd + zero;
      j++;
    }
  }
  n->txt[j] = 0;				/* string terminator	*/
  return j;
}

/*	INCLUDE: xs_include/miniSocket.inc	removed 10-12-11	*/


/*	runs a packed argument's get magic once: false if it is then undefined	*/
static int
_packed_ok(SV * sv)
{
  SvGETMAGIC(sv);
  return SvOK(sv);
}

/*	the bytes of a packed argument after _packed_ok, without running its magic
	again; an upgraded string is read through a downgraded copy	*/
static unsigned char *
_packed_bytes(SV * sv, STRLEN * lenp)
{
  if (SvUTF8(sv)) {
    SV * copy = sv_newmortal();

    sv_setsv_flags(copy, sv, SV_NOSTEAL);
    sv_utf8_downgrade(copy, FALSE);	/* croaks on a wide character */
    sv = copy;
  }
  return (unsigned char *) SvPV_nomg(sv, *lenp);
}


MODULE = NetAddr::IP::Util    PACKAGE = NetAddr::IP::Util

PROTOTYPES: ENABLE

void
comp128(s,...)
	SV * s
ALIAS:
	NetAddr::IP::Util::ipv6to4 = 2
	NetAddr::IP::Util::shiftleft = 1
PREINIT:
	unsigned char * ap;
	const char * subname;
	U32 wa[4];
	STRLEN len;
	NV nv;
	int i, k;
PPCODE:
	if (ix == 2)
	  subname = is_ipv6to4;
	else if (ix == 1)
	  subname = is_shiftleft;
	else
	  subname = is_comp128;
	/* the count is read before ap, which its magic or overloading could free */
	sv_2mortal(SvREFCNT_inc_simple_NN(s));	/* and could free s itself */
	k = (ix == 1 && items >= 2) ? _num_arg(ST(1), &nv) : 0;
	if (!_packed_ok(s))
	  croak("Bad arg length for %s%s, length is undefined, should be 128",
		"NetAddr::IP::Util::",subname);
	ap = _packed_bytes(s,&len);
	if (len != 16) {
	  croak("Bad arg length for %s%s, length is %" UVuf ", should be %d",
		"NetAddr::IP::Util::",subname,(UV)(len *8),128);
	}
	if (ix == 2) {
	  XPUSHs(sv_2mortal(newSVpvn((char *)(ap +12),4)));
	  XSRETURN(1);
	}
	if (ix == 1) {
	  if (k == 0) {
	    memcpy(wa,ap,16);
	  }
	  /* NaN fails the range test, so it never reaches the cast */
	  else if (k < 0 || !(nv >= 0 && nv <= 128) || nv != (NV)(IV)nv) {
	    croak("Bad arg value for %s, is %s, should be 0 thru 128",
		"NetAddr::IP::Util::shiftleft",SvPV_nomg_nolen(ST(1)));
	  }
	  else if (nv == 0) {
	    memcpy(wa,ap,16);
	  }
	  else {
	    i = (int)nv;
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
	XSRETURN(1);

void
add128(as,bs)
	SV * as
	SV * bs
ALIAS:
	NetAddr::IP::Util::sub128 = 1
PREINIT:
	unsigned char * ap, *bp;
	const char * subname;
	U32 wa[4], wb[4];
	n128 a128;
	STRLEN len;
PPCODE:
	if (ix == 1)
	  subname = is_sub128;
	else
	  subname = is_add128;
	if (!_packed_ok(as) || !_packed_ok(bs))
	  croak("Bad arg length for %s%s, length is undefined, should be 128",
		"NetAddr::IP::Util::",subname);
	ap = _packed_bytes(as,&len);
	if (len != 16) {
    Bail:
	  croak("Bad arg length for %s%s, length is %" UVuf ", should be %d",
		"NetAddr::IP::Util::",subname,(UV)(len *8),128);
	}

	bp = _packed_bytes(bs,&len);
	if (len != 16) {
	  goto Bail;
	}
	netswap_copy(wa,ap,4);
	netswap_copy(wb,bp,4);
	if (ix == 1) {
	  fastcomp128(wb);
	  XPUSHs(sv_2mortal(newSViv((I32)adder128(wa,wb,&a128,1))));
	}
	else {
	  XPUSHs(sv_2mortal(newSViv((I32)adder128(wa,wb,&a128,0))));
	}
	if (GIMME_V == G_ARRAY) {
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
	  XSRETURN(2);
	}
	XSRETURN(1);

void
addconst(s,c)
	SV * s
	SV * c
PREINIT:
	n128 a128;
	unsigned char * ap;
	U32 wa[4], wb[4];
	STRLEN len;
	NV nv;
	I32 cnst;
	int k;
PPCODE:
	/* the constant is read before ap, which its magic or overloading could free */
	sv_2mortal(SvREFCNT_inc_simple_NN(s));	/* and could free s itself */
	k = _num_arg(c, &nv);
	if (!_packed_ok(s))
	  croak("Bad arg length for %s, length is undefined, should be 128",
		"NetAddr::IP::Util::addconst");
	ap = _packed_bytes(s,&len);
	if (len != 16) {
	  croak("Bad arg length for %s, length is %" UVuf ", should be %d",
		"NetAddr::IP::Util::addconst",(UV)(len *8),128);
	}
	if (k == 0)
	  cnst = 0;
	else if (k < 0 || !(nv >= -2147483648.0 && nv <= 2147483647.0) || nv != (NV)(I32)nv)
	  croak("Bad arg value for %s, is %s, should be an integer from -2147483648 thru 2147483647",
		"NetAddr::IP::Util::addconst",SvPV_nomg_nolen(c));
	else
	  cnst = (I32)nv;
	netswap_copy(wa,ap,4);
	XPUSHs(sv_2mortal(newSViv((I32)addercon(wa,wb,&a128,cnst))));
	if (GIMME_V == G_ARRAY) {
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
	  XSRETURN(2);
	}
	XSRETURN(1);


int
hasbits(s)
	SV * s
PREINIT:
	unsigned char * bp;
	const char * subname;
	STRLEN len;
CODE:
	subname = is_hasbits;
	if (!_packed_ok(s))
	  croak("Bad arg length for %s%s, length is undefined, should be 128",
		"NetAddr::IP::Util::",subname);
	bp = _packed_bytes(s,&len);
	if (len != 16) {
	  croak("Bad arg length for %s%s, length is %" UVuf ", should be %d",
		"NetAddr::IP::Util::",subname,(UV)(len *8),128);
	}
	RETVAL = have128(bp);
OUTPUT:
	RETVAL

void
bin2bcd(s)
	SV * s
ALIAS:
	NetAddr::IP::Util::bcdn2txt = 2
	NetAddr::IP::Util::bin2bcdn = 1
PREINIT:
	BCD n;
	unsigned char * cp;
	STRLEN	len;
PPCODE:
	if (!_packed_ok(s))
	  croak("Bad arg length for %s, length is undefined, should be %s",
		(ix == 2) ? "NetAddr::IP::Util::bcdn2txt"
		          : (ix == 1) ? "NetAddr::IP::Util::bin2bcdn"
		                      : "NetAddr::IP::Util::bin2bcd",
		(ix == 2) ? "40 digits" : "128");
	cp = _packed_bytes(s,&len);
	if (ix == 0) {
	  if (len != 16) {
	    croak("Bad arg length for %s, length is %" UVuf ", should be %d",
		"NetAddr::IP::Util::bin2bcd",(UV)(len *8),128);
	  }
	  (void) _bin2bcd(cp,&n);
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.txt,_bcd2txt((unsigned char *)n.bcd,&n))));
	}
	else if (ix == 1) {
	  if (len != 16) {
	    croak("Bad arg length for %s, length is %" UVuf ", should be %d",
		"NetAddr::IP::Util::bin2bcdn",(UV)(len *8),128);
	  }
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.bcd,_bin2bcd(cp,&n))));
	}
	else {
	  if (len != 20) {
	    croak("Bad arg length for %s, length is %" UVuf ", should be %d digits",
		"NetAddr::IP::Util::bcdn2txt",(UV)(len *2),40);
	  }
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.txt,_bcd2txt(cp,&n))));
	}
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
	BCD n;
	n128 c128, a128;
	unsigned char * cp, badc;
	const char * subname;
	int digits, k;
	NV nv;
	STRLEN len;
PPCODE:
	if (ix == 0)
	  subname = is_bcd2bin;
	else if (ix == 1)
	  subname = is_simple_pack;
	else
	  subname = is_bcdn2bin;
	if (!_packed_ok(s))
	  croak("Bad arg length for %s%s, length is undefined, should be 1 to 40 digits",
		"NetAddr::IP::Util::",subname);
	/* the digit count is read before cp, which its magic or overloading could free */
	sv_2mortal(SvREFCNT_inc_simple_NN(s));	/* and could free s itself */
	k = (ix == 2 && items >= 2) ? _num_arg(ST(1), &nv) : 0;
	/* packed bcd is binary; the digit text is checked byte by byte, so stays as is */
	cp = (ix == 2) ? _packed_bytes(s,&len) : (unsigned char *) SvPV_nomg(s,len);
	/* bcdn2bin takes packed bcd, two digits per byte; the others take one digit per byte */
	if (ix == 2)
	  len <<= 1;
	if (len > 40 || len < 1) {
	  croak("Bad arg length for %s%s, length is %" UVuf ", should be 1 to 40 digits",
		"NetAddr::IP::Util::",subname,(UV)len);
	}
	if (ix == 2) {
	  len >>= 1;
	  if (items < 2) {
	    croak("Bad usage, should have %s('packedbcd','length')",
		"NetAddr::IP::Util::bcdn2bin");
	  }
	  if (k <= 0 || !(nv >= 1 && nv < (NV)(len << 1) + 1) || nv != (NV)(int)nv) {
	    croak("Bad digit count for %s%s, is %s, should be 1 to %d digits",
		"NetAddr::IP::Util::",subname,k == 0 ? "0" : SvPV_nomg_nolen(ST(1)),(int)(len << 1));
	  }
	  digits = (int)nv;
	  subname = is_bcdn2bin;
	  if (_bcdn2bin(cp,&a128,&c128,digits))
	    croak("Bad arg value for %s%s, number is larger than 128 bits",
		"NetAddr::IP::Util::",subname);
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
	  XSRETURN(1);
	}
	if (_simple_pack(cp, (int)len, &n, &badc)) {
	  croak("Bad char in string for %s%s, character is '%c', allowed are 0-9",
		"NetAddr::IP::Util::",subname,badc);
	}
	if (ix == 0) {
	  subname = is_bcd2bin;
	  if (_bcdn2bin((void *)n.bcd,&a128,&c128,40))
	    croak("Bad arg value for %s%s, number is larger than 128 bits",
		"NetAddr::IP::Util::",subname);
	  netswap(a128.u,4);
	  XPUSHs(sv_2mortal(newSVpvn((char *)a128.c,16)));
	}
	else {	/*	ix == 1	*/
	  XPUSHs(sv_2mortal(newSVpvn((char *)n.bcd,20)));
	}
	XSRETURN(1);

void
notcontiguous(s)
	SV * s
PREINIT:
	unsigned char * ap, count;
	U32 wa[4];
	STRLEN len;
PPCODE:
	if (!_packed_ok(s))
	  croak("Bad arg length for %s, length is undefined, should be %d",
		"NetAddr::IP::Util::notcontiguous",128);
	ap = _packed_bytes(s,&len);
	if (len != 16) {
	  croak("Bad arg length for %s, length is %" UVuf ", should be %d",
		"NetAddr::IP::Util::notcontiguous",(UV)(len *8),128);
	}
	netswap_copy(wa,ap,4);
	count = _countbits(wa);
	XPUSHs(sv_2mortal(newSViv((I32)have128(wa))));
	if (GIMME_V == G_ARRAY) {
	  XPUSHs(sv_2mortal(newSViv((I32)count)));
	  XSRETURN(2);
	}
	XSRETURN(1);

void
ipv4to6(s)
	SV * s
ALIAS:
	NetAddr::IP::Util::mask4to6 = 1
PREINIT:
	unsigned char * ip;
	const char * subname;
	U32 wa[4];
	STRLEN len;
PPCODE:
	if (ix == 1)
	  subname = is_mask4to6;
	else
	  subname = is_ipv4to6;
	if (!_packed_ok(s))
	  croak("Bad arg length for %s%s, length is undefined, should be 32",
		"NetAddr::IP::Util::",subname);
	ip = _packed_bytes(s,&len);
	if (len != 4) {
	  croak("Bad arg length for %s%s, length is %" UVuf ", should be 32",
		"NetAddr::IP::Util::",subname,(UV)(len *8));
	}
	if (ix == 0)
	  extendipv4(ip, wa);
	else
	  extendmask4(ip, wa);
	XPUSHs(sv_2mortal(newSVpvn((char *)wa,16)));
	XSRETURN(1);

void
ipanyto6(s)
	SV * s
ALIAS:
	NetAddr::IP::Util::maskanyto6 = 1
PREINIT:
	unsigned char * ip;
	const char * subname;
	U32 wa[4];
	STRLEN len;
PPCODE:
	if (ix == 1)
	  subname = is_maskanyto6;
	else
	  subname = is_ipanyto6;
	if (!_packed_ok(s))
	  croak("Bad arg length for %s%s, length is undefined, should be 32 or 128",
		"NetAddr::IP::Util::",subname);
	ip = _packed_bytes(s,&len);
	if (len == 16)		/* if already 128 bits, return input	*/
	  XPUSHs(sv_2mortal(newSVpvn((char *)ip,16)));
	else if (len == 4) {
	  if (ix == 0)
	    extendipv4(ip, wa);
	  else
	    extendmask4(ip, wa);
	  XPUSHs(sv_2mortal(newSVpvn((char *)wa,16)));
	}
	else {
	  croak("Bad arg length for %s%s, length is %" UVuf ", should be 32 or 128",
		"NetAddr::IP::Util::",subname,(UV)(len *8));
	}
	XSRETURN(1);

