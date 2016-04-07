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

  $('#previous-courses-datatable').DataTable({
    paging: false,
    autoWidth: false,
    info: false,
    order: [[ 0, "desc" ]],
    language: {
      search: 'Search table:'
    }
  });
});
