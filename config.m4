PHP_ARG_ENABLE(stemmer, whether to enable stemmer,
[ --enable-stemmer   Enable stemmer support])

if test "$PHP_STEMMER" != "no"; then
  AH_BOTTOM([
#ifdef __clang__
#include "main/php_config.h"
#/**/undef/**/ HAVE_ASM_GOTO
#endif
  ])
  AC_DEFINE(HAVE_STEMMER, 1, [Whether you have stemmer])
dnl  PHP_ADD_LIBRARY_WITH_PATH(stemmer, libstemmer_c, STEMMER_SHARED_LIBADD)
  PHP_ADD_LIBRARY(stemmer, 1, STEMMER_SHARED_LIBADD)
  PHP_NEW_EXTENSION(stemmer, php_stemmer.c, $ext_shared, , $PHP_STEMMER_FLAGS)
  PHP_SUBST(STEMMER_SHARED_LIBADD)
fi
