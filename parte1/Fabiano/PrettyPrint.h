#ifndef PRETTYPRINT_H
#define PRETTYPRINT_H

#include "MyConfig.h"
#include <string>

std::string prettyPrintValue(const MyValue& v);
std::string prettyPrint(const MyConfig& config);

#endif