#!/usr/bin/env bash

# Shared helpers for OpenClaw deployment scripts.

if [[ -n "${OPENCLAW_COMMON_SH_LOADED:-}" ]]; then
  return 0
fi
OPENCLAW_COMMON_SH_LOADED=1

OPENCLAW_CURRENT_STEP="bootstrap"
OPENCLAW_ERROR_HANDLER=""
OPENCLAW_EXIT_HANDLER=""
OPENCLAW_ERROR_REPORTED=0
OPENCLAW_STACK_STARTED=0
OPENCLAW_UNIT_INSTALLED=0
OPENCLAW_ROLLBACK_IMAGE_TAG=""
OPENCLAW_BACKUP_PATH=""
OPENCLAW_COMPOSE_IMPLEMENTATION=""
OPENCLAW_ARCH=""
OPENCLAW_OS_FAMILY=""
OPENCLAW_PACKAGE_MANAGER=""
OPENCLAW_SUDO=()

set_default_vars() {
  : "${OPENCLAW_APP_NAME:=OpenClaw}"
  : "${OPENCLAW_SERVICE_NAME:=openclaw}"
  : "${OPENCLAW_INSTALL_DIR:=/opt/openclaw}"
  : "${OPENCLAW_CHANNEL:=stable}"
  : "${OPENCLAW_VERSION:=latest}"
  : "${OPENCLAW_DEPLOY_MODE:=image}"
  : "${OPENCLAW_EXISTING_ACTION:=repair}"
  : "${OPENCLAW_SOURCE_MODE:=git}"
  : "${OPENCLAW_GIT_REPO:=}"
  : "${OPENCLAW_GIT_REF:=main}"
  : "${OPENCLAW_LOCAL_SOURCE_PATH:=}"
  : "${OPENCLAW_IMAGE_REF:=openclaw-managed:latest}"
  : "${OPENCLAW_BASE_IMAGE:=python:3.11-slim}"
  : "${OPENCLAW_DOCKERFILE_NAME:=Dockerfile}"
  : "${OPENCLAW_BUILD_CONTEXT:=.}"
  : "${OPENCLAW_BUILD_TARGET:=}"
  : "${OPENCLAW_RUNTIME_WORKDIR:=/workspace/app}"
  : "${OPENCLAW_RUN_CMD:=}"
  : "${OPENCLAW_BIND_ADDRESS:=0.0.0.0}"
  : "${OPENCLAW_HOST_PORT:=8080}"
  : "${OPENCLAW_CONTAINER_PORT:=8080}"
  : "${OPENCLAW_HEALTHCHECK_MODE:=http}"
  : "${OPENCLAW_HEALTHCHECK_URL:=http://127.0.0.1:${OPENCLAW_HOST_PORT}/}"
  : "${OPENCLAW_HEALTHCHECK_HOST:=127.0.0.1}"
  : "${OPENCLAW_HEALTHCHECK_PORT:=${OPENCLAW_HOST_PORT}}"
  : "${OPENCLAW_HEALTHCHECK_PATH:=/}"
  : "${OPENCLAW_HEALTHCHECK_CMD:=}"
  : "${OPENCLAW_HEALTHCHECK_COMPOSE_CMD:=}"
  : "${OPENCLAW_HEALTHCHECK_INTERVAL:=30}"
  : "${OPENCLAW_HEALTHCHECK_TIMEOUT:=10}"
  : "${OPENCLAW_HEALTHCHECK_RETRIES:=20}"
  : "${OPENCLAW_REQUIRED_SECRETS:=}"
  : "${OPENCLAW_LOG_MAX_SIZE:=10m}"
  : "${OPENCLAW_LOG_MAX_FILES:=5}"
  : "${OPENCLAW_MIN_MEMORY_MB:=4096}"
  : "${OPENCLAW_MIN_DISK_MB:=10240}"
  : "${OPENCLAW_MIN_SWAP_MB:=2048}"
  : "${OPENCLAW_SWAPFILE_SIZE_MB:=2048}"
  : "${OPENCLAW_SWAPFILE_PATH:=/swapfile-openclaw}"
  : "${OPENCLAW_NON_INTERACTIVE:=0}"
  : "${OPENCLAW_FORCE:=0}"
  : "${OPENCLAW_SKIP_DOCKER_INSTALL:=0}"
  : "${OPENCLAW_SKIP_HEALTHCHECK:=0}"
  : "${OPENCLAW_SKIP_SYSTEMD:=0}"
  : "${OPENCLAW_DRY_RUN:=0}"
  : "${OPENCLAW_CONFIGURE_DOCKER_MIRROR:=0}"
  : "${OPENCLAW_UNINSTALL_MODE:=containers}"
  : "${OPENCLAW_GIT_CLONE_DEPTH:=1}"
  : "${DOCKER_REGISTRY_MIRROR_URL:=}"
  : "${HTTP_PROXY:=}"
  : "${HTTPS_PROXY:=}"
  : "${NO_PROXY:=}"
  : "${PIP_INDEX_URL:=}"
  : "${PIP_EXTRA_INDEX_URL:=}"
  : "${APT_MIRROR:=}"
  : "${OPENCLAW_LOG_FILE:=}"
}

apply_directory_layout() {
  : "${OPENCLAW_CONFIG_DIR:=${OPENCLAW_INSTALL_DIR}/config}"
  : "${OPENCLAW_DATA_DIR:=${OPENCLAW_INSTALL_DIR}/data}"
  : "${OPENCLAW_LOG_DIR:=${OPENCLAW_INSTALL_DIR}/logs}"
  : "${OPENCLAW_CACHE_DIR:=${OPENCLAW_INSTALL_DIR}/cache}"
  : "${OPENCLAW_BACKUP_DIR:=${OPENCLAW_INSTALL_DIR}/backups}"
  : "${OPENCLAW_SOURCE_DIR:=${OPENCLAW_INSTALL_DIR}/source}"
  : "${OPENCLAW_ASSET_DIR:=${OPENCLAW_INSTALL_DIR}/assets}"
  : "${OPENCLAW_ENV_FILE:=${OPENCLAW_INSTALL_DIR}/.env}"
  : "${OPENCLAW_RUNTIME_ENV_FILE:=${OPENCLAW_INSTALL_DIR}/runtime.env}"
  : "${OPENCLAW_COMPOSE_FILE:=${OPENCLAW_INSTALL_DIR}/compose.yaml}"
  : "${OPENCLAW_MARKER_FILE:=${OPENCLAW_INSTALL_DIR}/.openclaw-managed}"
  : "${OPENCLAW_SYSTEMD_UNIT:=openclaw-compose.service}"
  : "${OPENCLAW_TOOLKIT_DIR:=${OPENCLAW_ASSET_DIR}/toolkit}"
  : "${OPENCLAW_APP_SOURCE_DIR:=${OPENCLAW_SOURCE_DIR}/app}"
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

set_current_step() {
  OPENCLAW_CURRENT_STEP="$1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf "%s" "$value"
}

shell_quote() {
  printf "%q" "$1"
}

log_line() {
  local level="$1"
  shift
  local message
  message="$(printf "%s" "$*")"
  local line
  line="$(timestamp) [${level}] [${OPENCLAW_CURRENT_STEP}] ${message}"
  if [[ -n "${OPENCLAW_LOG_FILE:-}" ]]; then
    printf "%s\n" "$line" >> "${OPENCLAW_LOG_FILE}"
  fi
  printf "%s\n" "$line" >&2
}

log_info() {
  log_line "INFO" "$@"
}

log_warn() {
  log_line "WARN" "$@"
}

log_error() {
  log_line "ERROR" "$@"
}

die() {
  log_error "$1"
  exit "${2:-1}"
}

require_root_or_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    OPENCLAW_SUDO=()
    return 0
  fi
  if ! command_exists sudo; then
    die "This script requires root or sudo access."
  fi
  if ! sudo -n true >/dev/null 2>&1; then
    if [[ "${OPENCLAW_NON_INTERACTIVE}" == "1" ]]; then
      die "sudo password is required but non-interactive mode is enabled."
    fi
    log_info "sudo privileges are required for system changes."
    sudo -v
  fi
  OPENCLAW_SUDO=(sudo)
}

sudo_exec() {
  if [[ "${OPENCLAW_DRY_RUN}" == "1" ]]; then
    log_info "[dry-run] $*"
    return 0
  fi
  if [[ "${#OPENCLAW_SUDO[@]}" -gt 0 ]]; then
    "${OPENCLAW_SUDO[@]}" "$@"
  else
    "$@"
  fi
}

run_cmd() {
  log_info "Running: $*"
  if [[ "${OPENCLAW_DRY_RUN}" == "1" ]]; then
    return 0
  fi
  "$@" 2>&1 | tee -a "${OPENCLAW_LOG_FILE}"
  local status="${PIPESTATUS[0]}"
  if [[ "${status}" -ne 0 ]]; then
    log_error "Command failed with exit code ${status}: $*"
    return "${status}"
  fi
  return 0
}

run_cmd_privileged() {
  log_info "Running: $*"
  if [[ "${OPENCLAW_DRY_RUN}" == "1" ]]; then
    return 0
  fi
  if [[ "${#OPENCLAW_SUDO[@]}" -gt 0 ]]; then
    "${OPENCLAW_SUDO[@]}" "$@" 2>&1 | tee -a "${OPENCLAW_LOG_FILE}"
  else
    "$@" 2>&1 | tee -a "${OPENCLAW_LOG_FILE}"
  fi
  local status="${PIPESTATUS[0]}"
  if [[ "${status}" -ne 0 ]]; then
    log_error "Command failed with exit code ${status}: $*"
    return "${status}"
  fi
  return 0
}

capture_cmd_privileged() {
  if [[ "${#OPENCLAW_SUDO[@]}" -gt 0 ]]; then
    "${OPENCLAW_SUDO[@]}" "$@"
  else
    "$@"
  fi
}

retry_command() {
  local attempts="$1"
  local sleep_seconds="$2"
  shift 2
  local try=1
  while true; do
    if "$@"; then
      return 0
    fi
    if [[ "${try}" -ge "${attempts}" ]]; then
      return 1
    fi
    log_warn "Retry ${try}/${attempts} failed. Waiting ${sleep_seconds}s before retry."
    sleep "${sleep_seconds}"
    try=$((try + 1))
  done
}

confirm() {
  local prompt="$1"
  local default_answer="${2:-N}"
  if [[ "${OPENCLAW_NON_INTERACTIVE}" == "1" ]]; then
    [[ "${OPENCLAW_FORCE}" == "1" ]]
    return
  fi
  local suffix="[y/N]"
  if [[ "${default_answer}" == "Y" ]]; then
    suffix="[Y/n]"
  fi
  local answer
  read -r -p "${prompt} ${suffix} " answer
  answer="$(trim "${answer}")"
  if [[ -z "${answer}" ]]; then
    [[ "${default_answer}" == "Y" ]]
    return
  fi
  [[ "${answer}" =~ ^[Yy]([Ee][Ss])?$ ]]
}

append_csv_value() {
  local current="$1"
  local next="$2"
  if [[ -z "${current}" ]]; then
    printf "%s" "${next}"
    return 0
  fi
  printf "%s,%s" "${current}" "${next}"
}

register_error_traps() {
  trap 'openclaw_on_error $? "$BASH_COMMAND"' ERR
  trap 'openclaw_on_signal INT' INT
  trap 'openclaw_on_signal TERM' TERM
  trap 'openclaw_on_exit' EXIT
}

openclaw_on_error() {
  local status="$1"
  local command_text="$2"
  if [[ "${OPENCLAW_ERROR_REPORTED}" == "1" ]]; then
    exit "${status}"
  fi
  OPENCLAW_ERROR_REPORTED=1
  log_error "Step failed while running: ${command_text}"
  if [[ -n "${OPENCLAW_ERROR_HANDLER}" ]] && declare -F "${OPENCLAW_ERROR_HANDLER}" >/dev/null 2>&1; then
    "${OPENCLAW_ERROR_HANDLER}" "${status}" "${command_text}" || true
  fi
  exit "${status}"
}

openclaw_on_signal() {
  local signal_name="$1"
  log_warn "Received signal ${signal_name}; stopping."
  exit 130
}

openclaw_on_exit() {
  if [[ -n "${OPENCLAW_EXIT_HANDLER}" ]] && declare -F "${OPENCLAW_EXIT_HANDLER}" >/dev/null 2>&1; then
    "${OPENCLAW_EXIT_HANDLER}" || true
  fi
}

resolve_log_file() {
  local action_name="$1"
  local file_name="openclaw_${action_name}.log"
  local candidates=(
    "/var/log/${file_name}"
    "${HOME}/.local/state/openclaw/${file_name}"
    "${OPENCLAW_INSTALL_DIR}/logs/${file_name}"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    local parent
    parent="$(dirname "${candidate}")"
    if sudo_exec mkdir -p "${parent}" >/dev/null 2>&1; then
      if sudo_exec touch "${candidate}" >/dev/null 2>&1; then
        if [[ "${#OPENCLAW_SUDO[@]}" -gt 0 ]]; then
          sudo_exec chown "$(id -un)":"$(id -gn)" "${candidate}" >/dev/null 2>&1 || true
        fi
        printf "%s" "${candidate}"
        return 0
      fi
    fi
  done
  return 1
}

setup_logging() {
  local action_name="$1"
  OPENCLAW_LOG_FILE="$(resolve_log_file "${action_name}")"
  [[ -n "${OPENCLAW_LOG_FILE}" ]] || die "Unable to resolve a writable log file."
  log_info "Logging to ${OPENCLAW_LOG_FILE}"
}

detect_os() {
  set_current_step "detect_os"
  [[ -f /etc/os-release ]] || die "/etc/os-release is missing; unsupported Linux distribution."
  # shellcheck source=/dev/null
  source /etc/os-release
  case "${ID}" in
    ubuntu|debian|kali)
      OPENCLAW_OS_FAMILY="debian"
      OPENCLAW_PACKAGE_MANAGER="apt"
      ;;
    centos|rhel|rocky|almalinux|fedora)
      OPENCLAW_OS_FAMILY="rhel"
      if command_exists dnf; then
        OPENCLAW_PACKAGE_MANAGER="dnf"
      else
        OPENCLAW_PACKAGE_MANAGER="yum"
      fi
      ;;
    arch)
      OPENCLAW_OS_FAMILY="arch"
      OPENCLAW_PACKAGE_MANAGER="pacman"
      ;;
    *)
      die "Unsupported Linux distribution: ${ID}"
      ;;
  esac
  log_info "Detected OS ${PRETTY_NAME}"
}

check_arch() {
  set_current_step "check_arch"
  case "$(uname -m)" in
    x86_64|amd64)
      OPENCLAW_ARCH="x86_64"
      ;;
    aarch64|arm64)
      OPENCLAW_ARCH="aarch64"
      ;;
    *)
      die "Unsupported architecture: $(uname -m)"
      ;;
  esac
  log_info "Detected architecture ${OPENCLAW_ARCH}"
}

check_prerequisites() {
  set_current_step "check_prerequisites"
  local missing=()
  if ! command_exists curl && ! command_exists wget; then
    missing+=("curl or wget")
  fi
  if ! command_exists ss; then
    missing+=("ss")
  fi
  if [[ "${#missing[@]}" -gt 0 ]]; then
    die "Missing required host tools: ${missing[*]}"
  fi
}

available_memory_mb() {
  awk '/MemAvailable/ { print int($2 / 1024) }' /proc/meminfo
}

available_swap_mb() {
  awk '/SwapFree/ { print int($2 / 1024) }' /proc/meminfo
}

available_disk_mb() {
  df -Pm "${OPENCLAW_INSTALL_DIR}" 2>/dev/null | awk 'NR == 2 { print $4 }'
}

port_in_use() {
  local port="$1"
  ss -lnt | awk 'NR > 1 { print $4 }' | grep -Eq "[:.]${port}$"
}

create_swapfile() {
  set_current_step "create_swapfile"
  local size_mb="${OPENCLAW_SWAPFILE_SIZE_MB}"
  log_warn "Creating swapfile ${OPENCLAW_SWAPFILE_PATH} (${size_mb} MB)."
  if [[ "${OPENCLAW_DRY_RUN}" == "1" ]]; then
    return 0
  fi
  sudo_exec fallocate -l "${size_mb}M" "${OPENCLAW_SWAPFILE_PATH}" || sudo_exec dd if=/dev/zero of="${OPENCLAW_SWAPFILE_PATH}" bs=1M count="${size_mb}" status=progress
  sudo_exec chmod 600 "${OPENCLAW_SWAPFILE_PATH}"
  sudo_exec mkswap "${OPENCLAW_SWAPFILE_PATH}"
  sudo_exec swapon "${OPENCLAW_SWAPFILE_PATH}"
  if ! grep -Fq "${OPENCLAW_SWAPFILE_PATH}" /etc/fstab; then
    printf "%s none swap sw 0 0\n" "${OPENCLAW_SWAPFILE_PATH}" | sudo_exec tee -a /etc/fstab >/dev/null
  fi
}

check_resources() {
  set_current_step "check_resources"
  local memory_mb
  memory_mb="$(available_memory_mb)"
  local swap_mb
  swap_mb="$(available_swap_mb)"
  local disk_mb
  disk_mb="$(available_disk_mb)"
  [[ -n "${disk_mb}" ]] || disk_mb=0

  log_info "Available memory: ${memory_mb} MB"
  log_info "Available swap: ${swap_mb} MB"
  log_info "Available disk: ${disk_mb} MB"

  if [[ "${memory_mb}" -lt "${OPENCLAW_MIN_MEMORY_MB}" ]]; then
    log_warn "Available memory is below the conservative default threshold (${OPENCLAW_MIN_MEMORY_MB} MB)."
    if [[ "${swap_mb}" -lt "${OPENCLAW_MIN_SWAP_MB}" ]]; then
      log_warn "Swap is below the conservative default threshold (${OPENCLAW_MIN_SWAP_MB} MB)."
      if confirm "Create a helper swapfile at ${OPENCLAW_SWAPFILE_PATH}? This modifies /etc/fstab." "N"; then
        create_swapfile
      else
        log_warn "Continuing without extra swap. Local builds may run out of memory."
      fi
    fi
  fi

  if [[ "${disk_mb}" -lt "${OPENCLAW_MIN_DISK_MB}" ]]; then
    die "Available disk is below the conservative default threshold (${OPENCLAW_MIN_DISK_MB} MB)."
  fi
}

check_ports() {
  set_current_step "check_ports"
  if port_in_use "${OPENCLAW_HOST_PORT}"; then
    if capture_cmd_privileged docker ps --format '{{.Names}}' 2>/dev/null | grep -Fxq "${OPENCLAW_SERVICE_NAME}"; then
      log_warn "Host port ${OPENCLAW_HOST_PORT} is already in use by the existing ${OPENCLAW_SERVICE_NAME} container; continuing."
      return 0
    fi
    die "Host port ${OPENCLAW_HOST_PORT} is already in use."
  fi
}

check_network() {
  set_current_step "check_network"
  local url="https://download.docker.com/"
  if command_exists curl; then
    if curl -fsSIL --max-time 10 "${url}" >/dev/null 2>&1; then
      log_info "HTTPS connectivity check succeeded."
      return 0
    fi
  elif command_exists wget; then
    if wget --spider --timeout=10 "${url}" >/dev/null 2>&1; then
      log_info "HTTPS connectivity check succeeded."
      return 0
    fi
  fi
  log_warn "HTTPS connectivity check failed. Docker install, image pull, git clone, or build-time downloads may fail."
  return 0
}

docker_is_installed() {
  command_exists docker
}

ensure_docker_running() {
  set_current_step "ensure_docker_running"
  if command_exists systemctl; then
    sudo_exec systemctl enable --now docker
  fi
}

install_docker_debian() {
  sudo_exec mkdir -p /etc/apt/keyrings
  retry_command 3 5 sudo_exec apt-get update
  retry_command 3 5 sudo_exec apt-get install -y ca-certificates curl gnupg lsb-release
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | sudo_exec gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  fi
  printf "deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/%s %s stable\n" \
    "$(dpkg --print-architecture)" "${ID}" "${VERSION_CODENAME}" | sudo_exec tee /etc/apt/sources.list.d/docker.list >/dev/null
  retry_command 3 5 sudo_exec apt-get update
  retry_command 3 5 sudo_exec apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin git
}

install_docker_rhel() {
  retry_command 3 5 sudo_exec "${OPENCLAW_PACKAGE_MANAGER}" install -y yum-utils
  sudo_exec yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  retry_command 3 5 sudo_exec "${OPENCLAW_PACKAGE_MANAGER}" install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin git
}

install_docker_arch() {
  retry_command 3 5 sudo_exec pacman -Sy --noconfirm docker docker-compose git
}

install_docker() {
  set_current_step "install_docker"
  if docker_is_installed; then
    log_info "Docker already installed."
    ensure_docker_running
    return 0
  fi
  if [[ "${OPENCLAW_SKIP_DOCKER_INSTALL}" == "1" ]]; then
    die "Docker is not installed and --skip-docker-install was provided."
  fi
  case "${OPENCLAW_OS_FAMILY}" in
    debian)
      install_docker_debian
      ;;
    rhel)
      install_docker_rhel
      ;;
    arch)
      install_docker_arch
      ;;
    *)
      die "Unsupported OS family for Docker installation: ${OPENCLAW_OS_FAMILY}"
      ;;
  esac
  ensure_docker_running
}

configure_docker_mirror() {
  set_current_step "configure_docker_mirror"
  if [[ "${OPENCLAW_CONFIGURE_DOCKER_MIRROR}" != "1" ]] || [[ -z "${DOCKER_REGISTRY_MIRROR_URL}" ]]; then
    return 0
  fi
  if ! confirm "Back up and replace /etc/docker/daemon.json with a registry mirror configuration?" "N"; then
    log_warn "Skipping Docker registry mirror configuration."
    return 0
  fi

  local daemon_json="/etc/docker/daemon.json"
  local backup_json="/etc/docker/daemon.json.openclaw.bak.$(date +%Y%m%d%H%M%S)"
  if [[ -f "${daemon_json}" ]]; then
    sudo_exec cp "${daemon_json}" "${backup_json}"
    log_info "Backed up ${daemon_json} to ${backup_json}"
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  cat > "${tmp_file}" <<EOF
{
  "registry-mirrors": [
    "${DOCKER_REGISTRY_MIRROR_URL}"
  ]
}
EOF
  sudo_exec install -m 0644 "${tmp_file}" "${daemon_json}"
  rm -f "${tmp_file}"
  if command_exists systemctl; then
    sudo_exec systemctl restart docker
  fi
}

detect_compose_command() {
  set_current_step "detect_compose"
  if docker compose version >/dev/null 2>&1; then
    OPENCLAW_COMPOSE_IMPLEMENTATION="plugin"
    return 0
  fi
  if command_exists docker-compose; then
    OPENCLAW_COMPOSE_IMPLEMENTATION="standalone"
    return 0
  fi
  die "Docker Compose is not available."
}

compose_capture() {
  if [[ "${OPENCLAW_COMPOSE_IMPLEMENTATION}" == "plugin" ]]; then
    capture_cmd_privileged docker compose --project-name "${OPENCLAW_SERVICE_NAME}" -f "${OPENCLAW_COMPOSE_FILE}" "$@"
  else
    capture_cmd_privileged docker-compose --project-name "${OPENCLAW_SERVICE_NAME}" -f "${OPENCLAW_COMPOSE_FILE}" "$@"
  fi
}

compose_exec() {
  if [[ "${OPENCLAW_COMPOSE_IMPLEMENTATION}" == "plugin" ]]; then
    run_cmd_privileged docker compose --project-name "${OPENCLAW_SERVICE_NAME}" -f "${OPENCLAW_COMPOSE_FILE}" "$@"
  else
    run_cmd_privileged docker-compose --project-name "${OPENCLAW_SERVICE_NAME}" -f "${OPENCLAW_COMPOSE_FILE}" "$@"
  fi
}

path_is_safe() {
  local path="$1"
  [[ -n "${path}" ]] && [[ "${path}" != "/" ]]
}

ensure_install_parent() {
  local parent_dir
  parent_dir="$(dirname "${OPENCLAW_INSTALL_DIR}")"
  sudo_exec mkdir -p "${parent_dir}"
}

prepare_directories() {
  set_current_step "prepare_directories"
  ensure_install_parent
  sudo_exec mkdir -p \
    "${OPENCLAW_INSTALL_DIR}" \
    "${OPENCLAW_CONFIG_DIR}" \
    "${OPENCLAW_DATA_DIR}" \
    "${OPENCLAW_LOG_DIR}" \
    "${OPENCLAW_CACHE_DIR}" \
    "${OPENCLAW_BACKUP_DIR}" \
    "${OPENCLAW_SOURCE_DIR}" \
    "${OPENCLAW_ASSET_DIR}" \
    "${OPENCLAW_TOOLKIT_DIR}/scripts/lib"
}

write_marker_file() {
  set_current_step "write_marker"
  local tmp_file
  tmp_file="$(mktemp)"
  cat > "${tmp_file}" <<EOF
OPENCLAW_MANAGED=1
OPENCLAW_SERVICE_NAME=$(shell_quote "${OPENCLAW_SERVICE_NAME}")
OPENCLAW_INSTALL_DIR=$(shell_quote "${OPENCLAW_INSTALL_DIR}")
OPENCLAW_CREATED_AT=$(shell_quote "$(date -Iseconds)")
EOF
  sudo_exec install -m 0644 "${tmp_file}" "${OPENCLAW_MARKER_FILE}"
  rm -f "${tmp_file}"
}

write_deployment_env_file() {
  set_current_step "generate_env_file"
  local tmp_file
  tmp_file="$(mktemp)"
  cat > "${tmp_file}" <<EOF
# Generated by OpenClaw deployment tooling.
# Conservative defaults in this file are toolkit defaults, not proven OpenClaw runtime facts.
OPENCLAW_APP_NAME=$(shell_quote "${OPENCLAW_APP_NAME}")
OPENCLAW_SERVICE_NAME=$(shell_quote "${OPENCLAW_SERVICE_NAME}")
OPENCLAW_INSTALL_DIR=$(shell_quote "${OPENCLAW_INSTALL_DIR}")
OPENCLAW_CONFIG_DIR=$(shell_quote "${OPENCLAW_CONFIG_DIR}")
OPENCLAW_DATA_DIR=$(shell_quote "${OPENCLAW_DATA_DIR}")
OPENCLAW_LOG_DIR=$(shell_quote "${OPENCLAW_LOG_DIR}")
OPENCLAW_CACHE_DIR=$(shell_quote "${OPENCLAW_CACHE_DIR}")
OPENCLAW_BACKUP_DIR=$(shell_quote "${OPENCLAW_BACKUP_DIR}")
OPENCLAW_SOURCE_DIR=$(shell_quote "${OPENCLAW_SOURCE_DIR}")
OPENCLAW_ASSET_DIR=$(shell_quote "${OPENCLAW_ASSET_DIR}")
OPENCLAW_COMPOSE_FILE=$(shell_quote "${OPENCLAW_COMPOSE_FILE}")
OPENCLAW_RUNTIME_ENV_FILE=$(shell_quote "${OPENCLAW_RUNTIME_ENV_FILE}")
OPENCLAW_MARKER_FILE=$(shell_quote "${OPENCLAW_MARKER_FILE}")
OPENCLAW_SYSTEMD_UNIT=$(shell_quote "${OPENCLAW_SYSTEMD_UNIT}")
OPENCLAW_CHANNEL=$(shell_quote "${OPENCLAW_CHANNEL}")
OPENCLAW_VERSION=$(shell_quote "${OPENCLAW_VERSION}")
OPENCLAW_DEPLOY_MODE=$(shell_quote "${OPENCLAW_DEPLOY_MODE}")
OPENCLAW_EXISTING_ACTION=$(shell_quote "${OPENCLAW_EXISTING_ACTION}")
OPENCLAW_SOURCE_MODE=$(shell_quote "${OPENCLAW_SOURCE_MODE}")
OPENCLAW_GIT_REPO=$(shell_quote "${OPENCLAW_GIT_REPO}")
OPENCLAW_GIT_REF=$(shell_quote "${OPENCLAW_GIT_REF}")
OPENCLAW_LOCAL_SOURCE_PATH=$(shell_quote "${OPENCLAW_LOCAL_SOURCE_PATH}")
OPENCLAW_IMAGE_REF=$(shell_quote "${OPENCLAW_IMAGE_REF}")
OPENCLAW_BASE_IMAGE=$(shell_quote "${OPENCLAW_BASE_IMAGE}")
OPENCLAW_DOCKERFILE_NAME=$(shell_quote "${OPENCLAW_DOCKERFILE_NAME}")
OPENCLAW_BUILD_CONTEXT=$(shell_quote "${OPENCLAW_BUILD_CONTEXT}")
OPENCLAW_BUILD_TARGET=$(shell_quote "${OPENCLAW_BUILD_TARGET}")
OPENCLAW_RUNTIME_WORKDIR=$(shell_quote "${OPENCLAW_RUNTIME_WORKDIR}")
OPENCLAW_RUN_CMD=$(shell_quote "${OPENCLAW_RUN_CMD}")
OPENCLAW_BIND_ADDRESS=$(shell_quote "${OPENCLAW_BIND_ADDRESS}")
OPENCLAW_HOST_PORT=$(shell_quote "${OPENCLAW_HOST_PORT}")
OPENCLAW_CONTAINER_PORT=$(shell_quote "${OPENCLAW_CONTAINER_PORT}")
OPENCLAW_HEALTHCHECK_MODE=$(shell_quote "${OPENCLAW_HEALTHCHECK_MODE}")
OPENCLAW_HEALTHCHECK_URL=$(shell_quote "${OPENCLAW_HEALTHCHECK_URL}")
OPENCLAW_HEALTHCHECK_HOST=$(shell_quote "${OPENCLAW_HEALTHCHECK_HOST}")
OPENCLAW_HEALTHCHECK_PORT=$(shell_quote "${OPENCLAW_HEALTHCHECK_PORT}")
OPENCLAW_HEALTHCHECK_PATH=$(shell_quote "${OPENCLAW_HEALTHCHECK_PATH}")
OPENCLAW_HEALTHCHECK_CMD=$(shell_quote "${OPENCLAW_HEALTHCHECK_CMD}")
OPENCLAW_HEALTHCHECK_COMPOSE_CMD=$(shell_quote "${OPENCLAW_HEALTHCHECK_COMPOSE_CMD}")
OPENCLAW_HEALTHCHECK_INTERVAL=$(shell_quote "${OPENCLAW_HEALTHCHECK_INTERVAL}")
OPENCLAW_HEALTHCHECK_TIMEOUT=$(shell_quote "${OPENCLAW_HEALTHCHECK_TIMEOUT}")
OPENCLAW_HEALTHCHECK_RETRIES=$(shell_quote "${OPENCLAW_HEALTHCHECK_RETRIES}")
OPENCLAW_REQUIRED_SECRETS=$(shell_quote "${OPENCLAW_REQUIRED_SECRETS}")
OPENCLAW_LOG_MAX_SIZE=$(shell_quote "${OPENCLAW_LOG_MAX_SIZE}")
OPENCLAW_LOG_MAX_FILES=$(shell_quote "${OPENCLAW_LOG_MAX_FILES}")
OPENCLAW_MIN_MEMORY_MB=$(shell_quote "${OPENCLAW_MIN_MEMORY_MB}")
OPENCLAW_MIN_DISK_MB=$(shell_quote "${OPENCLAW_MIN_DISK_MB}")
OPENCLAW_MIN_SWAP_MB=$(shell_quote "${OPENCLAW_MIN_SWAP_MB}")
OPENCLAW_SWAPFILE_SIZE_MB=$(shell_quote "${OPENCLAW_SWAPFILE_SIZE_MB}")
OPENCLAW_SWAPFILE_PATH=$(shell_quote "${OPENCLAW_SWAPFILE_PATH}")
OPENCLAW_SKIP_SYSTEMD=$(shell_quote "${OPENCLAW_SKIP_SYSTEMD}")
DOCKER_REGISTRY_MIRROR_URL=$(shell_quote "${DOCKER_REGISTRY_MIRROR_URL}")
HTTP_PROXY=$(shell_quote "${HTTP_PROXY}")
HTTPS_PROXY=$(shell_quote "${HTTPS_PROXY}")
NO_PROXY=$(shell_quote "${NO_PROXY}")
PIP_INDEX_URL=$(shell_quote "${PIP_INDEX_URL}")
PIP_EXTRA_INDEX_URL=$(shell_quote "${PIP_EXTRA_INDEX_URL}")
APT_MIRROR=$(shell_quote "${APT_MIRROR}")
EOF
  sudo_exec install -m 0600 "${tmp_file}" "${OPENCLAW_ENV_FILE}"
  rm -f "${tmp_file}"
}

load_deployment_env_file() {
  local env_file="$1"
  if [[ -f "${env_file}" ]]; then
    # shellcheck source=/dev/null
    source "${env_file}"
  fi
}

copy_project_assets() {
  set_current_step "copy_assets"
  local project_root="$1"
  local toolkit_dir="${OPENCLAW_TOOLKIT_DIR}"
  sudo_exec install -m 0755 "${project_root}/install_openclaw.sh" "${toolkit_dir}/install_openclaw.sh"
  sudo_exec install -m 0755 "${project_root}/upgrade_openclaw.sh" "${toolkit_dir}/upgrade_openclaw.sh"
  sudo_exec install -m 0755 "${project_root}/uninstall_openclaw.sh" "${toolkit_dir}/uninstall_openclaw.sh"
  sudo_exec install -m 0644 "${project_root}/compose.yaml" "${toolkit_dir}/compose.yaml"
  sudo_exec install -m 0644 "${project_root}/Dockerfile" "${toolkit_dir}/Dockerfile"
  sudo_exec install -m 0644 "${project_root}/.env.example" "${toolkit_dir}/.env.example"
  if [[ -f "${project_root}/README.md" ]]; then
    sudo_exec install -m 0644 "${project_root}/README.md" "${toolkit_dir}/README.md"
  fi
  sudo_exec install -m 0644 "${project_root}/scripts/lib/openclaw-common.sh" "${toolkit_dir}/scripts/lib/openclaw-common.sh"
  sudo_exec install -m 0644 "${project_root}/Dockerfile" "${OPENCLAW_INSTALL_DIR}/Dockerfile"
}

runtime_secret_present() {
  local key="$1"
  [[ -f "${OPENCLAW_RUNTIME_ENV_FILE}" ]] && grep -Eq "^${key}=" "${OPENCLAW_RUNTIME_ENV_FILE}"
}

append_runtime_env_value() {
  local key="$1"
  local value="$2"
  if runtime_secret_present "${key}"; then
    return 0
  fi
  if [[ "${OPENCLAW_DRY_RUN}" == "1" ]]; then
    log_info "[dry-run] write ${key} to ${OPENCLAW_RUNTIME_ENV_FILE}"
    return 0
  fi
  printf "%s=%s\n" "${key}" "${value}" | sudo_exec tee -a "${OPENCLAW_RUNTIME_ENV_FILE}" >/dev/null
}

prepare_runtime_env_file() {
  set_current_step "prepare_runtime_env"
  sudo_exec mkdir -p "$(dirname "${OPENCLAW_RUNTIME_ENV_FILE}")"
  if [[ ! -f "${OPENCLAW_RUNTIME_ENV_FILE}" ]]; then
    local tmp_file
    tmp_file="$(mktemp)"
    cat > "${tmp_file}" <<'EOF'
# Container runtime environment values.
# Add non-secret application settings here.
EOF
    sudo_exec install -m 0600 "${tmp_file}" "${OPENCLAW_RUNTIME_ENV_FILE}"
    rm -f "${tmp_file}"
  fi

  local raw_key
  IFS=',' read -r -a raw_keys <<< "${OPENCLAW_REQUIRED_SECRETS}"
  for raw_key in "${raw_keys[@]}"; do
    local key
    key="$(trim "${raw_key}")"
    [[ -n "${key}" ]] || continue
    if runtime_secret_present "${key}"; then
      continue
    fi
    if [[ "${OPENCLAW_NON_INTERACTIVE}" == "1" ]]; then
      log_warn "Runtime secret ${key} is required but missing. Add it to ${OPENCLAW_RUNTIME_ENV_FILE} before starting the application."
      continue
    fi
    local value
    read -r -s -p "Enter a value for ${key}: " value
    printf "\n" >&2
    if [[ -n "${value}" ]]; then
      append_runtime_env_value "${key}" "${value}"
    else
      log_warn "No value entered for ${key}. Some application features may remain unavailable."
    fi
  done
}

validate_required_config() {
  set_current_step "validate_config"
  case "${OPENCLAW_DEPLOY_MODE}" in
    image)
      [[ -n "${OPENCLAW_IMAGE_REF}" ]] || die "OPENCLAW_IMAGE_REF is required for image mode."
      if [[ -z "${OPENCLAW_RUN_CMD}" ]]; then
        log_warn "OPENCLAW_RUN_CMD is empty. The image must provide a working default command."
      fi
      ;;
    build)
      [[ -n "${OPENCLAW_IMAGE_REF}" ]] || die "OPENCLAW_IMAGE_REF is required for build mode."
      [[ -n "${OPENCLAW_RUN_CMD}" ]] || die "OPENCLAW_RUN_CMD is required for build mode because the generic Dockerfile defaults to a no-op command."
      case "${OPENCLAW_SOURCE_MODE}" in
        git)
          [[ -n "${OPENCLAW_GIT_REPO}" ]] || die "OPENCLAW_GIT_REPO is required for build mode with source_mode=git."
          ;;
        local)
          [[ -n "${OPENCLAW_LOCAL_SOURCE_PATH}" ]] || die "OPENCLAW_LOCAL_SOURCE_PATH is required for build mode with source_mode=local."
          [[ -d "${OPENCLAW_LOCAL_SOURCE_PATH}" ]] || die "OPENCLAW_LOCAL_SOURCE_PATH does not exist: ${OPENCLAW_LOCAL_SOURCE_PATH}"
          ;;
        *)
          die "Unsupported OPENCLAW_SOURCE_MODE: ${OPENCLAW_SOURCE_MODE}"
          ;;
      esac
      ;;
    *)
      die "Unsupported OPENCLAW_DEPLOY_MODE: ${OPENCLAW_DEPLOY_MODE}"
      ;;
  esac

  case "${OPENCLAW_HEALTHCHECK_MODE}" in
    http)
      [[ -n "${OPENCLAW_HEALTHCHECK_URL}" ]] || die "OPENCLAW_HEALTHCHECK_URL is required for HTTP healthchecks."
      ;;
    tcp)
      [[ -n "${OPENCLAW_HEALTHCHECK_HOST}" ]] || die "OPENCLAW_HEALTHCHECK_HOST is required for TCP healthchecks."
      [[ -n "${OPENCLAW_HEALTHCHECK_PORT}" ]] || die "OPENCLAW_HEALTHCHECK_PORT is required for TCP healthchecks."
      ;;
    exec)
      [[ -n "${OPENCLAW_HEALTHCHECK_CMD}" ]] || die "OPENCLAW_HEALTHCHECK_CMD is required for exec healthchecks."
      ;;
    none)
      ;;
    *)
      die "Unsupported OPENCLAW_HEALTHCHECK_MODE: ${OPENCLAW_HEALTHCHECK_MODE}"
      ;;
  esac
}

prepare_application_source() {
  set_current_step "prepare_source"
  if [[ "${OPENCLAW_DEPLOY_MODE}" != "build" ]]; then
    return 0
  fi
  sudo_exec mkdir -p "${OPENCLAW_SOURCE_DIR}"
  if [[ "${OPENCLAW_SOURCE_MODE}" == "git" ]] && ! command_exists git; then
    case "${OPENCLAW_PACKAGE_MANAGER}" in
      apt)
        retry_command 3 5 sudo_exec apt-get update
        retry_command 3 5 sudo_exec apt-get install -y git
        ;;
      yum|dnf)
        retry_command 3 5 sudo_exec "${OPENCLAW_PACKAGE_MANAGER}" install -y git
        ;;
      pacman)
        retry_command 3 5 sudo_exec pacman -Sy --noconfirm git
        ;;
      *)
        die "git is required for build mode and could not be installed automatically."
        ;;
    esac
  fi
  if [[ "${OPENCLAW_DRY_RUN}" == "1" ]]; then
    log_info "[dry-run] source mode ${OPENCLAW_SOURCE_MODE}"
    return 0
  fi
  case "${OPENCLAW_SOURCE_MODE}" in
    git)
      if [[ -d "${OPENCLAW_APP_SOURCE_DIR}/.git" ]]; then
        run_cmd_privileged git -C "${OPENCLAW_APP_SOURCE_DIR}" fetch --all --tags
        run_cmd_privileged git -C "${OPENCLAW_APP_SOURCE_DIR}" checkout "${OPENCLAW_GIT_REF}"
        run_cmd_privileged git -C "${OPENCLAW_APP_SOURCE_DIR}" reset --hard "origin/${OPENCLAW_GIT_REF}"
      else
        sudo_exec rm -rf "${OPENCLAW_APP_SOURCE_DIR}"
        run_cmd_privileged git clone --depth "${OPENCLAW_GIT_CLONE_DEPTH}" --branch "${OPENCLAW_GIT_REF}" "${OPENCLAW_GIT_REPO}" "${OPENCLAW_APP_SOURCE_DIR}"
      fi
      ;;
    local)
      sudo_exec rm -rf "${OPENCLAW_APP_SOURCE_DIR}"
      sudo_exec mkdir -p "${OPENCLAW_APP_SOURCE_DIR}"
      if command_exists rsync; then
        run_cmd_privileged rsync -a --delete "${OPENCLAW_LOCAL_SOURCE_PATH}/" "${OPENCLAW_APP_SOURCE_DIR}/"
      else
        run_cmd_privileged cp -R "${OPENCLAW_LOCAL_SOURCE_PATH}/." "${OPENCLAW_APP_SOURCE_DIR}/"
      fi
      ;;
  esac
}

compose_healthcheck_command() {
  if [[ -n "${OPENCLAW_HEALTHCHECK_COMPOSE_CMD}" ]]; then
    printf "%s" "${OPENCLAW_HEALTHCHECK_COMPOSE_CMD}"
    return 0
  fi
  case "${OPENCLAW_HEALTHCHECK_MODE}" in
    http)
      if [[ "${OPENCLAW_DEPLOY_MODE}" == "build" ]]; then
        printf "curl -fsS http://127.0.0.1:%s%s >/dev/null" "${OPENCLAW_CONTAINER_PORT}" "${OPENCLAW_HEALTHCHECK_PATH}"
      else
        printf "exit 0"
      fi
      ;;
    exec)
      printf "%s" "${OPENCLAW_HEALTHCHECK_CMD:-exit 0}"
      ;;
    *)
      printf "exit 0"
      ;;
  esac
}

generate_compose_file() {
  set_current_step "generate_compose_file"
  local tmp_file
  tmp_file="$(mktemp)"
  local compose_health_cmd
  compose_health_cmd="$(compose_healthcheck_command)"

  cat > "${tmp_file}" <<EOF
services:
  ${OPENCLAW_SERVICE_NAME}:
    container_name: ${OPENCLAW_SERVICE_NAME}
    image: ${OPENCLAW_IMAGE_REF}
EOF

  if [[ "${OPENCLAW_DEPLOY_MODE}" == "build" ]]; then
    cat >> "${tmp_file}" <<EOF
    build:
      context: .
      dockerfile: ./${OPENCLAW_DOCKERFILE_NAME}
      args:
        BASE_IMAGE: ${OPENCLAW_BASE_IMAGE}
        HTTP_PROXY: ${HTTP_PROXY}
        HTTPS_PROXY: ${HTTPS_PROXY}
        NO_PROXY: ${NO_PROXY}
        PIP_INDEX_URL: ${PIP_INDEX_URL}
        PIP_EXTRA_INDEX_URL: ${PIP_EXTRA_INDEX_URL}
        APT_MIRROR: ${APT_MIRROR}
EOF
    if [[ -n "${OPENCLAW_BUILD_TARGET}" ]]; then
      cat >> "${tmp_file}" <<EOF
      target: ${OPENCLAW_BUILD_TARGET}
EOF
    fi
  else
    cat >> "${tmp_file}" <<EOF
    pull_policy: always
EOF
  fi

  cat >> "${tmp_file}" <<EOF
    restart: unless-stopped
    working_dir: ${OPENCLAW_RUNTIME_WORKDIR}
    env_file:
      - ${OPENCLAW_RUNTIME_ENV_FILE}
    ports:
      - "${OPENCLAW_BIND_ADDRESS}:${OPENCLAW_HOST_PORT}:${OPENCLAW_CONTAINER_PORT}"
    volumes:
      - ${OPENCLAW_DATA_DIR}:/var/lib/openclaw
      - ${OPENCLAW_CONFIG_DIR}:/etc/openclaw
      - ${OPENCLAW_LOG_DIR}:/var/log/openclaw
      - ${OPENCLAW_CACHE_DIR}:/var/cache/openclaw
    logging:
      driver: json-file
      options:
        max-size: "${OPENCLAW_LOG_MAX_SIZE}"
        max-file: "${OPENCLAW_LOG_MAX_FILES}"
EOF

  if [[ -n "${OPENCLAW_RUN_CMD}" ]]; then
    cat >> "${tmp_file}" <<EOF
    command:
      - /bin/sh
      - -lc
      - |
        exec ${OPENCLAW_RUN_CMD}
EOF
  fi

  if [[ "${OPENCLAW_HEALTHCHECK_MODE}" != "none" ]]; then
    cat >> "${tmp_file}" <<EOF
    healthcheck:
      test:
        - CMD-SHELL
        - ${compose_health_cmd}
      interval: ${OPENCLAW_HEALTHCHECK_INTERVAL}s
      timeout: ${OPENCLAW_HEALTHCHECK_TIMEOUT}s
      retries: 3
EOF
  fi

  sudo_exec install -m 0644 "${tmp_file}" "${OPENCLAW_COMPOSE_FILE}"
  rm -f "${tmp_file}"
}

build_or_pull_image() {
  set_current_step "build_or_pull_image"
  if [[ "${OPENCLAW_DEPLOY_MODE}" == "image" ]]; then
    retry_command 3 5 run_cmd_privileged docker pull "${OPENCLAW_IMAGE_REF}"
    return 0
  fi
  retry_command 3 5 compose_exec build --pull
}

install_service_wrapper() {
  set_current_step "install_service_wrapper"
  if [[ "${OPENCLAW_SKIP_SYSTEMD}" == "1" ]]; then
    log_warn "Skipping systemd wrapper installation by request."
    return 0
  fi
  if ! command_exists systemctl; then
    log_warn "systemd not available. Relying on Docker restart policies only."
    return 0
  fi

  local compose_command
  if [[ "${OPENCLAW_COMPOSE_IMPLEMENTATION}" == "plugin" ]]; then
    compose_command="docker compose"
  else
    compose_command="docker-compose"
  fi

  local unit_path="/etc/systemd/system/${OPENCLAW_SYSTEMD_UNIT}"
  local tmp_file
  tmp_file="$(mktemp)"
  cat > "${tmp_file}" <<EOF
[Unit]
Description=OpenClaw Compose Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${OPENCLAW_INSTALL_DIR}
ExecStart=/usr/bin/env bash -lc '${compose_command} --project-name ${OPENCLAW_SERVICE_NAME} -f ${OPENCLAW_COMPOSE_FILE} up -d --remove-orphans --no-build'
ExecStop=/usr/bin/env bash -lc '${compose_command} --project-name ${OPENCLAW_SERVICE_NAME} -f ${OPENCLAW_COMPOSE_FILE} down --remove-orphans'
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
  sudo_exec install -m 0644 "${tmp_file}" "${unit_path}"
  rm -f "${tmp_file}"
  sudo_exec systemctl daemon-reload
  sudo_exec systemctl enable "${OPENCLAW_SYSTEMD_UNIT}"
  OPENCLAW_UNIT_INSTALLED=1
}

remove_service_wrapper() {
  local unit_path="/etc/systemd/system/${OPENCLAW_SYSTEMD_UNIT}"
  if [[ -f "${unit_path}" ]]; then
    if command_exists systemctl; then
      sudo_exec systemctl disable --now "${OPENCLAW_SYSTEMD_UNIT}" || true
      sudo_exec systemctl daemon-reload || true
    fi
    sudo_exec rm -f "${unit_path}"
  fi
}

start_openclaw() {
  set_current_step "start_openclaw"
  compose_exec up -d --remove-orphans --no-build
  OPENCLAW_STACK_STARTED=1
}

stop_openclaw_stack() {
  if [[ -f "${OPENCLAW_COMPOSE_FILE}" ]]; then
    set_current_step "stop_openclaw"
    compose_exec down --remove-orphans || true
  fi
}

http_healthcheck() {
  if command_exists curl; then
    curl -fsS --max-time "${OPENCLAW_HEALTHCHECK_TIMEOUT}" "${OPENCLAW_HEALTHCHECK_URL}" >/dev/null
    return $?
  fi
  wget -qO- --timeout="${OPENCLAW_HEALTHCHECK_TIMEOUT}" "${OPENCLAW_HEALTHCHECK_URL}" >/dev/null
}

tcp_healthcheck() {
  timeout "${OPENCLAW_HEALTHCHECK_TIMEOUT}" bash -lc ">/dev/tcp/${OPENCLAW_HEALTHCHECK_HOST}/${OPENCLAW_HEALTHCHECK_PORT}"
}

exec_healthcheck() {
  capture_cmd_privileged docker exec "${OPENCLAW_SERVICE_NAME}" /bin/sh -lc "${OPENCLAW_HEALTHCHECK_CMD}"
}

healthcheck_openclaw() {
  set_current_step "healthcheck"
  if [[ "${OPENCLAW_SKIP_HEALTHCHECK}" == "1" ]]; then
    log_warn "Skipping healthcheck by request."
    return 0
  fi
  if [[ "${OPENCLAW_HEALTHCHECK_MODE}" == "none" ]]; then
    log_warn "No healthcheck configured."
    return 0
  fi

  local attempts="${OPENCLAW_HEALTHCHECK_RETRIES}"
  local try=1
  while [[ "${try}" -le "${attempts}" ]]; do
    case "${OPENCLAW_HEALTHCHECK_MODE}" in
      http)
        if http_healthcheck; then
          log_info "HTTP healthcheck passed."
          return 0
        fi
        ;;
      tcp)
        if tcp_healthcheck; then
          log_info "TCP healthcheck passed."
          return 0
        fi
        ;;
      exec)
        if exec_healthcheck; then
          log_info "Exec healthcheck passed."
          return 0
        fi
        ;;
    esac
    log_warn "Healthcheck attempt ${try}/${attempts} failed."
    sleep "${OPENCLAW_HEALTHCHECK_INTERVAL}"
    try=$((try + 1))
  done
  die "OpenClaw healthcheck did not pass."
}

current_container_image_id() {
  capture_cmd_privileged docker inspect --format '{{.Image}}' "${OPENCLAW_SERVICE_NAME}" 2>/dev/null || true
}

tag_current_image_for_rollback() {
  set_current_step "prepare_rollback_image"
  local image_id
  image_id="$(current_container_image_id)"
  if [[ -z "${image_id}" ]]; then
    return 0
  fi
  OPENCLAW_ROLLBACK_IMAGE_TAG="${OPENCLAW_SERVICE_NAME}:rollback-$(date +%Y%m%d%H%M%S)"
  run_cmd_privileged docker image tag "${image_id}" "${OPENCLAW_ROLLBACK_IMAGE_TAG}"
}

backup_installation_state() {
  set_current_step "backup_state"
  local stamp
  stamp="$(date +%Y%m%d%H%M%S)"
  OPENCLAW_BACKUP_PATH="${OPENCLAW_BACKUP_DIR}/${stamp}"
  sudo_exec mkdir -p "${OPENCLAW_BACKUP_PATH}"
  [[ -f "${OPENCLAW_ENV_FILE}" ]] && sudo_exec cp "${OPENCLAW_ENV_FILE}" "${OPENCLAW_BACKUP_PATH}/.env"
  [[ -f "${OPENCLAW_RUNTIME_ENV_FILE}" ]] && sudo_exec cp "${OPENCLAW_RUNTIME_ENV_FILE}" "${OPENCLAW_BACKUP_PATH}/runtime.env"
  [[ -f "${OPENCLAW_COMPOSE_FILE}" ]] && sudo_exec cp "${OPENCLAW_COMPOSE_FILE}" "${OPENCLAW_BACKUP_PATH}/compose.yaml"
}

restore_backup_state() {
  if [[ -z "${OPENCLAW_BACKUP_PATH}" ]] || [[ ! -d "${OPENCLAW_BACKUP_PATH}" ]]; then
    return 0
  fi
  set_current_step "restore_backup"
  [[ -f "${OPENCLAW_BACKUP_PATH}/.env" ]] && sudo_exec cp "${OPENCLAW_BACKUP_PATH}/.env" "${OPENCLAW_ENV_FILE}"
  [[ -f "${OPENCLAW_BACKUP_PATH}/runtime.env" ]] && sudo_exec cp "${OPENCLAW_BACKUP_PATH}/runtime.env" "${OPENCLAW_RUNTIME_ENV_FILE}"
  [[ -f "${OPENCLAW_BACKUP_PATH}/compose.yaml" ]] && sudo_exec cp "${OPENCLAW_BACKUP_PATH}/compose.yaml" "${OPENCLAW_COMPOSE_FILE}"
}

rollback_install() {
  log_warn "Rolling back install changes created in this run."
  stop_openclaw_stack
  if [[ "${OPENCLAW_UNIT_INSTALLED}" == "1" ]]; then
    remove_service_wrapper
  fi
}

rollback_upgrade() {
  log_warn "Rolling back upgrade attempt."
  restore_backup_state
  if [[ -f "${OPENCLAW_ENV_FILE}" ]]; then
    load_deployment_env_file "${OPENCLAW_ENV_FILE}"
    apply_directory_layout
  fi
  if [[ -n "${OPENCLAW_ROLLBACK_IMAGE_TAG}" ]]; then
    OPENCLAW_IMAGE_REF="${OPENCLAW_ROLLBACK_IMAGE_TAG}"
    generate_compose_file
  fi
  stop_openclaw_stack
  start_openclaw || true
}

assert_managed_installation() {
  [[ -f "${OPENCLAW_MARKER_FILE}" ]] || die "Managed installation marker not found at ${OPENCLAW_MARKER_FILE}."
}

choose_existing_action() {
  if [[ "${OPENCLAW_NON_INTERACTIVE}" == "1" ]]; then
    printf "%s" "${OPENCLAW_EXISTING_ACTION}"
    return 0
  fi
  printf "%s\n" "Existing OpenClaw installation detected:"
  printf "%s\n" "  1. Reinstall toolkit files (keep config and data)"
  printf "%s\n" "  2. Repair environment"
  printf "%s\n" "  3. Upgrade OpenClaw"
  printf "%s\n" "  4. Exit"
  local answer
  read -r -p "Choose an action [1-4]: " answer
  case "${answer}" in
    1) printf "%s" "reinstall" ;;
    2) printf "%s" "repair" ;;
    3) printf "%s" "upgrade" ;;
    *) printf "%s" "exit" ;;
  esac
}

remove_installation_paths() {
  set_current_step "remove_paths"
  assert_managed_installation
  path_is_safe "${OPENCLAW_INSTALL_DIR}" || die "Refusing to remove unsafe install directory."
  sudo_exec rm -rf "${OPENCLAW_INSTALL_DIR}"
}

show_post_install_guide() {
  set_current_step "summary"
  local compose_command
  if [[ "${OPENCLAW_COMPOSE_IMPLEMENTATION}" == "plugin" ]]; then
    compose_command="docker compose"
  else
    compose_command="docker-compose"
  fi
  cat >&2 <<EOF

OpenClaw deployment summary
---------------------------
Install directory : ${OPENCLAW_INSTALL_DIR}
Compose file      : ${OPENCLAW_COMPOSE_FILE}
Toolkit directory : ${OPENCLAW_TOOLKIT_DIR}
Config directory  : ${OPENCLAW_CONFIG_DIR}
Data directory    : ${OPENCLAW_DATA_DIR}
Log directory     : ${OPENCLAW_LOG_DIR}
Runtime env file  : ${OPENCLAW_RUNTIME_ENV_FILE}
Service name      : ${OPENCLAW_SERVICE_NAME}
Access endpoint   : ${OPENCLAW_BIND_ADDRESS}:${OPENCLAW_HOST_PORT}

Status:
  ${compose_command} --project-name ${OPENCLAW_SERVICE_NAME} -f ${OPENCLAW_COMPOSE_FILE} ps

Logs:
  ${compose_command} --project-name ${OPENCLAW_SERVICE_NAME} -f ${OPENCLAW_COMPOSE_FILE} logs -f

Restart:
  ${compose_command} --project-name ${OPENCLAW_SERVICE_NAME} -f ${OPENCLAW_COMPOSE_FILE} up -d --remove-orphans --no-build

Upgrade:
  ${OPENCLAW_TOOLKIT_DIR}/upgrade_openclaw.sh --dir ${OPENCLAW_INSTALL_DIR}

Uninstall:
  ${OPENCLAW_TOOLKIT_DIR}/uninstall_openclaw.sh --dir ${OPENCLAW_INSTALL_DIR} --mode containers

EOF
}
