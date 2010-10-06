// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$().ready(function() {
  $('#popup').jqm({modal:true});
  $('#popup2').jqm({modal:true});
  
  $('a.destroy_assignment').click(function(){
    $('#popup form').attr('action', $(this).attr('href'));
    $('#popup').jqmShow();
    return false;
  });
  
  $('a.import_assignments').click(function(){
    $('#popup2').jqmShow();
    return false;
  });
  
});

function toggleVrboFields(){
  if($('#assignment_save_on_remote_server').attr('checked'))
    $('#vrbo_account').show();
  else
    $('#vrbo_account').hide();
}