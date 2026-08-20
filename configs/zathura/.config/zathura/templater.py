import json
from pathlib import Path


def hex_to_rgba(hex_str, alpha):
    """Converts a hex color string to an rgba string."""
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 6:
        r, g, b = tuple(int(hex_str[i : i + 2], 16) for i in (0, 2, 4))
        return f"rgba({r}, {g}, {b}, {alpha})"
    return f"#{hex_str}"


def resolve_filepath(path_string):
    """
    Expands the tilde (~) to the user's home directory and
    resolves to an absolute path.
    """
    # 1. Path() creates a path object
    # 2. expanduser() replaces '~' with the actual home directory (e.g., /home/user)
    # 3. resolve() makes the path absolute and resolves any symlinks
    resolved_path = Path(path_string).expanduser().resolve()

    return resolved_path


def read_json_from_file(filepath):
    """Reads and parses a JSON file."""
    try:
        # Using 'with' ensures the file is properly closed after reading
        with open(filepath, "r") as file:
            data = json.load(file)  # Use json.load() for files
            return dict(data)

    except FileNotFoundError:
        print(f"Error: The file '{filepath}' was not found.")
    except json.JSONDecodeError:
        print(f"Error: The file '{filepath}' contains invalid JSON.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")


def create_rc(color_tbl):
    hl_color = hex_to_rgba(f"{color_tbl["color4"]}", 0.2)
    hl_color_active = hex_to_rgba(f"{color_tbl["color6"]}", 0.5)
    opts = """
set synctex-editor-command "nvim --remote-silent +%{line} %{input}"
set synctex true
# ==========================================
# General Settings
# ==========================================
# Copy selected text to the system clipboard (instead of primary selection)
set selection-clipboard clipboard

# Automatically fit the document to the window width when opened
set adjust-open "width"

# Smooth scrolling settings
set scroll-page-aware true
set smooth-scroll true
set scroll-step 50

# Set the font for the status bar and index
set font "monospace 10"

# Hide the status bar by default (press 'Ctrl + m' to toggle)
# set optionsbar-hidden true 

# ==========================================
# Document Recoloring (Dark Mode)
# ==========================================
# Automatically invert pages to dark mode (Toggle on/off with Ctrl + r)
set recolor true

# Keep the original colors of images and links when recoloring
set recolor-keephue true
"""
    file_contents = f"""
# ==========================================
# PyWal Colors
# ==========================================
set default-bg "{color_tbl["background"]}"
set default-fg "{color_tbl["foreground"]}"
set statusbar-bg "{color_tbl["background"]}"
set statusbar-fg "{color_tbl["foreground"]}"
set inputbar-bg "{color_tbl["background"]}"
set inputbar-fg "{color_tbl["foreground"]}"
set notification-bg "{color_tbl["background"]}"
set notification-fg "{color_tbl["foreground"]}"
set notification-error-bg "{color_tbl["color1"]}"
set notification-error-fg "{color_tbl["foreground"]}"
set notification-warning-bg "{color_tbl["color3"]}"
set notification-warning-fg "{color_tbl["background"]}"
set highlight-color "{hl_color}"
set highlight-active-color "{hl_color_active}"
set completion-bg "{color_tbl["background"]}"
set completion-fg "{color_tbl["foreground"]}"
set completion-highlight-bg "{color_tbl["color4"]}"
set completion-highlight-fg "{color_tbl["background"]}"
set recolor-lightcolor "{color_tbl["background"]}"
set recolor-darkcolor "{color_tbl["foreground"]}"
"""
    return opts + file_contents


def write_rc(file_contents):
    path = resolve_filepath("~/.config/zathura/zathurarc")
    with open(path, "w") as rc_file:
        rc_file.write(file_contents)


# --- Example Usage ---
if __name__ == "__main__":
    path = "~/.cache/wal/colors.json"
    tbl = read_json_from_file(resolve_filepath(path))
    tbl_n = tbl["special"] | tbl["colors"]
    fc = create_rc(tbl_n)
    print(fc)
    write_rc(fc)
