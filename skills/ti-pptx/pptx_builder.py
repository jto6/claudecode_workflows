"""
TI Presentation Builder
Core module for creating TI-branded PowerPoint presentations
"""

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN
from pptx.dml.color import RGBColor
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass
import os

# TI Brand Colors
TI_RED = RGBColor(204, 0, 0)
TI_BLUE = RGBColor(0, 51, 141)
TI_DARK_GRAY = RGBColor(51, 51, 51)
TI_LIGHT_GRAY = RGBColor(128, 128, 128)

# Template locations - use bundled templates
SKILL_DIR = Path(__file__).parent
TEMPLATE_DIR = SKILL_DIR / "templates"

# Validate that templates directory exists and contains templates
if not TEMPLATE_DIR.exists():
    raise FileNotFoundError(
        f"Templates directory not found at {TEMPLATE_DIR}. "
        "The templates directory must be bundled with this skill."
    )

if not list(TEMPLATE_DIR.glob("*.pptx")):
    raise FileNotFoundError(
        f"No PowerPoint templates found in {TEMPLATE_DIR}. "
        "Please ensure template files (*.pptx) are present in the templates directory."
    )

# Template mappings
TEMPLATES = {
    "nda": "Presentation1_NDA_Restrictions.pptx",
    "internal": "Presentation2_NDA_Restrictions_InternalOnly.pptx",
    "selective": "Presentation3_SelectiveDisclosure.pptx",
    "max": "Presentation4_MaxRestrictions.pptx",
    "max_internal": "Presentation5_MaxRestrictions_InternalOnly.pptx"
}


@dataclass
class ColorScheme:
    """Custom color scheme for presentations."""
    primary: RGBColor = TI_RED
    accent: RGBColor = TI_BLUE
    text_primary: RGBColor = TI_DARK_GRAY
    text_secondary: RGBColor = TI_LIGHT_GRAY


class TIPresentationBuilder:
    """
    Builder class for creating TI-branded PowerPoint presentations.

    Example:
        builder = TIPresentationBuilder(template_type="nda")
        builder.add_title_slide("My Presentation", "Subtitle")
        builder.add_content_slide("Overview", [("Point 1", 0), ("Point 2", 0)])
        builder.save()
    """

    def __init__(
        self,
        template_type: str = "nda",
        custom_template: Optional[str] = None,
        output_path: str = "output/presentation.pptx",
        color_scheme: Optional[ColorScheme] = None
    ):
        """
        Initialize the presentation builder.

        Args:
            template_type: One of "nda", "max", "internal", "selective"
            custom_template: Optional path to custom .pptx template
            output_path: Where to save the final presentation
            color_scheme: Optional custom color scheme
        """
        self.template_type = template_type
        self.custom_template = custom_template
        self.output_path = output_path
        self.color_scheme = color_scheme or ColorScheme()

        # Load template
        self.prs = self._load_template()
        self.template_name = self._get_template_name()

        # Metadata
        self.metadata = {}

    def _load_template(self) -> Presentation:
        """Load the PowerPoint template."""
        # Use custom template if provided
        if self.custom_template and Path(self.custom_template).exists():
            return Presentation(self.custom_template)

        # Use standard TI template
        template_file = TEMPLATES.get(self.template_type, TEMPLATES["nda"])
        template_path = Path(TEMPLATE_DIR) / template_file

        if template_path.exists():
            return Presentation(str(template_path))
        else:
            # Fall back to blank presentation
            print(f"Warning: Template not found at {template_path}, using blank")
            return Presentation()

    def _get_template_name(self) -> str:
        """Get the name of the loaded template."""
        if self.custom_template:
            return Path(self.custom_template).name
        return TEMPLATES.get(self.template_type, "blank")

    @property
    def slide_count(self) -> int:
        """Return the number of slides in the presentation."""
        return len(self.prs.slides)

    def set_metadata(
        self,
        title: str,
        subtitle: Optional[str] = None,
        author: Optional[str] = None,
        date: Optional[str] = None
    ):
        """
        Set presentation metadata.

        Args:
            title: Presentation title
            subtitle: Optional subtitle
            author: Author name
            date: Date string
        """
        self.metadata = {
            'title': title,
            'subtitle': subtitle,
            'author': author,
            'date': date
        }

        # Set core properties
        self.prs.core_properties.title = title
        if author:
            self.prs.core_properties.author = author

    def add_title_slide(self, title: str, subtitle: str = ""):
        """
        Add a title slide.

        Args:
            title: Main title
            subtitle: Subtitle text
        """
        slide = self.prs.slides.add_slide(self.prs.slide_layouts[0])

        title_shape = slide.shapes.title
        subtitle_shape = slide.placeholders[1]

        title_shape.text = title
        subtitle_shape.text = subtitle

    def add_content_slide(
        self,
        title: str,
        bullets: List[Tuple[str, int]] = None,
        highlight_text: Optional[str] = None,
        highlight_color: str = "blue",
        font_size: int = 14
    ):
        """
        Add a content slide with bullet points.

        Args:
            title: Slide title
            bullets: List of (text, indent_level) tuples
            highlight_text: Optional text to highlight at bottom
            highlight_color: Color for highlight ("blue" or "red")
            font_size: Base font size for bullets
        """
        slide = self.prs.slides.add_slide(self.prs.slide_layouts[4])  # Title and Content

        title_shape = slide.shapes.title
        title_shape.text = title

        body = slide.placeholders[1]
        tf = body.text_frame
        tf.clear()  # Clear default text

        # Add bullets
        if bullets:
            for i, (text, level) in enumerate(bullets):
                if i == 0:
                    p = tf.paragraphs[0]
                else:
                    p = tf.add_paragraph()
                p.text = text
                p.level = level
                p.font.size = Pt(font_size if level == 0 else font_size - 2)

        # Add highlight text
        if highlight_text:
            tf.add_paragraph()
            p = tf.add_paragraph()
            p.text = highlight_text
            p.font.bold = True
            p.font.size = Pt(font_size + 2)

            color = self.color_scheme.accent if highlight_color == "blue" else self.color_scheme.primary
            p.font.color.rgb = color

    def add_two_column_slide(
        self,
        title: str,
        left_bullets: List[Tuple] = None,
        right_image: Optional[str] = None,
        right_text: Optional[str] = None
    ):
        """
        Add a two-column slide (text left, image/text right).

        Args:
            title: Slide title
            left_bullets: List of tuples: (text, level) or (text, level, color, bold)
            right_image: Path to image for right column
            right_text: Alternative text for right column
        """
        slide = self.prs.slides.add_slide(self.prs.slide_layouts[5])  # Two Content

        title_shape = slide.shapes.title
        title_shape.text = title

        # Left column: bullets
        left = slide.placeholders[1]
        tf = left.text_frame
        tf.clear()

        if left_bullets:
            for i, item in enumerate(left_bullets):
                # Unpack with defaults
                if len(item) == 2:
                    text, level = item
                    color, bold = None, False
                elif len(item) == 4:
                    text, level, color, bold = item
                else:
                    text, level = item[0], item[1]
                    color, bold = None, False

                if i == 0:
                    p = tf.paragraphs[0]
                else:
                    p = tf.add_paragraph()

                p.text = text
                p.level = level
                p.font.size = Pt(13 if level == 0 else 11)

                if color == "blue":
                    p.font.color.rgb = self.color_scheme.accent
                elif color == "red":
                    p.font.color.rgb = self.color_scheme.primary

                if bold:
                    p.font.bold = True

        # Right column: image or text
        right = slide.placeholders[2]

        if right_image and Path(right_image).exists():
            # Clear placeholder and add image
            sp = right._element
            sp.getparent().remove(sp)

            # Add image to slide
            left_pos = right.left
            top_pos = right.top
            height = right.height
            slide.shapes.add_picture(right_image, left_pos, top_pos, height=height)

        elif right_text:
            right.text = right_text

    def add_diagram_slide(
        self,
        title: str,
        diagram_type: str,
        content: str,
        font_size: int = 11
    ):
        """
        Add a slide with an ASCII diagram or flowchart.

        Args:
            title: Slide title
            diagram_type: "ascii" or "mermaid"
            content: The diagram content
            font_size: Font size for the diagram
        """
        slide = self.prs.slides.add_slide(self.prs.slide_layouts[4])  # Title and Content

        title_shape = slide.shapes.title
        title_shape.text = title

        body = slide.placeholders[1]
        tf = body.text_frame
        tf.text = content

        # Format as monospace
        for paragraph in tf.paragraphs:
            paragraph.font.name = "Courier New"
            paragraph.font.size = Pt(font_size)

    def add_image_slide(
        self,
        title: str,
        image_path: str,
        caption: Optional[str] = None
    ):
        """
        Add a slide with a large image.

        Args:
            title: Slide title
            image_path: Path to image file
            caption: Optional caption below image
        """
        slide = self.prs.slides.add_slide(self.prs.slide_layouts[7])  # Title Only

        title_shape = slide.shapes.title
        title_shape.text = title

        if Path(image_path).exists():
            # Add image centered
            left = Inches(1)
            top = Inches(2)
            width = Inches(8)

            slide.shapes.add_picture(image_path, left, top, width=width)

            # Add caption if provided
            if caption:
                textbox = slide.shapes.add_textbox(
                    Inches(1), Inches(6.5), Inches(8), Inches(0.5)
                )
                tf = textbox.text_frame
                p = tf.paragraphs[0]
                p.text = caption
                p.font.size = Pt(10)
                p.font.color.rgb = TI_LIGHT_GRAY
                p.font.italic = True
                p.alignment = PP_ALIGN.CENTER

    def add_images_from_directory(
        self,
        directory: str,
        pattern: str = "*.png",
        captions: bool = True
    ):
        """
        Add multiple images from a directory, one per slide.

        Args:
            directory: Directory containing images
            pattern: File pattern to match (e.g., "*.png")
            captions: Whether to use filename as caption
        """
        dir_path = Path(directory)
        if not dir_path.exists():
            print(f"Warning: Directory not found: {directory}")
            return

        images = sorted(dir_path.glob(pattern))

        for img_path in images:
            caption = img_path.stem.replace('_', ' ').title() if captions else None
            self.add_image_slide(
                title=caption or "Image",
                image_path=str(img_path),
                caption=caption
            )

    def create_from_outline(self, outline: Dict[str, Any]):
        """
        Create presentation from a structured outline dictionary.

        Args:
            outline: Dictionary with title, subtitle, and slides list

        Example:
            outline = {
                "title": "My Presentation",
                "subtitle": "Subtitle",
                "author": "Team",
                "slides": [
                    {"type": "title", "content": {"title": "...", "subtitle": "..."}},
                    {"type": "content", "content": {"title": "...", "bullets": [...]}}
                ]
            }
        """
        # Set metadata
        if 'title' in outline:
            self.set_metadata(
                title=outline.get('title'),
                subtitle=outline.get('subtitle'),
                author=outline.get('author'),
                date=outline.get('date')
            )

        # Add slides
        for slide_def in outline.get('slides', []):
            slide_type = slide_def.get('type')
            content = slide_def.get('content', {})

            if slide_type == 'title':
                self.add_title_slide(
                    title=content.get('title', ''),
                    subtitle=content.get('subtitle', '')
                )

            elif slide_type == 'content':
                self.add_content_slide(
                    title=content.get('title', ''),
                    bullets=content.get('bullets', []),
                    highlight_text=content.get('highlight_text'),
                    highlight_color=content.get('highlight_color', 'blue')
                )

            elif slide_type == 'two_column':
                self.add_two_column_slide(
                    title=content.get('title', ''),
                    left_bullets=content.get('left', []),
                    right_image=content.get('right_image')
                )

            elif slide_type == 'diagram':
                self.add_diagram_slide(
                    title=content.get('title', ''),
                    diagram_type=content.get('diagram_type', 'ascii'),
                    content=content.get('content', '')
                )

            elif slide_type == 'image':
                self.add_image_slide(
                    title=content.get('title', ''),
                    image_path=content.get('image_path', ''),
                    caption=content.get('caption')
                )

    def save(self) -> str:
        """
        Save the presentation to file.

        Returns:
            Path to saved file
        """
        # Ensure output directory exists
        output_path = Path(self.output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Save presentation
        self.prs.save(str(output_path))

        return str(output_path)


# Utility function
def create_ti_presentation(
    title: str,
    slides: List[Dict[str, Any]],
    template_type: str = "nda",
    output_path: str = "output/presentation.pptx"
) -> str:
    """
    Quick helper to create a TI presentation.

    Args:
        title: Presentation title
        slides: List of slide definitions
        template_type: Template to use
        output_path: Output file path

    Returns:
        Path to created presentation
    """
    builder = TIPresentationBuilder(
        template_type=template_type,
        output_path=output_path
    )

    outline = {
        'title': title,
        'slides': slides
    }

    builder.create_from_outline(outline)
    return builder.save()
