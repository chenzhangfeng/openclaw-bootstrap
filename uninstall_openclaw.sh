#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/openclaw-common.sh
source "${SCRIPT_DIR}/scripts/lib/openclaw-common.sh"

usage() {
  cat <<'EOF'
Usage: ./uninstall_openclaw.sh [options]

Options:
  --dir PATH                 Install directory. Default: /opt/openclaw
  --mode MODE                containers | images | all
  --non-interactive          Disable prompts.
  --force                    Auto-confirm prompts in non-interactive mode.
  --dry-run                  Print actions without changing the system.
  --help                     Show this help.
EOF
}

bootstrap_arg_scan() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir)
        OPENCLAW_INSTALL_DIR="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir)
        OPENCLAW_INSTALL_DIR="$2"
        shift 2
        ;;
      --mode)
        OPENCLAW_UNINSTALL_MODE="$2"
        shift 2
        ;;
      --non-interactive)
        OPENCLAW_NON_INTERACTIVE="1"
        shift
        ;;
      --force)
        OPENCLAW_FORCE="1"
        shift
        ;;
      --dry-run)
        OPENCLAW_DRY_RUN="1"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
}

confirm_uninstall() {
  local mode="$1"
  local summary
  case "${mode}" in
    containers)
      summary="This will stop and remove the OpenClaw container stack, but keep images, config, and data."
      ;;
    images)
      summary="This will stop and remove the container stack and remove the image tag ${OPENCLAW_IMAGE_REF}, but keep config and data."
      ;;
    all)
      summary="This will remove the container stack, images, configuration, data, logs, cache, backups, and toolkit files under ${OPENCLAW_INSTALL_DIR}."
      ;;
    *)
      die "Unsupported uninstall mode: ${mode}"
      ;;
  esac
  log_warn "${summary}"
  confirm "Proceed with uninstall mode '${mode}'?" "N" || exit 0
  if [[ "${mode}" == "all" ]]; then
    confirm "Final confirmation: delete all managed OpenClaw files under ${OPENCLAW_INSTALL_DIR}?" "N" || exit 0
  fi
}

remove_images() {
  local image_ids=()
  if capture_cmd_privileged docker image inspect "${OPENCLAW_IMAGE_REF}" >/dev/null 2>&1; then
    image_ids+=("${OPENCLAW_IMAGE_REF}")
  fi
  local rollback_images
  rollback_images="$(capture_cmd_privileged docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "^${OPENCLAW_SERVICE_NAME}:rollback-" || true)"
  local rollback_image
  for rollback_image in ${rollback_images}; do
    image_ids+=("${rollback_image}")
  done
  local image_ref
  for image_ref in "${image_ids[@]}"; do
    [[ -n "${image_ref}" ]] || continue
    run_cmd_privileged docker image rm -f "${image_ref}" || true
  done
}

main() {
  set_default_vars
  bootstrap_arg_scan "$@"
  apply_directory_layout
  load_deployment_env_file "${OPENCLAW_ENV_FILE}"
  parse_args "$@"
  apply_directory_layout

  require_root_or_sudo
  setup_logging "uninstall"
  register_error_traps

  assert_managed_installation
  detect_os
  detect_compose_command
  confirm_uninstall "${OPENCLAW_UNINSTALL_MODE}"

  stop_openclaw_stack
  remove_service_wrapper

  case "${OPENCLAW_UNINSTALL_MODE}" in
    containers)
      ;;
    images)
      remove_images
      ;;
    all)
      remove_images
      remove_installation_paths
      ;;
  esac

  log_info "Uninstall mode '${OPENCLAW_UNINSTALL_MODE}' completed."
}

main "$@"
