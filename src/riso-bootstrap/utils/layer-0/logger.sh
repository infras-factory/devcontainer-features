#!/bin/bash

# Don't exit on errors in logger - we want to handle them gracefully
set +e

# ----------------------------------------
# Local Variables
# ----------------------------------------
# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# ----------------------------------------
# Context Tracking Variables
# ----------------------------------------
# Global variables for logging context
CURRENT_WORKFLOW=""
CURRENT_STEP=""
CURRENT_GROUP=""
WORKFLOW_START_TIME=""
STEP_START_TIME=""

# ----------------------------------------
# utils/logger.sh - Enhanced Logging utilities for Riso Bootstrap
# Following GitHub Actions logging style with hierarchy support
# ----------------------------------------

# ----------------------------------------
# Context Management Functions
# ----------------------------------------
set_workflow_context() {
    CURRENT_WORKFLOW="$1"
    WORKFLOW_START_TIME=$(date +%s)
}

set_step_context() {
    CURRENT_STEP="$1"
    STEP_START_TIME=$(date +%s)
}

get_duration() {
    local start_time="$1"
    local end_time
    end_time=$(date +%s)
    echo $((end_time - start_time))
}

# ----------------------------------------
# Workflow-level Logging Functions
# ----------------------------------------
log_workflow_start() {
    local workflow_name="$1"
    set_workflow_context "$workflow_name"
    echo -e "\n${BOLD}${PURPLE}🚀 Starting workflow: ${workflow_name}${NC}" >&2
}

log_workflow_end() {
    local workflow_name="$1"
    local status="$2"  # success/failure
    local duration=""

    if [ -n "$WORKFLOW_START_TIME" ]; then
        duration=" in $(get_duration "$WORKFLOW_START_TIME")s"
    fi

    if [ "$status" = "success" ]; then
        echo -e "${BOLD}${GREEN}✅ Workflow completed: ${workflow_name}${duration}${NC}" >&2
    else
        echo -e "${BOLD}${RED}❌ Workflow failed: ${workflow_name}${duration}${NC}" >&2
    fi
}

# ----------------------------------------
# Step-level Logging Functions
# ----------------------------------------
log_step_start() {
    local step_name="$1"
    local step_number="$2"
    local total_steps="$3"
    set_step_context "$step_name"
    echo -e "\n${BOLD}${BLUE}[${step_number}/${total_steps}] ${step_name}${NC}" >&2
}

log_step_end() {
    local step_name="$1"
    local status="$2"  # success/failure
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✓ ${step_name} completed${NC}" >&2
    else
        echo -e "${RED}✗ ${step_name} failed${NC}" >&2
    fi
}

log_step_end_with_timing() {
    local step_name="$1"
    local status="$2"
    local duration=""

    if [ -n "$STEP_START_TIME" ]; then
        duration=" in $(get_duration "$STEP_START_TIME")s"
    fi

    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✓ ${step_name} completed${duration}${NC}" >&2
    else
        echo -e "${RED}✗ ${step_name} failed${duration}${NC}" >&2
    fi
}

# ----------------------------------------
# Group-level Logging Functions
# ----------------------------------------
log_group_start() {
    local group_title="$1"
    CURRENT_GROUP="$group_title"
    echo -e "${CYAN}▶ ${group_title}${NC}" >&2
}

log_group_end() {
    local group_title="$1"
    echo -e "${CYAN}◀ End: ${group_title}${NC}" >&2
    # Clear current group context for tracking
    # shellcheck disable=SC2034
    CURRENT_GROUP=""
}

log_group() {
    local group_title="$1"
    local commands="$2"
    log_group_start "$group_title"
    eval "$commands"
    log_group_end "$group_title"
}

# ----------------------------------------
# Command-level Logging Functions (Enhanced)
# ----------------------------------------
log_notice() {
    echo -e "${BLUE}ℹ️  NOTICE: $1${NC}" >&2
}

log_debug() {
    if [ "${DEBUG_MODE:-false}" = "true" ]; then
        echo -e "${PURPLE}🐛 DEBUG: $1${NC}" >&2
    fi
}

# ----------------------------------------
# Existing Functions (Updated to use stderr)
# ----------------------------------------
# ----------------------------------------
# Existing Functions (Updated to use stderr)
# ----------------------------------------
log_phase() {
    local phase_message="$1"
    local message_length=${#phase_message}
    local total_width=$((message_length + 10))  # Add padding
    local separator
    separator=$(printf '%*s' "$total_width" '' | tr ' ' '=')

    echo -e "\n${BOLD}${PURPLE}${separator}${NC}" >&2
    echo -e "${BOLD}${PURPLE}     ${phase_message}${NC}" >&2
    echo -e "${BOLD}${PURPLE}${separator}${NC}" >&2
}

display_bold_message() {
    local message="$1"
    local message_length=${#message}
    local total_width=$((message_length + 10))  # Add padding like log_phase
    local separator
    separator=$(printf '%*s' "$total_width" '' | tr ' ' '=')
    echo -e "${GREEN}${separator}${NC}" >&2
    echo -e "${GREEN}${BOLD}     ${message}${NC}" >&2
    echo -e "${GREEN}${separator}${NC}" >&2
}

log_section() {
    local section_message="$1"
    echo -e "${CYAN}${section_message}${NC}" >&2
}

log_subsection() {
    local subsection_message="$1"
    echo "" >&2
    echo -e "${BOLD}${CYAN}  ${subsection_message}${NC}" >&2
}

log_section_info() {
    echo -e "${WHITE}    $1${NC}" >&2
}

log_header() {
    echo -e "\n${BOLD}${BLUE}🎯 $1${NC}" >&2
}

log_info() {
    echo -e "${CYAN}💡 $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}🎉 $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}🚨 $1${NC}" >&2
}

log_error() {
    echo -e "${RED}💥 $1${NC}" >&2
}

log_step() {
    local step="$1"
    local total="$2"
    local message="$3"
    echo -e "${BOLD}${BLUE}[$step/$total]${NC} ${CYAN}$message${NC}" >&2
}

# ----------------------------------------
# Error Handling Functions
# ----------------------------------------
handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    local recovery_hint="$3"

    log_error "$error_message"
    if [ -n "$recovery_hint" ]; then
        log_notice "Recovery hint: $recovery_hint"
    fi

    if [ -n "$CURRENT_WORKFLOW" ]; then
        log_workflow_end "$CURRENT_WORKFLOW" "failure"
    fi
    exit "$exit_code"
}

# Setup error trap (can be enabled by setting ERROR_TRAP=true)
setup_error_trap() {
    if [ "${ERROR_TRAP:-false}" = "true" ]; then
        trap 'handle_error "Unexpected error in $CURRENT_WORKFLOW at step $CURRENT_STEP" $? "Check the logs above for details"' ERR
    fi
}
