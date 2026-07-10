  Done — everything the PDF requires is built and verified in parte1-gruppo-24-14/. All demo cases pass,
  including a byte-identical round-trip, and the deletion functions check out.

  What's there

  - lexer.l (Flex 2.6.4) — tokenizes the language; strips #-comments and saves them with their line number in a
  structure only the pretty-printer reads, exactly as the text requires.
  - parser.y (Bison 3.8.2) — the grammar, with the section head as a separate rule so a duplicate section is a
  blocking error the moment it's opened, and local $var references can see the section under construction. Field
  redefinition in the same section warns on stderr and the new value wins.
  - config.h / config.cpp — Alternative 1 data structure (sections → bindings of base int/bool/string values; the
  parser resolves $var and $sez.var at parse time, so one lookup resolves any chain). Includes the required
  deleteSection / deleteBinding and the pretty-printer, which interleaves saved comments by original line number;
  elements created or edited after parsing carry no line, so orphaned comments are flushed at the end — never
  lost.
  - main.cpp — the required executable: parse a file, emit its serialization.
  - Makefile — GNU make, g++ -std=c++17, targets all, demo, clean.
  - tests/ — the PDF's own example, reference chains (local + cross-section), redefinition warning,
  duplicate-section error, and the round-trip check.

  Assumptions applied (worth restating orally at the exam since you're skipping the report): keywords
  section/field/name are reserved; strings have no escapes and can't span lines; integers may be negative;
  references must point to already-defined variables (true of the PDF's example — Alternative 1 resolves
  eagerly); comment placement in output is "nearest surviving element", which the text doesn't constrain.

  Skipped: BNFC prototype (optional per the text), modify functions (explicitly optional), report (your
  instruction). Before zipping for submission, run make clean — the zip must not contain generated files
  (confparser, parser.tab.*, lex.yy.cpp), and remember the required zip/report naming if you add the report
  later.
