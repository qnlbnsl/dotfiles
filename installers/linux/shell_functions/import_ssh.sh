#!/usr/bin/env bash

import_ssh() {
    # Import my SSH keys
    curl https://github.com/qnlbnsl.keys > ~/.ssh/authorized_keys
}