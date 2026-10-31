SHELL := /bin/bash

PAKKA_PORT ?= 8011
RUN_DIR    := .run
BACKEND_LOG := $(RUN_DIR)/backend.log
BACKEND_PID := $(RUN_DIR)/backend.pid
HEALTH_URL  := http://127.0.0.1:$(PAKKA_PORT)/api/users

.PHONY: help install install-backend install-frontend \
        backend frontend dev stop logs test clean

help:
	@echo "make install    - install backend + frontend deps"
	@echo "make backend    - run backend only, foreground (blocks ~15s while it trains)"
	@echo "make frontend   - run frontend only, foreground"
	@echo "make dev        - backend in background + frontend in foreground (waits for backend health)"
	@echo "make stop       - kill a backgrounded backend started by 'make dev'"
	@echo "make logs       - tail the backgrounded backend's log"
	@echo "make test       - run backend test suite"
	@echo "make clean      - remove .run/ pid and log files"

install: install-backend install-frontend

install-backend:
	cd pakka && uv sync

install-frontend:
	cd web && npm install

# Backend alone. The lifespan hook trains the risk model before serving the
# first request (~15s) so the demo's first click isn't the one that pays for
# it -- see pakka/src/pakka/api/main.py. That means this blocks for a bit
# before printing "Uvicorn running": that's expected, not a hang.
backend:
	uv run --project pakka uvicorn pakka.api.main:app --port $(PAKKA_PORT) --reload

frontend:
	cd web && npm run dev

# The combination that actually matters for a pitch: start the backend in
# the background, block until it is *actually* answering requests (not just
# "process started"), then bring up the frontend in the foreground. Ctrl-C
# here tears down the backend too, so nothing is left running.
dev: $(RUN_DIR)
	@if [ -f $(BACKEND_PID) ] && kill -0 $$(cat $(BACKEND_PID)) 2>/dev/null; then \
		echo "Backend already running (pid $$(cat $(BACKEND_PID))), reusing it."; \
	else \
		echo "Starting backend in background (log: $(BACKEND_LOG))..."; \
		uv run --project pakka uvicorn pakka.api.main:app --port $(PAKKA_PORT) --reload > $(BACKEND_LOG) 2>&1 & \
		echo $$! > $(BACKEND_PID); \
	fi
	@trap '$(MAKE) --no-print-directory stop' EXIT INT TERM; \
	echo "Waiting for backend to finish training and come up on :$(PAKKA_PORT)..."; \
	i=0; \
	until curl -s -o /dev/null -w '' $(HEALTH_URL); do \
		i=$$((i+1)); \
		if [ $$i -ge 90 ]; then \
			echo "Backend did not become healthy after 90s -- check $(BACKEND_LOG)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done; \
	echo "Backend is up ($$i s). Starting frontend..."; \
	$(MAKE) --no-print-directory frontend

stop:
	@if [ -f $(BACKEND_PID) ]; then \
		pid=$$(cat $(BACKEND_PID)); \
		if kill -0 $$pid 2>/dev/null; then kill $$pid && echo "Stopped backend (pid $$pid)."; fi; \
		rm -f $(BACKEND_PID); \
	fi

logs:
	@tail -f $(BACKEND_LOG)

test:
	cd pakka && uv run pytest

# Narration. The MP3s in web/public/voice/ are committed, so neither of these
# is needed to run the demo -- only to change what it says.
voice:
	uv run --project pakka python scripts/gen_voice.py

voice-verify:
	uv run --project pakka python scripts/gen_voice.py --verify

clean: stop
	rm -rf $(RUN_DIR)

$(RUN_DIR):
	@mkdir -p $(RUN_DIR)
