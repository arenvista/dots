.pragma library

// Small, safe arithmetic evaluator for the launcher (no eval): numbers,
// + - * / % ^, parentheses, pi/e and common functions. evaluate() returns a
// number, or null when the text isn't a calculation. Bare numbers ("2") are
// not calculations, so they keep searching apps; a leading "=" forces one.

var FUNCTIONS = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, exp: Math.exp,
    sin: Math.sin, cos: Math.cos, tan: Math.tan,
    asin: Math.asin, acos: Math.acos, atan: Math.atan,
    ln: Math.log, log: Math.log10, log2: Math.log2,
    round: Math.round, floor: Math.floor, ceil: Math.ceil
}
var CONSTANTS = { pi: Math.PI, e: Math.E, tau: 2 * Math.PI }

function tokenize(s) {
    var tokens = []
    var i = 0
    while (i < s.length) {
        var c = s[i]
        if (c === " ") { i++; continue }
        var num = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/.exec(s.slice(i))
        if (num) { tokens.push({ t: "num", v: parseFloat(num[0]) }); i += num[0].length; continue }
        var id = /^[a-z][a-z0-9]*/.exec(s.slice(i))
        if (id) { tokens.push({ t: "id", v: id[0] }); i += id[0].length; continue }
        if ("+-*/%^(),".indexOf(c) >= 0) { tokens.push({ t: c }); i++; continue }
        if (c === "×") { tokens.push({ t: "*" }); i++; continue }
        if (c === "÷") { tokens.push({ t: "/" }); i++; continue }
        return null
    }
    return tokens
}

function Parser(tokens) {
    this.tokens = tokens
    this.pos = 0
    this.isCalc = false  // saw an operator or function call
}
Parser.prototype.peek = function() { return this.tokens[this.pos] }
Parser.prototype.take = function(t) {
    var tok = this.tokens[this.pos]
    if (tok && tok.t === t) { this.pos++; return tok }
    return null
}
Parser.prototype.expr = function() {
    var v = this.term()
    for (var op; (op = this.take("+") || this.take("-"));) {
        this.isCalc = true
        var r = this.term()
        v = op.t === "+" ? v + r : v - r
    }
    return v
}
Parser.prototype.term = function() {
    var v = this.unary()
    for (var op; (op = this.take("*") || this.take("/") || this.take("%"));) {
        this.isCalc = true
        var r = this.unary()
        v = op.t === "*" ? v * r : op.t === "/" ? v / r : v % r
    }
    return v
}
Parser.prototype.unary = function() {
    if (this.take("-")) { this.isCalc = true; return -this.unary() }
    if (this.take("+")) return this.unary()
    return this.power()
}
Parser.prototype.power = function() {
    var base = this.primary()
    if (this.take("^")) {
        this.isCalc = true
        return Math.pow(base, this.unary())  // right-associative; allows 2^-1
    }
    return base
}
Parser.prototype.primary = function() {
    var tok = this.peek()
    if (!tok) throw "end"
    if (this.take("num")) return tok.v
    if (this.take("(")) {
        var v = this.expr()
        if (!this.take(")")) throw "paren"
        return v
    }
    if (this.take("id")) {
        // A lone constant isn't a calculation: typing "e" should still search apps.
        if (CONSTANTS.hasOwnProperty(tok.v)) return CONSTANTS[tok.v]
        if (FUNCTIONS.hasOwnProperty(tok.v) && this.take("(")) {
            this.isCalc = true
            var arg = this.expr()
            if (!this.take(")")) throw "paren"
            return FUNCTIONS[tok.v](arg)
        }
    }
    throw "unexpected"
}

function evaluate(text) {
    var s = String(text).trim().toLowerCase()
    var forced = s.startsWith("=")
    if (forced) s = s.slice(1)
    if (s === "") return null
    var tokens = tokenize(s)
    if (!tokens || tokens.length === 0) return null
    var p = new Parser(tokens)
    var v
    try { v = p.expr() } catch (e) { return null }
    if (p.pos !== tokens.length || !isFinite(v) || !(p.isCalc || forced)) return null
    return v
}

// 0.1 + 0.2 -> "0.3", not "0.30000000000000004".
function format(v) {
    return String(Number(v.toPrecision(12)))
}
