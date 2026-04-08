---
name: ti-pptx
description: "Create professional PowerPoint presentations with Texas Instruments branding for knowledge sharing, technical presentations, and project updates. Use when user requests to create PowerPoint, PPT, PPTX presentations, or generate TI-branded slides."
version: 1.0
author: Sirish Boddikurapati (sirishb@ti.com)
created: 2026-02-19
organization: Texas Instruments - Processor BU PE/TE Team
dependencies: python-pptx (see Installation section below)
templates: templates/ (bundled TI PowerPoint templates in skill directory)
source: https://bitbucket.itg.ti.com/projects/TI_AI/repos/util_claude_code_tiai/browse/collaterals/skills/ti-pptx
---

# TI PowerPoint Generation Skill

**Author:** Sirish Boddikurapati (sirishb@ti.com)
**Organization:** Texas Instruments - Processor BU PE/TE Team
**Created:** February 2026
**Version:** 1.0

Create professional PowerPoint presentations with Texas Instruments branding for knowledge sharing, technical presentations, and project updates.

## Overview

This skill guides you through creating TI-branded PowerPoint presentations by gathering requirements from users and generating properly formatted slides using the `pptx_builder` Python module (bundled with this skill).

## Environment Check
This skill may be called from several different environments. First thing you must determine is  in which environment you are executing. The following steps allow you to determine which environment
### Checking the environment
Run the command
```bash
hostname -d
```
For this result
- Text containing `design` are in the design environment. If you are within this environment, the dependencies for this skill are located here
   - `python` is located at `/db/techdev/ailibs/envs/ai_env/bin/python`
- Text containing `dhcp` is a local computer environment. Use default package location

- Text containing `itg` is the enterprise domain. Use default package location

## Source-of-Truth Protocol: Creating vs. Updating

**This is the most important rule of this skill.**

### The existing PPTX file is always the source of truth

Once a presentation has been created and the user has worked with it, the `.pptx` file on disk is the authoritative version. It may contain layout adjustments, formatting changes, image placements, and other manual edits that exist nowhere in any Python script. Those edits must never be lost.

**NEVER regenerate or overwrite an existing presentation from a Python script.** Any Python build scripts used to scaffold the initial version are temporary scaffolding — discard them after the first build.

### Decision: Creating vs. Updating

Before writing any code, ask: **does this file already exist?**

- **File does not exist** → Create it fresh using `TIPresentationBuilder` (see steps below)
- **File already exists** → Open the existing file with `python-pptx` directly and make targeted changes only

### Updating an existing presentation

When asked to add, modify, or remove slides from an existing `.pptx`:

1. Open the file with `python-pptx` directly — **do not** use `TIPresentationBuilder` with that file as a template, as this may trigger append behavior
2. Make only the targeted change (add a slide, edit text in a specific slide, etc.)
3. Find slides by title text, not by index — slide order may have changed since the file was generated
4. Save back to the same path
5. Never restore from a baseline or earlier version before making changes

```python
from pptx import Presentation
from pptx.util import Pt
from pathlib import Path

pptx_path = Path("/path/to/existing.pptx")
prs = Presentation(str(pptx_path))

# Find slide by title
def find_slide_by_title(prs, title_text):
    for slide in prs.slides:
        for shape in slide.shapes:
            if shape.has_text_frame and shape.shape_type == 13:  # title placeholder
                if title_text.lower() in shape.text.lower():
                    return slide
            if hasattr(shape, "placeholder_format") and shape.placeholder_format:
                if shape.placeholder_format.idx == 0:  # title placeholder
                    if title_text.lower() in shape.text.lower():
                        return slide
    return None

slide = find_slide_by_title(prs, "CCC Signing Architectures")
# ... modify slide content ...

prs.save(str(pptx_path))
print(f"✓ Saved {prs.slides.__len__()} slides to {pptx_path}")
```

### What not to do

- **Do not** run a build script that regenerates slides from scratch when the file already exists
- **Do not** restore from a git baseline or backup before making changes
- **Do not** use `custom_template` pointing to the existing file if the intent is to modify it — this appends slides rather than editing in place
- **Do not** assume slide indices are stable — always find slides by title

---

## User Interaction Flow

When a user requests to create a PowerPoint presentation, follow these steps:

### Step 0: Import Helper and Check Dependencies

First, check dependencies and import the helper module:

```python
import sys
from pathlib import Path

# Check for python-pptx
try:
    import pptx
    print("✓ python-pptx package found")
except ImportError:
    print("❌ ERROR: python-pptx package required")
    print("\nInstallation options:")
    print("  1. Download requirements file first (recommended for virtual envs):")
    print("     curl -O https://procpe.dal.design.ti.com/deps/requirements_for_skills.txt")
    print("     pip install -r requirements_for_skills.txt")
    print("\n  2. Install package directly:")
    print("     pip install python-pptx")
    raise SystemExit()

# Add skill directory to path
skill_dir = Path.home() / ".claude/skills/ti-pptx"
sys.path.insert(0, str(skill_dir))

# Import the builder
from pptx_builder import TIPresentationBuilder

print("✓ PowerPoint builder loaded")
```

### Step 1: Ask Required Questions

**ALWAYS** ask the following questions using the `AskUserQuestion` tool to gather requirements:

#### Required Questions

**Question 1: CIP Classification & Template**
```
Which data classification and template should be used?

Options:
- NDA Restrictions (Default - TI Confidential, NDA Required)
- MAX Restrictions (Maximum restrictions, highly sensitive)
- Internal Only (TI Internal use only)
- Selective Disclosure (Limited external sharing)
- Custom Template (Provide your own .pptx template path)
```

**Question 2: Presentation Purpose**
```
What is the primary purpose of this presentation?

Options:
- Knowledge Sharing (Technical deep-dive for team)
- Project Update (Status, progress, results)
- Architecture Review (System design, technical architecture)
- Training/Tutorial (Educational content)
- Results/Metrics (Data analysis, performance results)
- Other (Specify custom purpose)
```

**Question 3: Target Audience**
```
Who is the primary audience?

Options:
- Internal Team (Direct team members)
- Cross-Functional Teams (Multiple teams within TI)
- Management/Leadership (Directors, VPs)
- External Partners (Vendors, partners under NDA)
- Mix of technical and non-technical
```

**Question 4: Images & Assets**
```
Do you have images to include in the presentation?

Options:
- Yes - I'll provide image paths
- Auto-detect from assets/ directory
- Generate diagrams from code/data
- No images needed
```

**Question 5: Customization**
```
Any specific branding or formatting requirements?

Options:
- Use standard TI branding (Recommended)
- Custom color scheme (specify colors)
- Custom fonts (specify font family)
- Additional logo/watermark
- No customization
```

## TI Templates

Templates are bundled with this skill in the `templates/` directory (relative to this SKILL.md file).

### Available Templates

| Template | File | Use Case |
|----------|------|----------|
| **NDA Restrictions** | `Presentation1_NDA_Restrictions.pptx` | Default, TI Confidential |
| **NDA Internal Only** | `Presentation2_NDA_Restrictions_InternalOnly.pptx` | NDA but internal only |
| **Selective Disclosure** | `Presentation3_SelectiveDisclosure.pptx` | Limited external sharing |
| **MAX Restrictions** | `Presentation4_MaxRestrictions.pptx` | Highly sensitive internal |
| **MAX Internal Only** | `Presentation5_MaxRestrictions_InternalOnly.pptx` | Maximum restrictions, internal |

### Template Selection Logic

```python
from pathlib import Path

def select_template(classification: str, custom_path: str = None) -> str:
    if custom_path and Path(custom_path).exists():
        return custom_path

    # Get the skill directory (where SKILL.md is located)
    skill_dir = Path(__file__).parent  # Or detect dynamically
    templates_dir = skill_dir / "templates"

    templates = {
        "nda": "Presentation1_NDA_Restrictions.pptx",
        "nda_internal": "Presentation2_NDA_Restrictions_InternalOnly.pptx",
        "selective": "Presentation3_SelectiveDisclosure.pptx",
        "max": "Presentation4_MaxRestrictions.pptx",
        "max_internal": "Presentation5_MaxRestrictions_InternalOnly.pptx"
    }

    return str(templates_dir / templates[classification])
```

**IMPORTANT:** When using templates, reference them relative to the skill directory:
```python
# If working from ~/.claude/skills/ti-pptx/
template_path = Path.home() / ".claude/skills/ti-pptx/templates/Presentation1_NDA_Restrictions.pptx"
```

## TI Branding Guidelines

### Official Color Palette (Source: TI Color and Design Guide 2024-08-05)

**Primary colors:**

| Name                   | Hex       | `TIColors` constant | Usage                                    |
|------------------------|-----------|---------------------|------------------------------------------|
| Texas Instruments Red  | `#CC0000` | `RED`               | Primary brand — large areas, headers     |
| Process Black          | `#000000` | `BLACK`             | Body text, strong contrast               |
| Texas Instruments Gray | `#AAAAAA` | `GRAY`              | Secondary text, borders                  |
| Process White          | `#FFFFFF` | `WHITE`             | Backgrounds, text on dark fills          |

**Secondary colors:**

| Name        | Hex       | `TIColors` constant | Usage                                       |
|-------------|-----------|---------------------|---------------------------------------------|
| Dark Red    | `#990000` | `DARK_RED`          | Dark accent, headers on dark backgrounds    |
| Dark Teal   | `#115566` | `DARK_TEAL`         | Section headers, dark card fills            |
| Teal        | `#007C8C` | `TEAL`              | Accent — use sparingly                      |
| Bright Cyan | `#00BBCC` | `BRIGHT_CYAN`       | Small highlights only                       |
| Light Gray  | `#E0E0E0` | `LIGHT_GRAY`        | Card backgrounds, borders                   |

**Brand usage rules:**

1. **Embrace red** — RED / DARK_RED can fill large areas and headers
2. **Red + White** together for high-contrast large-area layouts
3. **Teal sparingly** — "a little teal goes a long way"
4. **Lines and borders** are encouraged — consistent with TI design style
5. **Do NOT use `#00338D`** (dark blue) — it is not in the official TI palette

**IMPORTANT:** All colors in generated slides MUST come from `builder.colors.*` (which maps to `TIColors`). Do not use raw `RGBColor()` values. If you need a color not in `TIColors`, ask the user.

### Typography

Font sizes are available as `builder.fonts.*` constants (maps to `TIFonts`):

| Constant      | Size | Usage                               |
|---------------|------|-------------------------------------|
| `TITLE`       | 22pt | Slide titles                        |
| `SUBTITLE`    | 16pt | Subtitles                           |
| `SECTION`     | 16pt | Section headers within a slide      |
| `BODY`        | 12pt | Body text                           |
| `SMALL_BODY`  | 11pt | Sub-bullets, secondary body         |
| `SMALL`       | 10pt | Captions, card labels               |
| `LABEL`       | 9pt  | Fine print, annotations             |

**IMPORTANT:** All font sizes in generated slides MUST come from `builder.fonts.*`. Do not use raw `Pt()` values.

### Layout Best Practices

1. **Concise Content**: Avoid overcrowding slides
2. **Visual Balance**: Mix text and images
3. **Consistent Headers**: Use red family or dark teal for emphasis
4. **White Space**: Don't fill every pixel
5. **Font Sizing**: Ensure readability (no content in footer area)

### When to Use Which Slide Type

- **Bullet-heavy informational slides** (agendas, status updates, feature lists) — use `add_content_slide()`, `add_two_column_slide()` for fast, consistent results
- **Spatial / graphical layouts** (motivation stories, architecture overviews, visual narratives, comparison matrices) — use `add_freeform_slide()` with shape helpers for full layout control
- Both approaches inherit TI branding from the template slide master (footer, logo, background)

## Python Module: pptx_builder

Location: Bundled with this skill in `collaterals/skills/ti-pptx/pptx_builder.py`

### Dependency Check

**ALWAYS** check for required packages before using this skill:

```python
# Check for required external package
try:
    from pptx import Presentation
except ImportError:
    print("="*70)
    print("❌ ERROR: 'python-pptx' package is required for ti-pptx skill")
    print("="*70)
    print("\nThe python-pptx library is needed for PowerPoint generation.")
    print("\nInstallation options:")
    print("  1. Download requirements file first (recommended for virtual envs):")
    print("     curl -O https://procpe.dal.design.ti.com/deps/requirements_for_skills.txt")
    print("     pip install -r requirements_for_skills.txt")
    print("\n  2. Install package directly:")
    print("     pip install python-pptx")
    print("\n  3. For conda users:")
    print("     conda activate ai_env  (or your conda environment)")
    print("     pip install python-pptx")
    print("="*70)
    raise SystemExit("Missing required package: python-pptx")

print("✓ Dependencies validated")
```

### Basic Usage

```python
from pptx_builder import TIPresentationBuilder

# Initialize builder
builder = TIPresentationBuilder(
    template_type="nda",  # or "max", "internal", "selective"
    custom_template=None,  # Optional custom template path
    output_path="output/presentation.pptx"
)

# Set presentation metadata
builder.set_metadata(
    title="Activity Digest System",
    subtitle="Automated Weekly Team Activity Reporting",
    author="PROCPE Tools Team",
    date="February 2026"
)

# Add title slide
builder.add_title_slide(
    title="Activity Digest System",
    subtitle="AI-Powered Data Aggregation & Analysis"
)

# Add content slide
builder.add_content_slide(
    title="Problem Statement",
    bullets=[
        ("Data scattered across multiple systems", 0),  # (text, indent_level)
        ("Manual compilation: 2-3 hours per week", 0),
        ("Inconsistent reporting", 0)
    ],
    highlight_text="Need: Automated reporting",
    highlight_color="blue"
)

# Add slide with image
builder.add_two_column_slide(
    title="Agent-Based Design",
    left_bullets=[
        ("Device Access Agent", 0, "blue", True),  # (text, level, color, bold)
        ("Collects logs, tracks users", 1),
        ("Jira Tickets Agent", 0, "blue", True),
        ("Fetches via API", 1)
    ],
    right_image="assets/images/summary_agents.png"
)

# Add data flow diagram
builder.add_diagram_slide(
    title="System Architecture",
    diagram_type="ascii",  # or "mermaid", "image"
    content="""
    ┌──────────────┐
    │ Orchestrator │
    └──────┬───────┘
           │
    ┌──────▼───────┐
    │    Agents    │
    └──────────────┘
    """,
    font_size=11
)

# Save presentation
builder.save()
print(f"Presentation created: {builder.output_path}")
```

### Advanced Features

#### Custom Color Schemes

```python
from pptx_builder import TIPresentationBuilder, ColorScheme

# Define custom colors
custom_colors = ColorScheme(
    primary=RGBColor(0, 102, 204),  # Custom blue
    accent=RGBColor(255, 102, 0),   # Orange
    text_primary=RGBColor(51, 51, 51),
    text_secondary=RGBColor(128, 128, 128)
)

builder = TIPresentationBuilder(
    template_type="nda",
    color_scheme=custom_colors
)
```

#### Bulk Image Processing

```python
# Auto-detect and add images from directory
builder.add_images_from_directory(
    directory="assets/images",
    pattern="*.png",
    captions=True
)
```

#### Templates with Placeholders

```python
# Use placeholder-based approach
builder.create_from_outline(
    outline={
        "title": "My Presentation",
        "slides": [
            {
                "type": "title",
                "content": {"title": "...", "subtitle": "..."}
            },
            {
                "type": "content",
                "content": {"title": "...", "bullets": [...]}
            },
            {
                "type": "two_column",
                "content": {"title": "...", "left": [...], "right_image": "..."}
            }
        ]
    }
)
```

## Complete Workflow Example

Here's how to create a presentation from start to finish:

### Step 1: Gather Requirements

```python
# Use AskUserQuestion tool to gather:
# - classification: "nda"
# - purpose: "knowledge_sharing"
# - audience: "internal_team"
# - images: ["assets/images/diagram1.png", "assets/images/chart.png"]
# - customization: "standard"
```

### Step 2: Initialize Builder

```python
from pptx_builder import TIPresentationBuilder

builder = TIPresentationBuilder(
    template_type="nda",
    output_path="output/knowledge_share.pptx"
)

builder.set_metadata(
    title="System Architecture Deep Dive",
    author="Engineering Team",
    date="February 2026"
)
```

### Step 3: Build Slides

```python
# Title slide
builder.add_title_slide(
    title="System Architecture Deep Dive",
    subtitle="Technical Knowledge Sharing Session"
)

# Content slides
builder.add_content_slide(
    title="Overview",
    bullets=[
        ("Multi-agent architecture", 0),
        ("Scalable design", 0),
        ("Production deployment", 0)
    ]
)

# Slide with image
builder.add_two_column_slide(
    title="Agent Design",
    left_bullets=[
        ("Device Access Agent", 0, "blue", True),
        ("Tracks device logs", 1),
        ("Jira Tickets Agent", 0, "blue", True),
        ("Monitors tickets", 1)
    ],
    right_image="assets/images/agents.png"
)

# Architecture diagram
builder.add_diagram_slide(
    title="System Flow",
    diagram_type="ascii",
    content=architecture_diagram
)
```

### Step 4: Save and Report

```python
builder.save()

print(f"✓ Presentation created: {builder.output_path}")
print(f"✓ Total slides: {builder.slide_count}")
print(f"✓ Template: {builder.template_name}")
```

## Slide Types Reference

### 1. Title Slide

**Use**: Opening slide with presentation title
**Layout**: Template layout [0]

```python
builder.add_title_slide(
    title="Main Title",
    subtitle="Subtitle or context"
)
```

### 2. Content Slide

**Use**: Bullet points and text
**Layout**: Template layout [4] - "Title and Content"

```python
builder.add_content_slide(
    title="Section Title",
    bullets=[
        ("Main point", 0),
        ("Sub-point", 1),
        ("Main point 2", 0)
    ],
    highlight_text="Key takeaway",
    highlight_color="blue"
)
```

### 3. Two Column Slide

**Use**: Text on left, image on right
**Layout**: Template layout [5] - "Two Content"

```python
builder.add_two_column_slide(
    title="Feature Overview",
    left_bullets=[...],
    right_image="path/to/image.png"
)
```

### 4. Diagram Slide

**Use**: ASCII diagrams, flowcharts
**Layout**: Template layout [4]

```python
builder.add_diagram_slide(
    title="Architecture",
    diagram_type="ascii",
    content="...",
    font_size=11
)
```

### 5. Full Image Slide

**Use**: Large diagram or screenshot
**Layout**: Template layout [7] - "Title Only"

```python
builder.add_image_slide(
    title="System Dashboard",
    image_path="assets/dashboard.png",
    caption="Live production dashboard"
)
```

### 6. Freeform Slide

**Use**: Spatial/graphical layouts — motivation stories, architecture overviews, visual narratives, comparison matrices
**Layout**: Template layout [7] - "Title Only" (or any layout name)

```python
# Get a branded slide with full layout control
slide = builder.add_freeform_slide(title="Why sdv-compose?")

# Place boxes, lines, and text using brand constants
builder.add_branded_box(
    slide, left=Emu(256032), top=Emu(548640),
    width=Emu(4187952), height=Emu(1310640),
    fill_color=builder.colors.DARK_TEAL,
    text="THE PREMISE",
    font_size=builder.fonts.SECTION,
    font_color=builder.colors.WHITE,
    bold=True
)

builder.add_accent_line(
    slide, left=Emu(256032), top=Emu(475488),
    width=Emu(8631936),
    color=builder.colors.RED
)

tf = builder.add_text_box(
    slide, left=Emu(256032), top=Emu(4900000),
    width=Emu(8631936), height=Emu(200000),
    text="Tagline text here",
    font_size=builder.fonts.SMALL,
    font_color=builder.colors.DARK_TEAL,
    bold=True, alignment=PP_ALIGN.CENTER
)
```

**Brand compliance rule**: ALL colors must come from `builder.colors.*` and ALL font sizes from `builder.fonts.*`. Do not use raw `RGBColor()` or `Pt()` values.

## Best Practices

### Content Guidelines

1. **One Idea Per Slide**: Don't overload
2. **6x6 Rule**: Max 6 bullets, 6 words per bullet (guideline)
3. **Visual Hierarchy**: Use indentation and colors
4. **Highlight Key Points**: Use TI Red or Dark Teal for emphasis
5. **Consistent Style**: Same font sizes across slides
6. **ASCII Diagram Limit**: Keep diagrams to 10 lines or less to avoid footer overflow

### Image Guidelines

1. **High Resolution**: Minimum 1024px width for diagrams
2. **PNG Format**: Preferred for screenshots/diagrams
3. **SVG/Vector**: Best for logos and icons
4. **Size Appropriately**: Don't stretch or pixelate
5. **Captions**: Always add context for images

### Template Selection

| Audience | Content | Recommended Template |
|----------|---------|---------------------|
| Internal team | Technical details | NDA Restrictions |
| Management | High-level metrics | MAX Restrictions |
| Cross-functional | Project updates | NDA Internal |
| External partners | Limited disclosure | Selective Disclosure |

## Troubleshooting

### Template Not Loading

```python
# Check if template exists (relative to skill directory)
from pathlib import Path
skill_dir = Path.home() / ".claude/skills/ti-pptx"
template_path = skill_dir / "templates/Presentation1_NDA_Restrictions.pptx"
if not template_path.exists():
    print(f"Template not found: {template_path}")
```

### Images Not Appearing

```python
# Verify image paths are absolute
from pathlib import Path
image_path = Path("assets/images/diagram.png").absolute()
builder.add_image_slide(title="Diagram", image_path=str(image_path))
```

### Content Overflowing

```python
# Reduce font size for dense content
builder.add_content_slide(
    title="Details",
    bullets=[...],
    font_size=11  # Smaller than default 12-14
)
```

### ASCII Diagrams Overflowing Into Footer

**Problem**: ASCII diagrams with too many lines extend into footer area

**Solutions** (in order of preference):

1. **Simplify the diagram** (BEST):
```python
# ❌ BAD: 25+ line complex diagram
architecture_diagram = """
┌──────────────────────────────────────────────────────┐
│         User's Workspace (PROGRAM_PATH)               │
│              ✓ No files created                       │
│              ✓ Clean, non-invasive                    │
└───────────────────────┬──────────────────────────────┘
                        │
...  # Many more lines
"""

# ✓ GOOD: 10-12 line simplified diagram
architecture_diagram = """
┌─────────────────────────────────────┐
│  User's Workspace (PROGRAM_PATH)    │
│  ✓ No files created                 │
└──────────────┬──────────────────────┘
               │ source claude.sh
               ▼
┌─────────────────────────────────────┐
│  /db/petools/conda_lib/claude/      │
│  • commands/   • settings/           │
└─────────────────────────────────────┘
"""
builder.add_diagram_slide(
    title="Architecture",
    diagram_type="ascii",
    content=architecture_diagram,
    font_size=12  # Keep readable
)
```

2. **Split into multiple slides**:
```python
# Split complex diagram into overview + details
builder.add_diagram_slide(title="Overview", content=simple_diagram)
builder.add_content_slide(title="Details", bullets=[...])
```

3. **Use bullet points instead**:
```python
# For complex structures, bullets are safer than ASCII
builder.add_content_slide(
    title="Directory Structure",
    bullets=[
        ("commands/: Slash commands", 0),
        ("skills/: AI assistants", 0),
        ("templates/: Documentation", 0)
    ]
)
```

4. **Last resort - reduce font size**:
```python
# Only if diagram must be complex
builder.add_diagram_slide(
    content=complex_diagram,
    font_size=9  # Smaller, harder to read
)
```

**Guidelines for ASCII Diagrams**:
- Keep to 10 lines or less for safety
- Use 12pt font for readability
- Test: If line count × font_size > ~150, will likely overflow
- Simplify > reduce font size
- Consider bullet points for detailed structures

## Examples in Other Projects

See complete implementations:
- `/db/petools/releases/aitools/working/aitools/create_digest_presentation.py`

## Installation

The `pptx_builder` module is bundled with this skill. To verify it's accessible:

```bash
# From the skill directory
python -c "from pptx_builder import TIPresentationBuilder; print('✓ Module loaded')"
```

## Support

- **Primary Owner**: a0271775@ti.com
- **Support Team**: procpe_tool_dev@list.ti.com
- **Module Location**: Bundled with skill at `collaterals/skills/ti-pptx/pptx_builder.py`
- **Templates**: Bundled in `templates/` directory (relative to this skill)

## Summary Checklist

When creating a TI PowerPoint presentation:

- [ ] Ask user for classification, purpose, audience, images, customization
- [ ] Select appropriate template based on classification
- [ ] Initialize TIPresentationBuilder with correct template
- [ ] Set metadata (title, author, date)
- [ ] Add title slide
- [ ] Add content slides (concise, well-formatted)
- [ ] Include images and diagrams where helpful
- [ ] Use TI Blue for highlights and emphasis
- [ ] Keep ASCII diagrams to 10 lines or less (simplify if needed)
- [ ] Keep font sizes appropriate (no footer overflow)
- [ ] Save and report output path to user
- [ ] Provide slide count and template info
