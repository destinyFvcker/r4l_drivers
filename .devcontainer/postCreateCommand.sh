#!/bin/sh
git submodule update --init --recursive --depth=20
# git submodule update --remote
rustup override set $(`dirname $0`/../linux_raspberrypi/scripts/min-tool-version.sh rustc)
rustup component add rust-src
cargo install --locked --version $(`dirname $0`/../linux_raspberrypi/scripts/min-tool-version.sh bindgen) bindgen-cli