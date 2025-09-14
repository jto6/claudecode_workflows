# Knowledge Base Import - /kb-import

Import files or URLs to create rich markdown knowledge base files optimized for analysis and Q&A capabilities.

## Usage
```
/kb-import <source> [output_directory]
```

- `source`: File path or URL to import
- `output_directory`: Optional directory to save the markdown file (defaults to current directory)

## Description

This command captures content from various sources and converts them to structured markdown knowledge base files that are optimized for Claude's analysis and Q&A capabilities. The resulting files include metadata, structure analysis, and searchable content organization.

**Supported Sources:**
- **Files**: PDF, DOCX, TXT, MD, HTML, and other text-based formats
- **URLs**: Web pages with automatic subpage discovery for comprehensive documentation import
- **Binary files**: Uses rgpipe utility as fallback for unsupported formats

**Output Features:**
- Rich markdown formatting optimized for analysis
- Metadata tracking and source information
- Structured content with analysis sections
- Cross-reference capabilities via .kbmap files

## Implementation Workflow

### Phase 1: Source Analysis and Validation

#### 1.1 Validate Input Parameters
- Check if source parameter is provided
- Determine if source is a file path or URL
- Validate output directory (create if needed)
- Set default output directory to current directory if not specified

#### 1.2 Source Type Detection
**For Files:**
- Verify file exists and is readable
- Detect file type by extension and content analysis
- Estimate processing method based on file characteristics

**For URLs:**
- Validate URL format and accessibility
- Check for robots.txt compliance
- Identify if URL represents documentation site or single page

### Phase 2: Content Extraction

#### 2.1 File Processing Strategy
Execute in this priority order:

**PDF Files:**
1. **Primary**: Use Claude Code's Read tool (supports PDF natively)
2. **Fallback**: Try `pdftotext` via Bash tool if available
3. **Last resort**: Use rgpipe utility via Bash tool

**DOCX/DOC Files:**
1. **Primary**: Use Claude Code's Read tool if supported
2. **Fallback**: Try `pandoc` conversion via Bash tool
3. **Last resort**: Use rgpipe utility via Bash tool

**Text-based Files (TXT, MD, HTML):**
1. **Primary**: Use Claude Code's Read tool directly
2. **Processing**: Apply format-specific parsing for better structure

**Other Binary Files:**
1. **Primary**: Use rgpipe utility via Bash tool
2. **Validation**: Ensure extracted content is meaningful

#### 2.2 URL Processing Strategy
**Single Page Processing:**
1. Use WebFetch tool to retrieve content with comprehensive prompt
2. Extract main content, navigation structure, and metadata
3. Identify linked subpages and related documentation

**Multi-page Documentation Processing:**
1. Start with main URL using WebFetch
2. Parse response for navigation links and subpage references
3. **Interactive Decision**: Present discovered subpages to user:
   - Option 1: Import main page only
   - Option 2: Import main page + selected subpages
   - Option 3: Import entire documentation site (with reasonable limits)
4. Process additional pages based on user selection
5. Combine related content into structured knowledge base

### Phase 3: Markdown Generation

#### 3.1 Create Rich Markdown Structure
Generate comprehensive markdown file with these sections:

**Header Section:**
```markdown
# Knowledge Base: [Source Title]

## Source Information
- **Source**: [Original source path/URL]
- **Import Date**: [ISO timestamp]
- **Content Type**: [File/URL/Multi-page]
- **File Size/Content Length**: [Size metrics]
- **Processing Method**: [Tool used for extraction]
- **Source Hash**: [SHA256 for files, URL fingerprint for web content]
```

**Content Analysis Section:**
```markdown
## Content Analysis

### Executive Summary
[AI-generated summary of main topics and purpose]

### Document Structure
[Outline of major sections, chapters, or topics]

### Key Topics and Keywords
[Extracted important terms and concepts for searchability]

### Content Classification
[Type: Tutorial, Reference, Documentation, Research Paper, etc.]
```

**Main Content Section:**
```markdown
## Document Content

[Properly formatted content with:]
- Preserved heading hierarchy
- Clean paragraph separation
- Code blocks where appropriate
- Lists and tables properly formatted
- Image references noted (but not embedded)
```

**Analysis and Reference Section:**
```markdown
## Analysis Notes

### Searchable Keywords
[Comprehensive keyword list for easy reference]

### Related Materials
[Cross-references to other knowledge base files]

### Questions This Content Can Answer
[AI-generated list of questions this material addresses]

### Potential Follow-up Research
[Suggested related topics or materials to investigate]

### URL References (for web content)
[List of all links found in the content]
```

#### 3.2 File Naming Convention
- Sanitize source name for filesystem compatibility
- Pattern: `{sanitized_source_name}_kb.md`
- Ensure uniqueness in target directory
- Examples:
  - `research_paper.pdf` → `research_paper_kb.md`
  - `https://docs.python.org/3/` → `docs_python_org_3_kb.md`

### Phase 4: Knowledge Base Mapping

#### 4.1 Update .kbmap File
Create or update `.kbmap` file in output directory with YAML format:

```yaml
# Knowledge Base Mapping File
# Tracks relationships between source materials and knowledge base files
version: "1.0"
created: "2025-09-13T10:30:00-04:00"
last_updated: "2025-09-13T10:30:00-04:00"

mappings:
  - id: "kb_001"
    source: "/path/to/document.pdf"
    source_type: "file"
    output_file: "document_kb.md"
    import_date: "2025-09-13T10:30:00-04:00"
    file_hash: "sha256_hash_here"
    content_summary: "Technical documentation about..."
    keywords: ["keyword1", "keyword2", "keyword3"]
    status: "active"
    subpages: []

  - id: "kb_002"
    source: "https://docs.example.com/guide"
    source_type: "url"
    output_file: "docs_example_com_guide_kb.md"
    import_date: "2025-09-13T10:35:00-04:00"
    file_hash: ""
    content_summary: "User guide for..."
    keywords: ["guide", "tutorial", "examples"]
    status: "active"
    subpages: ["https://docs.example.com/guide/chapter1", "https://docs.example.com/guide/chapter2"]
```

#### 4.2 Cross-Reference Integration
- Scan existing .kbmap entries for related content
- Add cross-references to the new markdown file
- Update related files with bidirectional references where appropriate

### Phase 5: Quality Validation and User Feedback

#### 5.1 Content Validation
- Verify markdown file was created successfully
- Check file size and content completeness
- Validate that key sections contain meaningful content
- Ensure proper markdown formatting

#### 5.2 Present Results to User
Show completion summary:
```
✅ Successfully imported knowledge base file

📁 Output File: /path/to/output_kb.md
📊 Content Length: 15,247 characters
🏷️  Key Topics: [extracted topics]
🔗 Cross-references: [number] related files found
📋 Questions answered: [number] potential Q&A topics identified

💡 The knowledge base file is ready for analysis and Q&A queries.
```

#### 5.3 Suggest Next Steps
- Recommend questions to ask about the imported content
- Suggest related materials that might be worth importing
- Offer to perform initial content analysis

## Error Handling and Fallbacks

### File Processing Errors
- **File not found**: Clear error message with path verification
- **Permission denied**: Guide user to fix permissions
- **Unsupported format**: Attempt rgpipe fallback
- **rgpipe failure**: Report extraction failure with suggestions

### URL Processing Errors
- **Network errors**: Retry with exponential backoff
- **Access denied**: Report status and suggest alternatives
- **Malformed content**: Use best-effort parsing

### Content Quality Issues
- **Empty extraction**: Report issue and suggest manual review
- **Very large content**: Warn about size and offer truncation options
- **Non-text content**: Report content type and processing limitations

## Examples

### Import a PDF Research Paper
```
/kb-import research_paper.pdf
```
*Creates: `research_paper_kb.md` with full document analysis*

### Import Documentation Website
```
/kb-import https://docs.python.org/3/ docs/
```
*Interactive prompt for subpage selection, creates comprehensive knowledge base*

### Import Word Document to Specific Directory
```
/kb-import user_manual.docx knowledge_base/
```
*Creates: `knowledge_base/user_manual_kb.md` with structured content*

### Import with Fallback Processing
```
/kb-import legacy_document.xyz
```
*Uses rgpipe utility for unsupported format, creates best-effort knowledge base*

## Dependencies

### Claude Code Tools (Built-in)
- **Read**: For direct file content extraction
- **WebFetch**: For URL content retrieval
- **Write**: For creating markdown files
- **Bash**: For utility commands and rgpipe

### External Tools (Optional for Enhanced Processing)
- **pdftotext**: Better PDF text extraction (`apt install poppler-utils`)
- **pandoc**: Document format conversion (`apt install pandoc`)
- **rgpipe**: Binary file content extraction (assumed available on workstation)

### Automatic Fallbacks
- If specialized tools unavailable, uses Claude Code's built-in capabilities
- rgpipe serves as universal fallback for unsupported binary formats
- WebFetch handles all URL processing with comprehensive content analysis

## Advanced Features

### Multi-page Documentation Import
- Automatically discovers linked documentation pages
- Presents user with import options (single page vs. full documentation)
- Creates unified knowledge base with cross-references
- Maintains source page relationships in .kbmap

### Content Enhancement
- AI-powered content summarization
- Automatic keyword extraction
- Question generation for Q&A preparation
- Cross-reference discovery with existing knowledge base

### Update and Maintenance
- Source change detection via file hashes
- Knowledge base refresh capabilities
- Orphaned file cleanup in .kbmap
- Content freshness tracking for URLs

Execute this workflow to create comprehensive, analyzable knowledge base files from any source material.