 $(function() {
    $(".student-reqs").click(function() {
        $(".reqs-container").toggle();
        if ($(".reqs-container").is(":visible")) {
            $(".reqs-container").slideDown();
        } else {
            $(".reqs-container").slideUp();
        }
        return false;
    });
});
