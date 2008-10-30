/*
 *	localconf.h
 *
 */

#ifdef WORDS_BIGENDIAN
#define host_is_BIG_ENDIAN 1
#else
#define host_is_LITTLE_ENDIAN 1
#endif

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

#ifndef SIZEOF_U_INT8_T
typedef uint8_t u_int8_t
#endif

#ifndef SIZEOF_U_INT16_T
typedef uint16_t u_int16_t
#endif

#ifndef SIZEOF_U_INT32_T
typedef uint32_t u_int32_t
#endif
