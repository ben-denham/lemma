// Format %%hy and %%lemma cells using scheme syntax highlighting.
IPython.CodeCell.options_default.highlight_modes['magic_text/x-scheme'] = {'reg': [/^%%(hy|lemma)/]} ;
IPython.notebook.events.one('kernel_ready.Kernel', function() {
  IPython.notebook.get_cells().map(function(cell) {
    if (cell.cell_type == 'code'){
        cell.auto_highlight();
    }
  });
});
// Add more obvious highlighting of matching brackets.
var styleSheet = document.createElement('style');
styleSheet.type = 'text/css';
styleSheet.innerText = '.CodeMirror-matchingbracket { outline: solid 1px; }';
document.head.appendChild(styleSheet);