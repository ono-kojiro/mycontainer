#!/bin/sh

export WLR_BACKENDS=headless
export WLR_LIBINPUT_NO_DEVICES=1

exec sway

