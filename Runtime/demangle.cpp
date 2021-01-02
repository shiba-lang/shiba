//
//  demangle.cpp
//  Shiba
//
//  Created by Khoa Le on 07/12/2020.
//

#include "demangle.h"
#include <string>
#include <vector>

namespace shiba {
bool readNum(std::string &str, int &out) {
  char *end;
  const char *start = str.c_str();
  int num = (int)strtol(start, &end, 10);
  if (end == start) {
    return false;
  }
  str.erase(0, end - start);
  out = num;
  return true;
}

bool readName(std::string &str, std::string &out) {
  int num = 0;
  if (!readNum(str, num)) {
    return false;
  }

  if (str.size() < num) {
    return false;
  }

  out += str.substr(0, num);
  str.erase(0, num);
  return true;
}

bool readType(std::string &str, std::string &out) {
  if (str.front() == 'P') {
    str.erase(0, 1);
    int num;
    if (!readNum(str, num)) {
      return false;
    }
    out += std::string(num, '*');
    if (str.front() != 'T') {
      return false;
    }
    str.erase(0, 1);
  }

  if (str.front() == 'F') {
    str.erase(0, 1);
    out += '(';
    std::vector<std::string> argNames;
    while (str.front() != 'R') {
      std::string name;
      if (!readType(str, name)) {
        return false;
      }
      argNames.push_back(name);
    }
    str.erase(0, 1);
    for (auto i = 0; i < argNames.size(); ++i) {
      out += argNames[i];
      if (i < argNames.size() - 1) {
        out += ", ";
      }
    }
    out += ") -> ";
    if (!readType(str, out)) {
      return false;
    }
  } else if (str.front() == 't') {
    str.erase(0, 1);
    out += '(';
    std::vector<std::string> fieldNames;
    while (str.front() != 'T') {
      std::string name;
      if (!readType(str, name)) {
        return false;
      }
      fieldNames.push_back(name);
    }
    str.erase(0, 1);
    for (auto i = 0; i < fieldNames.size(); ++i) {
      out += fieldNames[i];
      if (i < fieldNames.size() - 1) {
        out += ", ";
      }
    }
    out += ')';
  } else if (str.front() == 's') {
    str.erase(0, 1);
    switch (str.front()) {
    case 'i':
      str.erase(0, 1);
      out += "Int";
      int num;
      if (readNum(str, num)) {
        out += std::to_string(num);
      }
      break;
    case 'I':
      str.erase(0, 1);
      out += "Int";
      break;
    case 'f':
      str.erase(0, 1);
      out += "Float";
      break;
    case 'd':
      str.erase(0, 1);
      out += "Double";
      break;
    case 'F':
      str.erase(0, 1);
      out += "Float80";
      break;
    case 'b':
      str.erase(0, 1);
      out += "Bool";
      break;
    case 'v':
      str.erase(0, 1);
      out += "Void";
      break;
    default:
      return false;
    }
  } else {
    if (!readName(str, out)) {
      return false;
    }
  }
  return true;
}

bool readArg(std::string &str, std::string &out) {
  std::string external = "";
  std::string internal = "";

  auto isSingleName = false;
  if (str.front() == 'S') {
    str.erase(0, 1);
    isSingleName = true;
  } else if (str.front() == 'E') {
    str.erase(0, 1);
    if (!readName(str, external)) {
      return false;
    }
  }

  if (!readName(str, internal)) {
    return false;
  }

  std::string type;
  if (!readType(str, type)) {
    return false;
  }

  if (!isSingleName) {
    if (external.empty()) {
      external = "_";
    }
    out += external + " ";
  }
  out += internal + ": ";
  out += type;
  return true;
}

bool demangleType(std::string &symbol, std::string &out) {
  symbol.erase(0, 1);
  return readType(symbol, out);
}

bool demangleClosure(std::string &symbol, std::string &out) {
  assert(false && "closure demangling is unimplemented");
  return false;
}

bool demangleFunction(std::string &symbol, std::string &out) {
  symbol.erase(0, 1);
  if (symbol.front() == 'D') {
    symbol.erase(0, 1);
    if (!readType(symbol, out)) {
      return false;
    }
    out += ".deinit";
  } else {
    if (symbol.front() == 'M') {
      symbol.erase(0, 1);
      if (!readType(symbol, out)) {
        return false;
      }
      out += '.';
      if (!readName(symbol, out)) {
        return false;
      }
    } else if (symbol.front() == 'I') {
      symbol.erase(0, 1);
      if (!readType(symbol, out)) {
        return false;
      }
      out += ".init";
    } else {
      if (!readName(symbol, out)) {
        return false;
      }
    }
    out += '(';
    std::vector<std::string> args;
    while (symbol.front() != '_') {
      std::string arg;
      if (!readArg(symbol, arg)) {
        return false;
      }
      args.push_back(arg);
    }
    symbol.erase(0, 1);
    for (auto i = 0; i < args.size(); ++i) {
      out += args[i];
      if (i < args.size() - 1) {
        out += ", ";
      }
    }
    out += ')';
    if (symbol.front() == 'R') {
      symbol.erase(0, 1);
      std::string type;
      if (!readType(symbol, type)) {
        return false;
      }
      out += " -> " + type;
    }
    if (symbol.front() == 'C') {
      symbol.erase(0, 1);
      out += " (closure #1)";
    }
  }
  return true;
}

bool demangle(std::string &symbol, std::string &out) {
  if (symbol.substr(0, 2) != "_W") {
    return false;
  }
  symbol.erase(0, 2);
  switch (symbol.front()) {
  case 'C':
    return demangleClosure(symbol, out);
  case 'F':
		return demangleFunction(symbol, out);
  case 'T':
    return demangleType(symbol, out);
  }
  return false;
}

char *shiba_demangle(const char *symbol) {
  std::string sym(symbol);
  std::string out;
  if (!demangle(sym, out)) {
    return nullptr;
  }
  return strdup(out.c_str());
}

} // namespace shiba
