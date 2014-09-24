 $(function() {
    $(".student-reqs").click(function() {
        $(".reqs-container").toggle();
        if ($(".reqs-container").is(":visible")) {
            $(".reqs-container").fadeIn();
        } else {
            $(".reqs-container").fadeOut();
        }
        return false;
    });
});
