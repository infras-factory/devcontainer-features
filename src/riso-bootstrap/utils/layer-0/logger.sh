#!/bin/bash

set -e

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
# utils/logger.sh - Logging utilities for Riso Bootstrap
# ----------------------------------------
# Logging functions
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

log_debug() {
    if [ "${DEBUG:-}" = "true" ]; then
        echo -e "${BLUE}🔍 $1${NC}" >&2
    fi
}

log_step() {
    local step="$1"
    local total="$2"
    local message="$3"
    echo -e "${BOLD}${BLUE}[$step/$total]${NC} ${CYAN}$message${NC}" >&2
}

# ----------------------------------------
# Workflow logging functions for better process tracking
# ----------------------------------------

log_workflow_start() {
    local workflow_name="$1"
    echo -e "\n${BOLD}${PURPLE}▶ Starting: ${workflow_name}${NC}" >&2
}

log_workflow_step() {
    local step_name="$1"
    echo -e "${BLUE}  ├─ ${step_name}${NC}" >&2
}

log_workflow_substep() {
    local substep_name="$1"
    echo -e "${CYAN}  │  └─ ${substep_name}${NC}" >&2
}

log_workflow_end() {
    local workflow_name="$1"
    local status="${2:-success}"
    if [ "$status" = "success" ]; then
        echo -e "${BOLD}${GREEN}▶ Completed: ${workflow_name}${NC}" >&2
    else
        echo -e "${BOLD}${RED}▶ Failed: ${workflow_name}${NC}" >&2
    fi
}

log_file_operation() {
    local operation="$1"
    local file_path="$2"
    echo -e "${YELLOW}📄 ${operation}: ${file_path}${NC}" >&2
}

log_processing() {
    local item="$1"
    local context="${2:-}"
    if [ -n "$context" ]; then
        echo -e "${CYAN}⚙️  Processing ${item} (${context})${NC}" >&2
    else
        echo -e "${CYAN}⚙️  Processing ${item}${NC}" >&2
    fi
}

log_result() {
    local result="$1"
    echo -e "${GREEN}✓ ${result}${NC}" >&2
}

log_skip() {
    local reason="$1"
    echo -e "${YELLOW}⏭️  Skipped: ${reason}${NC}" >&2
}
