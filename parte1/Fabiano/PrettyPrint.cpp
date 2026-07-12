#include "PrettyPrint.h"
#include <sstream>

std::string prettyPrintValue(const MyValue& v) {
    switch (v.kind) {
        case ValueKind::Int:
            return std::to_string(v.ival);
        case ValueKind::Bool:
            return v.bval ? "true" : "false";
        case ValueKind::Str:
            return "\"" + v.sval + "\"";
        case ValueKind::RefLocal:
            return "$" + v.refName;
        case ValueKind::RefQual:
            return "$" + v.refSection + "." + v.refName;
    }
    return "";
}

std::string prettyPrint(const MyConfig& config) {
    std::ostringstream out;

    for (const MySection& sect : config.sections) {
        for (const std::string& c : sect.commenti) {
            out << c << "\n";
        }
        out << "<section name=" << sect.name << ">\n";

        for (const Binding& b : sect.fields) {
            for (const std::string& c : b.commenti) {
                out << c << "\n";
            }
            out << "<field name=" << b.name << ">"
                << prettyPrintValue(b.value)
                << "</field>\n";
        }

        out << "</section>\n";
    }

    return out.str();
}