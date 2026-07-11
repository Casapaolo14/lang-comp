#ifndef MYCONFIG_H
#define MYCONFIG_H

#include <string>
#include <vector>

enum class ValueKind { Int, Bool, Str, RefLocal, RefQual };

struct MyValue {
    ValueKind kind;
    int ival = 0;
    bool bval = false;
    std::string sval;
    std::string refSection;
    std::string refName;
};

struct Binding {
    std::string name;
    MyValue value;
};

struct MySection {
    std::string name;
    std::vector<Binding> fields;
};

struct MyConfig {
    std::vector<MySection> sections;
};

#endif