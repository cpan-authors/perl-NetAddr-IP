# Process this file with autoconf to produce a configure script.
AC_INIT()
AC_CONFIG_HEADER([config.h])

# Checks for programs.
AC_PROG_CC

# Checks for header files.
AC_CHECK_HEADERS([arpa/inet.h netdb.h netinet/in.h stdint.h sys/socket.h])


# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_INT32_T 
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT8_T

# Checks for library functions.
AC_HEADER_STDC
AC_PROG_GCC_TRADITIONAL
AC_CHECK_FUNCS([gethostbyname memset inet_addr inet_aton inet_pton])

# my additions
AC_C_BIGENDIAN
AC_CHECK_SIZEOF([u_int8_t])
AC_CHECK_SIZEOF([u_int16_t])
AC_CHECK_SIZEOF([u_int32_t])

AC_OUTPUT
