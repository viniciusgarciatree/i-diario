$(function () {
  'use strict';

  var flashMessages = new FlashMessages();
  var $classroom = $('#student_report_data_form_classroom_id');
  var $student = $('#student_report_data_form_student_id');

  $classroom.on('change', function(){
    var classroom_id = $classroom.select2('val');

    $student.select2('val', '');
    $student.select2({ data: [] });

    if (!_.isEmpty(classroom_id)) {
      fetchStudents(classroom_id);
    }
  });


  function fetchStudents() {
      var classroom_id = $classroom.select2('val');

      if (!_.isEmpty(classroom_id)) {
          $.ajax({
                     url: Routes.classroom_students_pt_br_path({ classroom_id: classroom_id, format: 'json' }),
                     success: handleFetchStudentsSuccess,
                     error: handleFetchStudentsError
                 });
      }
  };

  function handleFetchStudentsSuccess(data) {
      var studentPreviouslySelectedExists = false;

      var students = _.map(data.students, function(student) {
          if (student.id == window.studentPreviouslySelected) {
              studentPreviouslySelectedExists = true;
          }

          return { id: student.id, text: student.name };
      });

      $student.select2({ data: students });

      if (studentPreviouslySelectedExists) {
          $student.select2('val', window.studentPreviouslySelected);
          window.studentPreviouslySelected = null;
          $student.trigger('change');
      }
  };

  function handleFetchStudentsError() {
      flashMessages.error('Ocorreu um erro ao buscar os alunos da turma selecionada.');
  };

  fetchStudents();
  $student.select2('val', '');

});

