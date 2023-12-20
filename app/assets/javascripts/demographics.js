$(function() {
  if ($('#new_demographic_info').length > 0) {
    COLLEGE_OR_HIGHER = ["associate's degree", "bachelor's degree", "master's degree", "doctoral degree or above", "other"];
    if (!COLLEGE_OR_HIGHER.includes($('#demographic_info_education').val())) {
      $('#cs_degree').hide();
    }
    if ($('#demographic_info_after_graduation').val() !== "I intend to start a new in-field job within 180 days of graduating the program.") {
      $('#time_off').hide();
    }
    if ($('#demographic_info_pronouns_other').prop('checked') === false) {
      $('#pronouns_blank').hide();
    }

    $('#demographic_info_education').change(function() {
      if (COLLEGE_OR_HIGHER.includes($(this).val())) {
        $('#cs_degree').show();
      } else {
        $('#cs_degree').hide();
      }
    });
    $('#demographic_info_after_graduation').change(function() {
      if ($(this).val() === "I intend to start a new in-field job within 180 days of graduating the program.") {
        $('#time_off').show();
      } else {
        $('#time_off').hide();
      }
    });
    $('#demographic_info_pronouns_other').change(function() {
      if ($('#demographic_info_pronouns_other').prop('checked') === true) {
        $('#pronouns_blank').show();
        $('#demographic_info_pronouns_blank').focus();
      } else {
        $('#pronouns_blank').hide();
      }
    });

    // enforces numbers only; adds dashes in correct places
    $('#demographic_info_ssn').keyup(function(event) {
      var selection = window.getSelection().toString();
      if (selection !== '' || $.inArray( event.keyCode, [38,40,37,39,8] ) !== -1) {
        return; // ignore arrow keys and backspace
      }
      var val = this.value.replace(/\D/g, '');
      var newVal = '';
      if(val.length > 4) {
        this.value = val;
      }
      if((val.length > 3) && (val.length < 6)) {
        newVal += val.substr(0, 3) + '-';
        val = val.substr(3);
      }
      if (val.length > 5) {
        newVal += val.substr(0, 3) + '-';
        newVal += val.substr(3, 2) + '-';
        val = val.substr(5);
      }
      newVal += val;
      if(newVal.length === 3 || newVal.length === 6) {
        newVal += '-';
      }
      this.value = newVal.substring(0, 11);
    });
  }
});
