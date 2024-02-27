--- w.c.orig
+++ w.c
@@ -45,9 +45,8 @@
 #include <unistd.h>
 #ifdef HAVE_UTMPX_H
 #	include <utmpx.h>
-#else
-#	include <utmp.h>
 #endif
+#include <utmp.h>
 #include <arpa/inet.h>
 
 #include "c.h"
@@ -64,12 +63,6 @@
 typedef struct utmpx utmp_t;
 #else
 typedef struct utmp utmp_t;
-#endif
-
-#if !defined(UT_HOSTSIZE) || defined(__UT_HOSTSIZE)
-#	define UT_HOSTSIZE __UT_HOSTSIZE
-#	define UT_LINESIZE __UT_LINESIZE
-#	define UT_NAMESIZE __UT_NAMESIZE
 #endif
 
 #ifdef W_SHOWFROM
