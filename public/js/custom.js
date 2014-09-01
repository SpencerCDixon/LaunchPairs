var $alertBox = $('.alert-box')
$alertBox.delay(3000).fadeOut(1000)


$(function() {

  $('#project').on('submit', function(e){
    e.preventDefault();

    // var details = $('#project').serializeArray();

    // $.post('/profile/:user_id/projects', details, function(data){
    //   $('#profile_project').html(data);
    // });

    $.ajax({
      type: 'post',
      dataType: 'json',
      data: $('#project').serialize(),
      url: '/profile/:user_id/projects',
      success: function(data) {
        $('#profile_project').text(data.project);
      }
    });
  });

});

$(function() {

  $('#project').on('submit', function(e){
    e.preventDefault();

    // var details = $('#project').serializeArray();

    // $.post('/profile/:user_id/projects', details, function(data){
    //   $('#profile_project').html(data);
    // });

    $.ajax({
      type: 'post',
      dataType: 'json',
      data: $('#project').serialize(),
      url: '/profile/:user_id/projects',
      success: function(data) {
        $('#profile_project').text(data.project);
      }
    });
  });

});

$(function() {

  $('#project').on('submit', function(e){
    e.preventDefault();

    // var details = $('#project').serializeArray();

    // $.post('/profile/:user_id/projects', details, function(data){
    //   $('#profile_project').html(data);
    // });

    $.ajax({
      type: 'post',
      dataType: 'json',
      data: $('#project').serialize(),
      url: '/profile/:user_id/projects',
      success: function(data) {
        $('#profile_project').text(data.project);
      }
    });
  });

});
