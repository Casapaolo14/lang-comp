#ifndef BUILD_H
#define BUILD_H

#include "MyConfig.h"
#include "Absyn.H"

MyValue convertiValue(Value* v);
MyConfig build(Conf* ast);

#endif