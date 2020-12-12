//
//  demangle.hpp
//  Shiba
//
//  Created by Khoa Le on 07/12/2020.
//

#ifndef demangle_h
#define demangle_h

#include <stdio.h>

#ifdef __cplusplus
#include <string>
namespace shiba {
bool demangle(std::string &symbol, std::string &out);

extern "C" {
#endif

char *shiba_demangle(const char *symbol);

#ifdef __cplusplus
}
}
#endif

#endif /* demangle_hpp */
