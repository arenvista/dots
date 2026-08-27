local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {

-- ==================================================
-- BASIC STRUCTURE
-- ==================================================

s({ trig = "main" }, {
    t({ "#include <bits/stdc++.h>",
        "using namespace std;",
        "",
        "int main() {",
        "    " }),
    i(1),
    t({ "",
        "    return 0;",
        "}" }),
}),

s({ trig = "mainc" }, {
    t({ "#include <stdio.h>",
        "#include <stdlib.h>",
        "#include <unistd.h>",
        "",
        "int main() {",
        "    " }),
    i(1),
    t({ "",
        "    return 0;",
        "}" }),
}),

-- ==================================================
-- STRUCTS
-- ==================================================

s({ trig = "struct" }, {
    t({ "struct " }), i(1, "Name"),
    t({ " {", "    " }),
    i(2, "// members"),
    t({ "", "};" }),
}),

s({ trig = "tstruct" }, {
    t({ "typedef struct {", "    " }),
    i(1, "// members"),
    t({ "", "} " }), i(2, "Name"), t({ ";" }),
}),

-- ==================================================
-- HEADER GUARDS
-- ==================================================

s({ trig = "guard" }, {
    t({ "#ifndef " }), i(1, "FILENAME_H"),
    t({ "", "#define " }), i(1),
    t({ "", "" }),
    i(2, "// declarations"),
    t({ "", "", "#endif // " }), i(1),
}),

s({ trig = "once" }, {
    t({ "#pragma once", "" }),
    i(1, "// declarations"),
}),

-- ==================================================
-- STL CONTAINERS
-- ==================================================

s({ trig = "vec" }, {
    t("vector<"), i(1, "int"), t("> "), i(2, "v")
}),

s({ trig = "mp" }, {
    t("map<"), i(1, "int"), t(", "), i(2, "int"), t("> "), i(3, "m")
}),

s({ trig = "ump" }, {
    t("unordered_map<"), i(1, "int"), t(", "), i(2, "int"), t("> "), i(3, "um")
}),

s({ trig = "st" }, {
    t("set<"), i(1, "int"), t("> "), i(2, "s")
}),

s({ trig = "pq" }, {
    t("priority_queue<"), i(1, "int"), t("> "), i(2, "pq")
}),

s({ trig = "ll" }, t("long long")),
s({ trig = "pii" }, t("pair<int,int>")),
s({ trig = "pll" }, t("pair<long long,long long>")),

-- ==================================================
-- LOOPS
-- ==================================================

s({ trig = "fori" }, {
    t("for (int "), i(1, "i"),
    t(" = "), i(2, "0"),
    t("; "), i(1),
    t(" < "), i(3, "n"),
    t("; "), i(1),
    t("++) {"),
    t({ "", "    " }),
    i(4),
    t({ "", "}" }),
}),

s({ trig = "each" }, {
    t("for (auto &"), i(1, "x"),
    t(" : "), i(2, "container"),
    t(") {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
}),

-- ==================================================
-- SWITCH / CASE
-- ==================================================

s({ trig = "switch" }, {
    t("switch ("), i(1, "expr"), t(") {"),
    t({ "", "case " }), i(2, "value"), t(":"),
    t({ "", "    " }), i(3, "// code"),
    t({ "", "    break;", "", "default:", "    " }),
    i(4, "// default"),
    t({ "", "    break;", "}" }),
}),

s({ trig = "case" }, {
    t("case "), i(1, "value"), t(":"),
    t({ "", "    " }), i(2, "// code"),
    t({ "", "    break;" }),
}),

-- ==================================================
-- STL HELPERS
-- ==================================================

s({ trig = "pb" }, t(".push_back(")),
s({ trig = "em" }, t(".emplace_back(")),

s({ trig = "all" }, {
    i(1, "v"), t(".begin(), "), i(1), t(".end()")
}),

s({ trig = "srt" }, {
    t("sort("), i(1, "v.begin(), v.end()"), t(");")
}),

-- ==================================================
-- IO
-- ==================================================

s({ trig = "cout" }, {
    t("cout << "), i(1), t(" << endl;")
}),

s({ trig = "cin" }, {
    t("cin >> "), i(1), t(";")
}),

s({ trig = "printf" }, {
    t('printf("'), i(1),
    t('\\n", '), i(2), t(");")
}),

-- ==================================================
-- POSIX SYSCALLS
-- ==================================================

s({ trig = "fork" }, t("fork();")),

s({ trig = "exec" }, {
    t('execl("'), i(1, "/bin/ls"),
    t('", "'), i(2, "ls"),
    t('", NULL);')
}),

s({ trig = "wait" }, t("wait(NULL);")),

s({ trig = "pipe" }, {
    t("int "), i(1, "fd"),
    t({ "[2];", "pipe(" }), i(1), t(");")
}),

s({ trig = "dup2" }, {
    t("dup2("), i(1), t(", "), i(2), t(");")
}),

s({ trig = "open" }, {
    t('open("'), i(1, "file.txt"),
    t('", O_RDONLY);')
}),

s({ trig = "read" }, {
    t("read("), i(1),
    t(", "), i(2),
    t(", "), i(3),
    t(");")
}),

s({ trig = "write" }, {
    t("write("), i(1),
    t(", "), i(2),
    t(", "), i(3),
    t(");")
}),

s({ trig = "close" }, {
    t("close("), i(1), t(");")
}),

s({ trig = "exit" }, {
    t("exit("), i(1, "0"), t(");")
}),

}
