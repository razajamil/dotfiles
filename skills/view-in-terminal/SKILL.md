---
name: view-in-terminal
description: Shows PDFs, images, SVGs, Word documents, spreadsheets, Markdown/HTML pages, directories of files, archives and videos to the user inside their terminal, in a viewer pane next to the agent, through clv (clview) and the kitty graphics protocol. Use when the user asks to see, show, view, preview, open or look at a file or asset ("show me the screenshot", "open the PDF", "let me see the chart", "preview the docx"), and proactively after you create or change a visual asset the user will want to check (a screenshot, a rendered chart or diagram, a generated PDF/DOCX/XLSX, an exported image, a video recording).
---

# View assets in the terminal

The Bash tool captures command output. Graphics that a command writes to stdout do not
get to the user's screen. Thus, do not run `clv file` in Bash and expect the user to see it.
Use the `show` script. It opens a new pane in the user's real terminal and runs the
viewer there.

```sh
~/.claude/skills/view-in-terminal/scripts/show <file|dir>... [clv options]
```

## When to use it

- **The user asks.** "Show me", "let me see", "open", "preview", "display" a file or an
  asset. Use the script immediately.
- **Proactively, when it helps.** After you make or change a visual result that the user
  must check: a screenshot, a chart, a diagram, an exported image, a generated PDF, DOCX,
  XLSX or slide export, or a video recording. Show it one time when the work is done.
  Do not show it after each small iteration.
- **Do not use it** for source code, logs or plain text. Do not use it for files that you
  only read to do your work. Do not open more than one viewer for one request. Give
  all the files to one `show` command (they show as a list of tiles).

To understand an image or a PDF yourself, use the Read tool. The viewer is only for the user.

## What it shows

- **Through clv directly:** PDF; PNG, JPEG, GIF, WebP, TIFF, BMP, ICO, JPEG XL, EXR, HDR,
  TGA, QOI; SVG; Word (docx, doc), odt, rtf; Markdown and HTML; xlsx, xls, ods, csv, tsv;
  zip and tar archives; directories.
- **Converted first by the script:** HEIC, HEIF and AVIF (sips or ffmpeg to PNG).
- **Video:** the script plays the video with `mpv --vo=kitty --keep-open=yes` (mpv is installed with Homebrew).
  If mpv is not installed, it makes a contact sheet of 12 frames with ffmpeg and shows that.
  Tell the user that it is a contact sheet and not playback.
- **Not supported:** pptx/key slides. Export them to PDF first (for example
  `soffice --headless --convert-to pdf deck.pptx`), then show the PDF.

## Where it opens

The script finds the first of these that is available:

1. **herdr** (`HERDR_ENV` is set): a split pane on the right side of the agent pane. The
   focus moves to the split pane.
2. **tmux** (`TMUX` is set): a horizontal split.
3. **WezTerm** (`WEZTERM_PANE` is set): a split pane on the right side.
4. **kitty** remote control (a live `/tmp/kitty-*` socket): an overlay window.

If no target is available, the script prints the command and exits with code 2. Give that
command to the user to run in a separate terminal tab. Do not tell the user to use the `!`
prefix: `!` also captures the output, and the graphics do not show.

## Useful options (passed to clv)

| Option | Use |
|---|---|
| `--pages 1,3-5` | Only these pages (or tiles of a list) |
| `--zoom 4` / `--zoom width` | 4 pages in a row (an overview) / fit the page to the window width |
| `--theme light\|dark` | The theme for Markdown and HTML |
| `-r` | For a directory, show the files of the subdirectories as tiles |
| `--password PW` | For an encrypted PDF, docx or xlsx |

The script always adds `--pager`. Thus a single image stays on screen until the user
presses `q`, and then the pane closes. Other keys in the viewer: `space`/`b` move one page,
`+`/`-` zoom, `c` copies the page to the clipboard, `?` shows help.

## Examples

```sh
S=~/.claude/skills/view-in-terminal/scripts/show
$S screenshot.png
$S report.pdf --pages 1-3
$S --zoom 4 slides.pdf                 # an overview of the pages
$S out/*.png                           # one viewer, tiles for each image
$S demo.mov                            # mpv playback, or a contact sheet
$S --dry-run photo.heic                # show the target and the command, but do not open
```

After you run the script, tell the user in one line where the viewer opened and that `q`
closes it.

## Troubleshooting

- `clv: command not found`: install it with `mise use -g github:dobladez/clview@latest`.
- The pane opens but shows text blocks and no picture: the terminal is not kitty, Ghostty
  or WezTerm, or the multiplexer blocks the graphics. In herdr, make sure that
  `kitty_graphics` is not `false` in `~/.config/herdr/config.toml`.
- The kitty overlay does not open: `allow_remote_control` and `listen_on` must be set in
  `kitty.conf`.
- In herdr, the mpv controls hide when the pointer moves to them, or the video is
  blurry: herdr reports a pane size of 0×0 pixels. Then mpv puts each mouse event at
  (0, 0) and renders at 320×240. To prevent this, `show` reads the cell size from the tty
  of the herdr client and runs mpv through `scripts/pxrun`. This wrapper writes the
  correct pixel size to the pane's terminal. If the problem occurs, run `show --dry-run`
  and make sure that the command starts with `pxrun`.
- The mpv controls hide when the pointer moves to them, in any terminal: mpv's vo_kitty
  centers the video, but it lays out the controls and maps the mouse from the top-left
  corner. Thus `show` gives `--video-align-x=-1 --video-align-y=-1` to mpv. Do not remove
  these options.
