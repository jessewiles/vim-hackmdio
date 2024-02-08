" Title:        HackMD.io Plugin
" Description:  A plugin synchronize files with hackmd.io.
" Last Change:  29 February 2023
" Maintainer:   Jesse Wiles <https://github.com/jessewiles>

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_hackmd_api")
    finish
endif
let g:loaded_hackmd_api = 1

" Exposes the plugin's functions for use as commands in Vim.
command! -nargs=0 SyncNotes :call hackmd_api#SyncNotes()
command! -nargs=0 ForceSyncNotes :call hackmd_api#ForceSyncNotes()
command! -nargs=0 PushNote :call hackmd_api#PushNote()
command! -nargs=0 CreateNote :call hackmd_api#CreateNote()

