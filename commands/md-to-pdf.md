# Markdown to PDF Converter - /md-to-pdf

Convert a markdown file to PDF using pandoc with Chrome headless engine for accurate SVG rendering.

## Usage

`/md-to-pdf filename.md`

## Description

This command converts a markdown file to PDF with professional formatting, automatically detecting and using appropriate CSS styling:

1. **CSS Priority System**: 
   - First checks for project-specific `scripts/pdf-style.css` in current directory
   - Falls back to default template at `~/.claude/templates/pdf-style.css` (symlinked during install)
2. **HTML Header Removal**: Automatically strips HTML content before the first # header (e.g., #+TITLE, #+HTML_HEAD)
3. **Image Protection**: Prevents images and SVGs from splitting across page boundaries
4. **SVG Fidelity**: Accurate SVG rendering that preserves original text positioning and fonts
5. **Professional Formatting**: Applies Times New Roman font, proper margins, and page numbering
6. **Accurate SVG Rendering**: Uses Chrome headless engine for pixel-perfect SVG text alignment

## CSS Template System

The default CSS template is stored in this repository at `css/pdf-style.css` and symlinked to `~/.claude/templates/pdf-style.css` during installation. This allows:

- **Centralized updates**: Improvements to the default CSS are automatically available via git pull + reinstall
- **Project overrides**: Individual projects can create `scripts/pdf-style.css` to customize styling
- **Clean separation**: Templates are kept separate from commands in the `~/.claude/` directory structure

**To modify the default PDF styling**: Edit `css/pdf-style.css` in this repository. Changes will be reflected in all future PDF generations after the symlink is updated.

## Implementation

The command executes the following logic:

```bash
md_file="$1"
if [ -z "$md_file" ]; then
    echo "Usage: /md-to-pdf filename.md"
    exit 1
fi

pdf_file="${md_file%.md}.pdf"
temp_md=$(mktemp --suffix=.md)

# CSS file priority: local project > default template
if [ -f "scripts/pdf-style.css" ]; then
    css_file="scripts/pdf-style.css"
else
    css_file="$HOME/.claude/templates/pdf-style.css"
fi

# Remove HTML content before first # header (like #+TITLE, #+HTML_HEAD, etc.)
sed '/^#[[:space:]]/,$!d' "$md_file" > "$temp_md"

# Convert markdown to HTML first (without embedding resources to preserve SVG file references)
html_file="${md_file%.md}.html"
pandoc "$temp_md" -o "$html_file" \
    --css="$css_file" \
    --standalone

# Use Chrome to generate PDF from HTML with accurate SVG rendering
google-chrome --headless \
    --disable-gpu \
    --no-sandbox \
    --print-to-pdf="$pdf_file" \
    --print-to-pdf-no-header \
    --virtual-time-budget=5000 \
    "file://$html_file"

echo "Intermediate HTML saved: $html_file"

# Clean up temporary file
rm -f "$temp_md"

echo "PDF generated: $pdf_file"
```

## Output Format

- **Paper Size**: US Letter (8.5" x 11")
- **Margins**: 1" top/bottom, 0.5" left/right
- **Font**: Times New Roman, 14pt body text with scaled headers
- **Page Numbers**: Centered in footer
- **File Extension**: Original filename with `.pdf` extension

## Dependencies

- `pandoc` - Document converter
- `google-chrome` - Chrome browser for PDF rendering engine
- CSS file - Either local `scripts/pdf-style.css` or fallback `~/.claude/templates/pdf-style.css`

## Examples

```bash
# Convert README.md to README.pdf
/md-to-pdf README.md

# Convert documentation.md to documentation.pdf  
/md-to-pdf documentation.md
```

## CSS Styling

The CSS file provides:
- Times New Roman font family
- Responsive header sizing (h1: 20pt, h2: 18pt, etc.)
- Page break avoidance for headers
- List formatting that prevents page breaks within lists
- Professional document appearance

## Error Handling

- Validates input file is provided
- Uses appropriate CSS file based on availability  
- Pandoc will warn if document lacks title metadata
- Chrome requires local file access for SVGs and images
- PDF generation proceeds even with warnings