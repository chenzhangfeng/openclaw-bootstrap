#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/openclaw-common.sh
source "${SCRIPT_DIR}/scripts/lib/openclaw-common.sh"

print_banner() {
  cat <<'EOF'
OpenClaw One-Click Installer
This script prepares Docker, deployment assets, runtime config, and service management.
EOF
}

usage() {
  cat <<'EOF'
Usage: ./install_openclaw.sh [options]

Core options:
  --dir PATH                 Install directory. Default: /opt/openclaw
  --version VALUE            Toolkit/application version label.
  --channel VALUE            Release channel label.
  --mode image|build         Deploy from a prebuilt image or build from source.
  --image IMAGE_REF          Image reference for image mode or built image tag.
  --git-repo URL             Git repository for build mode.
  --git-ref REF              Git branch/tag/commit for build mode.
  --local-source PATH        Local source directory for build mode.
  --run-cmd CMD              Runtime command executed inside the container.
  --port PORT                Host port to expose.
  --container-port PORT      Container port expected by the app.
  --healthcheck-url URL      Host-side HTTP healthcheck URL.
  --healthcheck-cmd CMD      Container exec healthcheck command.
  --required-secret KEY      Secret key to collect into runtime.env. Repeatable.

Operational options:
  --mirror URL               Configure Docker registry mirror after confirmation.
  --proxy URL                Set both HTTP_PROXY and HTTPS_PROXY.
  --no-proxy VALUE           Set NO_PROXY.
  --skip-docker-install      Fail instead of installing Docker automatically.
  --skip-healthcheck         Skip post-start healthcheck.
  --skip-systemd             Do not install a systemd unit.
  --existing-action ACTION   reinstall | repair | upgrade | exit
  --non-interactive          Disable prompts.
  --force                    Auto-confirm high-risk prompts in non-interactive mode.
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
      --mode)
        OPENCLAW_DEPLOY_MODE="$2"
        shift 2
        ;;
      --image)
        OPENCLAW_DEPLOY_MODE="image"
        OPENCLAW_IMAGE_REF="$2"
        shift 2
        ;;
      --git-repo)
        OPENCLAW_DEPLOY_MODE="build"
        OPENCLAW_SOURCE_MODE="git"
        OPENCLAW_GIT_REPO="$2"
        shift 2
        ;;
      --git-ref)
        OPENCLAW_GIT_REF="$2"
        shift 2
        ;;
      --local-source)
        OPENCLAW_DEPLOY_MODE="build"
        OPENCLAW_SOURCE_MODE="local"
        OPENCLAW_LOCAL_SOURCE_PATH="$2"
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
      --container-port)
        OPENCLAW_CONTAINER_PORT="$2"
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
      --required-secret)
        OPENCLAW_REQUIRED_SECRETS="$(append_csv_value "${OPENCLAW_REQUIRED_SECRETS}" "$2")"
        shift 2
        ;;
      --mirror)
        DOCKER_REGISTRY_MIRROR_URL="$2"
        OPENCLAW_CONFIGURE_DOCKER_MIRROR="1"
        shift 2
        ;;
      --proxy)
        HTTP_PROXY="$2"
        HTTPS_PROXY="$2"
        shift 2
        ;;
      --no-proxy)
        NO_PROXY="$2"
        shift 2
        ;;
      --existing-action)
        OPENCLAW_EXISTING_ACTION="$2"
        shift 2
        ;;
      --skip-docker-install)
        OPENCLAW_SKIP_DOCKER_INSTALL="1"
        shift
        ;;
      --skip-healthcheck)
        OPENCLAW_SKIP_HEALTHCHECK="1"
        shift
        ;;
      --skip-systemd)
        OPENCLAW_SKIP_SYSTEMD="1"
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

handle_existing_installation() {
  if [[ ! -f "${OPENCLAW_MARKER_FILE}" ]]; then
    return 0
  fi
  local action
  action="$(choose_existing_action)"
  case "${action}" in
    reinstall|repair)
      log_info "Continuing with existing installation action: ${action}"
      ;;
    upgrade)
      log_info "Delegating to upgrade script."
      exec "${SCRIPT_DIR}/upgrade_openclaw.sh" --dir "${OPENCLAW_INSTALL_DIR}"
      ;;
    *)
      log_info "Exiting without changes."
      exit 0
      ;;
  esac
}

main() {
  set_default_vars
  bootstrap_arg_scan "$@"
  apply_directory_layout
  if [[ -f "${OPENCLAW_ENV_FILE}" ]]; then
    load_deployment_env_file "${OPENCLAW_ENV_FILE}"
  fi
  parse_args "$@"
  apply_directory_layout

  print_banner
  require_root_or_sudo
  setup_logging "install"
  OPENCLAW_ERROR_HANDLER="rollback_install"
  register_error_traps

  detect_os
  check_arch
  check_prerequisites
  handle_existing_installation
  check_network
  install_docker
  configure_docker_mirror
  detect_compose_command
  prepare_directories
  check_resources
  check_ports
  validate_required_config
  write_deployment_env_file
  prepare_runtime_env_file
  copy_project_assets "${SCRIPT_DIR}"
  prepare_application_source
  write_marker_file
  generate_compose_file
  build_or_pull_image
  install_service_wrapper
  start_openclaw
  healthcheck_openclaw
  show_post_install_guide
}

main "$@"
