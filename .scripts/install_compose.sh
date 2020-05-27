#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_compose() {
    local MINIMUM_COMPOSE="1.17.0"
    # Find minimum compatible version at https://docs.docker.com/release-notes/docker-compose/
    local INSTALLED_COMPOSE
    if [[ ${FORCE:-} == true ]]; then
        INSTALLED_COMPOSE="0"
    else
        INSTALLED_COMPOSE=$( (/usr/local/bin/docker-compose --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
    fi
    if vergt "${MINIMUM_COMPOSE}" "${INSTALLED_COMPOSE}"; then
        local AVAILABLE_COMPOSE
        AVAILABLE_COMPOSE=$( (curl -H "${GH_HEADER:-}" -fsL "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "[Vv]?\K.*?(?=")') || echo "0")
        if [[ ${AVAILABLE_COMPOSE} == "0" ]]; then
            if [[ ${INSTALLED_COMPOSE} == "0" ]]; then
                fatal "The latest available version of docker-compose could not be confirmed. This is usually caused by exhausting the rate limit on GitHub's API. Please check https://api.github.com/rate_limit"
            else
                warn "Failed to check latest available docker-compose version. This can be ignored for now."
                return
            fi
        fi
        if vergt "${AVAILABLE_COMPOSE}" "${INSTALLED_COMPOSE}"; then
            # run_script 'package_manager_run' remove_python_conflicts
            # info "Installing latest python pip."
            # run_script 'run_python' -m pip install -IUq pip > /dev/null 2>&1 || warn "Failed to install pip from pip. This can be ignored for now."

            # info "Removing old docker-compose."
            # rm /usr/local/bin/docker-compose > /dev/null 2>&1 || true
            # rm /usr/bin/docker-compose > /dev/null 2>&1 || true
            # run_script 'run_python' -m pip uninstall docker-py > /dev/null 2>&1 || true

            # info "Installing latest setuptools."
            # run_script 'run_python' -m pip install -IUq setuptools > /dev/null 2>&1 || warn "Failed to install setuptools from pip. This can be ignored for now."
            # info "Installing latest urllib3[secure]."
            # run_script 'run_python' -m pip install -IUq "urllib3[secure]" > /dev/null 2>&1 || warn "Failed to install urllib3[secure] from pip. This can be ignored for now."

            # https://docs.docker.com/compose/install/
            info "Installing latest docker-compose."
            # run_script 'run_python' -m pip install -IUq docker-compose > /dev/null 2>&1 || warn "Failed to install docker-compose from pip. This can be ignored for now."

            curl -fsL "https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh" -o /usr/local/bin/docker-compose > /dev/null 2>&1 || fatal "Failed to install docker-compose."
            if [[ ! -L "/usr/bin/docker-compose" ]]; then
                ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || fatal "Failed to create /usr/bin/docker-compose symlink."
            fi
            chmod +x /usr/local/bin/docker-compose > /dev/null 2>&1 || true

            local UPDATED_COMPOSE
            UPDATED_COMPOSE=$( (/usr/local/bin/docker-compose --version 2> /dev/null || echo "0") | sed -E 's/.* version ([^,]*)(, build .*)?/\1/')
            if vergt "${AVAILABLE_COMPOSE}" "${UPDATED_COMPOSE}"; then
                fatal "Failed to install the latest docker-compose."
            fi
            if vergt "${MINIMUM_COMPOSE}" "${UPDATED_COMPOSE}"; then
                fatal "Failed to install the minimum required docker-compose."
            fi
        fi
    fi
}

test_install_compose() {
    run_script 'install_compose'
    /usr/local/bin/docker-compose --version || fatal "Failed to determine docker-compose version."
}
