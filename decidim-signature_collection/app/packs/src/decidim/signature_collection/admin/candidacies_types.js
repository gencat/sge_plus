(() => {
  const $scope = $("#promoting-committee-details");

  const $promotingCommitteeCheckbox = $(
    "#candidacies_type_promoting_committee_enabled",
    $scope
  );

  const $signatureType = $("#candidacies_type_signature_type");

  const $collectUserDataCheckbox = $("#candidacies_type_collect_user_extra_fields");

  const toggleVisibility = () => {
    if ($promotingCommitteeCheckbox.is(":checked")) {
      $(".minimum-committee-members-details", $scope).show();
    } else {
      $(".minimum-committee-members-details", $scope).hide();
    }

    if ($signatureType.val() === "offline") {
      $("#candidacies_type_undo_online_signatures_enabled").parent().parent().hide();
    } else {
      $("#candidacies_type_undo_online_signatures_enabled").parent().parent().show();
    }
  };

  $($promotingCommitteeCheckbox).click(() => toggleVisibility());
  $($signatureType).change(() => toggleVisibility());
  $($collectUserDataCheckbox).click(() => toggleVisibility());

  toggleVisibility();
})();
