var $alertBox = $('.alert-box')
$alertBox.delay(3000).fadeOut(1000)


$(function() {

  $('#project').on('submit', function(e){
    e.preventDefault();
    var details = $('#project').serialize();
    $.post('/profile/:user_id/projects', details, function(data){
      $('#profile_project').html(data);
    });
  });

});
