@echo off
rem Regenerates the Markdown version of the spec from the Word source.
rem  -t gfm            GitHub-flavored Markdown (no backslash-escaped quotes/brackets)
rem  --wrap=none       one paragraph per line, so diffs show real changes only
rem  --extract-media=. writes embedded images to .\media\ so links resolve on GitHub
pandoc Reactive-Composite-Memory.docx -f docx -t gfm --wrap=none --extract-media=. -o Reactive-Composite-Memory.md
