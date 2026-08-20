/* The two wrappers that shared a file with a compatibility definition.
 *
 * upstream/libutil/reallocarray.c holds three functions. The first is
 * compatibility: a definition of `reallocarray' for a C library that does not
 * have one. The C library beneath this package does have one, so that
 * definition is not wanted --- and because this tool links objects rather than
 * archives, "not wanted" is the same as "not permitted": two definitions of one
 * name in one link is an error rather than a preference.
 *
 * Upstream does not meet that because it builds libutil into an archive, where
 * a member is taken only when something still needs it. The difference is a
 * property of how a program is linked and not of the sources, which is why the
 * response is in this package's own directory and upstream's file is left
 * byte-identical and excluded by a glob in the manifest.
 *
 * What is copied here is the two functions that are not compatibility. They are
 * upstream's, under upstream's terms; see upstream/LICENSE.
 */
#include <stdlib.h>

#include "../upstream/util.h"

void *
ereallocarray(void *optr, size_t nmemb, size_t size)
{
	return enreallocarray(1, optr, nmemb, size);
}

void *
enreallocarray(int status, void *optr, size_t nmemb, size_t size)
{
	void *p;

	if (!(p = reallocarray(optr, nmemb, size)))
		enprintf(status, "reallocarray: out of memory\n");

	return p;
}
