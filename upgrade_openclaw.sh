#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/openclaw-common.sh
source "${SCRIPT_DIR}/scripts/lib/openclaw-common.sh"

usage() {
  cat <<'EOF'
Usage: ./upgrade_openclaw.sh [options]

Options:
  --dir PATH                 Install directory. Default: /opt/openclaw
  --version VALUE            Update version label.
  --channel VALUE            Update channel label.
  --image IMAGE_REF          Switch to a new image ref.
  --git-ref REF              Update the source ref for build mode.
  --run-cmd CMD              Replace the runtime command.
  --port PORT                Update host port.
  --healthcheck-url URL      Update HTTP healthcheck URL.
  --healthcheck-cmd CMD      Update exec healthcheck command.
  --skip-healthcheck         Skip post-upgrade healthcheck.
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
      --version)
        OPENCLAW_VERSION="$2"
        shift 2
        ;;
      --channel)
        OPENCLAW_CHANNEL="$2"
        shift 2
        ;;
      --image)
        OPENCLAW_IMAGE_REF="$2"
        OPENCLAW_DEPLOY_MODE="image"
        shift 2
        ;;
      --git-ref)
        OPENCLAW_GIT_REF="$2"
        shift 2
        ;;
      --run-cmd)
        OPENCLAW_RUN_CMD="$2"
        shift 2
        ;;
      --port)
        OPENCLAW_HOST_PORT="$2"
        OPENCLAW_HEALTHCHECK_PORT="$2"
        OPENCLAW_HEALTHCHECK_URL="http://127.0.0.1:${2}/"
        shift 2
        ;;
      --healthcheck-url)
        OPENCLAW_HEALTHCHECK_MODE="http"
        OPENCLAW_HEALTHCHECK_URL="$2"
        shift 2
        ;;
      --healthcheck-cmd)
        OPENCLAW_HEALTHCHECK_MODE="exec"
        OPENCLAW_HEALTHCHECK_CMD="$2"
        shift 2
        ;;
      --skip-healthcheck)
        OPENCLAW_SKIP_HEALTHCHECK="1"
        shift
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

main() {
  set_default_vars
  bootstrap_arg_scan "$@"
  apply_directory_layout
  load_deployment_env_file "${OPENCLAW_ENV_FILE}"
  parse_args "$@"
  apply_directory_layout

  require_root_or_sudo
  setup_logging "upgrade"
  OPENCLAW_ERROR_HANDLER="rollback_upgrade"
  register_error_traps

  assert_managed_installation
  detect_os
  check_arch
  check_prerequisites
  install_docker
  detect_compose_command
  backup_installation_state
  tag_current_image_for_rollback
  validate_required_config
  write_deployment_env_file
  prepare_runtime_env_file
  prepare_application_source
  generate_compose_file
  build_or_pull_image
  install_service_wrapper
  start_openclaw
  healthcheck_openclaw
  show_post_install_guide
}

main "$@"
