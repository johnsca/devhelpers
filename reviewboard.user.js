// ==UserScript==
// @name           Highlight ReviewBoard
// @namespace      userscripts.org
// @description    Colorize review summaries on RB based on whether they've been merged into dev, master, or not.
// @include        http://reviews.mydomedia.com*
// @include        http://reviews.nextowntech.com*
// @copyright      Cory Johns (masterbunnyfu)
// @version        0.2
// ==/UserScript==

function main() {
    var CSS_OPTIONS = {
        'master': {
            'row': {'opacity': 0.3},
            'summary': {'color': '#070'}
        },
        'dev': {
            'row': {'opacity': 0.6},
            'summary': {'color': '#070'}
        },
        'not merged': {
            'row': {},
            'summary': {'font-weight': 'bold'}
        }
    };

    $('#dashboard-main .datagrid tr').each(function(i, e) {
        var row = $(e);
        var summary = row.find('.summary a');
        var match = summary.text().match(/^\s*\((master|dev)\)\s+/);
        var css_options = CSS_OPTIONS[match ? match[1] : 'not merged'];

        row.css(css_options['row']);
        summary.css(css_options['summary']);
    });
}

// run main in the context of the page so it can access the page's jQuery
runInDocument(main);

function runInDocument(callback) {
    var script = document.createElement("script");
    script.textContent = "(" + callback.toString() + ")();";
    document.body.appendChild(script);
}

