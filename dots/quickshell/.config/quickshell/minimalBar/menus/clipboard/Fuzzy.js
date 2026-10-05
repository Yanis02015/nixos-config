.pragma library

// fzf-style subsequence matching for the clipboard panel.
/* Each query token must appear in the text as a subsequence (letters in order,
 gaps allowed), otherwise the entry is dropped (return null). For each token the
 shortest window is found (forward scan to the first full match, then backward
 scan to tighten its start), and the matched characters are scored:
 base 16 · consecutive +15 · word boundary +10 · gap -3 first char, -1 after.
 Token scores add up; matched positions are returned for highlighting. */

var BASE = 16;
var CONSECUTIVE = 15;
var BOUNDARY = 10;
var GAP_START = 3;
var GAP_EXTEND = 1;

function isBoundary(ch) {
    return !/[a-z0-9]/.test(ch);
}

function matchToken(text, tok) {
    // forward: earliest end of a full subsequence match
    var j = 0;
    var end = -1;
    for (var i = 0; i < text.length && j < tok.length; i++) {
        if (text[i] === tok[j]) {
            j++;
            if (j === tok.length)
                end = i;
        }
    }
    if (end < 0)
        return null;

    // backward: latest start that still matches -> shortest window
    var k = tok.length - 1;
    var start = end;
    for (var b = end; b >= 0 && k >= 0; b--) {
        if (text[b] === tok[k]) {
            k--;
            start = b;
        }
    }

    // forward again inside the window to collect positions + score them
    var positions = [];
    var score = 0;
    var prev = -1;
    j = 0;
    for (var p = start; p <= end && j < tok.length; p++) {
        if (text[p] !== tok[j])
            continue;
        var s = BASE;
        if (prev >= 0 && p === prev + 1)
            s += CONSECUTIVE;
        else if (prev >= 0)
            s -= GAP_START + (p - prev - 2) * GAP_EXTEND;
        if (p === 0 || isBoundary(text[p - 1]))
            s += BOUNDARY;
        score += s;
        positions.push(p);
        prev = p;
        j++;
    }
    return {
        score: score,
        positions: positions
    };
}

// text must already be lowercased; tokens are lowercased, non-empty strings
function match(text, tokens) {
    var total = 0;
    var positions = [];
    for (var i = 0; i < tokens.length; i++) {
        var m = matchToken(text, tokens[i]);
        if (!m)
            return null;
        total += m.score;
        positions = positions.concat(m.positions);
    }
    return {
        score: total,
        positions: positions
    };
}

function escapeChar(ch) {
    if (ch === "&")
        return "&amp;";
    if (ch === "<")
        return "&lt;";
    if (ch === ">")
        return "&gt;";
    return ch;
}

// StyledText with matched characters wrapped in a colored <font> run
function highlight(text, positions, color) {
    var hit = {};
    for (var i = 0; i < positions.length; i++)
        hit[positions[i]] = true;
    var out = "";
    var inRun = false;
    for (var c = 0; c < text.length; c++) {
        if (hit[c] && !inRun) {
            out += '<font color="' + color + '">';
            inRun = true;
        } else if (!hit[c] && inRun) {
            out += "</font>";
            inRun = false;
        }
        out += escapeChar(text[c]);
    }
    if (inRun)
        out += "</font>";
    return out;
}
