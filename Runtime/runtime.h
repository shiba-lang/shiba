//
//  Runtime.hpp
//  Runtime
//
//  Created by Khoa Le on 07/12/2020.
//

#ifndef runtime_h
#define runtime_h

#include <stdio.h>

#define SHIBA_NORETURN __attribute__((noreturn))

#ifdef __cplusplus
namespace Shiba {
extern "C" {
#endif

void shiba_init();
void *_Nonnull shiba_alloc(size_t size);
void shiba_fatalError(const char *_Nonnull message) SHIBA_NORETURN;
void shiba_registerDeinitializer(
    void *_Nonnull object, void (*_Nonnull deinitializer)(void *_Nonnull));

#ifdef __cplusplus
}
}
#endif

#endif /* runtime*/
