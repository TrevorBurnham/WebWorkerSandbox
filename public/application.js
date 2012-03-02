if (!window.Worker) {
  alert('Sorry, your browser does not support Web Workers.');
};

// Initialize editors
var JavaScriptMode = require('ace/mode/javascript').Mode;

var masterEditor = ace.edit('masterEditor'), 
    workerEditor = ace.edit('workerEditor');
[masterEditor, workerEditor].forEach(function(editor) {
  editor.setTheme('ace/theme/tomorrow_night')
  editor.setShowPrintMargin(false);
});

var masterSession = masterEditor.getSession(),
    workerSession = workerEditor.getSession();
[masterSession, workerSession].forEach(function(session) {
  session.setMode(new JavaScriptMode());
  session.setTabSize(2);
  session.setUseSoftTabs(true);
  session.setUseWrapMode(true);
});

// Enable run button
$('#run').on('click', function() {
  var master = masterSession.getValue();
  var worker = workerSession.getValue();
  $('<form action="run" method="POST">')
  .append($('<input name="master" type="hidden">').val(master))
  .append($('<input name="worker" type="hidden">').val(worker))
  .appendTo($('body'))
  .submit();
  return false;
});

// Now let's try to run the master script...
if (document.location.pathname !== '/') {
  $('body').append($('<script>').html(masterSession.getValue()));
};