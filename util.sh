#!/bin/bash

function random_string() {
RANDOM_BYTES=${1:-16}
	dd if=/dev/urandom count=1 bs=$RANDOM_BYTES 2>/dev/null | hexdump -ve '1/1 "%.2x"'
}
