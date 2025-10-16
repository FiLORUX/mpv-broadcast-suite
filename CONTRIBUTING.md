# Contributing to mpv broadcast suite

Thank you for considering contributing to this project! This guide outlines the process for contributing code, documentation, and feedback.

## Code of Conduct

Be respectful, constructive, and professional. This project serves the broadcast engineering community, and we expect all contributors to uphold industry standards of professionalism.

## How to Contribute

### Reporting Bugs

Before creating a bug report:
1. Check existing [GitHub Issues](https://github.com/FiLORUX/mpv-broadcast-suite/issues)
2. Verify you're running the latest version
3. Test with a clean mpv configuration to rule out conflicts

When reporting bugs, include:
- **mpv version:** Output of `mpv --version`
- **Operating System:** Including version (e.g., Ubuntu 22.04, macOS 13.5, Windows 11)
- **File Information:** Container format, video codec, audio configuration
- **Steps to Reproduce:** Clear, numbered steps
- **Expected Behaviour:** What should happen
- **Actual Behaviour:** What actually happens
- **Screenshots/Logs:** If applicable

### Suggesting Features

Feature requests should:
- Describe the use case clearly
- Explain how it benefits broadcast workflows
- Consider compatibility with existing features
- Reference any relevant broadcast standards (e.g., SMPTE, EBU)

### Pull Requests

1. **Fork the repository** and create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Follow coding standards:**
   - Lua code: 4-space indentation, descriptive variable names
   - Comments: International English spelling, clear technical descriptions
   - Documentation: Update README.md and inline comments

3. **Test thoroughly:**
   - Test on Linux, macOS, and Windows if possible
   - Test with various file formats (MP4, MOV, MXF, TS)
   - Test with different framerates and audio channel counts
   - Verify no regressions in existing functionality

4. **Commit with clear messages:**
   ```bash
   git commit -m "Add support for 32-channel audio routing"
   ```

5. **Submit pull request:**
   - Describe changes in detail
   - Reference any related issues
   - Include test results

## Development Setup

### Prerequisites
- mpv 0.35.0 or later
- Text editor with Lua support
- Test media files with various configurations

### Testing Locally

```bash
# Clone your fork
git clone https://github.com/FiLORUX/mpv-broadcast-suite.git
cd mpv-broadcast-suite

# Create test configuration directory
mkdir -p test_config/scripts

# Symlink files for testing
ln -s $(pwd)/mpv.conf test_config/
ln -s $(pwd)/input.conf test_config/
ln -s $(pwd)/scripts/*.lua test_config/scripts/

# Run mpv with test configuration
mpv --config-dir=./test_config your_test_file.mp4
```

### Code Style Guidelines

**Lua Scripts:**
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 100 characters
- Function names: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Local variables: descriptive names (e.g., `channel_count`, not `cc`)

**Comments:**
- Use British English spelling (colour, behaviour, normalise)
- Technical terms: Use industry-standard terminology
- Complex algorithms: Include mathematical notation where helpful

**Example:**
```lua
-- Calculate drop-frame compensation for NTSC framerates
-- Formula: frames + (drops_per_minute × complete_minutes) - (drops_per_10min × complete_10min_blocks)
local function calc_dropframe(frames, fps_rounded, is_df)
    if not is_df then return frames end
    
    local drop_per_min = (fps_rounded == 60) and 4 or 2
    -- [rest of implementation]
end
```

## Documentation

### Inline Comments
- Explain **why**, not just **what**
- Document edge cases and limitations
- Reference standards where applicable (e.g., "per SMPTE 12M-1")

### README Updates
- Keep language clear and professional
- Update keyboard reference tables when adding bindings
- Add new features to the appropriate section
- Update version in changelog

## Release Process

Maintainers will:
1. Review and test pull requests
2. Merge approved changes to `main` branch
3. Tag releases with semantic versioning (e.g., `v1.1.0`)
4. Update changelog in README.md
5. Create GitHub release with notes

## Questions?

Open a [GitHub Discussion](https://github.com/FiLORUX/mpv-broadcast-suite/discussions) for:
- General questions about usage
- Feature brainstorming
- Best practices discussions
- Workflow optimisation tips

## Recognition

Contributors will be recognised in:
- README.md acknowledgements section
- Git commit history
- Release notes for significant contributions

Thank you for contributing to the broadcast engineering community!

