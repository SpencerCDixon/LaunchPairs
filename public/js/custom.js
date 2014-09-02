var $alertBox = $('.alert-box')
$alertBox.delay(3000).fadeOut(1000)


$(function() {

  $('#project').on('submit', function(e){
    e.preventDefault();

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

// $(function() {
//
//   $('#status').on('submit', function(e){
//     e.preventDefault();
//
//     $.ajax({
//       type: 'post',
//       dataType: 'json',
//       data: $('#status').serialize(),
//       url: '/profile/:user_id',
//       success: function(data) {
//         $('#profile_status').text(data.status);
//       }
//     });
//   });
//
// });
