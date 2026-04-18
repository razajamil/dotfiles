import math
import re
from kitty.fast_data_types import Screen, get_boss, get_options
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_separator,
)

opts = get_options()

surface1 = as_rgb(int("bebbbb", 16))
window_icon = ""
layout_icon = ""
inactive_tab_title_length = 20
active_tab_title_length = 40

active_tab_id = None
active_tab_layout_name = ""
active_tab_num_windows = 1


def _tab_title_length(tab, tab_id: int) -> int:
    if getattr(tab, "is_active", False):
        return active_tab_title_length
    active_tab = getattr(get_boss(), "active_tab", None)
    if active_tab is not None and getattr(active_tab, "id", None) == tab_id:
        return active_tab_title_length
    if active_tab_id == tab_id:
        return active_tab_title_length
    return inactive_tab_title_length


def _format_tab_title(title: str, limit: int) -> str:
    title = re.sub(
        r"^([^A-Za-z0-9]*\s*)?(?:fix-rwr|fix/rwr)(?:[-/ ]*)",
        lambda match: match.group(1) or "",
        title,
        count=1,
        flags=re.IGNORECASE,
    )
    if len(title) > limit:
        return title[: limit - 1] + "…"
    return title


def draw_title(data: dict) -> str:
    tab_id = data.get("tab_id", data["tab"].tab_id)
    tab = get_boss().tab_for_id(tab_id)
    title = _format_tab_title(data.get("title", ""), _tab_title_length(tab, tab_id))
    if tab:
        for window in tab:
            status = window.user_vars.get("workmux_status", "")
            if status:
                return title + " " + status if title else status
    return title


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global active_tab_id
    global active_tab_layout_name
    global active_tab_num_windows
    if tab.is_active:
        active_tab_id = tab.tab_id
        active_tab_layout_name = tab.layout_name
        active_tab_num_windows = tab.num_windows
    end = draw_tab_with_separator(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )
    _draw_right_status(
        screen,
        is_last,
    )
    return end


def _draw_right_status(screen: Screen, is_last: bool) -> int:
    if not is_last:
        return screen.cursor.x

    cells = [
        # layout name
        (surface1, screen.cursor.bg, " " + layout_icon + " "),
        (surface1, screen.cursor.bg, active_tab_layout_name + " "),
        # num windows
        (surface1, screen.cursor.bg, " " + window_icon + " "),
        (surface1, screen.cursor.bg, str(active_tab_num_windows) + " "),
    ]

    # calculate leading spaces to separate tabs from right status
    right_status_length = 0
    for _, _, cell in cells:
        right_status_length += len(cell)
    leading_spaces = 0
    if opts.tab_bar_align == "center":
        leading_spaces = (
            math.ceil((screen.columns - screen.cursor.x) / 2) - right_status_length
        )
    elif opts.tab_bar_align == "left":
        leading_spaces = screen.columns - screen.cursor.x - right_status_length

    # draw leading spaces
    if leading_spaces > 0:
        screen.draw(" " * leading_spaces)

    # draw right status
    for fg, bg, cell in cells:
        screen.cursor.fg = fg
        screen.cursor.bg = bg
        screen.draw(cell)
    screen.cursor.fg = 0
    screen.cursor.bg = 0

    # update cursor position
    screen.cursor.x = max(screen.cursor.x, screen.columns - right_status_length)
    return screen.cursor.x
