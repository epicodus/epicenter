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

  $('#previous-courses-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    order: [[ 0, "desc" ]],
    language: {
      search: 'Search table:'
    }
  });

  $('#student-internship-rankings-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    searching: false,
    order: [[ 1, "asc" ]],
  });
});
