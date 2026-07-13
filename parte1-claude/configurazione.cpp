#include "configurazione.h"

#include <cstdio>
#include <cstdlib>
#include <ostream>

std::vector<Comment> comments;

void saveComment(int line, const char *text) {
    comments.push_back({line, text});
}

Value *mkInt(long v) {
    Value *r = new Value;
    r->kind = Value::INT;
    r->i = v;
    return r;
}

Value *mkBool(bool v) {
    Value *r = new Value;
    r->kind = Value::BOOL;
    r->b = v;
    return r;
}

Value *mkStr(const char *s) {
    Value *r = new Value;
    r->kind = Value::STR;
    r->s = s;
    return r;
}

void addSection(Config &c, const char *name, int line) {
    for (const Section &s : c.sections)
        if (s.name == name) {
            fprintf(stderr, "error: line %d: duplicate section '%s'\n", line, name);
            exit(1);
        }
    c.sections.push_back({name, {}, line, -1});
}

void addBinding(Config &c, const char *name, Value *v, int line) {
    Section &s = c.sections.back();
    for (Binding &b : s.bindings)
        if (b.name == name) {
            fprintf(stderr, "warning: line %d: redefinition of '%s' in section '%s'\n",
                    line, name, s.name.c_str());
            b.value = *v; /* the new value wins */
            b.line = line;
            delete v;
            return;
        }
    s.bindings.push_back({name, *v, line});
    delete v;
}

Value *resolveRef(const Config &c, const char *sect, const char *var, int line) {
    /* stored values are already base ones, so one lookup resolves any chain */
    const Section *s = sect ? nullptr : &c.sections.back();
    if (sect)
        for (const Section &t : c.sections)
            if (t.name == sect) { s = &t; break; }
    if (s)
        for (const Binding &b : s->bindings)
            if (b.name == var)
                return new Value(b.value);
    fprintf(stderr, "error: line %d: undefined reference $%s%s%s\n", line,
            sect ? sect : "", sect ? "." : "", var);
    exit(1);
}

bool deleteSection(Config &c, const std::string &name) {
    for (auto it = c.sections.begin(); it != c.sections.end(); ++it)
        if (it->name == name) {
            c.sections.erase(it);
            return true;
        }
    return false;
}

bool deleteBinding(Config &c, const std::string &sect, const std::string &var) {
    for (Section &s : c.sections)
        if (s.name == sect)
            for (auto it = s.bindings.begin(); it != s.bindings.end(); ++it)
                if (it->name == var) {
                    s.bindings.erase(it);
                    return true;
                }
    return false;
}

static void printValue(std::ostream &out, const Value &v) {
    switch (v.kind) {
    case Value::INT:  out << v.i; break;
    case Value::BOOL: out << (v.b ? "true" : "false"); break;
    case Value::STR:  out << '"' << v.s << '"'; break;
    }
}

void prettyPrint(const Config &c, std::ostream &out) {
    /* Comments are emitted, in source order, just before the first surviving
     * element whose original line is >= theirs; comments whose surroundings
     * were deleted (or when elements carry no line) are flushed at the end. */
    size_t next = 0;
    auto flush = [&](int upTo, const char *indent) {
        while (upTo >= 0 && next < comments.size() && comments[next].line <= upTo)
            out << indent << comments[next++].text << "\n";
    };
    bool first = true;
    for (const Section &s : c.sections) {
        if (!first)
            out << "\n";
        first = false;
        flush(s.line, "");
        out << "<section name=" << s.name << ">\n";
        for (const Binding &b : s.bindings) {
            flush(b.line, "   ");
            out << "   <field name=" << b.name << ">";
            printValue(out, b.value);
            out << "</field>\n";
        }
        flush(s.endLine, "   ");
        out << "</section>\n";
    }
    while (next < comments.size())
        out << comments[next++].text << "\n";
}
