$(function() {
  $('.datatable').DataTable({
    paging: false,
    autoWidth: false,
    searching: false,
    info: false
  });

  $('.searchable-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    language: {
      search: 'Search table:'
    }
  });

  $('.internships-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    language: {
      search: 'Search table:'
    },
    columnDefs: [
      { orderable: false, targets: [5,6] }
    ]
  });

  $('.courses-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    order: [[ 4, "asc" ]],
    language: {
      search: 'Search table:'
    }
  });

  $('.student-internship-rankings-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    searching: false,
    order: [[ 1, "asc" ]],
  });

  $('.daily-submissions-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    searching: false,
    order: [[ 0, "desc" ]]
  });

  $('.code-review-report-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    searching: false,
    order: [[ 0, "asc" ]]
  });

  $('.pair-evaluations-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    searching: false,
    order: [[ 5, "desc" ]]
  });

  $('.survey-code-reviews-datatable').DataTable({
    paging: false,
    autoWidth: false,
    searching: false,
    info: false,
    order: [[0, "asc"]]
  });
});
