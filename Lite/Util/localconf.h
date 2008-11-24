/*
 *	localconf.h
 *
 */

#include "config.h"

#ifdef WORDS_BIGENDIAN
#define host_is_BIG_ENDIAN 1
#else
#define host_is_LITTLE_ENDIAN 1
#endif

#include <stdio.h>
#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#ifdef STDC_HEADERS
# include <stdlib.h>
# include <stddef.h>
#else
# ifdef HAVE_STDLIB_H
#  include <stdlib.h>
# endif
#endif
#ifdef HAVE_STRING_H
# if !defined STDC_HEADERS && defined HAVE_MEMORY_H
#  include <memory.h>
# endif
# include <string.h>
#endif
#ifdef HAVE_STRINGS_H
# include <strings.h>
#endif
#ifdef HAVE_INTTYPES_H
# include <inttypes.h>
#endif
#ifdef HAVE_STDINT_H
# include <stdint.h>
#endif
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif

#ifdef HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif
#ifdef HAVE_NET_INET_H
# include <netinet/in.h>
#endif
#ifdef HAVE_ARPA_INET_H
# include <arpa/inet.h>
#endif
#ifdef HAVE_NETDB_H
# include <netdb.h>
#endif

#if SIZEOF_U_INT8_T == 0
#undef SIZEOF_U_INT8_T
#define SIZEOF_U_INT8_T SIZEOF_UINT8_T
typedef uint8_t u_int8_t;
#endif

#if SIZEOF_U_INT16_T == 0
#undef SIZEOF_U_INT16_T
#define SIZEOF_U_INT16_T SIZEOF_UINT16_T
typedef uint16_t u_int16_t;
#endif

#if SIZEOF_U_INT32_T == 0
#undef SIZEOF_U_INT32_T
#define SIZEOF_U_INT32_T SIZEOF_UINT32_T
typedef uint32_t u_int32_t;
#endif

#include "localperl.h"

/*
 *	defined if the C program should include <pthread.h>
 *	LOCAL_PERL_WANTS_PTHREAD_H
 *	
 *	defined if perl was compiled to use threads
 *	LOCAL_PERL_USE_THREADS
 *	
 *	defined if perl was compiled to use interpreter threads
 *	LOCAL_PERL_USE_I_THREADS
 *	
 *	defined if perl was compiled to use 5005 threads
 *	LOCAL_PERL_USE_5005_THREADS
 *
 *
 *	THREAD code is definetly ALPHA in Util.xs
 *	Benchmarks indicate that it runs up to 50% slower
 *	Use at your own risk for now
 *
 *	does not yet address the FreeBSD mutex mtx_xxx functions
 *	mtx_lock
 *	mtx_unlock
 *	mtx_destroy
 *	#include <sys/param.h>
 *	#include <sys/lock.h>
 *	#include <sys/mutex.h>
 */

#if defined I_REALLY_WANT_ALPHA_THREADS
#if defined (HAVE_PTHREAD_H) && defined (LOCAL_PERL_WANTS_PTHREAD_H)
#include <pthread.h>
#define LOCAL_USE_THREADS
#define DEFAULT_MUTEX_INIT PTHREAD_MUTEX_INITIALIZER
#define lcl_mutx_init pthread_mutex_t
#define lcl_mutx_lck(m) pthread_mutex_lock(m)   
#define lcl_mutx_ulck(m) pthread_mutex_unlock(m)
#define lcl_mutx_dsty(m) pthread_mutex_destroy(m)
# ifdef HAVE_THREAD_H
# undef HAVE_THREAD_H
# endif
#endif

#if defined (HAVE_THREAD_H) && defined (LOCAL_PERL_USE_THREADS)
#include <sched.h>
#include <thread.h>
#define LOCAL_USE_THREADS
#define DEFAULT_MUTEX_INIT DEFAULTMUTEX
#define lcl_mutx_init mutex_t
#define lcl_mutx_lck(m) mutex_lock(m)
#define lcl_mutx_ulck(m) mutex_unlock(m)
#define lcl_mutx_dsty(m) mutex_destroy(m)
#endif
#endif
