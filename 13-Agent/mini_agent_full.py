"""Start a chat with python mini_agent.py. Tool paths default to the working directory."""

import json
import os
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

client = OpenAI(base_url="https://api.deepseek.com", api_key=os.environ["DEEPSEEK_API_KEY"])

GREEN = "\033[32m"
GRAY = "\033[90m"
RESET = "\033[0m"

RULES = """Return one JSON object per turn. Write your final answer in English.
{"action":"list_files"} List the current directory. Directory names end in /.
{"action":"list_files","path":"demo"} List a specific directory.
{"action":"read","path":"demo/example.py"} Read a file before editing it.
{"action":"edit","path":"demo/example.py","old":"text to find","new":"replacement text"} Replace one unique match.
Each call resolves its own path. Relative paths start at the working directory.
If path is omitted or points to a directory, use the file field for read and edit.
{"action":"done","answer":"your answer"} Report what the tool results confirm."""


def list_files(path):
    if path.is_file():
        return [path.name]
    return sorted(
        entry.name + ("/" if entry.is_dir() else "")
        for entry in path.iterdir()
        if not entry.name.startswith(".") and not entry.is_symlink()
        and (entry.is_file() or entry.is_dir())
    )

def read_file(path):
    return path.read_text(encoding="utf-8")

def edit_file(path, old, new):
    source = read_file(path)
    if not old or source.count(old) != 1:
        return "Edit failed. Read the file again and choose a nonempty snippet that occurs exactly once."
    path.write_text(source.replace(old, new, 1), encoding="utf-8")
    return "Replaced one occurrence."

def file_path(path, name):
    if path.is_dir():
        if not name or Path(name).name != name or name.startswith("."):
            raise ValueError("Choose a filename from list_files.")
        path = path / name
    elif name is not None and name != path.name:
        raise ValueError("Only the supplied file is available.")
    if path.name.startswith(".") or path.is_symlink() or not path.is_file():
        raise ValueError("Choose a regular file from list_files.")
    return path

def use_tool(request):
    action = request["action"]
    path = Path(request.get("path", "."))
    if action == "list_files":
        return list_files(path)
    if action == "read":
        return read_file(file_path(path, request.get("file")))
    if action == "edit":
        return edit_file(file_path(path, request.get("file")), request["old"], request["new"])
    return "Unknown action. Choose list_files, read, edit, or done."

def call_llm(messages):
    response = client.chat.completions.create(
        model="deepseek-flash", messages=messages, response_format={"type": "json_object"}
    )
    reply = response.choices[0].message.content or ""
    return reply

def run_agent_loop():
    
    messages = [
        {"role": "system", "content": RULES}
    ]
    while True:
        user_input = input(f"{GREEN}You:{RESET} ")
        messages.append(
            {"role": "user", "content": user_input}
        )
        while True:
            llm_reply = call_llm(messages)
            messages.append({"role": "assistant", "content": llm_reply})
            print(f"{GRAY}Model -> {llm_reply}{RESET}")
            try:
                request = json.loads(llm_reply)
                if request["action"] == "done":
                    print(f"{GREEN}Assistant:{RESET} {request['answer']}")
                    break
                result = use_tool(request)
            except (ValueError, KeyError, TypeError, OSError) as error:
                result = f"Action failed: {error}"
            print(f"{GRAY}Tool -> {result}{RESET}")
            messages.append({"role": "user", "content": f"Tool result: {result}"})

if __name__ == "__main__":
    run_agent_loop()
