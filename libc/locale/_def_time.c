/*	$NetBSD: _def_time.c,v 1.11 2013/04/21 17:45:46 joerg Exp $	*/

/*
 * Written by J.T. Conklin <jtc@NetBSD.org>.
 * Public domain.
 */

#include <sys/cdefs.h>
#if defined(LIBC_SCCS) && !defined(lint)
__RCSID("$NetBSD: _def_time.c,v 1.11 2013/04/21 17:45:46 joerg Exp $");
#endif /* LIBC_SCCS and not lint */

#include <sys/localedef.h>
#include <locale.h>

const _TimeLocale _DefaultTimeLocale = 
{
	{
		"Sun","Mon","Tue","Wed","Thu","Fri","Sat",
	},
	{
		"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",
		"Friday", "Saturday"
	},
	{
		"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
	},
	{
		"January", "February", "March", "April", "May", "June", "July",
		"August", "September", "October", "November", "December"
	},
	{
		"AM", "PM"
	},
	"%a %b %e %H:%M:%S %Y",
	"%m/%d/%y",
	"%H:%M:%S",
	"%I:%M:%S %p"
};
