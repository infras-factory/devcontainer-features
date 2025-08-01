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

    echo -e "\n${BOLD}${PURPLE}${separator}${NC}"
    echo -e "${BOLD}${PURPLE}     ${phase_message}${NC}"
    echo -e "${BOLD}${PURPLE}${separator}${NC}"
}

display_bold_message() {
    local message="$1"
    local message_length=${#message}
    local total_width=$((message_length + 10))  # Add padding like log_phase
    local separator
    separator=$(printf '%*s' "$total_width" '' | tr ' ' '=')
    echo -e "${GREEN}${separator}${NC}"
    echo -e "${GREEN}${BOLD}     ${message}${NC}"
    echo -e "${GREEN}${separator}${NC}"
}

log_section() {
    local section_message="$1"
    echo -e "${CYAN}${section_message}${NC}"
}

log_subsection() {
    local subsection_message="$1"
    echo ""
    echo -e "${BOLD}${CYAN}  ${subsection_message}${NC}"
}

log_section_info() {
    echo -e "${WHITE}    $1${NC}"
}

log_header() {
    echo -e "\n${BOLD}${BLUE}🎯 $1${NC}"
}

log_info() {
    echo -e "${CYAN}💡 $1${NC}"
}

log_success() {
    echo -e "${GREEN}🎉 $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}🚨 $1${NC}"
}

log_error() {
    echo -e "${RED}💥 $1${NC}"
}

log_step() {
    local step="$1"
    local total="$2"
    local message="$3"
    echo -e "${BOLD}${BLUE}[$step/$total]${NC} ${CYAN}$message${NC}"
}
