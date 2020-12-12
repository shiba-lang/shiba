//
//  Runtime.cpp
//  Runtime
//
//  Created by Khoa Le on 07/12/2020.
//

#include "runtime.h"
#include "demangle.h"
#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>
#include <inttypes.h>
#include <iostream>
#include <libgen.h>
#include <string>

namespace shiba {

#define MAX_STACK_DEPTH 256

std::string demangle(std::string symbol) {
  std::string out;
  if (demangle(symbol, out)) {
    return out;
  }

  int status;
  auto result = abi::__cxa_demangle(symbol.c_str(), nullptr, nullptr, &status);
  if (result) {
    out = result;
    free(result);
    return out;
  }
  out = symbol;
  return out;
}

void print_stacktrace() {
  void *symbols[MAX_STACK_DEPTH];
  int frames = backtrace(symbols, MAX_STACK_DEPTH);
  fputs("Current stack trace:\n", stderr);

  for (int i = 0; i < frames; ++i) {
    Dl_info handle;
    if (dladdr(symbols[i], &handle) == 0) {
      continue;
    }

    auto base = basename((char *)handle.dli_fname);

    auto symbol = demangle(handle.dli_sname);
    fprintf(stderr, "%-4d %-34s 0x%016" PRIxPTR " %s + %ld\n", i, base,
            (long)handle.dli_saddr, symbol.c_str(),
            (intptr_t)symbols[i] - (intptr_t)handle.dli_saddr);
  }
}

SHIBA_NORETURN
void crash() {
  print_stacktrace();
  abort();
}

SHIBA_NORETURN
void shiba_fatalError(const char *_Nonnull message) {
  fprintf(stderr, "fatal error: %s\n", message);
  crash();
}

__attribute__((always_inline)) static void *shiba_malloc(size_t size) {
  return malloc(size);
}

void *shiba_alloc(size_t size) {
  void *ptr = shiba_malloc(size);
  if (!ptr) {
    shiba_fatalError("malloc failed");
  }
  memset(ptr, 0, size);
  return ptr;
}

void shiba_registerDeinitializer(void *object, void (*deinitializer)(void *)) {}

void shiba_handleSignal(int signal) {
  fprintf(stderr, "%s\n", strsignal(signal));
  print_stacktrace();
  abort();
}

void shiba_init() {
  signal(SIGSEGV, shiba_handleSignal);
  signal(SIGILL, shiba_handleSignal);
}

} // namespace shiba
