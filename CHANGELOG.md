# Changelog

## 1.0.2
- Remove .luaurc from Wally package to fix transitive dependency resolution
- Bump dependencies and update submodules

## 1.0.1
- Include .luaurc in Wally package
- Standardize test runner with code coverage

## 1.0.0
- Superseded broken 0.1.0 registry entry that included DevPackages/Packages in default.project.json

## 0.0.3
- Removed Packages and DevPackages entries from default.project.json to fix sourcemap generation in consuming projects

## 0.0.2
- Synced configuration with luau-package-template
- Updated lune to 0.10.4-horse.6.0
- Cleaned up project files to match template structure
- Updated submodules and tool versions
- Added yml/yaml 2-space indent rule to editorconfig
- Ignored DevPackages and Packages in static analysis
- Fixed CI issues
- Fixed nested reset style not restoring outer styles

## 0.0.1
- Initial release
- Added terminal string styling with ANSI color codes
- Added text modifiers (bold, dim, italic, underline, etc.)
- Added foreground and background colors (16 standard + bright variants)
- Added dynamic color functions (rgb, hex, ansi256)
- Fixed nested reset styles now properly restore outer styles
