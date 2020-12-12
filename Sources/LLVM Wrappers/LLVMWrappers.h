//
//  LLVMWrappers.hpp
//  Shiba
//
//  Created by Khoa Le on 07/12/2020.
//

#ifndef LLVMWrappers_h
#define LLVMWrappers_h

#include <stdbool.h>
#include <stdio.h>

#define _DEBUG
#define _GNU_SOURCE
#define __STDC_CONSTANT_MACROS
#define __STDC_FORMAT_MACROS
#define __STDC_LIMIT_MACROS
#undef DEBUG
#include <clang-c/Platform.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Core.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Transforms/IPO.h>
#include <llvm-c/Transforms/Scalar.h>

#include "shiba.h"

#ifdef I
#undef I
#endif

#import <clang-c/Index.h>

#ifdef __cplusplus
extern "C" {
#endif

_Pragma("clang assume_nonnull begin")

typedef enum RawMode {
	EmitAST,
	PrettyPrint
} RawMode;

typedef struct RawOptions {
	bool importC;
	RawMode mode;
	char *_Nullable filename;
	char *_Nullable *_Nonnull remainingArgs;
	size_t argCount;
} RawOptions;

int clang_isNoReturn(CXCursor cursor);
RawOptions ParseArguments(int argc, char *_Nullable *_Nullable argv);
void DestroyRawOptions(RawOptions options);

#ifdef __cplusplus
}
#endif

_Pragma("clang assume_nonnull end")

#endif /* LLVMWrappers_h */
