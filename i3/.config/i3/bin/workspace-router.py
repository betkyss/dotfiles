#!/usr/bin/env python3
"""
Keep i3 workspaces 1–5 on the left monitor and 6–10 on the right monitor.
Automatically detects left/right monitors by their X position.
Falls back gracefully if only one monitor is active.
"""
from __future__ import annotations

import sys
from typing import Optional

import i3ipc

LEFT_OUTPUT: Optional[str] = None
RIGHT_OUTPUT: Optional[str] = None


def detect_outputs(conn: i3ipc.Connection) -> None:
  global LEFT_OUTPUT, RIGHT_OUTPUT
  outputs = sorted(
    (o for o in conn.get_outputs() if o.active),
    key=lambda o: o.rect.x,
  )
  if len(outputs) >= 2:
    LEFT_OUTPUT = outputs[0].name
    RIGHT_OUTPUT = outputs[1].name
  elif len(outputs) == 1:
    LEFT_OUTPUT = outputs[0].name
    RIGHT_OUTPUT = outputs[0].name
  else:
    LEFT_OUTPUT = None
    RIGHT_OUTPUT = None


def target_output(workspace_num: Optional[int]) -> Optional[str]:
  if workspace_num is None:
    return None
  if 1 <= workspace_num <= 5:
    return LEFT_OUTPUT
  if 6 <= workspace_num <= 10:
    return RIGHT_OUTPUT
  return None


def active_output_names(conn: i3ipc.Connection) -> set[str]:
  return {o.name for o in conn.get_outputs() if o.active}


def enforce_layout(conn: i3ipc.Connection) -> None:
  detect_outputs(conn)
  outputs = active_output_names(conn)
  for ws in conn.get_workspaces():
    move_workspace_if_needed(conn, ws.num, ws.output, outputs)


def move_workspace_if_needed(
    conn: i3ipc.Connection,
    ws_num: Optional[int],
    current_output: Optional[str],
    outputs: Optional[set[str]] = None,
) -> None:
  target = target_output(ws_num)
  if not target:
    return
  if outputs is None:
    outputs = active_output_names(conn)
  if target not in outputs:
    return
  if current_output == target:
    return
  conn.command(f"workspace number {ws_num}")
  conn.command(f"move workspace to output {target}")


def on_workspace(conn: i3ipc.Connection, event: i3ipc.events.WorkspaceEvent) -> None:
  ws = event.current or event.workspace
  if ws is None or ws.num is None:
    return
  for fresh_ws in conn.get_workspaces():
    if fresh_ws.num == ws.num:
      move_workspace_if_needed(conn, fresh_ws.num, fresh_ws.output)
      return


def on_output(conn: i3ipc.Connection, _: i3ipc.events.OutputEvent) -> None:
  enforce_layout(conn)


def main() -> int:
  try:
    conn = i3ipc.Connection()
  except Exception as exc:
    print(f"[workspace-router] unable to connect to i3: {exc}", file=sys.stderr)
    return 1

  enforce_layout(conn)
  conn.on("workspace", on_workspace)
  conn.on("output", on_output)
  conn.main()
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
