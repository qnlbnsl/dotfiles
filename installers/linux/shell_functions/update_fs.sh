#!/usr/bin/env bash

function update_fs() {
  # Helps in general... Especially when coding in react
  # Increasing max watchers to 65535
  maxfiles="fs.file-max = 65535"
  # Increasing max watchers. Each file watch consumes up to 1080 bytes.
  # 524288 will be able to use up to 540MB
  maxwatches="fs.inotify.max_user_watches=524288"
  echo $maxfiles | sudo tee -a /etc/sysctl.conf
  echo $maxwatches | sudo tee -a /etc/sysctl.conf
}

export -f update_fs