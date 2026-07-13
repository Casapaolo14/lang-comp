#ifndef CONFIGURAZIONE_H
#define CONFIGURAZIONE_H

#include <string>
#include <vector>
#include <iosfwd>

/* Alternative 1: the structure holds base values only (int/bool/string);
 * $references are resolved by the parser as soon as they are read. */
struct Value {
    enum Kind { INT, BOOL, STR };
    Kind kind = INT;
    long i = 0;
    bool b = false;
    std::string s;
};

/* 'line' fields hold the position in the parsed file and are used only to
 * place the original comments during pretty-printing; elements created or
 * modified after parsing carry -1 (no comment is attached to them). */
struct Binding {
    std::string name;
    Value value;
    int line = -1;
};

struct Section {
    std::string name;
    std::vector<Binding> bindings;
    int line = -1;    /* opening tag */
    int endLine = -1; /* closing tag */
};

struct Config {
    std::vector<Section> sections;
};

/* Comments saved by the lexer (in source order), recovered by the
 * pretty-printer; they never reach the parser. */
struct Comment {
    int line;
    std::string text;
};
extern std::vector<Comment> comments;
void saveComment(int line, const char *text);

/* Construction functions used by the parser. */
Value *mkInt(long v);
Value *mkBool(bool v);
Value *mkStr(const char *s);
/* Appends a new section; duplicate section name: error + exit(1). */
void addSection(Config &c, const char *name, int line);
/* Adds a binding to the last section; redefinition: warning, new value wins. */
void addBinding(Config &c, const char *name, Value *v, int line);
/* Returns (a copy of) the base value bound to 'var' in section 'sect'
 * (nullptr = the section under construction); undefined: error + exit(1). */
Value *resolveRef(const Config &c, const char *sect, const char *var, int line);

/* Editing functions required by the assignment (not used by the executable);
 * they return false if the section/binding does not exist. */
bool deleteSection(Config &c, const std::string &name);
bool deleteBinding(Config &c, const std::string &sect, const std::string &var);

/* Serializes the structure in valid input syntax, interleaving the saved
 * comments according to their original line numbers. */
void prettyPrint(const Config &c, std::ostream &out);

#endif
