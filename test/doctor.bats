#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/doctor.sh
load helpers/common

setup() { common_setup; }

SCRIPT="common/doctor.sh"

@test "doctor: runs diagnostic healthcheck and exits 0" {
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LANGDEV_DOCTOR_RAN status=ok"* ]]
}
