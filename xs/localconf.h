/* Byte order and the fixed width types U32 and I32 come from perl.h,
 * so the XS needs no configure step.
 */

#include <string.h>

#if BYTEORDER == 0x4321 || BYTEORDER == 0x87654321
#define host_is_BIG_ENDIAN 1
#else
#define host_is_LITTLE_ENDIAN 1
#endif

#if U32SIZE != 4
#error "NetAddr::IP::Util needs a 32-bit U32"
#endif

