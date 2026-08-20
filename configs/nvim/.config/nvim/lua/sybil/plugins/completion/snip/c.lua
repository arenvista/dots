local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

return {
s({ trig = "print", snippetType = "autosnippet" },
        fmta([[
        printf("<>");
        ]],
        {i(1)}
        )
),

s({ trig = "prnl", snippetType = "autosnippet" },
    fmta([[
        printf("<>\n"<>);
        ]],
        {
            i(1, "Text"),
            i(2, ", args")
        }
    )
),
s({ trig = "#inc", snippetType = "autosnippet" },
        fmta([[#include <>]],
        {i(1)}
        )
),

s({ trig = "#def", snippetType = "autosnippet" },
        fmta([[#define <>]],
        {i(1)}
        )
),

-- ==================================================
-- BASIC STRUCTURE
-- ==================================================
s({ trig = "if", snippetType = "snippet" },
    fmta([[
    if (<>){
        <>
    }
        ]] ,
        {
            i(1, "/*expression*/"),
            i(2, "// code"),
        }
    ), {}
),

s({ trig = "elif", snippetType = "snippet" },
    fmta([[
    else if (<>){
        <>
    }
        ]] ,
        {
            i(1, "/*expression*/"),
            i(2, "// code"),
        }
    ), {}
),

s({ trig = "else", snippetType = "snippet" },
    fmta([[
    else {
        <>
    }
        ]] ,
        {
            i(1, "// code"),
        }
    ), {}
),

s({ trig = "func", snippetType = "snippet" },
    fmta([[
    <> <> (<>){
        <>
    } <>
        ]] ,
        {
            i(1, "void"),
            i(2, "func"),
            i(3, "int num"),
            i(4, "return;"),
            i(5)
        }
    ), {}
),

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

s({ trig = "struct", snippetType = "snippet" },
    fmta([[
    struct <>{
        <>
    } <>
        ]] ,
        {
            i(1, "Name"),
            i(2, "// Members"),
            i(3)
        }
    ), {}
),

s({ trig = "tstruct", snippetType = "snippet" },
    fmta([[
    typedef struct <>{
        <>
    } <>
        ]] ,
        {
            i(1, "NameA"),
            i(2, "// Members"),
            i(3, "NameB")
        }
    ), {}
),

-- ==================================================
-- HEADER GUARDS
-- ==================================================

s({ trig = "tstruct", snippetType = "snippet" },
    fmta([[
    #ifndef <>
    #define <>
    <>
    #endif 
        ]] ,
        {
            i(1, "Name"),
            rep(1),
            i(2, "// Declarations"),
        }
    ), {}
),


-- ==================================================
-- LOOPS
-- ==================================================
s({ trig = "fori", snippetType = "snippet" },
    fmta([[
    for (int i=0; i << <>; i++){
    <>
    } <>
        ]],
        {
            i(1, "itters"),
            i(2, "// Content"),
            i(3),
        }, { delimiters = "<>" }
    ), {}
),


s({ trig = "while", snippetType = "snippet" },
    fmta([[
    while (<>){
    <>
    }
        ]],
        {
            i(1, "expression"),
            i(2, "// code"),
        }, { delimiters = "<>" }
    ), {}
),

s({ trig = "len", snippetType = "snippet" },
    fmta([[
        size_t <> = sizeof(<>) / sizeof(<>[0]);
        ]],
        {
            i(1, "length"),
            i(2, "continer"),
            rep(2)
        }, { delimiters = "<>" }
    ), {}
),

-- ==================================================
-- SWITCH / CASE
-- ==================================================

s({ trig = "switch", snippetType = "snippet" },
    fmta([[
        switch (<>){
        case <>:
             <>
             break;
        default:
             <>
             break;
        }
        ]],
        {
            i(1, "expression"),
            i(2, "value"),
            i(3, "// code"),
            i(4, "default"),
        }, { delimiters = "<>" }
    ), {}
),

s({ trig = "switch", snippetType = "snippet" },
    fmta([[
    case <>:
        <>
        break;
        ]],
        {
            i(1, "value"),
            i(2, "// code"),
        }, { delimiters = "<>" }
    ), {}
),

-- ==================================================
-- ENUM
-- ==================================================

s({ trig = "enum", snippetType = "snippet" },
    fmta([[
    enum <>{
        <>
    };
        ]],
        {
            i(1, "Name"),
            i(2, "// code"),
        }, { delimiters = "<>" }
    ), {}
),

s({ trig = "enumr", snippetType = "snippet" },
    fmta([[
    enum <>{
        <>
    };

    enum <> resolve_<>(char* cmd_str){
        if (cmd_str == NULL) return 0;
        if (strcmp(cmd_str, "<>") == 0) return <>;
    }
        ]],
        {
            i(1, "Name"), -- 1st <>
            i(2, "VAL"),  -- 2nd <>
            rep(1),       -- 3rd <> (Repeats "Name")
            rep(1),       -- 4th <> (Repeats "Name")
            rep(2),       -- 5th <> (Repeats "VAL")
            rep(2),       -- 6th <> (Repeats "VAL")
        }
    )
),
-- ==================================================
-- FOPEN
-- ==================================================
s({ trig = "open_read", snippetType = "snippet" },
    fmta([[
        FILE* file = fopen("<>", "<>");
        if (file == NULL){
            printf("Error: File (<>) Could not open file.\n");
            return EXIT_FAILURE;
        }

        char *buffer = NULL; 
        size_t bufsize = 0;
        ssize_t chars_read;
        while ((chars_read = getline(&buffer, &bufsize, file)) != -1) {
            // buffer now holds the entire line, no matter how long it is
            printf("%s", buffer);
            <>
        }

        if (ferror(file)) {
            perror("Error reading from file");
            free(buffer);
            fclose(file);
            return EXIT_FAILURE;
        }

        free(buffer);
        fclose(file);
        ]],
        {
            i(1, "file_name"),
            i(2, "r"),
            rep(1),
            i(3, "// code"),
        }
    )
),

s({ trig = "open_write", snippetType = "snippet" },
    fmta([[
        FILE* file = fopen("<>", "<>");
        if (file == NULL){
            printf("Error: File (<>) could not be opened.\n");
            return EXIT_FAILURE;
        }

        fprintf(file, <>);

        if (ferror(file)) {
            perror("Error writing to file");
            fclose(file);
            return EXIT_FAILURE;
        }

        fclose(file);
        ]],
        {
            i(1, "file_name.txt"),
            i(2, "w"),
            rep(1),
            i(3, "f\"Hello World\\n\""),
        }
    )
),

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

--- 
s({ trig = "malloc", snippetType = "snippet" },
    fmta([[
        <> *<> = malloc(sizeof(<>) * <>);
        if (<> == NULL) {
            fprintf(stderr, "Error: Memory allocation failed for <>\n");
            <>
        }
        ]],
        {
            i(1, "type"),
            i(2, "ptr"),
            rep(1),          -- Repeats the type for sizeof
            i(3, "count"),
            rep(2),          -- Repeats ptr name in if check
            rep(2),          -- Repeats ptr name in error message
            i(4, "return EXIT_FAILURE;"),
        }
    )
),

s({ trig = "sfree", snippetType = "snippet" },
    fmta([[
        if (<> != NULL) {
            free(<>);
            <> = NULL;
        }
        ]],
        {
            i(1, "ptr"),
            rep(1),
            rep(1),
        }
    )
),

s({ trig = "alloc", snippetType = "snippet" },
    fmta([[
        <> *<> = <>(<>);
        if (<> == NULL) {
            fprintf(stderr, "Error: Memory allocation failed for <>\n");
            <>
        }
        ]],
        {
            i(1, "type"),
            i(2, "ptr"),
            -- Choice Node 1: Toggle between malloc and calloc
            c(3, {
                t("malloc"),
                t("calloc")
            }),
            i(4, "sizeof(type) * count"), -- The arguments
            rep(2),                       -- Repeats ptr for NULL check
            rep(2),                       -- Repeats ptr for error log
            -- Choice Node 2: Toggle how the error is handled
            c(5, {
                t("return EXIT_FAILURE;"),
                t("return NULL;"),
                t("exit(1);")
            }),
        }
    )
),
}
