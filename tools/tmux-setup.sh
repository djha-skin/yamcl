#!/bin/sh

tmux split-window -v
tmux send-keys -l -t :.1 "./tools/clrepl"
tmux send-keys -l -t :.1 "(asdf:load-system \"cl-mcp\")"
tmux send-keys -l -t :.1 "(cl-mcp:start-http-server :port 12345)"
tmux send-keys -l -t :.0 "./tools/goosew"
tmux send-keys -l -t :.0 "Please continue."