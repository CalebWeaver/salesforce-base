#!/bin/bash
# Initialize a new Salesforce project from the baseline template.
# Assembles AI agent rules (CLAUDE.md + Cursor) and copies templates
# based on the selected profile.

set -e

# ─── Resolve paths ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROFILES_DIR="$ROOT_DIR/profiles"
TEMPLATES_DIR="$ROOT_DIR/templates"
REFS_FILE="$ROOT_DIR/references/repos.json"

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ─── Helper functions ────────────────────────────────────────────
print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  Salesforce Project Initializer${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "\n${BOLD}${GREEN}▸ $1${NC}"
}

print_info() {
    echo -e "  ${CYAN}$1${NC}"
}

print_warn() {
    echo -e "  ${YELLOW}⚠ $1${NC}"
}

print_done() {
    echo -e "  ${GREEN}✓ $1${NC}"
}

# ─── Check dependencies ─────────────────────────────────────────
check_deps() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        echo "  Install with: brew install jq (macOS) or apt install jq (Linux)"
        exit 1
    fi
    if ! command -v sf &> /dev/null; then
        echo -e "${YELLOW}⚠ Salesforce CLI (sf) not found. SFDX project scaffolding will be skipped.${NC}"
        echo "  Install from: https://developer.salesforce.com/tools/salesforcecli"
        SF_AVAILABLE=false
    else
        SF_AVAILABLE=true
    fi
}

# ─── Profile selection ───────────────────────────────────────────
select_profile() {
    print_step "Select project profile"
    echo ""
    echo "  1) POC / Demo"
    echo "     Minimal structure for proofs of concept and demos."
    echo "     No tests, no SecurityEnforcer, just TriggerHandler."
    echo "     Includes a promotion checklist for hardening later."
    echo ""
    echo "  2) Lightweight"
    echo "     Simple trigger handlers, no FFLib. Best for small-to-medium"
    echo "     projects that need proper tests and security."
    echo ""
    echo "  3) Enterprise (FFLib)"
    echo "     Full Domain-Service-Selector-UnitOfWork architecture."
    echo "     Best for large, long-lived projects with multiple developers."
    echo ""

    while true; do
        read -p "  Choose profile [1/2/3]: " choice
        case "$choice" in
            1) PROFILE="poc"; break ;;
            2) PROFILE="lightweight"; break ;;
            3) PROFILE="enterprise"; break ;;
            *) echo -e "  ${RED}Please enter 1, 2, or 3${NC}" ;;
        esac
    done

    print_done "Selected profile: $PROFILE"
}

# ─── Project name ────────────────────────────────────────────────
select_project_name() {
    print_step "Project name"
    echo ""
    echo "  This will be used as the SFDX project name and directory name."
    echo "  Use lowercase with hyphens (e.g., my-sf-project)."
    echo ""

    while true; do
        read -p "  Project name: " name_input
        if [ -z "$name_input" ]; then
            echo -e "  ${RED}Project name is required${NC}"
        elif [[ ! "$name_input" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
            echo -e "  ${RED}Invalid name. Use letters, numbers, hyphens, underscores. Must start with a letter.${NC}"
        else
            PROJECT_NAME="$name_input"
            break
        fi
    done

    print_done "Project name: $PROJECT_NAME"
}

# ─── Scaffold SFDX project ──────────────────────────────────────
scaffold_sfdx_project() {
    print_step "Scaffolding SFDX project"

    if ! $SF_AVAILABLE; then
        print_warn "Salesforce CLI not available — skipping sf project generate"
        print_info "Run 'sf project generate -n $PROJECT_NAME' manually later"
        mkdir -p "$TARGET_DIR"
        return
    fi

    # If target already has sfdx-project.json, skip scaffolding
    if [ -f "$TARGET_DIR/sfdx-project.json" ]; then
        print_info "sfdx-project.json already exists — skipping scaffold"
        return
    fi

    # Generate into parent dir so sf creates the project folder
    local parent_dir=$(dirname "$TARGET_DIR")
    mkdir -p "$parent_dir"

    sf project generate -n "$PROJECT_NAME" -d "$parent_dir" --template standard 2>/dev/null
    print_done "Generated SFDX project at $TARGET_DIR"

    # Create scratch org config if it doesn't exist
    if [ ! -f "$TARGET_DIR/config/project-scratch-def.json" ]; then
        mkdir -p "$TARGET_DIR/config"
        cat > "$TARGET_DIR/config/project-scratch-def.json" << 'SCRATCH_EOF'
{
  "orgName": "Scratch Org",
  "edition": "Developer",
  "features": [],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    }
  }
}
SCRATCH_EOF
        print_done "Created config/project-scratch-def.json"
    fi
}

# ─── Optional add-ons ────────────────────────────────────────────
select_addons() {
    # NebulaLogger is bundled with enterprise, not available for lightweight
    # This function is kept as a hook for future optional add-ons
    INCLUDE_NEBULA=false  # not used as a toggle anymore; included via manifest
}

# ─── Target directory ────────────────────────────────────────────
select_target() {
    print_step "Target project directory"
    echo ""
    echo "  Where should the project be created?"
    echo "  The project name ($PROJECT_NAME) will be used as the directory name."
    echo "  Enter the parent directory, or press Enter to create it next to this baseline repo."
    echo ""

    local default_parent=$(dirname "$ROOT_DIR")
    read -p "  Parent directory [${default_parent}]: " target_input
    local parent="${target_input:-$default_parent}"

    # Expand ~ if present
    parent="${parent/#\~/$HOME}"

    TARGET_DIR="$parent/$PROJECT_NAME"

    if [ -d "$TARGET_DIR" ]; then
        print_warn "Directory $TARGET_DIR already exists"
        read -p "  Continue and merge into existing directory? [Y/n]: " merge_choice
        case "$merge_choice" in
            [nN]*) echo "Aborted."; exit 0 ;;
            *)     print_info "Will merge into existing directory" ;;
        esac
    fi

    print_done "Target: $TARGET_DIR"
}

# ─── Assemble CLAUDE.md ─────────────────────────────────────────
assemble_claude_md() {
    print_step "Assembling CLAUDE.md"

    local output_dir="$TARGET_DIR/.claude"
    local output_file="$output_dir/CLAUDE.md"
    local manifest="$PROFILES_DIR/$PROFILE/manifest.json"

    mkdir -p "$output_dir"

    # Check if this profile uses a standalone rules file (no composition)
    local standalone_rules=$(jq -r '.rules.standalone // empty' "$manifest" 2>/dev/null)

    if [ -n "$standalone_rules" ]; then
        # Standalone profile — copy directly, no composition
        cp "$ROOT_DIR/$standalone_rules" "$output_file"
    else
        # Composed profile — base + overlay
        local base_rules="$PROFILES_DIR/base/rules-base.md"
        local overlay_rules="$PROFILES_DIR/$PROFILE/rules-overlay.md"

        cp "$base_rules" "$output_file"

        if [ -f "$overlay_rules" ]; then
            echo "" >> "$output_file"
            echo "# ─── Profile-Specific Patterns ───────────────────────────────" >> "$output_file"
            cat "$overlay_rules" >> "$output_file"
        fi

        # Profile-specific notes
        if [ "$PROFILE" = "lightweight" ]; then
            echo "" >> "$output_file"
            echo "## Logging Note" >> "$output_file"
            echo "" >> "$output_file"
            echo "NebulaLogger is **not included** in this project profile. Use \`System.debug()\` for logging. If the project grows and you need enterprise logging, consider switching to the enterprise profile or manually adding NebulaLogger." >> "$output_file"
        fi
    fi

    print_done "Created $output_file"

    # Copy Claude slash commands (skills) into .claude/commands/
    local commands_src="$TEMPLATES_DIR/.claude/commands"
    local commands_dest="$output_dir/commands"
    if [ -d "$commands_src" ]; then
        mkdir -p "$commands_dest"
        cp "$commands_src"/*.md "$commands_dest/" 2>/dev/null || true
        print_done "Copied Claude commands to .claude/commands/"
    fi
}

# ─── Assemble Cursor rules ──────────────────────────────────────
assemble_cursor_rules() {
    print_step "Assembling Cursor rules"

    local output_dir="$TARGET_DIR/.cursor/rules"
    local output_file="$output_dir/salesforce-development.mdc"
    local manifest="$PROFILES_DIR/$PROFILE/manifest.json"

    mkdir -p "$output_dir"

    # Check if this profile uses a standalone cursor rules file (no composition)
    local standalone_cursor=$(jq -r '.cursorRules.standalone // empty' "$manifest" 2>/dev/null)

    if [ -n "$standalone_cursor" ]; then
        # Standalone profile — copy directly, no composition
        cp "$ROOT_DIR/$standalone_cursor" "$output_file"
    else
        # Composed profile — base + overlay
        local base_cursor="$PROFILES_DIR/base/cursor-base.mdc"
        local overlay_cursor="$PROFILES_DIR/$PROFILE/cursor-overlay.mdc"

        cp "$base_cursor" "$output_file"

        if [ -f "$overlay_cursor" ]; then
            echo "" >> "$output_file"
            # Strip YAML frontmatter from overlay before appending
            sed -n '/^---$/,/^---$/!p' "$overlay_cursor" >> "$output_file"
        fi
    fi

    print_done "Created $output_file"
}

# ─── Copy templates ──────────────────────────────────────────────
copy_templates() {
    print_step "Copying templates"

    local manifest="$PROFILES_DIR/$PROFILE/manifest.json"
    local dest="$TARGET_DIR/templates/salesforce/classes"

    mkdir -p "$dest"

    # Read copy paths from manifest
    jq -r '.templates.copy[]' "$manifest" | while read -r path; do
        local src="$ROOT_DIR/$path"
        # Strip the templates/salesforce/classes/ prefix to get relative path
        local rel_path=$(echo "$path" | sed "s|^templates/salesforce/classes/||")

        if [ -d "$src" ]; then
            # It's a directory — copy recursively, preserving relative position
            local target_dir="$dest/$rel_path"
            mkdir -p "$(dirname "$target_dir")"
            cp -r "$src" "$target_dir"
            print_done "Copied directory: $(basename "$rel_path")/"
        elif [ -f "$src" ]; then
            # It's a file — preserve directory structure
            local target_file="$dest/$rel_path"
            mkdir -p "$(dirname "$target_file")"
            cp "$src" "$target_file"
            print_done "Copied: $(basename "$path")"
        else
            print_warn "Not found: $path"
        fi
    done
}

# ─── Copy references config ─────────────────────────────────────
setup_references() {
    print_step "Setting up references"

    local refs_dest="$TARGET_DIR/references"
    mkdir -p "$refs_dest"

    # Filter repos.json to only include repos for this profile
    local manifest="$PROFILES_DIR/$PROFILE/manifest.json"
    local required_repos=$(jq -r '.references.required[]' "$manifest" 2>/dev/null)
    local optional_repos=$(jq -r '.references.optional[]' "$manifest" 2>/dev/null)

    # Build filtered repos.json
    local all_repos="$required_repos $optional_repos"

    # Create a jq filter for the selected repos
    local jq_filter=""
    for repo in $all_repos; do
        if [ -n "$jq_filter" ]; then
            jq_filter="$jq_filter or"
        fi
        jq_filter="$jq_filter .name == \"$repo\""
    done

    if [ -n "$jq_filter" ]; then
        jq "{repos: [.repos[] | select($jq_filter)]}" "$REFS_FILE" > "$refs_dest/repos.json"
        print_done "Created filtered repos.json"
    fi

    # Copy supporting files
    if [ -f "$ROOT_DIR/references/README.md" ]; then
        cp "$ROOT_DIR/references/README.md" "$refs_dest/README.md"
        print_done "Copied references README"
    fi

    if [ -f "$ROOT_DIR/references/.gitignore" ]; then
        cp "$ROOT_DIR/references/.gitignore" "$refs_dest/.gitignore"
        print_done "Copied references .gitignore"
    fi

    # Copy shared reference docs (async-patterns, lwc-patterns, etc.)
    for ref_file in "$ROOT_DIR"/references/*.md; do
        local basename=$(basename "$ref_file")
        if [ "$basename" != "README.md" ]; then
            cp "$ref_file" "$refs_dest/$basename"
            print_done "Copied $basename"
        fi
    done

    # Copy pattern files based on profile
    local standalone_rules=$(jq -r '.rules.standalone // empty' "$manifest" 2>/dev/null)
    local patterns_src="$ROOT_DIR/references/patterns"
    local patterns_dest="$refs_dest/patterns"

    if [ -n "$standalone_rules" ]; then
        # Standalone profile — only copy its own pattern directory
        if [ -d "$patterns_src/$PROFILE" ]; then
            mkdir -p "$patterns_dest/$PROFILE"
            cp -r "$patterns_src/$PROFILE/"* "$patterns_dest/$PROFILE/"
            print_done "Copied patterns/$PROFILE/"
        fi
    else
        # Composed profile — copy base patterns + profile-specific patterns
        if [ -d "$patterns_src/base" ]; then
            mkdir -p "$patterns_dest/base"
            cp -r "$patterns_src/base/"* "$patterns_dest/base/"
            print_done "Copied patterns/base/"
        fi
        if [ -d "$patterns_src/$PROFILE" ]; then
            mkdir -p "$patterns_dest/$PROFILE"
            cp -r "$patterns_src/$PROFILE/"* "$patterns_dest/$PROFILE/"
            print_done "Copied patterns/$PROFILE/"
        fi
    fi
}

# ─── Copy scripts ────────────────────────────────────────────────
copy_scripts() {
    print_step "Copying scripts"

    local scripts_dest="$TARGET_DIR/scripts"
    mkdir -p "$scripts_dest"

    cp "$ROOT_DIR/scripts/sync-references.sh" "$scripts_dest/sync-references.sh"
    chmod +x "$scripts_dest/sync-references.sh"
    print_done "Copied sync-references.sh"

    # Copy init script too for future re-runs
    cp "$ROOT_DIR/scripts/init-project.sh" "$scripts_dest/init-project.sh"
    chmod +x "$scripts_dest/init-project.sh"
    print_done "Copied init-project.sh"
}

# ─── Scaffold docs ──────────────────────────────────────────────
scaffold_docs() {
    print_step "Scaffolding project documentation"

    local docs_dir="$TARGET_DIR/docs"
    local modules_dir="$docs_dir/modules"
    local stories_dir="$docs_dir/user-stories"

    mkdir -p "$modules_dir" "$stories_dir"

    # Copy project reference if it doesn't already exist
    if [ ! -f "$docs_dir/project-reference.md" ]; then
        cp "$ROOT_DIR/templates/docs/project-reference.md" "$docs_dir/project-reference.md"
        print_done "Created docs/project-reference.md"
    else
        print_info "docs/project-reference.md already exists — skipping"
    fi

    # Copy architecture template if it doesn't already exist
    if [ ! -f "$docs_dir/architecture.md" ]; then
        cp "$ROOT_DIR/templates/docs/architecture.md" "$docs_dir/architecture.md"
        print_done "Created docs/architecture.md"
    else
        print_info "docs/architecture.md already exists — skipping"
    fi

    # Copy modules README if it doesn't already exist
    if [ ! -f "$modules_dir/README.md" ]; then
        cp "$ROOT_DIR/templates/docs/modules/README.md" "$modules_dir/README.md"
        print_done "Created docs/modules/README.md"
    else
        print_info "docs/modules/README.md already exists — skipping"
    fi

    # Copy user stories README if it doesn't already exist
    if [ ! -f "$stories_dir/README.md" ]; then
        cp "$ROOT_DIR/templates/docs/user-stories/README.md" "$stories_dir/README.md"
        print_done "Created docs/user-stories/README.md"
    else
        print_info "docs/user-stories/README.md already exists — skipping"
    fi
}

# ─── Copy .gitignore ────────────────────────────────────────────
copy_gitignore() {
    local gitignore_template="$ROOT_DIR/templates/gitignore"
    if [ -f "$gitignore_template" ]; then
        if [ -f "$TARGET_DIR/.gitignore" ]; then
            print_info ".gitignore already exists — skipping"
        else
            cp "$gitignore_template" "$TARGET_DIR/.gitignore"
            print_done "Created .gitignore"
        fi
    else
        print_info "No gitignore template found — skipping"
    fi
}

# ─── Write profile marker ───────────────────────────────────────
write_profile_marker() {
    print_step "Writing profile configuration"

    cat > "$TARGET_DIR/.sf-profile" << EOF
# Salesforce Baseline Profile
# Generated by init-project.sh on $(date '+%Y-%m-%d %H:%M:%S')
PROJECT_NAME=$PROJECT_NAME
PROFILE=$PROFILE
EOF

    print_done "Created .sf-profile"
}

# ─── Summary ─────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  Project Initialized!${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BOLD}Project:${NC}       $PROJECT_NAME"
    echo -e "  ${BOLD}Profile:${NC}       $PROFILE"
    echo -e "  ${BOLD}Target:${NC}        $TARGET_DIR"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    local step=1
    echo -e "  $step. cd $TARGET_DIR"
    step=$((step + 1))

    if ! $SF_AVAILABLE && [ ! -f "$TARGET_DIR/sfdx-project.json" ]; then
        echo -e "  $step. sf project generate -n $PROJECT_NAME    ${CYAN}# Install SF CLI first${NC}"
        step=$((step + 1))
    fi

    echo -e "  $step. ./scripts/sync-references.sh    ${CYAN}# Clone reference repos${NC}"
    step=$((step + 1))

    if [ "$PROFILE" = "enterprise" ]; then
        echo -e "  $step. Install packages:"
        jq -r '.repos[] | select(.profiles != null and (.profiles | index("enterprise"))) | select(.installMethod == "package") | "     " + .name + ": " + .packageInstall.unlocked' "$REFS_FILE" 2>/dev/null
        step=$((step + 1))
    fi

    echo ""
}

# ─── Main ────────────────────────────────────────────────────────
main() {
    print_header
    check_deps

    # Support non-interactive mode
    if [ -n "$1" ]; then
        case "$1" in
            --profile)
                PROFILE="$2"
                if [ "$PROFILE" != "poc" ] && [ "$PROFILE" != "lightweight" ] && [ "$PROFILE" != "enterprise" ]; then
                    echo -e "${RED}Error: Unknown profile '$PROFILE'. Use 'poc', 'lightweight', or 'enterprise'.${NC}"
                    exit 1
                fi
                INCLUDE_NEBULA=false
                PROJECT_NAME=""
                TARGET_DIR=""
                # Parse remaining flags
                shift 2
                while [ $# -gt 0 ]; do
                    case "$1" in
                        --name) PROJECT_NAME="$2"; shift ;;
                        --target) TARGET_DIR="$2"; shift ;;
                        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
                    esac
                    shift
                done
                # Require project name
                if [ -z "$PROJECT_NAME" ]; then
                    echo -e "${RED}Error: --name is required. Provide a project name.${NC}"
                    exit 1
                fi
                # Default target: sibling directory of baseline repo
                if [ -z "$TARGET_DIR" ]; then
                    TARGET_DIR="$(dirname "$ROOT_DIR")/$PROJECT_NAME"
                fi
                ;;
            --help|-h)
                echo "Usage: init-project.sh [OPTIONS]"
                echo ""
                echo "Interactive mode (no arguments):"
                echo "  ./scripts/init-project.sh"
                echo ""
                echo "Non-interactive mode:"
                echo "  ./scripts/init-project.sh --profile <poc|lightweight|enterprise> --name <project-name> [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --profile <name>      Project profile (poc, lightweight, or enterprise)"
                echo "  --name <project-name> SFDX project name (required, e.g., my-sf-project)"
                echo "  --target <dir>        Target directory (default: ../<project-name>)"
                echo "  --help, -h            Show this help"
                echo ""
                echo "Examples:"
                echo "  ./scripts/init-project.sh --profile poc --name field-routing-demo"
                echo "  ./scripts/init-project.sh --profile lightweight --name client-portal"
                echo "  ./scripts/init-project.sh --profile enterprise --name crm-overhaul --target ~/projects/crm-overhaul"
                echo ""
                echo "Notes:"
                echo "  NebulaLogger is automatically included with the enterprise profile."
                echo "  Requires Salesforce CLI (sf) for project scaffolding."
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1. Use --help for usage.${NC}"
                exit 1
                ;;
        esac
    else
        # Interactive mode
        select_project_name
        select_profile
        select_addons
        select_target
    fi

    # Execute
    scaffold_sfdx_project
    assemble_claude_md
    assemble_cursor_rules
    copy_templates
    setup_references
    copy_scripts
    scaffold_docs
    copy_gitignore
    write_profile_marker
    print_summary
}

main "$@"
