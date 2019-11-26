# These variables are specifically meant to be overridable via the make
# command-line.
WASM_CC ?= clang
WASM_NM ?= $(patsubst %clang,%llvm-nm,$(WASM_CC))
WASM_AR ?= $(patsubst %clang,%llvm-ar,$(WASM_CC))
WASM_CFLAGS ?= -O2 -DNDEBUG
# The directory where we build the sysroot.
SYSROOT ?= $(CURDIR)/sysroot
# A directory to install to for "make install".
INSTALL_DIR ?= /usr/local
# single or posix
THREAD_MODEL ?= single
# yes or no
BUILD_DLMALLOC ?= yes
BUILD_LIBC_BOTTOM_HALF ?= yes
BUILD_LIBC_TOP_HALF ?= yes
# The directory where we're store intermediate artifacts.
BUILD_DIR ?= $(CURDIR)/build

# Check dependencies.
ifeq ($(BUILD_LIBC_TOP_HALF),yes)
ifneq ($(BUILD_LIBC_BOTTOM_HALF),yes)
$(error BUILD_LIBC_TOP_HALF=yes depends on BUILD_LIBC_BOTTOM_HALF=yes)
endif
endif
ifeq ($(BUILD_LIBC_BOTTOM_HALF),yes)
ifneq ($(BUILD_DLMALLOC),yes)
$(error BUILD_LIBC_BOTTOM_HALF=yes depends on BUILD_DLMALLOC=yes)
endif
endif

# Set the target variables. Multiarch triples notably omit the vendor field,
# which happens to be what we do for the main target triple too.
override TARGET_TRIPLE = wasm32-wasi
override MULTIARCH_TRIPLE = wasm32-wasi

# The directory we built .o files in.
override OBJDIR := $(BUILD_DIR)
ifeq ($(LTO),yes)
override OBJDIR := $(OBJDIR)/llvm-lto/$(CLANG_VERSION)
endif

# These variables describe the locations of various files and directories in
# the source tree.
override BASICS_DIR = $(CURDIR)/basics
override BASICS_INC = $(BASICS_DIR)/include
override BASICS_CRT_SOURCES = $(wildcard $(BASICS_DIR)/crt/*.c)
override BASICS_SOURCES = $(wildcard $(BASICS_DIR)/sources/*.c)
override DLMALLOC_DIR = $(CURDIR)/dlmalloc
override DLMALLOC_SRC_DIR = $(DLMALLOC_DIR)/src
override DLMALLOC_SOURCES = $(DLMALLOC_SRC_DIR)/dlmalloc.c
override DLMALLOC_INC = $(DLMALLOC_DIR)/include
override LIBC_BOTTOM_HALF_DIR = $(CURDIR)/libc-bottom-half
override LIBC_BOTTOM_HALF_CLOUDLIBC_SRC = $(LIBC_BOTTOM_HALF_DIR)/cloudlibc/src
override LIBC_BOTTOM_HALF_CLOUDLIBC_SRC_INC = $(LIBC_BOTTOM_HALF_CLOUDLIBC_SRC)/include
override LIBC_BOTTOM_HALF_HEADERS_PUBLIC = $(LIBC_BOTTOM_HALF_DIR)/headers/public
override LIBC_BOTTOM_HALF_HEADERS_PRIVATE = $(LIBC_BOTTOM_HALF_DIR)/headers/private
override LIBC_BOTTOM_HALF_LIBPREOPEN_DIR = $(LIBC_BOTTOM_HALF_DIR)/libpreopen
override LIBC_BOTTOM_HALF_SOURCES = $(LIBC_BOTTOM_HALF_DIR)/sources
override LIBC_BOTTOM_HALF_ALL_SOURCES = \
    $(shell find $(LIBC_BOTTOM_HALF_CLOUDLIBC_SRC) -name \*.c) \
    $(LIBC_BOTTOM_HALF_LIBPREOPEN_DIR)/libpreopen.c \
    $(shell find $(LIBC_BOTTOM_HALF_SOURCES) -name \*.c)
override LIBWASI_EMULATED_MMAN_SOURCES = \
    $(shell find $(LIBC_BOTTOM_HALF_DIR)/mman -name \*.c)
override LIBC_BOTTOM_HALF_CRT_SOURCES = $(wildcard $(LIBC_BOTTOM_HALF_DIR)/crt/*.c)
override LIBC_TOP_HALF_DIR = $(CURDIR)/libc-top-half
override LIBC_TOP_HALF_MUSL_DIR = $(LIBC_TOP_HALF_DIR)/musl
override LIBC_TOP_HALF_MUSL_SRC_DIR = $(LIBC_TOP_HALF_MUSL_DIR)/src
override LIBC_TOP_HALF_MUSL_INC = $(LIBC_TOP_HALF_MUSL_DIR)/include
override LIBC_TOP_HALF_MUSL_SOURCES = \
    $(addprefix $(LIBC_TOP_HALF_MUSL_SRC_DIR)/, \
        misc/a64l.c \
        misc/basename.c misc/dirname.c \
        misc/ffs.c misc/ffsl.c misc/ffsll.c \
        misc/fmtmsg.c \
        misc/getdomainname.c misc/gethostid.c \
        misc/getopt.c misc/getopt_long.c \
        misc/getsubopt.c \
        misc/uname.c \
        misc/nftw.c \
        errno/strerror.c \
        network/htonl.c network/htons.c network/ntohl.c network/ntohs.c \
        network/inet_ntop.c network/inet_pton.c network/inet_aton.c \
        network/in6addr_any.c network/in6addr_loopback.c \
        fenv/fenv.c fenv/fesetround.c fenv/feupdateenv.c \
        fenv/fesetexceptflag.c fenv/fegetexceptflag.c fenv/feholdexcept.c \
        exit/exit.c exit/atexit.c exit/assert.c \
        exit/quick_exit.c exit/at_quick_exit.c \
        time/strftime.c time/asctime.c time/asctime_r.c \
        time/ctime.c time/ctime_r.c \
        time/wcsftime.c time/strptime.c time/difftime.c \
        time/timegm.c time/ftime.c time/gmtime.c time/gmtime_r.c \
        time/timespec_get.c \
        time/getdate.c \
        time/localtime.c time/localtime_r.c \
        time/mktime.c \
        time/__tm_to_secs.c time/__month_to_secs.c \
        time/__secs_to_tm.c time/__year_to_secs.c \
        time/__tz.c \
        fcntl/creat.c \
        dirent/alphasort.c dirent/versionsort.c \
        env/clearenv.c env/getenv.c env/putenv.c env/setenv.c env/unsetenv.c \
        unistd/posix_close.c \
    ) \
    $(filter-out %/procfdname.c %/syscall.c %/syscall_ret.c %/vdso.c %/version.c, \
                 $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/internal/*.c)) \
    $(filter-out %/flockfile.c %/funlockfile.c %/__lockfile.c %/ftrylockfile.c \
                 %/rename.c \
                 %/tmpnam.c %/tmpfile.c %/tempnam.c \
                 %/popen.c %/pclose.c \
                 %/remove.c \
                 %/gets.c, \
                 $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/stdio/*.c)) \
    $(filter-out %/strsignal.c, \
                 $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/string/*.c)) \
    $(filter-out %/dcngettext.c %/textdomain.c %/bind_textdomain_codeset.c, \
                 $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/locale/*.c)) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/stdlib/*.c) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/search/*.c) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/multibyte/*.c) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/regex/*.c) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/prng/*.c) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/conf/*.c) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/ctype/*.c) \
    $(filter-out %/crealf.c %/creal.c \
                 %/cimagf.c %/cimag.c, \
                 $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/complex/*.c)) \
    $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/crypt/*.c)
override MUSL_PRINTSCAN_SOURCES = \
    $(addprefix $(LIBC_TOP_HALF_MUSL_SRC_DIR)/, \
        internal/floatscan.c \
        stdio/vfprintf.c stdio/vfwprintf.c stdio/vfscanf.c \
        stdlib/strtod.c stdlib/wcstod.c \
    )
override LIBC_TOP_HALF_HEADERS_PRIVATE = $(LIBC_TOP_HALF_DIR)/headers/private
override LIBC_TOP_HALF_SOURCES = $(LIBC_TOP_HALF_DIR)/sources
override MATH_SOURCES = \
    $(wildcard $(BASICS_DIR)/sources/math/*.c) \
    $(filter-out %/__signbit.c %/__signbitf.c %/__signbitl.c \
                 %/__fpclassify.c %/__fpclassifyf.c %/__fpclassifyl.c \
                 %/ceilf.c %/ceil.c \
                 %/floorf.c %/floor.c \
                 %/truncf.c %/trunc.c \
                 %/rintf.c %/rint.c \
                 %/nearbyintf.c %/nearbyint.c \
                 %/sqrtf.c %/sqrt.c \
                 %/fabsf.c %/fabs.c \
                 %/copysignf.c %/copysign.c \
                 %/fminf.c %/fmaxf.c \
                 %/fmin.c %/fmax.c, \
                 $(wildcard $(LIBC_TOP_HALF_MUSL_SRC_DIR)/math/*.c))
ifeq ($(BUILD_LIBC_BOTTOM_HALF),no)
override CRT_SOURCES = $(BASICS_CRT_SOURCES)
else
override CRT_SOURCES = $(LIBC_BOTTOM_HALF_CRT_SOURCES)
endif
ifeq ($(LTO),yes)
# The following files define functions which are called by LLVM CodeGen,
# which runs after LLVM LTO, so LTO libraries don't satisfy them. They're
# also relatively uninteresting to LTO, as LLVM recognizes most of them
# even without seeing their definitions.
override LIBC_NONLTO_SOURCES = \
    $(MATH_SOURCES) \
    $(addprefix $(LIBC_TOP_HALF_MUSL_SRC_DIR)/, \
        exit/atexit.c \
        string/memcpy.c string/memmove.c string/memset.c \
    )
override LIBC_TOP_HALF_ALL_SOURCES := \
    $(filter-out $(LIBC_NONLTO_SOURCES), $(LIBC_TOP_HALF_MUSL_SOURCES))
else
override LIBC_TOP_HALF_ALL_SOURCES := \
    $(LIBC_TOP_HALF_MUSL_SOURCES) \
    $(MATH_SOURCES)
endif
override LIBC_TOP_HALF_ALL_SOURCES += \
    $(shell find $(LIBC_TOP_HALF_SOURCES) -name \*.c)

# These variables describe the locations of various files and directories in
# the build tree.
override objs = $(patsubst $(CURDIR)/%.c,$(OBJDIR)/%.o,$(1))
override BASICS_OBJS = $(call objs,$(BASICS_SOURCES))
override DLMALLOC_OBJS = $(call objs,$(DLMALLOC_SOURCES))
override LIBC_BOTTOM_HALF_ALL_OBJS = $(call objs,$(LIBC_BOTTOM_HALF_ALL_SOURCES))
override LIBC_TOP_HALF_ALL_OBJS = $(call objs,$(LIBC_TOP_HALF_ALL_SOURCES))
override LIBC_OBJS := $(BASICS_OBJS)
ifeq ($(BUILD_DLMALLOC),yes)
override LIBC_OBJS += $(DLMALLOC_OBJS)
endif
ifeq ($(BUILD_LIBC_BOTTOM_HALF),yes)
# Override basics' string.o with libc-bottom-half's.
override LIBC_OBJS := $(filter-out %/string.o,$(LIBC_OBJS))
# Add libc-bottom-half's objects.
override LIBC_OBJS += $(LIBC_BOTTOM_HALF_ALL_OBJS)
endif
ifeq ($(BUILD_LIBC_TOP_HALF),yes)
# Override libc-bottom-half's string.o with libc-top-half's.
override LIBC_OBJS := $(filter-out %/string.o,$(LIBC_OBJS))
# Override libc-bottom-half's qsort.o with libc-top-half's.
override LIBC_OBJS := $(filter-out %/qsort.o,$(LIBC_OBJS))
# libc-top-half is musl.
override LIBC_OBJS += $(LIBC_TOP_HALF_ALL_OBJS)
endif
override MUSL_PRINTSCAN_OBJS = $(call objs,$(MUSL_PRINTSCAN_SOURCES))
override MUSL_PRINTSCAN_LONG_DOUBLE_OBJS = $(patsubst %.o,%.long-double.o,$(MUSL_PRINTSCAN_OBJS))
override MUSL_PRINTSCAN_NO_FLOATING_POINT_OBJS = $(patsubst %.o,%.no-floating-point.o,$(MUSL_PRINTSCAN_OBJS))
override LIBWASI_EMULATED_MMAN_OBJS = $(call objs,$(LIBWASI_EMULATED_MMAN_SOURCES))
ifeq ($(LTO),yes)
override LIBC_NONLTO_OBJS = $(call objs,$(LIBC_NONLTO_SOURCES))
endif

# These variables describe the locations of various files and
# directories in the generated sysroot tree.
override SYSROOT_LIB := $(SYSROOT)/lib/$(MULTIARCH_TRIPLE)
ifeq ($(LTO),yes)
override SYSROOT_LIB := $(SYSROOT_LIB)/llvm-lto/$(CLANG_VERSION)
endif
override SYSROOT_INC = $(SYSROOT)/include
override SYSROOT_SHARE = $(SYSROOT)/share/$(MULTIARCH_TRIPLE)

# Compute WASM_CFLAGS.

# Set the target.
override WASM_CFLAGS += --target=$(TARGET_TRIPLE)
# WebAssembly floating-point match doesn't trap.
# TODO: Add -fno-signaling-nans when the compiler supports it.
override WASM_CFLAGS += -fno-trapping-math

# Configure support for threads.
ifeq ($(THREAD_MODEL), single)
override WASM_CFLAGS += -mthread-model single
endif
ifeq ($(THREAD_MODEL), posix)
override WASM_CFLAGS += -mthread-model posix -pthread
endif

# Set the sysroot.
override WASM_CFLAGS += --sysroot="$(SYSROOT)"

# If we're building LTO, enable it.
ifeq ($(LTO),yes)
override WASM_CFLAGS += -flto
endif

# By default, build the sysroot.
default: sysroot

# In an LTO build, we disable LTO for select source files.
ifeq ($(LTO),yes)
$(LIBC_NONLTO_OBJS): override WASM_CFLAGS += -fno-lto
endif

# Configure wasi-libc for building printf with and without long double support.
$(MUSL_PRINTSCAN_OBJS): override WASM_CFLAGS += \
    -D__wasilibc_printscan_no_long_double \
    -D__wasilibc_printscan_full_support_option="\"add -lc-printscan-long-double to the link command\""
$(MUSL_PRINTSCAN_NO_FLOATING_POINT_OBJS): override WASM_CFLAGS += \
    -D__wasilibc_printscan_no_floating_point \
    -D__wasilibc_printscan_floating_point_support_option="\"remove -lc-printscan-no-floating-point from the link command\""

# Add internal include directories.
$(DLMALLOC_OBJS): override WASM_CFLAGS += \
    -I$(DLMALLOC_INC)

# Add internal include directories.
crt $(LIBC_BOTTOM_HALF_ALL_OBJS): override WASM_CFLAGS += \
    -I$(LIBC_BOTTOM_HALF_HEADERS_PRIVATE) \
    -I$(LIBC_BOTTOM_HALF_CLOUDLIBC_SRC_INC) \
    -I$(LIBC_BOTTOM_HALF_CLOUDLIBC_SRC)

# Add internal include directories and suppression flags for harmless warnings.
$(LIBC_TOP_HALF_ALL_OBJS) \
    $(MUSL_PRINTSCAN_LONG_DOUBLE_OBJS) \
    $(MUSL_PRINTSCAN_NO_FLOATING_POINT_OBJS) \
    $(LIBC_NONLTO_OBJS) \
: override WASM_CFLAGS += \
    -I$(LIBC_TOP_HALF_MUSL_SRC_DIR)/include \
    -I$(LIBC_TOP_HALF_MUSL_SRC_DIR)/internal \
    -I$(LIBC_TOP_HALF_MUSL_DIR)/arch/wasm32 \
    -I$(LIBC_TOP_HALF_MUSL_DIR)/arch/generic \
    -I$(LIBC_TOP_HALF_HEADERS_PRIVATE) \
    -Wno-parentheses \
    -Wno-shift-op-parentheses \
    -Wno-bitwise-op-parentheses \
    -Wno-logical-op-parentheses \
    -Wno-string-plus-int \
    -Wno-dangling-else \
    -Wno-unknown-pragmas

# Files from musl's include directory that we don't want to install in the
# sysroot's include directory.
override MUSL_OMIT_HEADERS :=

# Remove files which aren't headers (we generate alltypes.h below).
override MUSL_OMIT_HEADERS += \
    "bits/syscall.h.in" \
    "bits/alltypes.h.in" \
    "alltypes.h.in"

# Use the compiler's version of these headers.
override MUSL_OMIT_HEADERS += \
    "stdarg.h" \
    "stddef.h"

# Use the WASI errno definitions.
override MUSL_OMIT_HEADERS += \
    "bits/errno.h"

# Remove headers that aren't supported yet or that aren't relevant for WASI.
override MUSL_OMIT_HEADERS += \
    "sys/procfs.h" \
    "sys/user.h" \
    "sys/kd.h" "sys/vt.h" "sys/soundcard.h" "sys/sem.h" \
    "sys/shm.h" "sys/msg.h" "sys/ipc.h" "sys/ptrace.h" \
    "sys/statfs.h" \
    "bits/kd.h" "bits/vt.h" "bits/soundcard.h" "bits/sem.h" \
    "bits/shm.h" "bits/msg.h" "bits/ipc.h" "bits/ptrace.h" \
    "bits/statfs.h" \
    "sys/vfs.h" \
    "sys/statvfs.h" \
    "syslog.h" "sys/syslog.h" \
    "wait.h" "sys/wait.h" \
    "ucontext.h" "sys/ucontext.h" \
    "paths.h" \
    "utmp.h" "utmpx.h" \
    "lastlog.h" \
    "sys/acct.h" \
    "sys/cachectl.h" \
    "sys/epoll.h" "sys/reboot.h" "sys/swap.h" \
    "sys/sendfile.h" "sys/inotify.h" \
    "sys/quota.h" \
    "sys/klog.h" \
    "sys/fsuid.h" \
    "sys/io.h" \
    "sys/prctl.h" \
    "sys/mtio.h" \
    "sys/mount.h" \
    "sys/fanotify.h" \
    "sys/personality.h" \
    "elf.h" "link.h" "bits/link.h" \
    "scsi/scsi.h" "scsi/scsi_ioctl.h" "scsi/sg.h" \
    "sys/auxv.h" \
    "pwd.h" "shadow.h" "grp.h" \
    "mntent.h" \
    "netdb.h" \
    "resolv.h" \
    "pty.h" \
    "dlfcn.h" \
    "setjmp.h" \
    "ulimit.h" \
    "sys/xattr.h" \
    "wordexp.h" \
    "spawn.h" \
    "sys/membarrier.h" \
    "sys/signalfd.h" \
    "termios.h" \
    "sys/termios.h" \
    "bits/termios.h" \
    "net/if.h" \
    "net/if_arp.h" \
    "net/ethernet.h" \
    "net/route.h" \
    "netinet/if_ether.h" \
    "netinet/ether.h" \
    "sys/timerfd.h" \
    "libintl.h" \
    "sys/sysmacros.h" \
    "utime.h"

ifeq ($(THREAD_MODEL), single)
# Remove headers not supported in single-threaded mode.
override MUSL_OMIT_HEADERS += "aio.h" "pthread.h"
endif

# Build the sysroot and perform basic sanity checks.
sysroot:
	$(RM) -r "$(SYSROOT)"

	#
	# Install the include files.
	#
	mkdir -p "$(SYSROOT_INC)"
	cp -r "$(BASICS_INC)" "$(SYSROOT)"
	cp -r "$(LIBC_BOTTOM_HALF_HEADERS_PUBLIC)"/* "$(SYSROOT_INC)"

	# Generate musl's bits/alltypes.h header.
	mkdir -p "$(SYSROOT_INC)/bits"
	sed -f $(LIBC_TOP_HALF_MUSL_DIR)/tools/mkalltypes.sed \
	    $(LIBC_TOP_HALF_MUSL_DIR)/arch/wasm32/bits/alltypes.h.in \
	    $(LIBC_TOP_HALF_MUSL_DIR)/include/alltypes.h.in \
	    > "$(SYSROOT_INC)/bits/alltypes.h"

	# Copy in the bulk of musl's public header files.
	cp -r "$(LIBC_TOP_HALF_MUSL_INC)"/* "$(SYSROOT_INC)"
	# Copy in the musl's "bits" header files.
	cp -r "$(LIBC_TOP_HALF_MUSL_DIR)"/arch/generic/bits/* "$(SYSROOT_INC)/bits"
	cp -r "$(LIBC_TOP_HALF_MUSL_DIR)"/arch/wasm32/bits/* "$(SYSROOT_INC)/bits"

	# Remove selected header files.
	$(RM) $(patsubst %,$(SYSROOT_INC)/%,$(MUSL_OMIT_HEADERS))

	#
	# Build the startup files.
	#
	$(MAKE) crt
	$(MAKE) crt LTO=yes

	#
	# Build the libc files.
	#
	$(MAKE) libc
	$(MAKE) libc LTO=yes

	#
	# Create empty placeholder libraries.
	#
	for name in m rt pthread crypt util xnet resolv dl; do \
	    $(WASM_AR) crs "$(SYSROOT_LIB)/lib$${name}.a"; \
	done

	#
	# Collect metadata on the sysroot and perform sanity checks.
	#
	@mkdir -p "$(SYSROOT_SHARE)"

	#
	# Collect symbol information.
	#
	@# TODO: Use llvm-nm --extern-only instead of grep. This is blocked on
	@# LLVM PR40497, which is fixed in 9.0, but not in 8.0.
	@# Ignore certain llvm builtin symbols such as those starting with __mul
	@# since these dependencies can vary between llvm versions.
	"$(WASM_NM)" --defined-only "$(SYSROOT_LIB)"/libc.a "$(SYSROOT_LIB)"/*.o \
	    |grep ' [[:upper:]] ' |sed 's/.* [[:upper:]] //' |LC_ALL=C sort > "$(SYSROOT_SHARE)/defined-symbols.txt"
	for undef_sym in $$("$(WASM_NM)" --undefined-only "$(SYSROOT_LIB)"/*.a "$(SYSROOT_LIB)"/*.o \
	    |grep ' U ' |sed 's/.* U //' |LC_ALL=C sort |uniq); do \
	    grep -q '\<'$$undef_sym'\>' "$(SYSROOT_SHARE)/defined-symbols.txt" || echo $$undef_sym; \
	done | grep -v "^__mul" > "$(SYSROOT_SHARE)/undefined-symbols.txt"
	grep '^_*wasi_' "$(SYSROOT_SHARE)/undefined-symbols.txt" \
	    > "$(SYSROOT_LIB)/libc.imports"
	cp "$(SYSROOT_LIB)/libc.imports" "$(SYSROOT_LIB)/llvm-lto/$(CLANG_VERSION)/libc.imports"

	#
	# Generate a test file that includes all public header files.
	#
	cd "$(SYSROOT)" && \
	  for header in $$(find include -type f -not -name mman.h |grep -v /bits/); do \
	      echo '#include <'$$header'>' | sed 's/include\///' ; \
	done |LC_ALL=C sort >share/$(MULTIARCH_TRIPLE)/include-all.c ; \
	cd - >/dev/null

	#
	# Test that it compiles.
	#
	"$(WASM_CC)" $(WASM_CFLAGS) -fsyntax-only "$(SYSROOT_SHARE)/include-all.c" -Wno-\#warnings

	#
	# Collect all the predefined macros, except for compiler version macros
	# which we don't need to track here.
	#
	@#
	@# For the __*_ATOMIC_*_LOCK_FREE macros, squash individual compiler names
	@# to attempt, toward keeping these files compiler-independent.
	@#
	@# We have to add `-isystem $(SYSROOT_INC)` because otherwise clang puts
	@# its builtin include path first, which produces compiler-specific
	@# output.
	@#
	@# TODO: Undefine __FLOAT128__ for now since it's not in clang 8.0.
	@# TODO: Filter out __FLT16_* for now, as not all versions of clang have these.
	"$(WASM_CC)" $(WASM_CFLAGS) "$(SYSROOT_SHARE)/include-all.c" \
	    -isystem $(SYSROOT_INC) \
	    -E -dM -Wno-\#warnings \
	    -D_ALL_SOURCE \
	    -U__llvm__ \
	    -U__clang__ \
	    -U__clang_major__ \
	    -U__clang_minor__ \
	    -U__clang_patchlevel__ \
	    -U__clang_version__ \
	    -U__GNUC__ \
	    -U__GNUC_MINOR__ \
	    -U__GNUC_PATCHLEVEL__ \
	    -U__VERSION__ \
	    -U__FLOAT128__ \
	    | sed -e 's/__[[:upper:][:digit:]]*_ATOMIC_\([[:upper:][:digit:]_]*\)_LOCK_FREE/__compiler_ATOMIC_\1_LOCK_FREE/' \
	    | grep -v '^#define __FLT16_' \
	    > "$(SYSROOT_SHARE)/predefined-macros.txt"

	# Check that the computed metadata matches the expected metadata.
	diff -ur "$(CURDIR)/expected/$(MULTIARCH_TRIPLE)" "$(SYSROOT_SHARE)"

	#
	# The build succeeded! The generated sysroot is in $(SYSROOT).
	#

# Build the sysroot and install it into $(INSTALL_DIR).
install: sysroot
	@mkdir -p "$(INSTALL_DIR)"
	cp -r "$(SYSROOT)/lib" "$(SYSROOT)/share" "$(SYSROOT)/include" "$(INSTALL_DIR)"

crt:
	@mkdir -p "$(OBJDIR)"
	@mkdir -p "$(SYSROOT_LIB)"
	cd "$(OBJDIR)" && \
	    "$(WASM_CC)" $(WASM_CFLAGS) -c $(CRT_SOURCES) -MD -MP && \
	    mv *.o "$(SYSROOT_LIB)"

libc: \
    $(SYSROOT_LIB)/libc.a \
    $(SYSROOT_LIB)/libc-printscan-long-double.a \
    $(SYSROOT_LIB)/libc-printscan-no-floating-point.a \
    $(SYSROOT_LIB)/libwasi-emulated-mman.a
ifeq ($(LTO),yes)
libc: $(SYSROOT_LIB)/libc-nonlto.a
endif

$(SYSROOT_LIB)/libc.a: $(LIBC_OBJS)
$(SYSROOT_LIB)/libc-printscan-long-double.a: $(MUSL_PRINTSCAN_LONG_DOUBLE_OBJS)
$(SYSROOT_LIB)/libc-printscan-no-floating-point.a: $(MUSL_PRINTSCAN_NO_FLOATING_POINT_OBJS)
$(SYSROOT_LIB)/libwasi-emulated-mman.a: $(LIBWASI_EMULATED_MMAN_OBJS)
ifeq ($(LTO),yes)
$(SYSROOT_LIB)/libc-nonlto.a: $(LIBC_NONLTO_OBJS)
endif

%.a:
	@mkdir -p "$(@D)"
	# On Windows, the commandline for the ar invocation got too long, so it needs to be split up.
	$(WASM_AR) crs $@ $(wordlist 1, 199, $^)
	$(WASM_AR) crs $@ $(wordlist 200, 399, $^)
	$(WASM_AR) crs $@ $(wordlist 400, 599, $^)
	$(WASM_AR) crs $@ $(wordlist 600, 799, $^)
	# This might eventually overflow again, but at least it'll do so in a loud way instead of
	# silently dropping the tail.
	$(WASM_AR) crs $@ $(wordlist 800, 100000, $^)

$(OBJDIR)/%.o: $(CURDIR)/%.c
	@mkdir -p "$(@D)"
	"$(WASM_CC)" $(WASM_CFLAGS) -MD -MP -o $@ -c $<

$(OBJDIR)/%.long-double.o: $(CURDIR)/%.c
	@mkdir -p "$(@D)"
	"$(WASM_CC)" $(WASM_CFLAGS) -MD -MP -o $@ -c $<

$(OBJDIR)/%.no-floating-point.o: $(CURDIR)/%.c
	@mkdir -p "$(@D)"
	"$(WASM_CC)" $(WASM_CFLAGS) -MD -MP -o $@ -c $<

-include $(shell find $(OBJDIR) -name \*.d)

.PHONY: default sysroot install crt libc
