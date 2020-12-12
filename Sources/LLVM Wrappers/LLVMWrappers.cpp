//
//  LLVMWrappers.cpp
//  Shiba
//
//  Created by Khoa Le on 07/12/2020.
//

#include "LLVMWrappers.h"
#include "clang/AST/Attr.h"
#include "clang/AST/Decl.h"
#include "clang/Lex/LiteralSupport.h"
#include "llvm/Analysis/Passes.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Object/Archive.h"
#include "llvm/Object/ObjectFile.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Transforms/IPO.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Scalar.h"

using namespace llvm;

int clang_isNoReturn(CXCursor cursor) {
  assert(cursor.kind == CXCursor_FunctionDecl);
  auto fn = static_cast<const clang::FunctionDecl *>(cursor.data[0]);
  if (!fn) {
    return 0;
  }
  // FIXME: cannot return `fn->isNoReturn()`
  return true;
}

RawOptions ParseArguments(int argc, char **argv) {
  cl::opt<std::string> filename(cl::Positional, cl::desc("<input file>"),
                                cl::Required);
  cl::opt<bool> emitAST("emit-ast", cl::desc("Emit the AST to stdout"));
  cl::opt<bool> noImport("no-import", cl::desc("Don't import C declarations"));
  cl::opt<bool> prettyPrint("pretty-print",
                            cl::desc("Emit pretty-printed AST"));
  cl::list<std::string> args(cl::Positional, cl::desc("<interpreter-args"),
                             cl::Optional);
  cl::ParseCommandLineOptions(argc, argv);

  RawMode mode;
  bool importC = !noImport;

  if (emitAST) {
    mode = EmitAST;
  } else {
    mode = PrettyPrint;
  }

  char **remainingArgs = (char **)malloc(args.size() * sizeof(char *));
  for (auto i = 0; i < args.size(); ++i) {
    remainingArgs[i] = strdup(args[i].c_str());
  }

  auto file = filename == "-" ? "<stdin>" : filename.c_str();

  return RawOptions{importC, mode, strdup(file), remainingArgs, args.size()};
}

void DestroyRawOptions(RawOptions options) {
  free(options.filename);
  for (auto i = 0; i < options.argCount; ++i) {
    free(options.remainingArgs[i]);
  }
  free(options.remainingArgs);
}
