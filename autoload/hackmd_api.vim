" Starts a section for Python 3 code.

python3 << EOF
# Imports Python modules to be used by the plugin.
import json
import os

import requests
import vim

API_KEY = os.getenv("HACKMD_API_KEY")
THIS_DIR = os.path.dirname(
    vim.eval("expand('<sfile>')")
)
SCRIPT_DIR = os.path.join(
    os.path.dirname(THIS_DIR),
    "hackmd.io"
)
os.makedirs(SCRIPT_DIR, exist_ok=True)
vim.command(f"let g:hackmd_dir = '{SCRIPT_DIR}'")


def sync(force=None):
    notes_index = os.path.join(SCRIPT_DIR, "notes.json")
    if os.path.isfile(notes_index) and not force:
        with open(notes_index, "rb") as reader:
            data = json.loads(reader.read())
    else:
        response = requests.get(
            "https://api.hackmd.io/v1/notes",
            headers={"Authorization": f"Bearer {API_KEY}"}
        )
        if response.status_code != 200:
            print("No notes joy :(")
            raise Exception("No notes joy :(")

        data = response.json()
        with open(notes_index, "w") as writer:
            json.dump(data, writer, indent=4)

        for note in data:
            ndata = sync_note(note["id"])
            filename = os.path.join(SCRIPT_DIR, f"{note['id']}.md")
            with open(filename, "wb") as writer:
                writer.write(bytes(ndata, "utf-8"))

    untitled_counter = 1
    for obj in data:
        if obj["title"] == "Untitled":
            obj["title"] = f"Untitled {untitled_counter}"
            untitled_counter += 1

    return {x["title"]: x for x in data}

def sync_note(note_id):
    response = requests.get(
        f"https://api.hackmd.io/v1/notes/{note_id}",
        headers={"Authorization": f"Bearer {API_KEY}"}
    )
    return response.json()["content"]

def push_note(path):
    content = str()
    with open(path, 'r') as reader:
        content = reader.read()
    note_id = os.path.splitext(os.path.basename(path))[0]
    response = requests.patch(
        f"https://api.hackmd.io/v1/notes/{note_id}",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        data=json.dumps({"content": content}),
    )
    return response.status_code

def create_note():
    response = requests.post(
        f"https://api.hackmd.io/v1/notes",
        headers={
            "Authorization": f"Bearer {API_KEY}",
        },
    )
    note_id = response.json()["id"]
    ndata = sync_note(note_id)
    filename = os.path.join(SCRIPT_DIR, f"{note_id}.md")
    with open(filename, "wb") as writer:
        writer.write(bytes(ndata, "utf-8"))

    notes_index = os.path.join(SCRIPT_DIR, "notes.json")
    response = requests.get(
        "https://api.hackmd.io/v1/notes",
        headers={"Authorization": f"Bearer {API_KEY}"}
    )
    if response.status_code != 200:
        print("No notes joy :(")
        raise Exception("No notes joy :(")

    data = response.json()
    with open(notes_index, "w") as writer:
        json.dump(data, writer, indent=4)

    return note_id
EOF

function! hackmd_api#SyncNotes() abort
    let g:hackmd_notes = py3eval("sync()")
    :below new
    :res -15
    :noremap <CR> :call hackmd_api#handleClick()<CR>
    :file '[HACKMD Notes]'
    let counter = 1
    for title in keys(g:hackmd_notes)
        :call setline(counter, title)
        let counter = counter + 1
    endfor
endfunction

function! hackmd_api#ForceSyncNotes() abort
    let g:hackmd_notes = py3eval("sync(force='true')")
    :below new
    :res -15
    :noremap <CR> :call hackmd_api#handleClick()<CR>
    :file '[HACKMD Notes]'
    let counter = 1
    for title in keys(g:hackmd_notes)
        :call setline(counter, title)
        let counter = counter + 1
    endfor
endfunction

function! hackmd_api#handleClick() abort
    let lineText = getline('.')
    let hid = g:hackmd_notes[lineText]["id"]
    let hmd_filename = g:hackmd_dir . '/' . hid . '.md'
    :bd!
    :noremap <CR> <CR>

    :exec(":e ".eval('hmd_filename'))
endfunction

function! hackmd_api#handleClick() abort
    let lineText = getline('.')
    let hid = g:hackmd_notes[lineText]["id"]
    let hmd_filename = g:hackmd_dir . '/' . hid . '.md'
    :bd!
    :noremap <CR> <CR>

    :exec(":e ".eval('hmd_filename'))
endfunction

function! hackmd_api#PushNote() abort
    " let content = join(getline(1,'$'), "\n")
    let path = expand('%:p')
    let response_status = py3eval("push_note('".path."')")
    if response_status == 202
        :echom "Content pushed..."
    endif
endfunction

function! hackmd_api#CreateNote() abort
    let note_id = py3eval("create_note()")
    let hmd_filename = g:hackmd_dir . '/' . note_id. '.md'
    :exec(":e ".eval('hmd_filename'))
endfunction
