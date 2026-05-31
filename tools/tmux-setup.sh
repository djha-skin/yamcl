#!/bin/sh

tmux split-window -h
tmux send-keys -l -t :.1 "./tools/clrepl"
tmux send-keys -l -t :.1 "(asdf:load-system \"cl-mcp\")"
tmux send-keys -l -t :.1 "(cl-mcp:start-http-server :port 12345)"
tmux send-keys -l -t :.1 "./tools/goosew"