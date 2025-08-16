# Markdown to PDF Converter - /md-to-pdf

Convert a markdown file to PDF using pandoc with wkhtmltopdf engine and consistent styling.

## Usage

`/md-to-pdf filename.md`

## Description

This command converts a markdown file to PDF with professional formatting, automatically detecting and using appropriate CSS styling:

1. **CSS Detection**: Looks for `scripts/pdf-style.css` in the current repository
2. **Fallback CSS**: If not found, uses `../BSFL/scripts/pdf-style.css` 
3. **Professional Formatting**: Applies Times New Roman font, proper margins, and page numbering
4. **Consistent Output**: Uses wkhtmltopdf engine for reliable PDF generation

## Implementation

The command executes the following logic:

```bash
md_file="$1"
if [ -z "$md_file" ]; then
    echo "Usage: /md-to-pdf filename.md"
    exit 1
fi

pdf_file="${md_file%.md}.pdf"

# Check for local CSS file, fallback to BSFL version
if [ -f "scripts/pdf-style.css" ]; then
    css_file="scripts/pdf-style.css"
else
    css_file="../BSFL/scripts/pdf-style.css"
fi

pandoc "$md_file" -o "$pdf_file" \
    --pdf-engine=wkhtmltopdf \
    --css="$css_file" \
    --pdf-engine-opt=--margin-left --pdf-engine-opt=0.5in \
    --pdf-engine-opt=--margin-right --pdf-engine-opt=0.5in \
    --pdf-engine-opt=--margin-top --pdf-engine-opt=1in \
    --pdf-engine-opt=--margin-bottom --pdf-engine-opt=1in \
    --pdf-engine-opt=--page-size --pdf-engine-opt=Letter \
    --pdf-engine-opt=--footer-center --pdf-engine-opt="[page]"
```

## Output Format

- **Paper Size**: US Letter (8.5" x 11")
- **Margins**: 1" top/bottom, 0.5" left/right
- **Font**: Times New Roman, 14pt body text with scaled headers
- **Page Numbers**: Centered in footer
- **File Extension**: Original filename with `.pdf` extension

## Dependencies

- `pandoc` - Document converter
- `wkhtmltopdf` - PDF rendering engine
- CSS file - Either local `scripts/pdf-style.css` or fallback `../BSFL/scripts/pdf-style.css`

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
- PDF generation proceeds even with warnings